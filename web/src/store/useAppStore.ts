'use client'

import { create } from 'zustand'

export type Tab = 'home' | 'drop' | 'sell' | 'chat' | 'profile'

export type OverlayRoute =
  | { name: 'search' }
  | { name: 'product'; id: string }
  | { name: 'map' }
  | { name: 'auth' }
  | { name: 'live' }
  | { name: 'ar' }
  | { name: 'wallet' }
  | { name: 'ai' }
  | { name: 'wishlist' }
  | { name: 'groupbuy' }
  | { name: 'flashsale' }
  | { name: 'chatDetail'; sessionId: string }

interface AppState {
  booted: boolean
  onboarded: boolean
  tab: Tab
  overlay: OverlayRoute | null
  boot: () => void
  finishOnboarding: () => void
  setTab: (t: Tab) => void
  push: (r: OverlayRoute) => void
  pop: () => void
}

export const useAppStore = create<AppState>((set) => ({
  booted: false,
  onboarded: false,
  tab: 'home',
  overlay: null,
  boot: () => set({ booted: true }),
  finishOnboarding: () => set({ onboarded: true }),
  setTab: (tab) => set({ tab, overlay: null }),
  push: (overlay) => set({ overlay }),
  pop: () => set({ overlay: null }),
}))

export const useNav = () => {
  const { push, pop, setTab } = useAppStore()
  return { push, pop, setTab }
}
