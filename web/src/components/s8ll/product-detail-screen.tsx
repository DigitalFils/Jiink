'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  BadgeCheck, MapPin, Star, Heart, Share2, Gavel, Users, ShieldCheck,
  Truck, RefreshCcw, Loader2,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { ProductCard } from './product-card'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import type { Product } from '@/lib/types'

async function fetchProduct(id: string) {
  const res = await fetch(`/api/products/${id}`)
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function ProductDetailScreen({ id }: { id: string }) {
  const { push, pop } = useAppStore()
  const { toast } = useToast()
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['product', id], queryFn: () => fetchProduct(id) })
  const product: Product | undefined = data?.product

  const { data: homeData } = useQuery({
    queryKey: ['home'],
    queryFn: async () => (await fetch('/api/home')).json(),
  })
  const related: Product[] = (homeData?.trending ?? []).filter((p: Product) => p.id !== id).slice(0, 4)

  const wishlist = useMutation({
    mutationFn: async () => {
      const res = await fetch('/api/wishlist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ productId: id }),
      })
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
    onSuccess: (d) => {
      qc.invalidateQueries({ queryKey: ['wishlist'] })
      toast({
        title: d.removed ? 'Removed from wishlist' : 'Added to wishlist ❤️',
        description: d.removed ? undefined : 'We\'ll alert you on price drops.',
      })
    },
  })

  if (isLoading || !product) {
    return (
      <div className="min-h-[100dvh]">
        <Skeleton className="aspect-square rounded-none bg-surface-light" />
        <div className="p-4 space-y-3">
          <Skeleton className="h-6 w-2/3 bg-surface-light" />
          <Skeleton className="h-4 w-1/3 bg-surface-light" />
          <Skeleton className="h-20 w-full bg-surface-light rounded-2xl" />
        </div>
      </div>
    )
  }

  const discount = product.originalPrice ? Math.round((1 - product.price / product.originalPrice) * 100) : 0

  return (
    <div className="min-h-[100dvh] pb-32">
      <ScreenHeader title={product.title} subtitle={`${product.category} • ${product.condition}`} />

      <div className="relative aspect-square keep-dark">
        { }
        <img src={product.image} alt={product.title} className="h-full w-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-background/60 to-transparent" />
        {product.isVerified && (
          <motion.button
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            onClick={() => push({ name: 'auth' })}
            className="absolute top-3 right-3 bg-black/70 backdrop-blur border border-s8ll/40 text-s8ll flex items-center gap-1.5 text-[10px] font-bold px-3 py-2 rounded-full"
          >
            <ShieldCheck className="h-3.5 w-3.5" /> Dewu Verified
          </motion.button>
        )}
        {discount > 0 && (
          <span className="absolute top-3 left-3 bg-live text-white text-[11px] font-black px-2.5 py-1.5 rounded-lg">
            -{discount}%
          </span>
        )}
      </div>

      <div className="px-4 mt-4 space-y-5">
        <section>
          <div className="flex items-baseline gap-2 flex-wrap">
            <span className="text-3xl font-black text-s8ll">
              £{product.price % 1 === 0 ? product.price : product.price.toFixed(2)}
            </span>
            {product.originalPrice && (
              <>
                <span className="text-sm text-txt3 line-through">£{product.originalPrice}</span>
                <span className="text-[11px] font-bold text-live">save £{(product.originalPrice - product.price).toFixed(0)}</span>
              </>
            )}
          </div>
          <h2 className="text-lg font-bold text-white mt-2 leading-snug">{product.title}</h2>
          <div className="flex items-center gap-3 mt-2 text-[11px] text-txt2 flex-wrap">
            <span className="flex items-center gap-1"><MapPin className="h-3.5 w-3.5" /> {product.location}</span>
            <span className="flex items-center gap-1"><Users className="h-3.5 w-3.5" /> {product.watchers} watching</span>
            {product.bids > 0 && <span className="flex items-center gap-1"><Gavel className="h-3.5 w-3.5" /> {product.bids} bids</span>}
          </div>
        </section>

        {/* seller card */}
        <section className="s8ll-card rounded-2xl p-4 flex items-center gap-3.5">
          { }
          <img src={product.seller.avatar} alt={product.seller.username} className="h-12 w-12 rounded-full object-cover border-2 border-border" />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-1.5">
              <span className="text-sm font-bold text-white truncate">{product.seller.username}</span>
              {product.seller.isVerified && <BadgeCheck className="h-4 w-4 text-s8ll shrink-0" />}
            </div>
            <div className="flex items-center gap-2 text-[11px] text-txt2 mt-0.5">
              <span className="flex items-center gap-0.5"><Star className="h-3 w-3 fill-gold text-gold" /> {product.seller.rating}</span>
              <span>• {product.seller.sales} sales • L{product.seller.level}</span>
            </div>
          </div>
          <Button variant="outline" className="h-9 rounded-full border-s8ll/40 text-s8ll text-[12px] px-4 hover:bg-s8ll/10">
            Follow
          </Button>
        </section>

        {/* trust bar */}
        <section className="grid grid-cols-3 gap-2.5">
          {[
            [Truck, 'Fast ship', '2-4 days'],
            [ShieldCheck, 'Buyer shield', '10x guarantee'],
            [RefreshCcw, '14-day returns', 'No questions'],
          ].map(([Icon, t, d], i) => {
            const I = Icon as typeof Truck
            return (
              <div key={i} className="s8ll-card rounded-2xl py-3 flex flex-col items-center gap-1 text-center">
                <I className="h-4.5 w-4.5 h-[18px] w-[18px] text-s8ll" />
                <span className="text-[10.5px] font-bold text-white">{t as string}</span>
                <span className="text-[9px] text-txt3">{d as string}</span>
              </div>
            )
          })}
        </section>

        <section>
          <h3 className="text-[13px] font-bold text-white mb-2">Description</h3>
          <p className="text-[13px] text-txt2 leading-relaxed">{product.description || 'No description provided.'}</p>
          <div className="flex gap-2 mt-3 flex-wrap">
            <span className="text-[10px] bg-surface border border-border text-txt2 px-2.5 py-1 rounded-md">Condition: {product.condition}</span>
            <span className="text-[10px] bg-surface border border-border text-txt2 px-2.5 py-1 rounded-md">Listed: {product.timeLeft}</span>
            <span className="text-[10px] bg-surface border border-border text-txt2 px-2.5 py-1 rounded-md">{product.sold} sold</span>
          </div>
        </section>

        <section>
          <h3 className="text-[13px] font-bold text-white mb-3">You may also like</h3>
          <div className="grid grid-cols-2 gap-3">
            {related.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      </div>

      {/* sticky bottom action bar */}
      <div className="fixed bottom-0 inset-x-0 z-40 mx-auto max-w-[480px] bg-surface/95 backdrop-blur-xl border-t border-border px-4 py-3 pb-[max(env(safe-area-inset-bottom),12px)]">
        <div className="flex items-center gap-2.5">
          <button
            onClick={() => wishlist.mutate()}
            aria-label="Add to wishlist"
            disabled={wishlist.isPending}
            className={cn(
              'h-12 w-12 rounded-2xl border flex items-center justify-center shrink-0 transition-colors',
              'bg-surface border-border text-txt2 hover:text-live hover:border-live/40',
            )}
          >
            {wishlist.isPending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Heart className="h-5 w-5" />}
          </button>
          <button aria-label="Share" className="h-12 w-12 rounded-2xl bg-surface border border-border flex items-center justify-center text-txt2 hover:text-white transition-colors shrink-0">
            <Share2 className="h-5 w-5" />
          </button>
          <Button
            onClick={() => toast({ title: 'Offer sent 🤝', description: 'Seller typically replies within minutes.' })}
            variant="outline"
            className="h-12 flex-1 rounded-2xl border-s8ll/50 text-s8ll text-[14px] hover:bg-s8ll/10"
          >
            Make Offer
          </Button>
          <Button className="s8ll-btn h-12 flex-1 rounded-2xl text-[14px]">
            Buy Now
          </Button>
        </div>
      </div>
    </div>
  )
}
