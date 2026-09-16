'use client'

import { motion } from 'framer-motion'

export function Logo({ size = 'md', showTag = true }: { size?: 'sm' | 'md' | 'lg' | 'xl'; showTag?: boolean }) {
  const dims = {
    sm: { box: 'h-9 w-9', text: 'text-lg', tag: 'text-[9px]' },
    md: { box: 'h-11 w-11', text: 'text-2xl', tag: 'text-[10px]' },
    lg: { box: 'h-14 w-14', text: 'text-3xl', tag: 'text-[11px]' },
    xl: { box: 'h-24 w-24', text: 'text-6xl', tag: 'text-sm' },
  }[size]

  return (
    <div className="flex flex-col items-center gap-2 select-none">
      <div className="flex items-center gap-2.5">
        <div
          className={`${dims.box} s8ll-btn rounded-2xl flex items-center justify-center font-black tracking-tighter text-black`}
          style={{ borderRadius: size === 'xl' ? 28 : 16 }}
        >
          S8
        </div>
        <span className={`${dims.text} font-black tracking-tighter text-white`}>
          LL<span className="s8ll-gradient-text">.</span>
        </span>
      </div>
      {showTag && (
        <span className={`${dims.tag} uppercase tracking-[0.35em] text-txt2`}>
          Ultimate Marketplace
        </span>
      )}
    </div>
  )
}

export function LogoSplash() {
  return (
    <motion.div
      initial={{ scale: 0.6, opacity: 0, y: 30 }}
      animate={{ scale: 1, opacity: 1, y: 0 }}
      transition={{ type: 'spring', stiffness: 200, damping: 12, delay: 0.15 }}
      className="flex flex-col items-center"
    >
      <div className="relative">
        <motion.div
          animate={{ y: [0, -14, 0] }}
          transition={{ duration: 1.4, repeat: Infinity, ease: 'easeInOut' }}
        >
          <div className="h-28 w-28 s8ll-btn rounded-[32px] flex items-center justify-center font-black tracking-tighter text-black text-6xl s8ll-glow">
            S8
          </div>
        </motion.div>
        <motion.div
          animate={{ scale: [1, 1.18, 1], opacity: [0.7, 1, 0.7] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute -inset-3 rounded-[36px] border-2 border-s8ll/30"
        />
      </div>
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="mt-6 text-5xl font-black tracking-tighter text-white"
      >
        LL<span className="s8ll-gradient-text">.</span>
      </motion.div>
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="mt-2 text-[11px] uppercase tracking-[0.4em] text-txt2"
      >
        Avito × Dewu × PDD × XHS
      </motion.p>
    </motion.div>
  )
}
