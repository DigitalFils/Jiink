import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

// GET /api/chat/[sessionId] — messages for one session
export async function GET(_req: NextRequest, ctx: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await ctx.params
    const session = await db.chatSession.findUnique({ where: { id: sessionId } })
    if (!session) return NextResponse.json({ error: 'Session not found' }, { status: 404 })

    const messages = await db.chatMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    })

    await db.chatSession.update({ where: { id: sessionId }, data: { unread: 0 } })

    return NextResponse.json({ session, messages })
  } catch (e) {
    console.error('chat messages error', e)
    return NextResponse.json({ error: 'Failed to load messages' }, { status: 500 })
  }
}
