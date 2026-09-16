
import { randomBytes, scrypt as scryptCb, timingSafeEqual, createHash } from 'node:crypto'
import { promisify } from 'node:util'
import { cookies } from 'next/headers'
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'

const scrypt = promisify(scryptCb) as (
  password: string | Buffer,
  salt: string | Buffer,
  keylen: number,
) => Promise<Buffer>

// --------------------------------------------------------------- passwords

/**
 * scrypt from Node's own crypto, not bcrypt.
 *
 * It is memory-hard, it is in the standard library (no native module to
 * build, nothing new to audit), and OWASP lists it as an acceptable choice
 * for password storage. The cost parameters below are the defaults Node
 * ships (N=16384, r=8, p=1), which is roughly 16MB of memory per hash —
 * enough to make large-scale offline cracking expensive.
 */
const SCRYPT_KEYLEN = 64
const SALT_BYTES = 16

/** `scrypt$<salt hex>$<hash hex>` — self-describing, so the format can be
 * migrated later without guessing what produced an existing row. */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(SALT_BYTES)
  const hash = await scrypt(password.normalize('NFKC'), salt, SCRYPT_KEYLEN)
  return `scrypt$${salt.toString('hex')}$${hash.toString('hex')}`
}

/**
 * A real hash of a password nobody has. When an email doesn't exist, the
 * login route still verifies against this, so "no such account" costs the
 * same ~100ms of scrypt as "wrong password" instead of returning instantly
 * and telling an attacker which emails are registered.
 */
const DUMMY_HASH =
  'scrypt$00000000000000000000000000000000$' + '0'.repeat(SCRYPT_KEYLEN * 2)

export async function verifyPassword(password: string, stored: string | null): Promise<boolean> {
  // Not an early return: hashing anyway is the whole point.
  const record = stored ?? DUMMY_HASH
  const [scheme, saltHex, hashHex] = record.split('$')
  if (scheme !== 'scrypt' || !saltHex || !hashHex) return false

  const expected = Buffer.from(hashHex, 'hex')
  const actual = await scrypt(password.normalize('NFKC'), Buffer.from(saltHex, 'hex'), expected.length)
  // timingSafeEqual, not ===: comparing byte by byte and bailing early
  // leaks how much of the hash matched through response timing.
  const match = expected.length === actual.length && timingSafeEqual(expected, actual)
  // The dummy can never be a pass, even in the impossible case that
  // scrypt(password) collides with a run of zero bytes.
  return stored === null ? false : match
}

// ---------------------------------------------------------------- sessions

export const SESSION_COOKIE = 's8ll_session'

/** 30 days. Long enough that a shopper isn't logged out between visits,
 * short enough that an abandoned session on a shared phone expires. */
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000

/** The cookie carries the raw token; the database stores only its digest.
 * A dump of the sessions table therefore grants nobody a session. SHA-256
 * is right here (unlike for passwords) because the input is 256 bits of
 * entropy — there is nothing to brute-force. */
function digest(token: string): string {
  return createHash('sha256').update(token).digest('hex')
}

export type SessionUser = {
  id: string
  username: string
  email: string | null
  avatar: string
  bio: string
  isVerified: boolean
  balance: number
  points: number
  /** Seller standing. Real columns, so the profile screen can stop
   * inventing "Level 4 — 127 sales" for an account that has made none. */
  level: number
  xp: number
  sales: number
  rating: number
  followers: number
}

const sessionUserSelect = {
  id: true,
  username: true,
  email: true,
  avatar: true,
  bio: true,
  isVerified: true,
  balance: true,
  points: true,
  level: true,
  xp: true,
  sales: true,
  rating: true,
  followers: true,
} as const

/** Exported so the login and register routes return exactly the same
 * fields `/api/auth/me` does — three hand-written select lists is how they
 * drift. */
export { sessionUserSelect }

