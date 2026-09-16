'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { MapPin, Navigation, Layers, Search, Compass } from 'lucide-react'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'
import type { Product } from '@/lib/types'

async function fetchTrending() {
  const res = await fetch('/api/products')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

// fixed pseudo-geo positions within the viewport (percentages)
const SPOTS = [
  { x: 22, y: 30 }, { x: 58, y: 22 }, { x: 78, y: 48 },
  { x: 38, y: 58 }, { x: 62, y: 72 }, { x: 18, y: 76 },
]

const ROADS = [
  'M0,40 L100,40', 'M0,68 L100,68', 'M30,0 L30,100', 'M70,0 L70,100', 'M0,85 L100,85',
  'M50,0 L50,100', 'M0,14 L100,14', 'M12,0 L12,100', 'M88,0 L88,100',
]

export function MapViewScreen() {
  const { push } = useAppStore()
  const { data } = useQuery({ queryKey: ['products'], queryFn: fetchTrending })
  const listings: Product[] = data?.products?.filter((p: Product) => p.location.includes('Manchester')) ?? []
  const [active, setActive] = useState<number>(0)
  const [followMode, setFollowMode] = useState(false)

  const current = listings[active]

  return (
    <div className="min-h-[100dvh] flex flex-col">
      <ScreenHeader title="Map Discovery" subtitle="Listings near you • Manchester" />

      <div className="flex-1 relative">
        {/* custom painted map */}
        <div className="relative h-[62dvh] map-grid bg-[#101014] overflow-hidden keep-dark">
          {/* roads */}
          <svg className="absolute inset-0 h-full w-full" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden>
            {ROADS.map((d, i) => (
              <path key={i} d={d} stroke="#1c1c22" strokeWidth={i < 5 ? 2.2 : 1.1} fill="none" />
            ))}
            {/* river */}
            <path d="M0,55 Q35,48 50,58 T100,52" stroke="#14222b" strokeWidth="5" fill="none" strokeLinecap="round" />
            {/* park */}
            <rect x="40" y="44" width="16" height="14" rx="2" fill="#14200f" />
          </svg>

          {/* user location */}
          <div className="absolute" style={{ left: '50%', top: '50%' }}>
            <span className={cn('block h-3.5 w-3.5 rounded-full bg-s8ll border-2 border-black', followMode && 'marker-pulse')} />
            <span className={cn('absolute -inset-2 rounded-full border border-s8ll/40', followMode && 'animate-ping')} />
          </div>

          {/* price markers */}
          {listings.slice(0, SPOTS.length).map((p, i) => (
            <motion.button
              key={p.id}
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: active === i ? 1.15 : 1 }}
              onClick={() => setActive(i)}
              className={cn(
                'absolute -translate-x-1/2 -translate-y-1/2 px-2.5 py-1 rounded-lg text-[11px] font-black shadow-lg transition-colors',
                active === i
                  ? 's8ll-btn text-black'
                  : 'bg-black/75 backdrop-blur text-white border border-border hover:border-s8ll/60',
              )}
              style={{ left: `${SPOTS[i].x}%`, top: `${SPOTS[i].y}%` }}
            >
              £{p.price}
            </motion.button>
          ))}

          {/* map controls */}
          <div className="absolute top-3 right-3 flex flex-col gap-2">
            {[
              { icon: Navigation, label: 'Recenter', fn: () => setFollowMode((f) => !f), active: followMode },
              { icon: Layers, label: 'Layers', fn: () => {}, active: false },
              { icon: Compass, label: 'Compass', fn: () => {}, active: false },
            ].map(({ icon: Icon, label, fn, active: a }) => (
              <button
                key={label}
                onClick={fn}
                aria-label={label}
                className={cn(
                  'h-10 w-10 rounded-xl backdrop-blur border flex items-center justify-center',
                  a ? 's8ll-btn text-black' : 'bg-black/60 border-border text-white',
                )}
              >
                <Icon className="h-4.5 w-4.5 h-[18px] w-[18px]" />
              </button>
            ))}
          </div>

          {/* search pill */}
          <button
            onClick={() => push({ name: 'search' })}
            className="absolute top-3 left-3 h-10 rounded-full bg-black/70 backdrop-blur border border-border flex items-center gap-2 px-4 text-[12px] text-txt2"
          >
            <Search className="h-3.5 w-3.5" /> Search this area
          </button>

          {/* district labels */}
          <span className="absolute text-[9px] font-bold text-txt3 uppercase tracking-widest" style={{ left: '31%', top: '10%' }}>Northern Quarter</span>
          <span className="absolute text-[9px] font-bold text-txt3 uppercase tracking-widest" style={{ left: '71%', top: '10%' }}>Ancoats</span>
          <span className="absolute text-[9px] font-bold text-txt3 uppercase tracking-widest" style={{ left: '8%', top: '56%' }}>Castlefield</span>
          <span className="absolute text-[9px] font-bold text-txt3 uppercase tracking-widest" style={{ left: '55%', top: '88%' }}>Piccadilly</span>
        </div>

        {/* nearby listings carousel */}
        <div className="bg-background border-t border-border pt-3 pb-6 px-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white">
              <MapPin className="h-4 w-4 text-s8ll" /> Nearby listings
            </h3>
            <span className="text-[11px] text-txt3">{listings.length} items around you</span>
          </div>
          <AnimatePresence mode="wait">
            {current && (
              <motion.button
                key={current.id}
                initial={{ opacity: 0, x: 30 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -30 }}
                onClick={() => push({ name: 'product', id: current.id })}
                className="s8ll-card rounded-2xl p-3 w-full flex items-center gap-3.5 text-left"
              >
                { }
                <img src={current.image} alt={current.title} className="h-16 w-16 rounded-xl object-cover shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="text-[13.5px] font-semibold text-white truncate">{current.title}</p>
                  <p className="text-[11px] text-txt2 mt-0.5 flex items-center gap-1 truncate">
                    <MapPin className="h-3 w-3 shrink-0" /> {current.location} • {(0.4 + active * 0.7).toFixed(1)} km away
                  </p>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[15px] font-black text-s8ll">£{current.price}</span>
                    <span className="text-[9px] bg-surface-light text-txt2 px-1.5 py-0.5 rounded">{current.condition}</span>
                  </div>
                </div>
              </motion.button>
            )}
          </AnimatePresence>
          <div className="flex justify-center gap-1.5 mt-3">
            {listings.slice(0, SPOTS.length).map((_, i) => (
              <button
                key={i}
                onClick={() => setActive(i)}
                aria-label={`Listing ${i + 1}`}
                className={cn('h-1.5 rounded-full transition-all', active === i ? 'w-6 bg-s8ll' : 'w-1.5 bg-surface-light')}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
