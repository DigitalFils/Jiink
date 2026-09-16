'use client'

import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  Search, Map, Radio, ScanFace, Users2, BadgeCheck, Bot, Wallet, Heart,
  Zap, Flame, ChevronRight, ArrowRight, TrendingUp,
} from 'lucide-react'
import { ProductCard } from './product-card'
import { pad2, useCountdown } from './hooks'
import { useAppStore } from '@/store/useAppStore'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'
import type { Product, Story } from '@/lib/types'

const FEATURES = [
  { label: 'Map View', icon: Map, route: 'map' as const, tint: 'text-success' },
  { label: 'Live', icon: Radio, route: 'live' as const, tint: 'text-live' },
  { label: 'AR Try-On', icon: ScanFace, route: 'ar' as const, tint: 'text-s8ll' },
  { label: 'Group Buy', icon: Users2, route: 'groupbuy' as const, tint: 'text-warn' },
  { label: 'Dewu Auth', icon: BadgeCheck, route: 'auth' as const, tint: 'text-sky-400' },
  { label: 'AI Helper', icon: Bot, route: 'ai' as const, tint: 'text-s8ll' },
  { label: 'Wallet', icon: Wallet, route: 'wallet' as const, tint: 'text-gold' },
  { label: 'Wishlist', icon: Heart, route: 'wishlist' as const, tint: 'text-live' },
]

