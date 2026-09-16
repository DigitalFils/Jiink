import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { db } from '@/lib/db'
import { verifyPassword, createSession, rateLimit, clientIp, sessionUserSelect, LIMITS } from '@/lib/auth'

export const dynamic = 'force-dynamic'

const Body = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1),
})

export async function POST(req: NextRequest) {
  const ip = clientIp(req) ?? 'unknown'
  const limit = rateLimit(`login:${ip}`, LIMITS.login.limit, LIMITS.login.windowMs)
  if (!limit.ok) {
    return NextResponse.json(
      { error: 'Too many attempts. Try again shortly.' },
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
    return NextResponse.json({ error: 'Enter your email and password' }, { status: 400 })
  }
  const { email, password } = parsed.data

  const user = await db.user.findUnique({
    where: { email },
    select: { ...sessionUserSelect, passwordHash: true },
  })

  // One message for "no such account" and for "wrong password", so this
  // endpoint can't be used to find out which emails are registered.
  // verifyPassword still runs on a null hash so both paths do comparable
  // work rather than the missing-account case returning noticeably faster.
  const ok = await verifyPassword(password, user?.passwordHash ?? null)
  if (!user || !ok) {
    return NextResponse.json({ error: 'Email or password is incorrect' }, { status: 401 })
  }

  const { passwordHash: _discard, ...safe } = user
  await createSession(user.id, { userAgent: req.headers.get('user-agent'), ip })
  return NextResponse.json({ user: safe })
}
