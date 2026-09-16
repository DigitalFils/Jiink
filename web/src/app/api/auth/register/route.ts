import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { db } from '@/lib/db'
import { hashPassword, createSession, rateLimit, clientIp, sessionUserSelect } from '@/lib/auth'

export const dynamic = 'force-dynamic'

const Body = z.object({
  username: z
    .string()
    .trim()
    .min(3, 'Username must be at least 3 characters')
    .max(24, 'Username must be 24 characters or fewer')
    // Usernames appear in public listings and chat, so keep them to
    // characters that can't be used to impersonate another name with
    // lookalike or invisible glyphs.
    .regex(/^[a-zA-Z0-9_]+$/, 'Use letters, numbers and underscores only'),
  email: z.string().trim().toLowerCase().email('Enter a valid email address'),
  // Length beats composition rules: NIST dropped the "one symbol, one
  // digit" advice because it pushes people toward Passw0rd! and nothing
  // stronger.
  password: z.string().min(8, 'Password must be at least 8 characters').max(200),
})

export async function POST(req: NextRequest) {
  const ip = clientIp(req) ?? 'unknown'
  const limit = rateLimit(`register:${ip}`, 5, 60 * 60 * 1000)
  if (!limit.ok) {
    return NextResponse.json(
      { error: 'Too many accounts created from here. Try again later.' },
      { status: 429, headers: { 'Retry-After': String(limit.retryAfter) } },
    )
  }

  let parsed
  try {
    parsed = Body.safeParse(await req.json())
  } catch {
    return NextResponse.json({ error: 'Expected a JSON body' }, { status: 400 })
  }
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid details', field: parsed.error.issues[0]?.path[0] },
      { status: 400 },
    )
  }
  const { username, email, password } = parsed.data

  const clash = await db.user.findFirst({
    where: { OR: [{ email }, { username }] },
    select: { email: true, username: true },
  })
  if (clash) {
    // Registration genuinely cannot hide whether an account exists — the
    // uniqueness constraint is the whole point — so say which field, and
    // rely on the rate limit above to stop bulk enumeration.
    const field = clash.email === email ? 'email' : 'username'
    return NextResponse.json(
      { error: field === 'email' ? 'That email already has an account' : 'That username is taken', field },
      { status: 409 },
    )
  }

  const user = await db.user.create({
    data: {
      username,
      email,
      passwordHash: await hashPassword(password),
      avatar: `https://i.pravatar.cc/150?u=${encodeURIComponent(username)}`,
      // Deliberately not seeded with a balance. The schema's £1240.50
      // default is demo furniture; a real new account starts at zero and
      // only moves when money actually moves. The same goes for the rest
      // of the demo defaults — 2,840 points and a 4.8 rating on an account
      // that has never sold anything is a fabricated reputation, and
      // reputation is exactly what a buyer is trusting.
      balance: 0,
      points: 0,
      rating: 0,
      sales: 0,
      level: 1,
      xp: 0,
      followers: 0,
    },
    select: sessionUserSelect,
  })

  await createSession(user.id, { userAgent: req.headers.get('user-agent'), ip })
  return NextResponse.json({ user }, { status: 201 })
}
