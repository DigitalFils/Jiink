'use client'

import { House, Radio, PlusCircle, MessageCircle, UserRound } from 'lucide-react'
import { motion } from 'framer-motion'
import { useAppStore, type Tab } from '@/store/useAppStore'
import { cn } from '@/lib/utils'

const TABS: { id: Tab; label: string; icon: typeof House }[] = [
  { id: 'home', label: 'Home', icon: House },
  { id: 'drop', label: 'Drop', icon: Radio },
  { id: 'sell', label: 'Sell', icon: PlusCircle },
  { id: 'chat', label: 'Chat', icon: MessageCircle },
  { id: 'profile', label: 'Profile', icon: UserRound },
]

export function BottomNav() {
  const { tab, setTab } = useAppStore()

  return (
    <nav className="fixed bottom-0 inset-x-0 z-40 mx-auto max-w-[480px]">
      <div className="bg-surface/95 backdrop-blur-xl border-t border-border">
        <div className="grid grid-cols-5 px-2 pb-[max(env(safe-area-inset-bottom),10px)] pt-2">
          {TABS.map(({ id, label, icon: Icon }) => {
            const active = tab === id
            return (
              <button
                key={id}
                onClick={() => setTab(id)}
                aria-label={label}
                aria-current={active ? 'page' : undefined}
                className={cn(
                  'relative flex flex-col items-center gap-1 rounded-xl py-2 min-h-[48px] transition-colors',
                  active ? 'text-s8ll' : 'text-txt3 hover:text-txt2',
                )}
              >
                {active && (
                  <motion.span
                    layoutId="nav-pill"
                    className="absolute inset-x-2 inset-y-1 rounded-xl bg-s8ll/10 border border-s8ll/20"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                <Icon className="h-[22px] w-[22px] relative z-10" strokeWidth={active ? 2.4 : 2} />
                <span className="text-[10px] font-bold relative z-10">{label}</span>
              </button>
            )
          })}
        </div>
      </div>
    </nav>
  )
}
