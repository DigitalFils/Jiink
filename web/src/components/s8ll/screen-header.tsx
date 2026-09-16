'use client'

import { useAppStore } from '@/store/useAppStore'

export function ScreenHeader({
  title,
  subtitle,
  showBack = true,
  right,
}: {
  title: string
  subtitle?: string
  showBack?: boolean
  right?: React.ReactNode
}) {
  const { pop } = useAppStore()
  return (
    <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
      <div className="flex items-center gap-3 px-4 h-16">
        {showBack && (
          <button
            onClick={pop}
            aria-label="Go back"
            className="h-10 w-10 shrink-0 rounded-full bg-surface border border-border flex items-center justify-center text-txt2 hover:text-white hover:border-s8ll/40 transition-colors"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 18l-6-6 6-6" />
            </svg>
          </button>
        )}
        <div className="flex-1 min-w-0">
          <h1 className="text-lg font-bold tracking-tight text-white truncate">{title}</h1>
          {subtitle && <p className="text-xs text-txt2 truncate">{subtitle}</p>}
        </div>
        {right}
      </div>
    </header>
  )
}
