import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

async function main() {
  // Clean
  await db.chatMessage.deleteMany()
  await db.chatSession.deleteMany()
  await db.wishlistItem.deleteMany()
  await db.walletTransaction.deleteMany()
  await db.groupBuy.deleteMany()
  await db.feedPost.deleteMany()
  await db.story.deleteMany()
  await db.liveStream.deleteMany()
  await db.product.deleteMany()
  await db.user.deleteMany()

  // ============ USERS ============
  const me = await db.user.create({
    data: {
      username: 'Abdalla',
      avatar: 'https://i.pravatar.cc/150?img=12',
      rating: 4.9,
      sales: 127,
      isVerified: true,
      level: 4,
      xp: 640,
      balance: 1240.5,
      points: 2840,
      followers: 512,
      bio: 'Sneakerhead & vintage tech collector. Manchester based.',
    },
  })

  const mk = async (username: string, img: number, opts: any = {}) =>
    db.user.create({
      data: {
        username,
        avatar: `https://i.pravatar.cc/150?img=${img}`,
        ...opts,
      },
    })

  const filmLover = await mk('FilmLover', 32)
  const streetWear = await mk('StreetWear', 45)
  const plantMom = await mk('PlantMom', 47)
  const vintageFinds = await mk('VintageFinds', 52)
  const official = await mk('S8LL Official', 68, { isVerified: true, sales: 4820, rating: 5.0, level: 10 })
  const hypevault = await mk('hypevault', 15, { isVerified: true, sales: 890 })
  const soledrop = await mk('soledrop.co', 22, { isVerified: true, sales: 1240 })
  const grailroom = await mk('grailroom', 44)
  const knox = await mk('knox_', 1)
  const leo = await mk('leo', 3)
  const mia = await mk('mia', 5)
  const jax = await mk('jax', 11)
  const zoe = await mk('zoe', 20)
  const jordanL = await mk('Jordan_L', 60)
  void leo; void mia; void jax; void zoe; void knox

  // ============ PRODUCTS ============
  const p = (data: any) => db.product.create({ data })
  await p({
    title: 'Vintage Film Camera', price: 320, image: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
    location: 'Manchester', condition: 'Excellent', category: 'Electronics', isVerified: true,
    description: 'Beautiful vintage film camera in perfect working condition. Fully serviced, new light seals, includes original strap and case. A collector dream.',
    timeLeft: '6h left', watchers: 18, bids: 7, sellerId: me.id, sold: 3,
  })
  await p({
    title: 'Noise Cancelling Headphones', price: 180, image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
    location: 'Manchester', condition: 'Like New', category: 'Electronics', isVerified: true,
    description: 'Premium noise-cancelling headphones with amazing sound quality. Includes all accessories and original box.',
    timeLeft: '6h left', watchers: 31, bids: 12, sellerId: me.id, sold: 12,
  })
  await p({
    title: 'Ceramic Succulent Planter', price: 42, image: 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=600',
    location: 'Manchester', condition: 'New', category: 'Home & Garden',
    description: 'Minimalist ceramic planter with live succulent. Perfect gift for plant lovers.',
    timeLeft: '6h left', watchers: 9, sellerId: me.id, sold: 27,
  })
  await p({
    title: 'Leather Tote Bag', price: 95, image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
    location: 'Manchester', condition: 'Great', category: 'Fashion',
    description: 'Genuine leather tote bag, spacious and stylish. Ages beautifully with use.',
    timeLeft: '6h left', watchers: 14, bids: 4, sellerId: me.id, sold: 8,
  })
  await p({
    title: 'Polaroid 600 Camera + Film Pack, Sealed', price: 25, image: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=600',
    location: 'Manchester • Northern Quarter', condition: 'Sealed', category: 'Electronics',
    description: 'Vintage Polaroid camera with sealed film pack. Ready to shoot.',
    timeLeft: '7h left', watchers: 22, sellerId: filmLover.id, sold: 5,
  })
  await p({
    title: 'The North Face Beanie, Black, One Size', price: 12, image: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600',
    location: 'Manchester • Piccadilly', condition: 'New', category: 'Fashion', isVerified: true,
    description: 'Authentic TNF black beanie, one size fits all. Tags attached.',
    timeLeft: '7h left', watchers: 8, sellerId: streetWear.id, sold: 41,
  })
  await p({
    title: 'Ceramic Plant Pot, Terracotta, 10cm', price: 2, image: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=600',
    location: 'Manchester • Ancoats', condition: 'New', category: 'Home & Garden',
    description: 'Small terracotta pot, perfect for succulents.',
    timeLeft: '7h left', watchers: 5, sellerId: plantMom.id, sold: 64,
  })
  await p({
    title: 'Leather Belt, Brown Leather, 34in', price: 12, image: 'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=600',
    location: 'Manchester • Castlefield', condition: 'Great', category: 'Fashion',
    description: 'Genuine brown leather belt, size 34. Classic timeless style.',
    timeLeft: '7h left', watchers: 6, sellerId: vintageFinds.id, sold: 9,
  })

  // Flash sale products
  const flash = [
    ['Adidas Stan Smith', 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=600'],
    ['Nike Air Force 1', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'],
    ['Vans Old Skool', 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=600'],
    ['New Balance 550', 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=600'],
    ['Adidas Ultraboost', 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600'],
    ['Nike Air Jordan 1', 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=600'],
  ]
  for (const [title, image] of flash) {
    await p({
      title, price: 24, originalPrice: 42, image, location: 'Online', condition: 'New',
      category: 'Sneakers', isVerified: true, isFlashSale: true, isGroupBuy: true,
      description: `${title} — flash sale price. Verified authentic by S8LL Authentication. Limited stock, ends soon!`,
      timeLeft: 'Flash', watchers: 120 + Math.floor(Math.random() * 200), sellerId: official.id, sold: 300 + Math.floor(Math.random() * 400),
    })
  }

  // AR try-on catalog (sneakers)
  const ar = [
    ['Nike Air Jordan 1', 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=600'],
    ['Nike Air Force 1', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'],
    ['Adidas Ultraboost', 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600'],
    ['New Balance 550', 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=600'],
  ]
  for (const [title, image] of ar) {
    await p({
      title, price: 189, originalPrice: 220, image, location: 'AR Try-On', condition: 'New',
      category: 'Sneakers', isVerified: true,
      description: `${title} with AR virtual try-on support. See how they look on your feet before you buy.`,
      timeLeft: 'AR ready', watchers: 64, sellerId: official.id, sold: 88,
    })
  }

  // ============ STORIES ============
  const stories: Array<[string, string, boolean]> = [
    ['knox_', 'https://i.pravatar.cc/150?img=1', true],
    ['leo', 'https://i.pravatar.cc/150?img=3', true],
    ['mia', 'https://i.pravatar.cc/150?img=5', true],
    ['jax', 'https://i.pravatar.cc/150?img=11', true],
    ['zoe', 'https://i.pravatar.cc/150?img=20', true],
  ]
  for (const [username, avatar, isLive] of stories) {
    await db.story.create({ data: { username, avatar, time: '12m', isLive } })
  }

  // ============ FEED POSTS (Xiaohongshu-style) ============
  await db.feedPost.create({ data: { sellerId: hypevault.id, title: 'Nike Air Jordan 1 Retro High "Olive" — Size US 9', price: 120, image: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=600', action: 'Make Offer', bids: 12, watching: 18, condition: '9/10', timeAgo: '2m ago' } })
  await db.feedPost.create({ data: { sellerId: soledrop.id, title: 'New Balance 550 "Green Olive" — Size US 8.5', price: 98, image: 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=600', action: 'Buy Now', ordersToday: 5, condition: '10/10', timeAgo: '15m ago' } })
  await db.feedPost.create({ data: { sellerId: grailroom.id, title: 'Carhartt WIP Detroit Jacket — Size M', price: 75, image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600', action: 'Make Offer', bids: 7, watching: 23, condition: '8/10', timeAgo: '42m ago' } })

  // ============ LIVE STREAMS ============
  await db.liveStream.create({ data: { host: 'SneakerFest Live', hostAvatar: 'https://i.pravatar.cc/150?img=15', title: 'RARE Jordan 1 Drop — Live Unboxing & Authentication', category: 'Sneakers', viewers: 2418, likes: 12400, cover: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800' } })
  await db.liveStream.create({ data: { host: 'TechDeals UK', hostAvatar: 'https://i.pravatar.cc/150?img=22', title: 'Vintage Cameras & Audio — Q&A + Flash Prices', category: 'Electronics', viewers: 891, likes: 3400, cover: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800' } })
  await db.liveStream.create({ data: { host: 'PlantMom', hostAvatar: 'https://i.pravatar.cc/150?img=47', title: 'Rare Succulents Haul — Free Cuttings Giveaway', category: 'Home & Garden', viewers: 412, likes: 2100, cover: 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=800', isLive: false } })

  // ============ CHAT SESSIONS ============
  const s1 = await db.chatSession.create({ data: { name: 'Jordan_L', avatar: jordanL.avatar, productTitle: 'Nike Air Jordan 1', productImage: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=200', unread: 1, lastMessage: 'Any chance of a discount?', lastTime: '2m' } })
  await db.chatMessage.create({ data: { sessionId: s1.id, senderName: 'Jordan_L', text: 'Hi! Interested in the sneaker. Still available?', createdAt: new Date(Date.now() - 5 * 60000) } })
  await db.chatMessage.create({ data: { sessionId: s1.id, senderName: 'Me', text: 'Yes, in great condition. Box included.', isMe: true, createdAt: new Date(Date.now() - 4 * 60000) } })
  await db.chatMessage.create({ data: { sessionId: s1.id, senderName: 'Jordan_L', text: 'Any chance of a discount?', createdAt: new Date(Date.now() - 2 * 60000) } })

  const s2 = await db.chatSession.create({ data: { name: 'soledrop.co', avatar: soledrop.avatar, productTitle: 'New Balance 550', productImage: 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=200', unread: 0, lastMessage: 'Shipped! Tracking sent', lastTime: '1h' } })
  await db.chatMessage.create({ data: { sessionId: s2.id, senderName: 'soledrop.co', text: 'Payment received, packing now.', createdAt: new Date(Date.now() - 70 * 60000) } })
  await db.chatMessage.create({ data: { sessionId: s2.id, senderName: 'soledrop.co', text: 'Shipped! Tracking sent', createdAt: new Date(Date.now() - 60 * 60000) } })

  const s3 = await db.chatSession.create({ data: { name: 'PlantMom', avatar: plantMom.avatar, productTitle: 'Terracotta Pot', productImage: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=200', unread: 0, lastMessage: 'Thanks! Leave a review', lastTime: '1d' } })
  await db.chatMessage.create({ data: { sessionId: s3.id, senderName: 'Me', text: 'Pot arrived safe, love it!', isMe: true, createdAt: new Date(Date.now() - 26 * 3600000) } })
  await db.chatMessage.create({ data: { sessionId: s3.id, senderName: 'PlantMom', text: 'Thanks! Leave a review', createdAt: new Date(Date.now() - 25 * 3600000) } })

  // ============ WISHLIST ============
  const cam = await p({ title: 'Leica M6 Classic', price: 1450, image: 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=600', location: 'London', condition: 'Excellent', category: 'Electronics', isVerified: true, description: 'Legendary rangefinder camera. CLA done this year.', timeLeft: '3d left', watchers: 44, sellerId: filmLover.id, sold: 1 })
  const jordan1 = await db.product.findFirst({ where: { title: 'Nike Air Jordan 1', location: 'AR Try-On' } })
  await db.wishlistItem.create({ data: { productId: cam.id, collection: 'Cameras', priceAlert: true } })
  if (jordan1) await db.wishlistItem.create({ data: { productId: jordan1.id, collection: 'Sneakers', priceAlert: false } })

  // ============ WALLET ============
  const txs: Array<[string, number, string, string, number]> = [
    ['Nike Dunk Low Purchase', -84.0, 'purchase', 'Wallet', 0],
    ['Sale - Adidas Samba', 62.0, 'sale', 'Wallet', 1],
    ['Wallet Top-up', 500.0, 'topup', 'Visa •• 4521', 2],
    ['Group Buy Refund', -12.0, 'refund', 'Wallet', 3],
    ['Seller Payout', 180.0, 'payout', 'Yandex Money', 4],
    ['AR Try-On Purchase', 189.0, 'purchase', 'Apple Pay', 5],
    ['Dewu Auth Fee', 15.0, 'auth', 'Wallet', 6],
  ]
  for (const [title, amount, type, method, d] of txs) {
    await db.walletTransaction.create({ data: { title, amount, type, method, createdAt: new Date(Date.now() - d * 86400000) } })
  }

  // ============ GROUP BUYS ============
  const gb: Array<[string, string, number, number, number, number, string, string, number]> = [
    ['Wireless Earbuds Pro', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600', 24.9, 79.9, 10, 7, 'tech_guru', 'https://i.pravatar.cc/150?img=33', 3],
    ['Smart Watch Series 9', 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=600', 89.0, 249.0, 15, 11, 'gadgetqueen', 'https://i.pravatar.cc/150?img=25', 6],
    ['Nike Air Force Bundle (3 pairs)', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600', 120.0, 300.0, 5, 3, 'StreetStyle', 'https://i.pravatar.cc/150?img=45', 9],
    ['Ceramic Dinner Set × 12', 'https://images.unsplash.com/photo-1493106641515-6d5639643d7f?w=600', 34.0, 89.0, 8, 5, 'homey_deco', 'https://i.pravatar.cc/150?img=47', 4],
    ['Mechanical Keyboard RGB', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600', 45.0, 129.0, 12, 9, 'clickykeys', 'https://i.pravatar.cc/150?img=14', 7],
  ]
  for (const [title, image, price, originalPrice, target, participants, leader, leaderAvatar, hours] of gb) {
    await db.groupBuy.create({ data: { title, image, price, originalPrice, target, participants, leader, leaderAvatar, endsAt: new Date(Date.now() + hours * 3600000), category: 'Electronics' } })
  }

  console.log('Seed complete')
}

main()
  .catch((e) => { console.error(e); process.exit(1) })
  .finally(() => db.$disconnect())
