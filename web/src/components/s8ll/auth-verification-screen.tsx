'use client'

import { useEffect, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ShieldCheck, Fingerprint, ScanLine, FileCheck2, Lock, Sparkles, BadgeCheck, CheckCircle2,
  QrCode, Star, RefreshCcw,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'

type Phase = 'idle' | 'scanning' | 'verifying' | 'verified'

const SECURITY_FEATURES = [
  { icon: Fingerprint, title: 'Biometric match', desc: 'AI fingerprint of materials & stitching' },
  { icon: ScanLine, title: 'Micro-stitch scan', desc: '1,200 data points per item' },
  { icon: Lock, title: 'NFC chip check', desc: 'Cryptographic tag verification' },
  { icon: FileCheck2, title: 'Chain of custody', desc: 'Full provenance history logged' },
]

async function fetchVerified() {
  const res = await fetch('/api/products')
  if (!res.ok) throw new Error('Failed')
  const data = await res.json()
  return data.products.find((p: any) => p.isVerified) ?? null
}

export function AuthVerificationScreen() {
  const { push } = useAppStore()
  const { toast } = useToast()
  const { data } = useQuery({ queryKey: ['products'], queryFn: fetchVerified })
  const product = data

  const [phase, setPhase] = useState<Phase>('idle')

  useEffect(() => {
    if (phase !== 'scanning') return
    const t = setTimeout(() => setPhase('verifying'), 2600)
    return () => clearTimeout(t)
  }, [phase])

  useEffect(() => {
    if (phase !== 'verifying') return
    const t = setTimeout(() => setPhase('verified'), 1800)
    return () => clearTimeout(t)
  }, [phase])

  const start = () => {
    setPhase('scanning')
  }

  return (
    <div className="min-h-[100dvh] pb-10">
      <ScreenHeader title="Dewu Authentication" subtitle="Industry-leading verification" />

      <div className="px-4 mt-4 space-y-5">
        {/* scan area */}
        <div className="relative aspect-[4/5] rounded-3xl overflow-hidden s8ll-card keep-dark">
          {product && (
            <>
              { }
              <img src={product.image} alt={product.title} className="absolute inset-0 h-full w-full object-cover" />
            </>
          )}
          <div className="absolute inset-0 bg-black/55" />

          {/* scan frame */}
          <div className="absolute inset-6 rounded-2xl border-2 border-s8ll/70">
            {phase === 'scanning' && (
              <div className="scanline absolute inset-x-2 h-[3px] bg-s8ll shadow-[0_0_24px_rgba(193,255,61,0.95)] rounded-full" />
            )}
            {/* corners */}
            {['top-0 left-0 border-t-4 border-l-4 rounded-tl-xl', 'top-0 right-0 border-t-4 border-r-4 rounded-tr-xl', 'bottom-0 left-0 border-b-4 border-l-4 rounded-bl-xl', 'bottom-0 right-0 border-b-4 border-r-4 rounded-br-xl'].map((pos) => (
              <span key={pos} className={cn('absolute h-8 w-8 border-s8ll', pos)} />
            ))}

            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <AnimatePresence mode="wait">
                {phase === 'idle' && (
                  <motion.div key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="text-center px-6">
                    <ShieldCheck className="h-14 w-14 text-s8ll mx-auto mb-4" strokeWidth={1.5} />
                    <p className="text-white font-black text-lg">Verify an item</p>
                    <p className="text-[12px] text-txt2 mt-2 leading-relaxed max-w-[240px]">
                      We check materials, stitching, tags and provenance. Takes ~10 seconds.
                    </p>
                  </motion.div>
                )}
                {phase === 'scanning' && (
                  <motion.div key="scanning" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="text-center">
                    <Loader />
                  </motion.div>
                )}
                {phase === 'verifying' && (
                  <motion.div key="verifying" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="text-center">
                    <p className="text-s8ll font-black text-base animate-pulse">Verifying…</p>
                    <p className="text-[11px] text-txt2 mt-1.5">Matching 1,200 micro-features</p>
                  </motion.div>
                )}
                {phase === 'verified' && (
                  <motion.div key="verified" initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="text-center pop-in">
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: 'spring', stiffness: 260, damping: 14, delay: 0.1 }}
                      className="h-20 w-20 rounded-full bg-success/20 border-2 border-success flex items-center justify-center mx-auto"
                    >
                      <CheckCircle2 className="h-10 w-10 text-success" />
                    </motion.div>
                    <p className="text-white font-black text-xl mt-4">AUTHENTIC ✓</p>
                    <p className="text-[12px] text-success font-bold mt-1">Certificate #S8LL-{product?.id.slice(-8).toUpperCase()}</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>

          {phase === 'scanning' && (
            <span className="absolute bottom-6 left-1/2 -translate-x-1/2 text-[11px] font-bold text-s8ll tracking-widest uppercase">
              Scanning item…
            </span>
          )}
        </div>

        {(phase === 'idle' || phase === 'verified') && (
          <div className="flex gap-2.5">
            <Button
              onClick={phase === 'verified' ? () => setPhase('idle') : start}
              variant={phase === 'verified' ? 'outline' : 'default'}
              className={cn(
                'flex-1 h-12 rounded-2xl text-[14px]',
                phase === 'verified' ? 'border-border bg-surface text-white hover:bg-surface-light' : 's8ll-btn',
              )}
            >
              {phase === 'verified' ? (
                <>
                  <RefreshCcw className="h-4 w-4 mr-2" /> Scan another item
                </>
              ) : (
                <>
                  <ScanLine className="h-4 w-4 mr-2" /> Start verification
                </>
              )}
            </Button>
            {phase === 'verified' && product && (
              <Button
                onClick={() => push({ name: 'product', id: product.id })}
                className="s8ll-btn h-12 px-6 rounded-2xl text-[14px]"
              >
                View item
              </Button>
            )}
          </div>
        )}

        {/* certificate */}
        <AnimatePresence>
          {phase === 'verified' && (
            <motion.section
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="s8ll-card rounded-3xl p-4 relative overflow-hidden pop-in"
            >
              <div className="absolute -right-8 -top-8 h-24 w-24 rounded-full bg-s8ll/10 blur-2xl" />
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-[10px] uppercase tracking-[0.3em] text-txt3">Certificate of authenticity</p>
                  <h3 className="text-[16px] font-black text-white mt-1.5">{product?.title ?? 'Item'}</h3>
                  <div className="flex items-center gap-1.5 mt-1">
                    <Star className="h-3.5 w-3.5 fill-gold text-gold" />
                    <span className="text-[11px] text-txt2">Grade: S — Mint • Verified 07 Sep 2026</span>
                  </div>
                </div>
                <div className="h-16 w-16 shrink-0 bg-surface-light border border-border rounded-2xl flex items-center justify-center">
                  <QrCode className="h-10 w-10 text-s8ll" strokeWidth={1.5} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2.5 mt-4">
                {[
                  ['Item ID', `#${product?.id.slice(-8).toUpperCase() ?? ''}`],
                  ['Appraiser', 'S8LL Lab 04'],
                  ['Material', 'Verified genuine'],
                  ['Warranty', '10x money-back'],
                ].map(([k, v]) => (
                  <div key={k} className="bg-surface rounded-xl p-2.5">
                    <p className="text-[9px] text-txt3 uppercase tracking-wider">{k}</p>
                    <p className="text-[12px] font-bold text-white mt-0.5">{v}</p>
                  </div>
                ))}
              </div>
            </motion.section>
          )}
        </AnimatePresence>

        {/* security features grid */}
        <section>
          <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-3">
            <Sparkles className="h-4 w-4 text-s8ll" /> How verification works
          </h3>
          <div className="grid grid-cols-2 gap-2.5">
            {SECURITY_FEATURES.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.06 }}
                className="s8ll-card rounded-2xl p-3.5"
              >
                <div className={cn(
                  'h-9 w-9 rounded-xl flex items-center justify-center mb-2',
                  phase === 'verified' ? 'bg-success/15 text-success' : 'bg-s8ll/10 text-s8ll',
                )}>
                  {phase === 'verified' ? <CheckCircle2 className="h-4.5 w-4.5 h-[18px] w-[18px]" /> : <f.icon className="h-[18px] w-[18px]" />}
                </div>
                <p className="text-[11.5px] font-bold text-white leading-tight">{f.title}</p>
                <p className="text-[9.5px] text-txt3 mt-1 leading-tight">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </section>

        {/* 10x guarantee badge */}
        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={() => toast({ title: '10x Guarantee active', description: 'If an authenticated item is found fake, we refund 10x the price.' })}
          className="w-full rounded-3xl p-5 relative overflow-hidden flex items-center gap-4 text-left"
          style={{ background: 'linear-gradient(135deg, #2a230a 0%, #141418 65%)' }}
        >
          <div className="absolute -right-8 -top-8 h-28 w-28 rounded-full bg-gold/15 blur-3xl" />
          <div className="h-14 w-14 rounded-2xl bg-gold/15 border border-gold/40 flex items-center justify-center shrink-0">
            <span className="text-gold font-black text-xl">10×</span>
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-1.5">
              <BadgeCheck className="h-4 w-4 text-gold" />
              <h3 className="text-[15px] font-black text-white">Money-back guarantee</h3>
            </div>
            <p className="text-[11px] text-txt2 mt-1">
              Fake found after authentication? We refund 10x the item price. That&apos;s how confident we are.
            </p>
          </div>
        </motion.button>
      </div>
    </div>
  )
}

function Loader() {
  return (
    <div className="flex flex-col items-center">
      <motion.div
        animate={{ rotate: 360 }}
        transition={{ duration: 1.1, repeat: Infinity, ease: 'linear' }}
        className="h-12 w-12 rounded-full border-2 border-s8ll/25 border-t-s8ll"
      />
      <p className="text-s8ll font-black text-sm mt-4">Scanning…</p>
      <p className="text-[11px] text-txt2 mt-1">Materials • stitching • tags • NFC</p>
    </div>
  )
}
