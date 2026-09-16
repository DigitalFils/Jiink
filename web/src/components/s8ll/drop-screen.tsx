'use client'

import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { BadgeCheck, Eye, Gavel, Package, Heart, MessageCircle, Share2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { useAppStore } from '@/store/useAppStore'
import type { FeedPost } from '@/lib/types'

async function fetchFeed() {
  const res = await fetch('/api/home')
  if (!res.ok) throw new Error('Failed')
  const data = await res.json()
  return data.feed as FeedPost[]
}

export function DropScreen() {
  const { push } = useAppStore()
  const { data: feed, isLoading } = useQuery({ queryKey: ['feed'], queryFn: fetchFeed })

  return (
    <div className="pb-28">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-4 pt-[max(env(safe-area-inset-top),14px)] pb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-black tracking-tight text-white">The Drop</h1>
            <span className="bg-s8ll/10 border border-s8ll/25 text-s8ll text-[9px] font-black px-2 py-0.5 rounded-full tracking-widest">
              XHS FEED
            </span>
          </div>
          <p className="text-[11px] text-txt2">Fresh finds from the community</p>
        </div>
      </header>

      <div className="px-4 space-y-5 mt-4">
        {isLoading &&
          Array.from({ length: 2 }).map((_, i) => (
            <div key={i} className="s8ll-card rounded-3xl overflow-hidden">
              <Skeleton className="aspect-[4/3] rounded-none bg-surface-light" />
              <div className="p-4 space-y-2">
                <Skeleton className="h-4 w-3/4 bg-surface-light" />
                <Skeleton className="h-3 w-1/2 bg-surface-light" />
              </div>
            </div>
          ))}

        {feed?.map((post, i) => (
          <motion.article
            key={post.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.08 }}
            className="s8ll-card rounded-3xl overflow-hidden"
          >
            <div className="relative aspect-[4/3] keep-dark">
              { }
              <img src={post.image} alt={post.title} className="h-full w-full object-cover" />
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-black/20" />
              <div className="absolute top-3 left-3 flex items-center gap-2 bg-black/60 backdrop-blur rounded-full pl-1 pr-3 py-1">
                { }
                <img src={post.seller.avatar} alt={post.seller.username} className="h-6 w-6 rounded-full object-cover" />
                <span className="text-[11px] font-bold text-white">{post.seller.username}</span>
                {post.seller.isVerified && <BadgeCheck className="h-3.5 w-3.5 text-s8ll" />}
              </div>
              <span className="absolute top-3 right-3 bg-black/60 backdrop-blur text-white text-[10px] font-semibold px-2 py-1 rounded-full">
                {post.timeAgo}
              </span>
              <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                <div>
                  <p className="text-white text-sm font-bold leading-tight line-clamp-2 max-w-[75%] text-shadow-hard">{post.title}</p>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-s8ll text-lg font-black">£{post.price}</span>
                    <span className="bg-black/60 text-white text-[9px] font-bold px-1.5 py-0.5 rounded">
                      cond {post.condition}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-3.5">
              <div className="flex items-center gap-4 text-[11px] text-txt2 mb-3">
                <span className="flex items-center gap-1"><Gavel className="h-3.5 w-3.5" /> {post.bids} bids</span>
                <span className="flex items-center gap-1"><Eye className="h-3.5 w-3.5" /> {post.watching} watching</span>
                {post.ordersToday > 0 && (
                  <span className="flex items-center gap-1"><Package className="h-3.5 w-3.5" /> {post.ordersToday} sold today</span>
                )}
              </div>
              <div className="flex items-center gap-2">
                <Button className="s8ll-btn flex-1 h-10 rounded-xl text-[13px]">{post.action}</Button>
                <button aria-label="Chat" className="h-10 w-10 rounded-xl bg-surface border border-border flex items-center justify-center text-txt2 hover:text-s8ll hover:border-s8ll/40 transition-colors">
                  <MessageCircle className="h-4 w-4" />
                </button>
                <button aria-label="Save" className="h-10 w-10 rounded-xl bg-surface border border-border flex items-center justify-center text-txt2 hover:text-live hover:border-live/40 transition-colors">
                  <Heart className="h-4 w-4" />
                </button>
                <button aria-label="Share" className="h-10 w-10 rounded-xl bg-surface border border-border flex items-center justify-center text-txt2 hover:text-white transition-colors">
                  <Share2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          </motion.article>
        ))}
      </div>
    </div>
  )
}
