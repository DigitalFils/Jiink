'use client'

import { useSyncExternalStore } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useTheme } from 'next-themes'
import { Switch } from '@/components/ui/switch'
import {
  Wallet, Heart, Package, Store, Settings, HelpCircle, ShieldCheck, Star,
  ChevronRight, TrendingUp, Award, LogOut, Moon, Sun, Languages, Loader2,
} from 'lucide-react'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { useSession, useSignOut } from '@/lib/session'
import { AvatarImage } from './avatar-image'
import { cn } from '@/lib/utils'

const QUICK = [
  { label: 'Wallet', icon: Wallet, route: 'wallet' as const, tint: 'text-gold' },
  { label: 'Wishlist', icon: Heart, route: 'wishlist' as const, tint: 'text-live' },
  { label: 'Orders', icon: Package, route: 'flashsale' as const, tint: 'text-s8ll' },
  { label: 'Selling', icon: Store, route: 'groupbuy' as const, tint: 'text-warn' },
]

/** One level every 800 XP — the number the design's progress bar was drawn
 * around. Kept here rather than in the database so it can be retuned
 * without a migration. */
const XP_PER_LEVEL = 800
const LEVEL_NAMES = ['New Seller', 'Rising Seller', 'Established Seller', 'Trusted Seller', 'Power Seller']

const MENU = [
  { icon: ShieldCheck, label: 'Dewu Authentication', desc: 'Verify items, view certificates', route: 'auth' as const },
  { icon: Award, label: 'Seller Level Program', desc: 'How levels and perks work', route: 'groupbuy' as const },
  { icon: TrendingUp, label: 'Price Insights', desc: 'Market trends & AI forecasts', route: 'ai' as const },
  { icon: Languages, label: 'Language & Region', desc: 'English • United Kingdom', route: 'map' as const },
  { icon: Settings, label: 'Settings', desc: 'Notifications, privacy, payments', route: null },
  { icon: HelpCircle, label: 'Help & Support', desc: 'FAQ, contact, dispute center', route: null },
]

