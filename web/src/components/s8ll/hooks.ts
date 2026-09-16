'use client'

import { useEffect, useRef, useState } from 'react'

export function useCountdown(target: number) {
  const [remaining, setRemaining] = useState(() => Math.max(0, target - Date.now()))
  useEffect(() => {
    const t = setInterval(() => setRemaining(Math.max(0, target - Date.now())), 1000)
    return () => clearInterval(t)
  }, [target])
  const totalSec = Math.floor(remaining / 1000)
  return {
    hours: Math.floor(totalSec / 3600),
    minutes: Math.floor((totalSec % 3600) / 60),
    seconds: totalSec % 60,
    done: remaining <= 0,
  }
}

export function pad2(n: number) {
  return String(n).padStart(2, '0')
}

export function useTicker(intervalMs = 3000, active = true) {
  const [tick, setTick] = useState(0)
  useEffect(() => {
    if (!active) return
    const t = setInterval(() => setTick((x) => x + 1), intervalMs)
    return () => clearInterval(t)
  }, [intervalMs, active])
  return tick
}

export function timeAgoLabel(mins: number): string {
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const h = Math.floor(mins / 60)
  if (h < 24) return `${h}h ago`
  return `${Math.floor(h / 24)}d ago`
}
