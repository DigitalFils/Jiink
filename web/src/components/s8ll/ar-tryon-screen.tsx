'use client'

import { useEffect, useRef, useState, type PointerEvent as RPointerEvent } from 'react'
import { useQuery } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ScanFace, RotateCw, RotateCcw, ZoomIn, ZoomOut, Camera, Check, Sparkles, Loader2, Footprints,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import type { Product } from '@/lib/types'

async function fetchAR() {
  const res = await fetch('/api/products?ar=true')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

type Phase = 'scanning' | 'detecting' | 'ready'

export function ARTryOnScreen() {
  const { push } = useAppStore()
  const { toast } = useToast()
  const { data } = useQuery({ queryKey: ['ar'], queryFn: fetchAR })
  const shoes: Product[] = data?.products ?? []

  const [selected, setSelected] = useState<Product | null>(null)
  const [phase, setPhase] = useState<Phase>('scanning')
  const [zoom, setZoom] = useState(1)
  const [rotation, setRotation] = useState(0)
  const [captured, setCaptured] = useState(false)
  const [pos, setPos] = useState({ x: 0, y: 0 })

  // --- v2 gesture engine: drag / pinch-zoom / twist-rotate / double-tap reset ---
  const viewportRef = useRef<HTMLDivElement | null>(null)
  const pointersRef = useRef(new Map<number, { x: number; y: number }>())
  const downInfoRef = useRef(new Map<number, { t: number; x: number; y: number }>())
  const pinchRef = useRef<{ baseZoom: number; baseRot: number; baseDist: number; baseAngle: number } | null>(null)
  const lastPointRef = useRef<{ x: number; y: number } | null>(null)
  const lastTapRef = useRef(0)

  const resetPlacement = () => {
    setZoom(1)
    setRotation(0)
    setPos({ x: 0, y: 0 })
  }

  const onPointerDown = (e: RPointerEvent<HTMLDivElement>) => {
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY })
    downInfoRef.current.set(e.pointerId, { t: Date.now(), x: e.clientX, y: e.clientY })
    try { viewportRef.current?.setPointerCapture(e.pointerId) } catch { /* pointer gone */ }

    const pts = [...pointersRef.current.values()]
    if (pts.length === 2) {
      const [a, b] = pts
      pinchRef.current = {
        baseZoom: zoom,
        baseRot: rotation,
        baseDist: Math.hypot(b.x - a.x, b.y - a.y) || 1,
        baseAngle: (Math.atan2(b.y - a.y, b.x - a.x) * 180) / Math.PI,
      }
      lastPointRef.current = null
    } else if (pts.length === 1) {
      lastPointRef.current = { x: e.clientX, y: e.clientY }
    }
  }

  const onPointerMove = (e: RPointerEvent<HTMLDivElement>) => {
    if (!pointersRef.current.has(e.pointerId)) return
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY })
    const pts = [...pointersRef.current.values()]

    if (pts.length >= 2 && pinchRef.current) {
      // two fingers: pinch zooms, twist rotates
      const [a, b] = pts
      const dist = Math.hypot(b.x - a.x, b.y - a.y)
      const angle = (Math.atan2(b.y - a.y, b.x - a.x) * 180) / Math.PI
      setZoom(Math.min(2.5, Math.max(0.5, (pinchRef.current.baseZoom * dist) / pinchRef.current.baseDist)))
      setRotation(pinchRef.current.baseRot + angle - pinchRef.current.baseAngle)
    } else if (pts.length === 1 && lastPointRef.current) {
      // single pointer: drag to reposition the shoe
      const dx = e.clientX - lastPointRef.current.x
      const dy = e.clientY - lastPointRef.current.y
      lastPointRef.current = { x: e.clientX, y: e.clientY }
      setPos((p) => ({
        x: Math.min(150, Math.max(-150, p.x + dx)),
        y: Math.min(200, Math.max(-200, p.y + dy)),
      }))
    }
  }

  const onPointerUp = (e: RPointerEvent<HTMLDivElement>) => {
    const info = downInfoRef.current.get(e.pointerId)
    pointersRef.current.delete(e.pointerId)
    downInfoRef.current.delete(e.pointerId)

    if (pointersRef.current.size < 2) pinchRef.current = null
    if (pointersRef.current.size === 1) {
      const only = [...pointersRef.current.values()][0]
      lastPointRef.current = { x: only.x, y: only.y }
    } else {
      lastPointRef.current = null
    }

    // tap = short press with little movement, released as the last pointer.
    // two taps within 300ms => double-tap => reset placement
    if (info && pointersRef.current.size === 0) {
      const dt = Date.now() - info.t
      const moved = Math.hypot(e.clientX - info.x, e.clientY - info.y)
      if (dt < 250 && moved < 12) {
        const now = Date.now()
        if (now - lastTapRef.current < 300) resetPlacement()
        lastTapRef.current = now
      }
    }
  }

  // desktop: wheel zooms the shoe
  useEffect(() => {
    const el = viewportRef.current
    if (!el) return
    const onWheel = (ev: WheelEvent) => {
      ev.preventDefault()
      setZoom((z) => Math.min(2.5, Math.max(0.5, z - ev.deltaY * 0.0012)))
    }
    el.addEventListener('wheel', onWheel, { passive: false })
    return () => el.removeEventListener('wheel', onWheel)
  }, [])

  useEffect(() => {
    if (phase !== 'scanning') return
    const t = setTimeout(() => setPhase('detecting'), 2200)
    return () => clearTimeout(t)
  }, [phase])

  useEffect(() => {
    if (phase !== 'detecting') return
    const t = setTimeout(() => setPhase('ready'), 1600)
    return () => clearTimeout(t)
  }, [phase])

  const rotate = () => setRotation((r) => r + 45)

  return (
    <div className="min-h-[100dvh] flex flex-col">
      <ScreenHeader title="AR Try-On" subtitle="Virtual sneaker fitting" />

      <div className="flex-1 px-4 py-4 space-y-5">
        {/* AR viewport — gesture layer (drag / pinch / twist / double-tap) */}
        <div
          ref={viewportRef}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
          className="relative aspect-[3/4] rounded-3xl overflow-hidden s8ll-card keep-dark cursor-grab active:cursor-grabbing select-none touch-none"
        >
          {/* simulated camera feed (feet environment) */}
          { }
          <img
            src="https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=600"
            alt="Camera view"
            className="absolute inset-0 h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-black/45" />

          {/* foot detection box */}
          <motion.div
            animate={{
              borderColor: phase === 'ready' ? 'rgba(52,199,89,0.9)' : 'rgba(193,255,61,0.8)',
              scale: phase === 'ready' ? 1 : [0.98, 1.02, 0.98],
            }}
            transition={{ duration: 1.4, repeat: phase === 'ready' ? 0 : Infinity }}
            className="absolute bottom-[14%] left-1/2 -translate-x-1/2 h-[38%] w-[64%] rounded-3xl border-2 border-dashed"
          >
            {/* corner marks */}
            {['top-0 left-0', 'top-0 right-0', 'bottom-0 left-0', 'bottom-0 right-0'].map((pos) => (
              <span key={pos} className={cn('absolute h-5 w-5 border-s8ll', pos,
                pos.includes('top') ? 'border-t-2' : 'border-b-2',
                pos.includes('left') ? 'border-l-2' : 'border-r-2',
                pos.includes('left') && pos.includes('top') && 'rounded-tl-lg',
                pos.includes('right') && pos.includes('top') && 'rounded-tr-lg',
                pos.includes('left') && pos.includes('bottom') && 'rounded-bl-lg',
                pos.includes('right') && pos.includes('bottom') && 'rounded-br-lg',
              )} />
            ))}

            {phase === 'scanning' && <div className="scanline absolute inset-x-3 h-0.5 bg-s8ll shadow-[0_0_18px_rgba(193,255,61,0.9)] rounded-full" />}
          </motion.div>

          {/* shoe overlay */}
          <AnimatePresence>
            {phase === 'ready' && selected && (
              <motion.div
                key={selected.id}
                initial={{ opacity: 0, y: 30, scale: 0.85 }}
                animate={{ opacity: 1, scale: zoom, rotate: rotation, x: pos.x, y: pos.y }}
                exit={{ opacity: 0 }}
                transition={{ type: 'spring', stiffness: 300, damping: 26 }}
                className="absolute bottom-[16%] left-1/2 -translate-x-1/2 origin-center"
              >
                <div className="relative w-[220px] h-[130px] shoe-ar">
                  { }
                  <img src={selected.image} alt={selected.title} className="h-full w-full object-contain drop-shadow-2xl" />
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* status chip */}
          <div className="absolute top-3 left-3 flex items-center gap-2">
            <span className={cn(
              'flex items-center gap-1.5 text-[10px] font-black px-2.5 py-1.5 rounded-full backdrop-blur',
              phase === 'ready' ? 'bg-success/20 text-success' : 'bg-s8ll/20 text-s8ll',
            )}>
              {phase === 'scanning' && <Loader2 className="h-3 w-3 animate-spin" />}
              {phase === 'detecting' && <Footprints className="h-3 w-3" />}
              {phase === 'ready' && <Check className="h-3 w-3" />}
              {phase === 'scanning' && 'Scanning environment…'}
              {phase === 'detecting' && 'Feet detected • size UK 9'}
              {phase === 'ready' && `Try-on active · drag · pinch ×${zoom.toFixed(1)} · twist`}
            </span>
          </div>

          <span className="absolute top-3 right-3 bg-black/55 backdrop-blur text-white text-[9px] font-bold px-2 py-1 rounded-full">
            AR • βeta
          </span>

          {captured && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              className="absolute inset-0 bg-black/70 backdrop-blur flex flex-col items-center justify-center"
            >
              <div className="h-20 w-20 s8ll-btn rounded-full flex items-center justify-center mb-4">
                <Check className="h-10 w-10 text-black" />
              </div>
              <p className="text-white font-black text-lg">Snapshot saved!</p>
              <p className="text-txt2 text-[12px] mt-1">Share your fit or add to wishlist</p>
              <Button
                className="s8ll-btn rounded-full mt-5 px-6"
                onClick={() => setCaptured(false)}
              >
                Back to try-on
              </Button>
            </motion.div>
          )}
        </div>

        {/* AR controls */}
        <div className="grid grid-cols-5 gap-2">
          {[
            { icon: ZoomOut, label: 'Zoom out', fn: () => setZoom((z) => Math.max(0.5, z - 0.15)) },
            { icon: ZoomIn, label: 'Zoom in', fn: () => setZoom((z) => Math.min(2.5, z + 0.15)) },
            { icon: RotateCw, label: 'Rotate 45°', fn: rotate },
            { icon: RotateCcw, label: 'Reset', fn: resetPlacement },
            {
              icon: Camera,
              label: 'Capture',
              fn: () => {
                if (!selected) {
                  toast({ title: 'Pick a sneaker first', description: 'Choose one from the catalog below.' })
                  return
                }
                setCaptured(true)
              },
            },
          ].map(({ icon: Icon, label, fn }) => (
            <button
              key={label}
              onClick={fn}
              className="s8ll-card rounded-2xl py-3.5 flex flex-col items-center gap-1.5 hover:border-s8ll/40 transition-colors"
            >
              <Icon className="h-5 w-5 text-s8ll" strokeWidth={2.2} />
              <span className="text-[9.5px] font-semibold text-txt2">{label}</span>
            </button>
          ))}
        </div>

        {/* sneaker picker */}
        <section>
          <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-3">
            <Sparkles className="h-4 w-4 text-s8ll" /> AR-ready sneakers
          </h3>
          <div className="flex gap-3 overflow-x-auto no-scrollbar pb-1">
            {(shoes.length > 0 ? shoes : Array.from({ length: 4 })).map((s: any, i) => (
              <motion.button
                key={s?.id ?? i}
                whileTap={{ scale: 0.95 }}
                onClick={() => s && (setSelected(s), setPhase('scanning'), setZoom(1), setRotation(0), setPos({ x: 0, y: 0 }))}
                className={cn(
                  'shrink-0 w-[120px] rounded-2xl overflow-hidden border text-left transition-colors',
                  selected?.id === s?.id ? 'border-s8ll bg-s8ll/10' : 'border-border bg-card',
                )}
              >
                <div className="relative aspect-square">
                  {s && (
                     
                    <img src={s.image} alt={s.title} className="h-full w-full object-cover" />
                  )}
                  {selected?.id === s?.id && (
                    <span className="absolute top-2 right-2 h-6 w-6 s8ll-btn rounded-full flex items-center justify-center">
                      <Check className="h-3.5 w-3.5 text-black" />
                    </span>
                  )}
                </div>
                <div className="p-2">
                  <p className="text-[10.5px] font-semibold text-white truncate">{s?.title ?? '…'}</p>
                  <p className="text-[12px] font-black text-s8ll mt-0.5">£{s?.price ?? '—'}</p>
                </div>
              </motion.button>
            ))}
          </div>
        </section>

        {selected && phase === 'ready' && (
          <Button
            onClick={() => push({ name: 'product', id: selected.id })}
            className="s8ll-btn w-full h-12 rounded-2xl text-[15px]"
          >
            <ScanFace className="h-4.5 w-4.5 h-[18px] w-[18px] mr-2" />
            It fits! View {selected.title}
          </Button>
        )}
      </div>
    </div>
  )
}
