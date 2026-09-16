'use client'

import { BadgeCheck, MapPin, Users } from 'lucide-react'
import { motion } from 'framer-motion'
import type { Product } from '@/lib/types'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'

export function ProductCard({ product, compact = false }: { product: Product; compact?: boolean }) {
  const { push } = useAppStore()
  const discount = product.originalPrice
    ? Math.round((1 - product.price / product.originalPrice) * 100)
    : 0

  return (
    <motion.button
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      whileTap={{ scale: 0.97 }}
      onClick={() => push({ name: 'product', id: product.id })}
      className={cn(
        's8ll-card rounded-2xl overflow-hidden text-left w-full hover:border-s8ll/40 transition-colors',
        compact ? 'w-[150px] shrink-0' : '',
      )}
      aria-label={product.title}
    >
      <div className="relative aspect-square overflow-hidden keep-dark">
        { }
        <img
          src={product.image}
          alt={product.title}
          loading="lazy"
          className="h-full w-full object-cover hover:scale-105 transition-transform duration-500"
        />
        {product.isFlashSale && (
          <span className="absolute top-2 left-2 bg-live text-white text-[10px] font-black px-2 py-1 rounded-md tracking-wide">
            -{discount}%
          </span>
        )}
        {product.isVerified && (
          <span className="absolute bottom-2 left-2 bg-black/70 backdrop-blur text-s8ll flex items-center gap-1 text-[9px] font-bold px-2 py-1 rounded-full">
            <BadgeCheck className="h-3 w-3" /> VERIFIED
          </span>
        )}
        {product.watchers > 0 && (
          <span className="absolute bottom-2 right-2 bg-black/70 backdrop-blur text-white flex items-center gap-1 text-[9px] font-semibold px-2 py-1 rounded-full">
            <Users className="h-3 w-3" /> {product.watchers}
          </span>
        )}
      </div>
      <div className="p-3">
        <h3 className="text-[13px] font-semibold text-white line-clamp-2 leading-snug min-h-[34px]">
          {product.title}
        </h3>
        <div className="mt-1.5 flex items-baseline gap-1.5 flex-wrap">
          <span className="text-base font-black text-s8ll">£{product.price % 1 === 0 ? product.price : product.price.toFixed(2)}</span>
          {product.originalPrice && (
            <span className="text-[11px] text-txt3 line-through">£{product.originalPrice}</span>
          )}
        </div>
        <div className="mt-1.5 flex items-center gap-1 text-[10px] text-txt3">
          <MapPin className="h-3 w-3 shrink-0" />
          <span className="truncate">{product.location}</span>
        </div>
      </div>
    </motion.button>
  )
}
