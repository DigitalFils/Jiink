import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const groupBuys = await db.groupBuy.findMany({ orderBy: { endsAt: 'asc' } })
    return NextResponse.json({ groupBuys })
  } catch (e) {
    console.error('groupbuys error', e)
    return NextResponse.json({ error: 'Failed to load group buys' }, { status: 500 })
  }
}
