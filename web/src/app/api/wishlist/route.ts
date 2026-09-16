import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

const include = {
  product: {
    include: {
      seller: { select: { id: true, username: true, avatar: true, rating: true, sales: true, isVerified: true, level: true } },
    },
  },
}

export async function GET() {
  try {
    const items = await db.wishlistItem.findMany({
      orderBy: { addedAt: 'desc' },
      include,
    })
    return NextResponse.json({ items })
  } catch (e) {
    console.error('wishlist get error', e)
    return NextResponse.json({ error: 'Failed to load wishlist' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const { productId, collection } = await req.json()
    if (!productId) return NextResponse.json({ error: 'productId required' }, { status: 400 })

    const existing = await db.wishlistItem.findFirst({ where: { productId } })
    if (existing) {
      await db.wishlistItem.delete({ where: { id: existing.id } })
      return NextResponse.json({ removed: true })
    }

    const item = await db.wishlistItem.create({
      data: { productId, collection: collection || 'All' },
      include,
    })
    return NextResponse.json({ removed: false, item }, { status: 201 })
  } catch (e) {
    console.error('wishlist toggle error', e)
    return NextResponse.json({ error: 'Failed to update wishlist' }, { status: 500 })
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const { id, priceAlert, collection } = await req.json()
    if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
    const data: any = {}
    if (priceAlert != null) data.priceAlert = !!priceAlert
    if (collection) data.collection = collection
    const item = await db.wishlistItem.update({ where: { id }, data, include })
    return NextResponse.json({ item })
  } catch (e) {
    console.error('wishlist patch error', e)
    return NextResponse.json({ error: 'Failed to update item' }, { status: 500 })
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const id = req.nextUrl.searchParams.get('id')
    if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
    await db.wishlistItem.delete({ where: { id } })
    return NextResponse.json({ ok: true })
  } catch (e) {
    console.error('wishlist delete error', e)
    return NextResponse.json({ error: 'Failed to remove item' }, { status: 500 })
  }
}
