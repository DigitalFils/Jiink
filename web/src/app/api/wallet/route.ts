import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { getSessionUser, requireUser, UnauthorizedError } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET() {
  const user = await getSessionUser()
  if (!user) return NextResponse.json({ error: 'Sign in required.' }, { status: 401 })

  // Scoped to the signed-in user. This previously read
  // `findFirst({ username: 'Abdalla' })` and returned his transactions to
  // every visitor.
  const transactions = await db.walletTransaction.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: 'desc' },
    take: 100,
  })

  return NextResponse.json({ balance: user.balance, points: user.points, transactions })
}

/**
 * Deliberately refuses to change the balance.
 *
 * What was here accepted an unauthenticated POST and did
 * `balance: { increment: amount }` with whatever number it was sent. One
 * curl with no credentials turned £1,690.50 into £251,690.50. There is no
 * payment provider behind this app yet, so there is no such thing as a
 * genuine top-up: any endpoint that raises a balance without money arriving
 * is a mint, however it is authenticated.
 *
 * It stays as a 501 rather than being deleted so the client gets a clear
 * answer instead of a 404, and so the shape of the route survives for the
 * Stripe work. When that lands, the balance moves in response to a verified
 * webhook from Stripe — never in response to a request from the client.
 */
export async function POST() {
  try {
    await requireUser()
  } catch (e) {
    if (e instanceof UnauthorizedError) {
      return NextResponse.json({ error: 'Sign in required.' }, { status: 401 })
    }
    throw e
  }

  return NextResponse.json(
    {
      error:
        'Top-ups are not available yet. A balance can only change when a real payment settles, ' +
        'and card payments are not connected to this app.',
    },
    { status: 501 },
  )
}
