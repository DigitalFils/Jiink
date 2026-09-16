import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { getSessionUser } from '@/lib/auth'

export const dynamic = 'force-dynamic'

const productInclude = {
  seller: {
    select: {
      id: true, username: true, avatar: true, rating: true, sales: true, isVerified: true, level: true,
    },
  },
}

// GET /api/products — list with filters
export async function GET(req: NextRequest) {
  try {
    const sp = req.nextUrl.searchParams
    const category = sp.get('category')
    const q = sp.get('q')
    const flash = sp.get('flash')
    const ar = sp.get('ar')
    const sort = sp.get('sort') || 'trending'

    const where: any = {}
    if (category && category !== 'All') where.category = category
    if (flash === 'true') where.isFlashSale = true
    if (ar === 'true') where.location = 'AR Try-On'
    if (q) {
      where.OR = [
        { title: { contains: q } },
        { description: { contains: q } },
        { category: { contains: q } },
      ]
    }

    const orderBy: any =
      sort === 'price-asc' ? { price: 'asc' } :
      sort === 'price-desc' ? { price: 'desc' } :
      sort === 'newest' ? { createdAt: 'desc' } :
      { watchers: 'desc' }

    const products = await db.product.findMany({ where, orderBy, take: 40, include: productInclude })
    return NextResponse.json({ products })
  } catch (e) {
    console.error('products api error', e)
    return NextResponse.json({ error: 'Failed to load products' }, { status: 500 })
  }
}

// POST /api/products — create a listing (Sell screen)
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { title, price, category, condition, location, description, image } = body

    if (!title || !price || price <= 0) {
      return NextResponse.json({ error: 'Title and a valid price are required' }, { status: 400 })
    }

    // The seller is whoever is signed in. This used to be a hardcoded
    // lookup of one username, which meant every listing anyone created was
    // published under that person's account.
    const seller = await getSessionUser()
    if (!seller) {
      return NextResponse.json({ error: 'Sign in to list something.' }, { status: 401 })
    }

    const product = await db.product.create({
      data: {
        title: String(title).slice(0, 120),
        price: Number(price),
        category: category || 'Electronics',
        condition: condition || 'New',
        location: location || 'Manchester',
        description: String(description || '').slice(0, 2000),
        image:
          image && String(image).startsWith('http')
            ? String(image)
            : 'https://images.unsplash.com/photo-1523275338841-9ef5b26bf5d6?w=600',
        timeLeft: 'Just listed',
        watchers: 0,
        bids: 0,
        sellerId: seller.id,
      },
      include: productInclude,
    })

    return NextResponse.json({ product }, { status: 201 })
  } catch (e) {
    console.error('create product error', e)
    return NextResponse.json({ error: 'Failed to create listing' }, { status: 500 })
  }
}