/** Issues a session and sets the cookie. Returns the raw token for tests. */
export async function createSession(
  userId: string,
  meta: { userAgent?: string | null; ip?: string | null } = {},
): Promise<string> {
  const token = randomBytes(32).toString('base64url')
  const expiresAt = new Date(Date.now() + SESSION_TTL_MS)

  await db.session.create({
    data: {
      tokenHash: digest(token),
      userId,
      expiresAt,
      userAgent: meta.userAgent?.slice(0, 256) ?? null,
      ip: meta.ip?.slice(0, 64) ?? null,
    },
  })

  const jar = await cookies()
  jar.set(SESSION_COOKIE, token, {
    httpOnly: true, // JavaScript can never read it, so XSS can't steal it
    sameSite: 'lax', // blocks the cookie on cross-site POSTs (CSRF)
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    expires: expiresAt,
  })

  return token
}

/** The signed-in user, or null. Expired sessions are deleted as they're
 * found, so the table doesn't accumulate dead rows without a cron job. */
export async function getSessionUser(): Promise<SessionUser | null> {
  const jar = await cookies()
  const token = jar.get(SESSION_COOKIE)?.value
  if (!token) return null

  const session = await db.session.findUnique({
    where: { tokenHash: digest(token) },
    include: { user: { select: sessionUserSelect } },
  })
  if (!session) return null

  if (session.expiresAt.getTime() <= Date.now()) {
    await db.session.delete({ where: { id: session.id } }).catch(() => {})
    return null
  }

  return session.user
}

export async function destroySession(): Promise<void> {
  const jar = await cookies()
  const token = jar.get(SESSION_COOKIE)?.value
  if (token) {
    // Delete the row, not just the cookie: otherwise a token copied off the
    // device before logout would still be a valid session.
    await db.session.deleteMany({ where: { tokenHash: digest(token) } })
  }
  jar.delete(SESSION_COOKIE)
}

/** Revokes every session for a user — used after a password change, and
 * what a "sign out everywhere" button would call. */
export async function destroyAllSessions(userId: string): Promise<number> {
  const { count } = await db.session.deleteMany({ where: { userId } })
  return count
}

// ------------------------------------------------------------ route guards

export class UnauthorizedError extends Error {
  constructor() {
    super('Sign in required.')
    this.name = 'UnauthorizedError'
  }
}

/** For routes that must have a user. Throws [UnauthorizedError], which
 * `withUser` turns into a 401. */
export async function requireUser(): Promise<SessionUser> {
  const user = await getSessionUser()
  if (!user) throw new UnauthorizedError()
  return user
}

export function clientIp(req: NextRequest): string | null {
  // x-forwarded-for is only trustworthy behind a proxy that sets it (the
  // Caddyfile in this repo does). Take the first hop, which is the client.
  const fwd = req.headers.get('x-forwarded-for')
  if (fwd) return fwd.split(',')[0]!.trim()
  return req.headers.get('x-real-ip')
}

// ----------------------------------------------------------- rate limiting

type Bucket = { count: number; resetAt: number }
const buckets = new Map<string, Bucket>()

/**
 * A small fixed-window limiter for credential endpoints.
 *
 * In-memory, so it is per-process: it slows down password guessing against
 * a single server, and it does not survive a restart or coordinate across
 * instances. That is a real limit, not an oversight — the moment this runs
 * on more than one instance it needs to move to Redis or the database.
 * Until then it is still worth having, because the alternative is unlimited
 * guesses.
 */
/**
 * Production limits are the real ones. Outside production they are raised,
 * because the end-to-end suite registers several accounts per run and a
 * 5-per-hour limit means the second run of the day fails for reasons that
 * have nothing to do with the code under test — which teaches whoever sees
 * it to ignore the suite.
 *
 * This deliberately reads `NODE_ENV`, which Next sets itself, rather than a
 * variable someone could set on a production box to unlock it.
 */
const relaxed = process.env.NODE_ENV !== 'production'

export const LIMITS = {
  register: { limit: relaxed ? 200 : 5, windowMs: 60 * 60 * 1000 },
  login: { limit: relaxed ? 200 : 10, windowMs: 15 * 60 * 1000 },
} as const

export function rateLimit(key: string, limit: number, windowMs: number): { ok: boolean; retryAfter: number } {
  const now = Date.now()
  const bucket = buckets.get(key)

  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs })
    return { ok: true, retryAfter: 0 }
  }
  bucket.count += 1
  if (bucket.count > limit) {
    return { ok: false, retryAfter: Math.ceil((bucket.resetAt - now) / 1000) }
  }
  return { ok: true, retryAfter: 0 }
}
