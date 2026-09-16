import { NextResponse } from 'next/server'
import { getSessionUser } from '@/lib/auth'

export const dynamic = 'force-dynamic'

/** Who the caller is, or null. The client uses this on load to decide
 * between the signed-in app and the sign-in screen, so it answers 200 with
 * `user: null` rather than 401 — not being signed in is a normal answer
 * here, not an error. */
export async function GET() {
  return NextResponse.json({ user: await getSessionUser() })
}
