import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

const productInclude = {
  seller: {
    select: {
      id: true, username: true, avatar: true, rating: true, sales: true, isVerified: true, level: true,
    },
  },
}

export async function GET() {
  try {
    const [stories, trending, flashSale, liveDrops, feedPosts, liveStreams] = await Promise.all([
      db.story.findMany({ take: 10 }),
      db.product.findMany({
        where: { isFlashSale: false, isGroupBuy: false },
        orderBy: { watchers: 'desc' },
        take: 8,
        include: productInclude,
      }),
      db.product.findMany({
        where: { isFlashSale: true },
        take: 6,
        include: productInclude,
      }),
      db.product.findMany({
        where: { category: 'Sneakers' },
        orderBy: { watchers: 'desc' },
        take: 8,
        include: productInclude,
      }),
      db.feedPost.findMany({
        include: { seller: { select: { username: true, avatar: true, isVerified: true } } },
        take: 10,
      }),
      db.liveStream.findMany({ take: 5 }),
    ])

    return NextResponse.json({ stories, trending, flashSale, liveDrops, feed: feedPosts, liveStreams })
  } catch (e) {
    console.error('home api error', e)
    return NextResponse.json({ error: 'Failed to load home data' }, { status: 500 })
  }
}