export function ProfileScreen() {
  const { push, setTab } = useAppStore()
  const { toast } = useToast()
  const { user } = useSession()
  const signOut = useSignOut()
  const { resolvedTheme, setTheme } = useTheme()
  // hydration-safe "is mounted" (server snapshot = false, client = true)
  const mounted = useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  )

  const isLight = mounted && resolvedTheme === 'light'

  // The shell only renders this screen behind the auth gate, so a null user
  // here means the session ended under us (logged out in another tab, or
  // the session expired). Render nothing rather than crash — the gate will
  // swap in the sign-in screen on the same tick.
  if (!user) return null

  const intoLevel = Math.min(user.xp % XP_PER_LEVEL, XP_PER_LEVEL)

  const onToggleTheme = (light: boolean) => {
    document.documentElement.classList.add('theme-anim')
    setTheme(light ? 'light' : 'dark')
    window.setTimeout(() => document.documentElement.classList.remove('theme-anim'), 500)
    toast({
      title: light ? 'Light mode on' : 'Dark mode on',
      description: light ? 'Easy on the eyes in daylight.' : 'The signature S8LL look.',
    })
  }

  const go = (r: string | null) => {
    if (r) {
      push({ name: r as any })
    } else {
      toast({ title: 'Coming soon', description: 'This section is on the roadmap.' })
    }
  }

  return (
    <div className="pb-28">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-4 pt-[max(env(safe-area-inset-top),14px)] pb-3 flex items-center justify-between">
          <h1 className="text-xl font-black tracking-tight text-white">Profile</h1>
          <button
            onClick={() => setTab('home')}
            className="text-[11px] font-semibold text-s8ll"
          >
            Done
          </button>
        </div>
      </header>

      <div className="px-4 mt-4 space-y-5">
        {/* User card + level progression */}
        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="s8ll-card rounded-3xl p-4 relative overflow-hidden"
        >
          <div className="absolute -right-8 -top-8 h-28 w-28 rounded-full bg-s8ll/10 blur-2xl" />
          <div className="flex items-center gap-4">
            <div className="relative shrink-0">
              <AvatarImage
                src={user.avatar}
                name={user.username}
                className="h-[72px] w-[72px] rounded-2xl border-2 border-s8ll/60 text-2xl"
              />
              <span className="absolute -bottom-1.5 -right-1.5 bg-s8ll text-black text-[9px] font-black px-1.5 py-0.5 rounded-md">
                L{user.level}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <h2 className="text-lg font-black text-white truncate">{user.username}</h2>
                {user.isVerified && <ShieldCheck className="h-4 w-4 text-s8ll shrink-0" />}
              </div>
              <p className="text-[11px] text-txt2 mt-0.5 truncate">
                {user.email ?? `@${user.username}`}
              </p>
              <div className="flex items-center gap-2 mt-1.5">
                {user.sales > 0 ? (
                  <span className="flex items-center gap-1 text-[11px] font-bold text-gold">
                    <Star className="h-3 w-3 fill-gold" /> {user.rating.toFixed(1)}
                  </span>
                ) : (
                  <span className="text-[11px] font-bold text-txt2">New seller</span>
                )}
                <span className="text-[11px] text-txt3">
                  • {user.sales} {user.sales === 1 ? 'sale' : 'sales'} • {user.followers.toLocaleString()} followers
                </span>
              </div>
            </div>
          </div>

          {/* XP progress — read off the account, not painted on */}
          <div className="mt-4">
            <div className="flex items-center justify-between text-[10px] mb-1.5">
              <span className="text-txt2 font-semibold">
                Level {user.level} — {LEVEL_NAMES[Math.min(user.level, LEVEL_NAMES.length) - 1]}
              </span>
              <span className="text-s8ll font-bold">{intoLevel} / {XP_PER_LEVEL} XP</span>
            </div>
            <div className="h-2 rounded-full bg-surface-light overflow-hidden">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${Math.round((intoLevel / XP_PER_LEVEL) * 100)}%` }}
                transition={{ duration: 1, delay: 0.3, ease: 'easeOut' }}
                className="h-full s8ll-btn rounded-full"
              />
            </div>
            <p className="text-[10px] text-txt3 mt-1.5">
              {XP_PER_LEVEL - intoLevel} XP to Level {user.level + 1}
            </p>
          </div>
        </motion.section>

        {/* Appearance — runtime theme toggle (v2.0, parity with Flutter) */}
        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="s8ll-card rounded-3xl p-4 flex items-center gap-3.5"
        >
          <div className="h-10 w-10 rounded-2xl bg-surface-light border border-border flex items-center justify-center shrink-0">
            <AnimatePresence mode="wait" initial={false}>
              <motion.span
                key={isLight ? 'sun' : 'moon'}
                initial={{ rotate: -90, opacity: 0, scale: 0.55 }}
                animate={{ rotate: 0, opacity: 1, scale: 1 }}
                exit={{ rotate: 90, opacity: 0, scale: 0.55 }}
                transition={{ duration: 0.25, ease: 'easeOut' }}
                className="flex"
              >
                {isLight
                  ? <Sun className="h-5 w-5 text-warn" strokeWidth={2.2} />
                  : <Moon className="h-5 w-5 text-s8ll" strokeWidth={2.2} />}
              </motion.span>
            </AnimatePresence>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[13.5px] font-semibold text-white">Appearance</p>
            <p className="text-[11px] text-txt3 mt-0.5">
              {isLight ? 'Light mode — daylight friendly' : 'Dark mode (signature)'}
            </p>
          </div>
          <Switch
            checked={isLight}
            onCheckedChange={onToggleTheme}
            aria-label="Toggle dark / light theme"
            className="data-[state=checked]:bg-foreground"
          />
        </motion.section>

        {/* Quick actions */}
        <section className="grid grid-cols-4 gap-3">
          {QUICK.map((q, i) => (
            <motion.button
              key={q.label}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => push({ name: q.route })}
              className="s8ll-card rounded-2xl py-3.5 flex flex-col items-center gap-1.5 hover:border-s8ll/30 transition-colors"
            >
              <q.icon className={cn('h-5 w-5', q.tint)} strokeWidth={2.2} />
              <span className="text-[10px] font-semibold text-txt2">{q.label}</span>
            </motion.button>
          ))}
        </section>

        {/* stats strip */}
        <section className="grid grid-cols-3 gap-3">
          {[
            [`£${user.balance.toLocaleString('en-GB', { maximumFractionDigits: 0 })}`, 'wallet balance'],
            [String(user.sales), user.sales === 1 ? 'completed sale' : 'completed sales'],
            [user.points.toLocaleString(), 'reward points'],
          ].map(([v, l]) => (
            <div key={l} className="s8ll-card rounded-2xl py-3 text-center">
              <p className="text-base font-black text-s8ll">{v}</p>
              <p className="text-[9px] text-txt3 mt-0.5 leading-tight">{l}</p>
            </div>
          ))}
        </section>

        {/* Menu */}
        <section className="s8ll-card rounded-3xl overflow-hidden divide-y divide-border">
          {MENU.map((m) => (
            <button
              key={m.label}
              onClick={() => go(m.route)}
              className="w-full flex items-center gap-3.5 p-4 hover:bg-surface/60 transition-colors text-left"
            >
              <div className="h-9 w-9 rounded-xl bg-surface-light border border-border flex items-center justify-center shrink-0">
                <m.icon className="h-4.5 w-4.5 h-[18px] w-[18px] text-txt2" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-[13.5px] font-semibold text-white">{m.label}</p>
                <p className="text-[11px] text-txt3 truncate">{m.desc}</p>
              </div>
              <ChevronRight className="h-4 w-4 text-txt3 shrink-0" />
            </button>
          ))}
        </section>

        <button
          onClick={() =>
            signOut.mutate(undefined, {
              onError: (e) =>
                toast({
                  title: 'Could not sign out',
                  description: e instanceof Error ? e.message : undefined,
                  variant: 'destructive',
                }),
            })
          }
          disabled={signOut.isPending}
          className="w-full s8ll-card rounded-2xl py-3.5 flex items-center justify-center gap-2 text-live text-sm font-bold hover:border-live/40 transition-colors disabled:opacity-60"
        >
          {signOut.isPending
            ? <Loader2 className="h-4 w-4 animate-spin" />
            : <LogOut className="h-4 w-4" />}
          Sign out
        </button>

        <p className="text-center text-[10px] text-txt3">S8LL v2.0 — Build 2026.09.07</p>
      </div>
    </div>
  )
}
