import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await ctx.params
    const product = await db.product.findUnique({
      where: { id },
      include: {
        seller: {
          select: { id: true, username: true, avatar: true, rating: true, sales: true, isVerified: true, level: true, followers: true },
        },
      },
    })
    if (!product) return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    return NextResponse.json({ product })
  } catch (e) {
    console.error('product detail error', e)
    return NextResponse.json({ error: 'Failed to load product' }, { status: 500 })
  }
}
