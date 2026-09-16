import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

// POST /api/groupbuys/[id] — join / leave a group buy
export async function POST(_req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await ctx.params
    const gb = await db.groupBuy.findUnique({ where: { id } })
    if (!gb) return NextResponse.json({ error: 'Group buy not found' }, { status: 404 })

    if (gb.joined) {
      const updated = await db.groupBuy.update({
        where: { id },
        data: { joined: false, participants: Math.max(1, gb.participants - 1) },
      })
      return NextResponse.json({ joined: false, groupBuy: updated })
    }

    const updated = await db.groupBuy.update({
      where: { id },
      data: { joined: true, participants: gb.participants + 1 },
    })
    return NextResponse.json({ joined: true, groupBuy: updated })
  } catch (e) {
    console.error('groupbuy join error', e)
    return NextResponse.json({ error: 'Failed to join group buy' }, { status: 500 })
  }
}
