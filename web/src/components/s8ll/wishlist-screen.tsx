'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { Heart, Bell, FolderOpen, Trash2, TrendingDown, Package } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import type { WishlistData } from '@/lib/types'

async function fetchWishlist() {
  const res = await fetch('/api/wishlist')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function WishlistScreen() {
  const { push } = useAppStore()
  const { toast } = useToast()
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['wishlist'], queryFn: fetchWishlist })
  const items: WishlistData[] = data?.items ?? []

  const collections = Array.from(new Set(items.map((i) => i.collection)))

  const remove = useMutation({
    mutationFn: async (id: string) => {
      const res = await fetch(`/api/wishlist?id=${id}`, { method: 'DELETE' })
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['wishlist'] })
      toast({ title: 'Removed from wishlist' })
    },
  })

  const toggleAlert = useMutation({
    mutationFn: async (item: WishlistData) => {
      const res = await fetch('/api/wishlist', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: item.id, priceAlert: !item.priceAlert }),
      })
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
    onSuccess: (_d, item) => {
      qc.invalidateQueries({ queryKey: ['wishlist'] })
      toast({
        title: item.priceAlert ? 'Price alert off' : 'Price alert on 🔔',
        description: item.priceAlert ? undefined : 'We\'ll ping you when the price drops 10%+.',
      })
    },
  })

  const totalValue = items.reduce((a, i) => a + i.product.price, 0)
  const alertsOn = items.filter((i) => i.priceAlert).length

  return (
    <div className="min-h-[100dvh] pb-10">
      <ScreenHeader title="Wishlist" subtitle={`${items.length} saved items`} />

      <div className="px-4 mt-4 space-y-5">
        {/* stats */}
        <section className="grid grid-cols-3 gap-2.5">
          {[
            [String(items.length), 'items', 'text-white'],
            [`£${totalValue.toFixed(0)}`, 'total value', 'text-s8ll'],
            [String(alertsOn), 'price alerts', 'text-warn'],
          ].map(([v, l, tint]) => (
            <div key={l} className="s8ll-card rounded-2xl py-3.5 text-center">
              <p className={cn('text-lg font-black', tint)}>{v}</p>
              <p className="text-[9px] text-txt3 mt-0.5 uppercase tracking-wider">{l}</p>
            </div>
          ))}
        </section>

        {/* collections */}
        {collections.length > 0 && (
          <section>
            <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-3">
              <FolderOpen className="h-4 w-4 text-s8ll" /> Collections
            </h3>
            <div className="flex gap-2 overflow-x-auto no-scrollbar">
              {collections.map((c) => (
                <button
                  key={c}
                  className="shrink-0 px-4 py-2.5 rounded-2xl bg-surface border border-border text-[12px] font-bold text-txt2 hover:border-s8ll/40 hover:text-white transition-colors flex items-center gap-2"
                >
                  <FolderOpen className="h-3.5 w-3.5 text-s8ll" />
                  {c}
                  <span className="bg-surface-light px-1.5 rounded-md text-[10px]">
                    {items.filter((i) => i.collection === c).length}
                  </span>
                </button>
              ))}
            </div>
          </section>
        )}

        {/* items */}
        <section>
          {isLoading && Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="flex gap-3 p-3 mb-2.5 s8ll-card rounded-2xl">
              <Skeleton className="h-20 w-20 rounded-xl bg-surface-light" />
              <div className="flex-1 space-y-2 py-1">
                <Skeleton className="h-3.5 w-3/4 bg-surface-light" />
                <Skeleton className="h-4 w-20 bg-surface-light" />
              </div>
            </div>
          ))}

          {items.length === 0 && !isLoading && (
            <div className="text-center py-16">
              <Heart className="h-12 w-12 text-txt3 mx-auto mb-3" />
              <p className="text-sm font-bold text-white">Nothing saved yet</p>
              <p className="text-[12px] text-txt2 mt-1">Tap the heart on any product to save it here.</p>
            </div>
          )}

          <AnimatePresence>
            {items.map((item, i) => (
              <motion.div
                key={item.id}
                layout
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: -120, transition: { duration: 0.25 } }}
                transition={{ delay: i * 0.04 }}
                className="s8ll-card rounded-2xl p-3 mb-2.5 flex gap-3"
              >
                <button onClick={() => push({ name: 'product', id: item.product.id })} className="shrink-0">
                  { }
                  <img src={item.product.image} alt={item.product.title} className="h-20 w-20 rounded-xl object-cover" />
                </button>
                <div className="flex-1 min-w-0">
                  <button onClick={() => push({ name: 'product', id: item.product.id })} className="text-left w-full">
                    <h4 className="text-[13px] font-semibold text-white line-clamp-2 leading-snug">{item.product.title}</h4>
                    <div className="flex items-baseline gap-1.5 mt-1">
                      <span className="text-[15px] font-black text-s8ll">£{item.product.price}</span>
                      {item.product.originalPrice && (
                        <>
                          <span className="text-[10px] text-txt3 line-through">£{item.product.originalPrice}</span>
                          <span className="text-[9px] text-live font-bold flex items-center gap-0.5">
                            <TrendingDown className="h-3 w-3" />
                            -{Math.round((1 - item.product.price / item.product.originalPrice) * 100)}%
                          </span>
                        </>
                      )}
                    </div>
                  </button>
                  <div className="flex items-center gap-2 mt-2">
                    <button
                      onClick={() => toggleAlert.mutate(item)}
                      className={cn(
                        'flex items-center gap-1 text-[10px] font-bold px-2 py-1 rounded-md border transition-colors',
                        item.priceAlert
                          ? 'bg-warn/15 text-warn border-warn/40'
                          : 'bg-surface text-txt2 border-border hover:text-warn',
                      )}
                    >
                      <Bell className="h-3 w-3" /> {item.priceAlert ? 'Alert on' : 'Alert off'}
                    </button>
                    <span className="text-[9px] text-txt3 flex items-center gap-1">
                      <Package className="h-3 w-3" /> {item.product.seller.username}
                    </span>
                    <button
                      onClick={() => remove.mutate(item.id)}
                      aria-label="Remove"
                      className="ml-auto h-8 w-8 rounded-lg bg-surface border border-border flex items-center justify-center text-txt3 hover:text-live hover:border-live/40 transition-colors"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </section>
      </div>
    </div>
  )
}
