import { NextRequest, NextResponse } from 'next/server'
import ZAI from 'z-ai-web-dev-sdk'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'
export const maxDuration = 60

interface ChatMsg {
  role: 'user' | 'assistant'
  content: string
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const messages: ChatMsg[] = Array.isArray(body.messages) ? body.messages.slice(-12) : []

    const lastUser = [...messages].reverse().find((m) => m.role === 'user')?.content || ''
    if (!lastUser) {
      return NextResponse.json({ error: 'messages required' }, { status: 400 })
    }

    // Inject live catalog context so the assistant recommends REAL products
    const products = await db.product.findMany({
      take: 30,
      include: { seller: { select: { username: true } } },
    })
    const catalog = products
      .map(
        (p) =>
          `#${p.id.slice(-6)} | ${p.title} | £${p.price}${p.originalPrice ? ` (was £${p.originalPrice})` : ''} | ${p.category} | ${p.condition} | ${p.location} | seller: ${p.seller.username}${p.isVerified ? ' [VERIFIED]' : ''}${p.isFlashSale ? ' [FLASH SALE]' : ''}`,
      )
      .join('\n')

    const systemPrompt = `You are S8LL AI, the shopping assistant inside the S8LL marketplace app (a blend of Avito, Dewu/Poizon, PDD and Xiaohongshu). You help users find products, compare prices, spot deals, and decide.

The user's currency is GBP (£). Be concise, friendly and concrete — like a knowledgeable friend. When you mention products, ALWAYS reference real items from the catalog below using their title and price.

Rules:
- Keep answers under 120 words unless asked for more detail.
- Recommend up to 3 products per answer.
- You can mention app features: Flash Sales (up to 70% off), Group Buy (PDD-style team deals), Live Stream shopping, AR Try-On for sneakers, Wallet, Wishlist price alerts, and Dewu-style authentication (verified badge + 10x money-back guarantee).
- Never invent products that are not in the catalog.

CATALOG:
${catalog}`

    const zai = await ZAI.create()
    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'assistant', content: systemPrompt },
        ...messages.map((m) => ({ role: m.role, content: m.content })),
      ],
      thinking: { type: 'disabled' },
    })

    const reply = completion.choices[0]?.message?.content
    if (!reply || !reply.trim()) {
      return NextResponse.json({ error: 'Empty AI response' }, { status: 502 })
    }

    // Attach the catalog products that are actually mentioned in the reply as cards
    const mentioned = products.filter((p) => {
      const t = p.title.toLowerCase()
      const core = t.split(/[,—(-]/)[0].trim()
      return core.length > 3 && reply.toLowerCase().includes(core.slice(0, 18))
    })
    const productCards = (mentioned.length > 0 ? mentioned : products.filter((p) => lastUser && p.category.toLowerCase().split(' ')[0].includes(lastUser.toLowerCase().split(' ')[0]))).slice(0, 3)

    return NextResponse.json({ reply, products: productCards })
  } catch (e) {
    console.error('ai chat error', e)
    return NextResponse.json({ error: 'AI assistant is unavailable right now' }, { status: 500 })
  }
}