async function fetchHome() {
  const res = await fetch('/api/home')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function HomeScreen() {
  const { push, setTab } = useAppStore()
  const { data, isLoading } = useQuery({ queryKey: ['home'], queryFn: fetchHome })

  const flashEnd = Date.now() + 2 * 3600000 + 14 * 60000
  const cd = useCountdown(flashEnd)

  const liveCount = data?.liveStreams?.filter((s: any) => s.isLive).length ?? 0
  const topStream = data?.liveStreams?.[0]

  return (
    <div className="pb-28">
      {/* Top bar */}
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl">
        <div className="px-4 pt-[max(env(safe-area-inset-top),14px)] pb-3">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h1 className="text-[22px] font-black tracking-tighter text-white leading-none">
                S8LL<span className="s8ll-gradient-text">.</span>
              </h1>
              <p className="text-[10px] text-txt3 tracking-[0.25em] uppercase mt-0.5">Ultimate Marketplace</p>
            </div>
            <div className="flex items-center gap-2">
              {liveCount > 0 && (
                <button
                  onClick={() => push({ name: 'live' })}
                  className="flex items-center gap-1.5 bg-live/15 border border-live/30 text-live text-[11px] font-bold px-3 py-1.5 rounded-full"
                >
                  <span className="live-dot h-2 w-2 rounded-full bg-live inline-block" />
                  {liveCount} live now
                </button>
              )}
              <button
                onClick={() => push({ name: 'wallet' })}
                aria-label="Wallet"
                className="h-9 w-9 rounded-full bg-surface border border-border flex items-center justify-center text-gold"
              >
                <Wallet className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Smart search bar */}
          <button
            onClick={() => push({ name: 'search' })}
            className="w-full h-11 rounded-full bg-surface border border-border flex items-center gap-3 px-4 text-txt3 hover:border-s8ll/40 transition-colors"
          >
            <Search className="h-4 w-4" />
            <span className="text-sm">Search anything… <span className="text-s8ll">AI powered</span></span>
            <kbd className="ml-auto text-[9px] font-bold bg-surface-light border border-border rounded-md px-1.5 py-0.5 text-txt2">⌘K</kbd>
          </button>
        </div>
      </header>

      <div className="px-4 space-y-6 mt-2">
        {/* Stories */}
        <section aria-label="Stories" className="-mx-4 px-4">
          <div className="flex gap-3.5 overflow-x-auto no-scrollbar pb-1">
            <div className="flex flex-col items-center gap-1 shrink-0 w-[62px]">
              <div className="h-[54px] w-[54px] rounded-full s8ll-btn flex items-center justify-center text-2xl font-thin text-black">
                +
              </div>
              <span className="text-[10px] text-txt2">Your story</span>
            </div>
            {(data?.stories ?? []).map((s: Story) => (
              <button key={s.id} className="flex flex-col items-center gap-1 shrink-0 w-[62px]">
                <div
                  className={cn(
                    'h-[54px] w-[54px] rounded-full p-[2.5px]',
                    s.isLive ? 'bg-gradient-to-tr from-live via-warn to-s8ll' : 'bg-gradient-to-tr from-s8ll/60 to-s8ll/20',
                  )}
                >
                  <div className="h-full w-full rounded-full bg-background p-[2px]">
                    { }
                    <img src={s.avatar} alt={s.username} className="h-full w-full rounded-full object-cover" />
                  </div>
                </div>
                <span className="text-[10px] text-txt2 truncate max-w-full">{s.username}</span>
              </button>
            ))}
          </div>
        </section>

        {/* Quick feature grid */}
        <section aria-label="Quick features">
          <div className="grid grid-cols-4 gap-3">
            {FEATURES.map((f, i) => (
              <motion.button
                key={f.label}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.04 }}
                onClick={() => push({ name: f.route })}
                className="flex flex-col items-center gap-1.5 s8ll-card rounded-2xl py-3 hover:border-s8ll/30 transition-colors"
              >
                <f.icon className={cn('h-5 w-5', f.tint)} strokeWidth={2.2} />
                <span className="text-[10px] font-semibold text-txt2">{f.label}</span>
              </motion.button>
            ))}
          </div>
        </section>

        {/* Flash sale banner — promo media card (stays dark in light theme) */}
        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={() => push({ name: 'flashsale' })}
          className="w-full s8ll-card keep-dark rounded-3xl overflow-hidden relative text-left"
        >
          <div className="flex items-center gap-3 p-3">
            <div className="relative h-[86px] w-[86px] shrink-0 rounded-2xl overflow-hidden">
              { }
              <img
                src={data?.flashSale?.[0]?.image ?? 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=300'}
                alt="Flash sale"
                className="h-full w-full object-cover"
              />
              <div className="absolute inset-0 bg-live/25" />
              <span className="absolute top-1.5 left-1.5 bg-live text-white text-[9px] font-black px-1.5 py-0.5 rounded">限时秒杀</span>
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <Zap className="h-4 w-4 text-warn fill-warn" />
                <h3 className="text-[15px] font-black text-white">Flash Sale</h3>
              </div>
              <p className="text-[11px] text-txt2 mt-0.5">Up to 70% OFF • Verified sneakers</p>
              <div className="flex items-center gap-1.5 mt-2">
                {[
                  [cd.hours, 'h'], [cd.minutes, 'm'], [cd.seconds, 's'],
                ].map(([v, u], i) => (
                  <span key={i} className="bg-black/50 border border-border rounded-lg px-1.5 py-1 text-[11px] font-black text-white tabular-nums">
                    {pad2(v as number)}
                    <span className="text-txt3 font-medium text-[9px] ml-0.5">{u}</span>
                  </span>
                ))}
                <span className="text-[10px] text-live ml-1 font-semibold">ends soon</span>
              </div>
            </div>
            <ArrowRight className="h-5 w-5 text-txt3 shrink-0" />
          </div>
        </motion.button>

        {/* Live stream banner */}
        {topStream && (
          <motion.button
            whileTap={{ scale: 0.98 }}
            onClick={() => push({ name: 'live' })}
            className="w-full keep-dark rounded-3xl overflow-hidden relative text-left h-40"
          >
            { }
            <img src={topStream.cover} alt={topStream.title} className="absolute inset-0 h-full w-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent" />
            <div className="absolute top-3 left-3 flex items-center gap-2">
              <span className="live-dot h-2 w-2 rounded-full bg-live inline-block" />
              <span className="bg-live text-white text-[10px] font-black px-2 py-0.5 rounded-md tracking-wide">LIVE</span>
              <span className="bg-black/60 backdrop-blur text-white text-[10px] font-bold px-2 py-0.5 rounded-md">
                {topStream.viewers.toLocaleString()} watching
              </span>
            </div>
            <div className="absolute bottom-3 inset-x-3">
              <div className="flex items-center gap-2">
                { }
                <img src={topStream.hostAvatar} alt={topStream.host} className="h-8 w-8 rounded-full border-2 border-s8ll object-cover" />
                <div className="min-w-0">
                  <p className="text-[13px] font-bold text-white truncate">{topStream.title}</p>
                  <p className="text-[10px] text-txt2">@{topStream.host} • {topStream.category}</p>
                </div>
              </div>
            </div>
          </motion.button>
        )}

        {/* Live drops (Dewu-style) */}
        <section aria-label="Live drops">
          <SectionHeader icon={Flame} title="Live Drops" action="See all" onAction={() => setTab('drop')} />
          <div className="flex gap-3 overflow-x-auto no-scrollbar -mx-4 px-4 pb-1">
            {(data?.liveDrops ?? []).map((p: Product, i: number) => (
              <div key={p.id} className="shrink-0 w-[132px]">
                <button onClick={() => push({ name: 'product', id: p.id })} className="relative w-full keep-dark aspect-square rounded-2xl overflow-hidden">
                  { }
                  <img src={p.image} alt={p.title} className="h-full w-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-transparent to-black/20" />
                  {i < 2 && (
                    <span className="absolute top-2 right-2 bg-live text-white text-[9px] font-black px-1.5 py-0.5 rounded flex items-center gap-1">
                      <span className="live-dot h-1.5 w-1.5 rounded-full bg-white inline-block" /> LIVE
                    </span>
                  )}
                  <div className="absolute bottom-2 left-2 right-2 text-left">
                    <p className="text-[10px] font-black text-s8ll tracking-widest">{p.title.split(' ')[0].toUpperCase()}</p>
                    <p className="text-[13px] font-black text-white">£{p.price}</p>
                  </div>
                </button>
              </div>
            ))}
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <Skeleton key={i} className="shrink-0 w-[132px] aspect-square rounded-2xl bg-surface-light" />
            ))}
          </div>
        </section>

        {/* Group buy banner */}
        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={() => push({ name: 'groupbuy' })}
          className="w-full s8ll-card rounded-3xl p-4 flex items-center gap-3 text-left relative overflow-hidden"
        >
          <div className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-warn/10 blur-2xl" />
          <div className="h-12 w-12 rounded-2xl bg-warn/15 border border-warn/30 flex items-center justify-center shrink-0">
            <Users2 className="h-6 w-6 text-warn" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-[15px] font-black text-white">Team up & Save up to 60%</h3>
            <p className="text-[11px] text-txt2 mt-0.5">PDD-style group buys — invite friends, unlock bulk prices</p>
          </div>
          <ChevronRight className="h-5 w-5 text-txt3 shrink-0" />
        </motion.button>

        {/* Trending near you */}
        <section aria-label="Trending near you">
          <SectionHeader icon={TrendingUp} title="Trending Near You" action="See all" onAction={() => push({ name: 'search' })} />
          <div className="grid grid-cols-2 gap-3">
            {(data?.trending ?? []).map((p: Product) => (
              <ProductCard key={p.id} product={p} />
            ))}
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="s8ll-card rounded-2xl overflow-hidden">
                <Skeleton className="aspect-square rounded-none bg-surface-light" />
                <div className="p-3 space-y-2">
                  <Skeleton className="h-3 w-full bg-surface-light" />
                  <Skeleton className="h-3 w-2/3 bg-surface-light" />
                  <Skeleton className="h-4 w-16 bg-surface-light" />
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}

function SectionHeader({ icon: Icon, title, action, onAction }: {
  icon: typeof TrendingUp; title: string; action?: string; onAction?: () => void
}) {
  return (
    <div className="flex items-center justify-between mb-3">
      <div className="flex items-center gap-2">
        <Icon className="h-4 w-4 text-s8ll" />
        <h2 className="text-[15px] font-bold text-white">{title}</h2>
      </div>
      {action && (
        <button onClick={onAction} className="text-[11px] font-semibold text-s8ll hover:underline">
          {action}
        </button>
      )}
    </div>
  )
}
