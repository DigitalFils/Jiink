import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

// GET /api/chat — list chat sessions
export async function GET() {
  try {
    const sessions = await db.chatSession.findMany({
      orderBy: { lastTime: 'desc' },
      include: { messages: { orderBy: { createdAt: 'asc' }, take: 1 } },
    })
    return NextResponse.json({ sessions })
  } catch (e) {
    console.error('chat list error', e)
    return NextResponse.json({ error: 'Failed to load chats' }, { status: 500 })
  }
}

// POST /api/chat — send message to a session
export async function POST(req: NextRequest) {
  try {
    const { sessionId, text } = await req.json()
    if (!sessionId || !text) {
      return NextResponse.json({ error: 'sessionId and text required' }, { status: 400 })
    }

    const message = await db.chatMessage.create({
      data: { sessionId, senderName: 'Me', text: String(text).slice(0, 500), isMe: true },
    })

    await db.chatSession.update({
      where: { id: sessionId },
      data: { lastMessage: String(text).slice(0, 80), lastTime: 'now', unread: 0 },
    })

    // Auto-reply simulation from the other party
    const replies = [
      'Sounds good 👍', 'Deal! Payment link sent.', 'Can you do £5 less?',
      'Sure, when can you ship?', 'Perfect — reserved for you.', 'Still available, yes!',
    ]
    const reply = replies[Math.floor(Math.random() * replies.length)]
    await db.chatMessage.create({
      data: { sessionId, senderName: 'them', text: reply, isMe: false },
    })
    await db.chatSession.update({
      where: { id: sessionId },
      data: { lastMessage: reply },
    })

    return NextResponse.json({ message, autoReply: reply }, { status: 201 })
  } catch (e) {
    console.error('chat send error', e)
    return NextResponse.json({ error: 'Failed to send message' }, { status: 500 })
  }
}
