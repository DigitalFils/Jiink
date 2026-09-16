'use client'

import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { Zap, Flame, TrendingUp } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'
import { ScreenHeader } from './screen-header'
import { ProductCard } from './product-card'
import { pad2, useCountdown } from './hooks'
import { useAppStore } from '@/store/useAppStore'
import type { Product } from '@/lib/types'

async function fetchFlash() {
  const res = await fetch('/api/products?flash=true')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

const FLASH_END = Date.now() + 2 * 3600000 + 14 * 60000 + 32 * 1000

export function FlashSaleScreen() {
  const { data, isLoading } = useQuery({ queryKey: ['flash'], queryFn: fetchFlash })
  const products: Product[] = data?.products ?? []
  const cd = useCountdown(FLASH_END)
  const sold = 61 // progress demo

  return (
    <div className="min-h-[100dvh] pb-10">
      <ScreenHeader title="Flash Sale" subtitle="限时秒杀 • Up to 70% off" />

      <div className="px-4 mt-4 space-y-5">
        {/* countdown hero — red promo card (stays dark in light theme) */}
        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-3xl p-5 relative overflow-hidden keep-dark"
          style={{ background: 'linear-gradient(135deg, #2a0d0d 0%, #141418 65%)' }}
        >
          <div className="absolute -right-10 -top-10 h-32 w-32 rounded-full bg-live/20 blur-3xl" />
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <div className="h-10 w-10 rounded-xl bg-live/15 border border-live/30 flex items-center justify-center">
                <Zap className="h-5 w-5 text-live fill-live" />
              </div>
              <div>
                <h2 className="text-[15px] font-black text-white">限时秒杀 Flash Kill</h2>
                <p className="text-[10px] text-txt2">Verified authentic • limited stock</p>
              </div>
            </div>
            <span className="bg-live text-white text-[9px] font-black px-2 py-1 rounded-md tracking-widest">
              LIVE NOW
            </span>
          </div>

          <div className="flex items-center gap-2">
            {[
              [cd.hours, '时'],
              [cd.minutes, '分'],
              [cd.seconds, '秒'],
            ].map(([v, u], i) => (
              <div key={i} className="flex items-center gap-1">
                <span className="bg-black/60 border border-live/30 rounded-xl px-3 py-2 text-xl font-black text-white tabular-nums">
                  {pad2(v as number)}
                </span>
                <span className="text-live text-[11px] font-bold">{u as string}</span>
              </div>
            ))}
          </div>

          <div className="mt-4">
            <div className="flex items-center justify-between text-[10px] mb-1.5">
              <span className="text-txt2 flex items-center gap-1">
                <Flame className="h-3 w-3 text-live" /> {sold}% of stock claimed
              </span>
              <span className="text-live font-bold">hurry!</span>
            </div>
            <div className="h-2 rounded-full bg-black/40 overflow-hidden">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${sold}%` }}
                transition={{ duration: 1.2, ease: 'easeOut' }}
                className="h-full rounded-full bg-gradient-to-r from-live to-warn"
              />
            </div>
          </div>
        </motion.section>

        {/* grid */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h3 className="flex items-center gap-1.5 text-[14px] font-bold text-white">
              <TrendingUp className="h-4 w-4 text-s8ll" /> Today&apos;s flash deals
            </h3>
            <span className="text-[11px] text-txt2">{products.length} items</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="s8ll-card rounded-2xl overflow-hidden">
                <Skeleton className="aspect-square rounded-none bg-surface-light" />
                <div className="p-3 space-y-2">
                  <Skeleton className="h-3 w-full bg-surface-light" />
                  <Skeleton className="h-4 w-14 bg-surface-light" />
                </div>
              </div>
            ))}
            {products.map((p, i) => (
              <motion.div
                key={p.id}
                initial={{ opacity: 0, y: 14 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.05 }}
              >
                <FlashCard product={p} />
              </motion.div>
            ))}
          </div>
        </section>

        <p className="text-center text-[10px] text-txt3">
          Prices locked during flash window. All items Dewu-verified with 10x guarantee.
        </p>
      </div>
    </div>
  )
}

function FlashCard({ product }: { product: Product }) {
  const { push } = useAppStore()
  const discount = product.originalPrice ? Math.round((1 - product.price / product.originalPrice) * 100) : 0
  const claimed = 40 + ((product.sold % 5) * 12)

  return (
    <button
      onClick={() => push({ name: 'product', id: product.id })}
      className="s8ll-card rounded-2xl overflow-hidden text-left w-full hover:border-s8ll/40 transition-colors"
    >
      <div className="relative aspect-square keep-dark">
        { }
        <img src={product.image} alt={product.title} loading="lazy" className="h-full w-full object-cover" />
        <span className="absolute top-2 left-2 bg-live text-white text-[11px] font-black px-2 py-1 rounded-md">
          -{discount}%
        </span>
        <div className="absolute bottom-0 inset-x-0 p-2">
          <div className="h-1.5 rounded-full bg-black/60 overflow-hidden">
            <div className="h-full rounded-full bg-gradient-to-r from-live to-warn" style={{ width: `${claimed}%` }} />
          </div>
          <p className="text-[8.5px] text-white/90 mt-1 text-shadow-hard">{claimed}% claimed</p>
        </div>
      </div>
      <div className="p-3">
        <h4 className="text-[12.5px] font-semibold text-white line-clamp-2 leading-snug min-h-[32px]">{product.title}</h4>
        <div className="flex items-baseline gap-1.5 mt-1">
          <span className="text-base font-black text-s8ll">£{product.price}</span>
          <span className="text-[10px] text-txt3 line-through">£{product.originalPrice}</span>
        </div>
        <p className="text-[9px] text-live font-bold mt-0.5">{product.sold}+ sold</p>
      </div>
    </button>
  )
}
