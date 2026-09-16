'use client'

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import { LogoSplash } from './logo'
import { useAppStore } from '@/store/useAppStore'

export function SplashScreen() {
  const { boot } = useAppStore()

  useEffect(() => {
    const t = setTimeout(() => boot(), 2400)
    return () => clearTimeout(t)
  }, [boot])

  return (
    <div className="min-h-[100dvh] bg-background keep-dark flex flex-col items-center justify-center relative overflow-hidden">
      {/* ambient glow */}
      <div className="absolute -top-24 -left-24 h-72 w-72 rounded-full bg-s8ll/10 blur-[90px]" />
      <div className="absolute -bottom-24 -right-24 h-72 w-72 rounded-full bg-s8ll/5 blur-[90px]" />

      <LogoSplash />

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: [0, 1, 1, 0] }}
        transition={{ duration: 2.4, times: [0, 0.3, 0.8, 1] }}
        className="absolute bottom-16 text-[11px] text-txt3 tracking-[0.3em] uppercase"
      >
        Loading the future of shopping
      </motion.div>

      <motion.div
        initial={{ width: 0 }}
        animate={{ width: '60%' }}
        transition={{ duration: 2.1, ease: 'easeInOut' }}
        className="absolute bottom-10 h-[2px] bg-gradient-to-r from-s8ll/0 via-s8ll to-s8ll/0 rounded-full"
      />
    </div>
  )
}
