'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Button } from '@/components/ui/button'
import {
  BadgeCheck, Radio, Users2, ScanFace, Globe2, ChevronLeft, ChevronRight,
} from 'lucide-react'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'

const PAGES = [
  {
    icon: BadgeCheck,
    title: 'Authenticity Guaranteed',
    desc: 'Every premium item passes our Dewu-grade verification with a certificate and 10x money-back guarantee.',
    art: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=600',
  },
  {
    icon: Radio,
    title: 'Live Shopping Experience',
    desc: 'Watch live drops, chat with hosts, and buy limited items in real time — just like Xiaohongshu live commerce.',
    art: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=600',
  },
  {
    icon: Users2,
    title: 'Smart Group Buying',
    desc: 'Team up with other buyers to unlock PDD-style bulk prices. The more people join, the more everyone saves.',
    art: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600',
  },
  {
    icon: ScanFace,
    title: 'AR Virtual Try-On',
    desc: 'Point your camera at your feet and see sneakers on you before buying. The online-offline gap is gone.',
    art: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600',
  },
  {
    icon: Globe2,
    title: 'Local & Global',
    desc: 'Deal with neighbours nearby like on Avito, or shop authenticated global drops — all in one app.',
    art: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
  },
]

export function OnboardingScreen() {
  const [page, setPage] = useState(0)
  const { finishOnboarding } = useAppStore()
  const last = page === PAGES.length - 1
  const current = PAGES[page]

  return (
    <div className="min-h-[100dvh] bg-background keep-dark flex flex-col relative overflow-hidden">
      <div className="absolute -top-20 -right-20 h-64 w-64 rounded-full bg-s8ll/10 blur-[80px]" />

      <div className="flex-1 flex flex-col justify-center px-8 relative">
        <AnimatePresence mode="wait">
          <motion.div
            key={page}
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
            className="flex flex-col items-center text-center"
          >
            <div className="relative w-full max-w-[280px] aspect-square rounded-3xl overflow-hidden s8ll-card mb-8">
              { }
              <img src={current.art} alt={current.title} className="h-full w-full object-cover" />
              <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-transparent" />
              <div className="absolute bottom-4 inset-x-0 flex justify-center">
                <div className="h-14 w-14 s8ll-btn rounded-2xl flex items-center justify-center">
                  <current.icon className="h-7 w-7 text-black" strokeWidth={2.2} />
                </div>
              </div>
            </div>

            <h2 className="text-2xl font-black tracking-tight text-white mb-3">{current.title}</h2>
            <p className="text-sm text-txt2 leading-relaxed max-w-[300px]">{current.desc}</p>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* progress dots */}
      <div className="flex items-center justify-center gap-2 py-4">
        {PAGES.map((_, i) => (
          <button
            key={i}
            aria-label={`Page ${i + 1}`}
            onClick={() => setPage(i)}
            className={cn(
              'h-1.5 rounded-full transition-all duration-300',
              i === page ? 'w-7 bg-s8ll' : 'w-1.5 bg-surface-light',
            )}
          />
        ))}
      </div>

      <div className="px-8 pb-[max(env(safe-area-inset-bottom),28px)]">
        <div className="flex items-center gap-3">
          {page > 0 && (
            <Button
              variant="outline"
              size="icon"
              onClick={() => setPage((p) => p - 1)}
              aria-label="Previous"
              className="h-12 w-12 rounded-full border-border bg-surface"
            >
              <ChevronLeft className="h-5 w-5" />
            </Button>
          )}
          <Button
            onClick={() => (last ? finishOnboarding() : setPage((p) => p + 1))}
            className="s8ll-btn flex-1 h-12 rounded-2xl text-[15px]"
          >
            {last ? 'Get Started' : 'Next'}
            {!last && <ChevronRight className="ml-1 h-4 w-4" />}
          </Button>
        </div>
        {last && (
          <p className="text-center text-[11px] text-txt3 mt-3">
            By continuing you agree to our Terms & Privacy Policy
          </p>
        )}
      </div>
    </div>
  )
}
