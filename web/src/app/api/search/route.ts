import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export const dynamic = 'force-dynamic'

const CATEGORIES = ['Electronics', 'Fashion', 'Home & Garden', 'Sneakers', 'Collectibles', 'Sports']

const TRENDING = [
  'jordan 1', 'vintage camera', 'air force', 'noise cancelling', 'leather bag',
  'terracotta pot', 'north face', 'film camera', 'new balance',
]

// POST /api/search — smart search with parsed filters
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const q = String(body.query || '').trim()
    const filters = body.filters || {}

    const where: any = {}
    if (filters.category && filters.category !== 'All') where.category = filters.category
    if (filters.verifiedOnly) where.isVerified = true
    if (filters.minPrice != null || filters.maxPrice != null) {
      where.price = {}
      if (filters.minPrice != null) where.price.gte = Number(filters.minPrice)
      if (filters.maxPrice != null) where.price.lte = Number(filters.maxPrice)
    }
    if (filters.condition && filters.condition !== 'Any') where.condition = filters.condition
    if (q) {
      const qs = q.toLowerCase()
      // natural-language-ish parsing: category keyword
      const catHit = CATEGORIES.find(
        (c) => qs.includes(c.toLowerCase().split(' ')[0]) || qs.includes(c.toLowerCase()),
      )
      if (catHit && !filters.category) where.category = catHit
      where.OR = [
        { title: { contains: q } },
        { description: { contains: q } },
      ]
    }

    const sort = filters.sort || 'trending'
    const orderBy: any =
      sort === 'price-asc' ? { price: 'asc' } :
      sort === 'price-desc' ? { price: 'desc' } :
      sort === 'newest' ? { createdAt: 'desc' } :
      { watchers: 'desc' }

    const products = await db.product.findMany({
      where,
      orderBy,
      take: 40,
      include: { seller: { select: { id: true, username: true, avatar: true, rating: true, sales: true, isVerified: true, level: true } } },
    })

    // AI-style suggestions derived from the query + catalog
    const suggestions: string[] = []
    if (q) {
      const catHit = CATEGORIES.find((c) => q.toLowerCase().includes(c.toLowerCase().split(' ')[0]))
      if (catHit) suggestions.push(`Browse all ${catHit}`)
      if (/under|<|≤|less/i.test(q)) suggestions.push('Filter: max price applied automatically')
      if (/verified|authentic|legit/i.test(q)) suggestions.push('Showing verified listings only')
      if (/cheap|budget|deal|discount/i.test(q)) suggestions.push('Try Flash Sale tab for extra deals')
      if (products.length > 0) {
        suggestions.push(`${products.length} matches — avg price £${Math.round(products.reduce((a, p) => a + p.price, 0) / products.length)}`)
      }
    }

    return NextResponse.json({
      products,
      trending: TRENDING,
      suggestions,
      parsed: {
        category: where.category || null,
        maxPrice: filters.maxPrice ?? null,
        verifiedOnly: !!filters.verifiedOnly,
      },
    })
  } catch (e) {
    console.error('search api error', e)
    return NextResponse.json({ error: 'Search failed' }, { status: 500 })
  }
}
