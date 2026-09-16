export type Product = {
  id: string
  title: string
  price: number
  originalPrice: number | null
  image: string
  location: string
  condition: string
  description: string
  category: string
  isVerified: boolean
  isFlashSale: boolean
  isGroupBuy: boolean
  brand: string | null
  watchers: number
  bids: number
  sold: number
  timeLeft: string
  seller: {
    id: string
    username: string
    avatar: string
    rating: number
    sales: number
    isVerified: boolean
    level: number
  }
}

export type Story = {
  id: string
  username: string
  avatar: string
  isLive: boolean
  time: string
}

export type FeedPost = {
  id: string
  title: string
  price: number
  image: string
  action: string
  bids: number
  watching: number
  ordersToday: number
  condition: string
  timeAgo: string
  seller: { username: string; avatar: string; isVerified: boolean }
}

export type LiveStreamData = {
  id: string
  host: string
  hostAvatar: string
  title: string
  category: string
  viewers: number
  likes: number
  cover: string
  isLive: boolean
}

export type ChatSessionData = {
  id: string
  name: string
  avatar: string
  productTitle: string | null
  productImage: string | null
  unread: number
  lastMessage: string
  lastTime: string
}

export type ChatMessageData = {
  id: string
  senderName: string
  text: string
  isMe: boolean
  createdAt: string
}

export type WalletData = {
  balance: number
  points: number
  transactions: {
    id: string
    title: string
    amount: number
    type: string
    method: string
    createdAt: string
  }[]
}

export type GroupBuyData = {
  id: string
  title: string
  image: string
  price: number
  originalPrice: number
  target: number
  participants: number
  endsAt: string
  category: string
  leader: string
  leaderAvatar: string
  joined: boolean
}

export type WishlistData = {
  id: string
  collection: string
  priceAlert: boolean
  addedAt: string
  product: Product
}
