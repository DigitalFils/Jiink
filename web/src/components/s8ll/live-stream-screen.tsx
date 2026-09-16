'use client'

import { useEffect, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { io, type Socket } from 'socket.io-client'
import {
  Eye, Heart, Send, ShoppingBag, Gift, Users2, BadgeCheck, Volume2, VolumeX, Maximize2,
} from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import type { LiveStreamData, Product } from '@/lib/types'

type LiveMessage = {
  id: string
  username: string
  content: string
  type: 'user' | 'system' | 'pinned' | 'gift'
  timestamp: number
}

async function fetchLive() {
  const res = await fetch('/api/home')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function LiveStreamScreen() {
  const { push, pop } = useAppStore()
  const { toast } = useToast()
  const { data } = useQuery({ queryKey: ['home'], queryFn: fetchLive })
  const stream: LiveStreamData | undefined = data?.liveStreams?.[0]
  const featured: Product[] = data?.liveDrops?.slice(0, 6) ?? []

  const [messages, setMessages] = useState<LiveMessage[]>([
    { id: 'init', username: 'System', content: 'Connecting to live feed…', type: 'system', timestamp: Date.now() },
  ])
  const [text, setText] = useState('')
  const [viewers, setViewers] = useState(2418)
  const [likes, setLikes] = useState(12400)
  const [connected, setConnected] = useState(false)
  const [muted, setMuted] = useState(true)
  const chatRef = useRef<HTMLDivElement>(null)
  const socketRef = useRef<Socket | null>(null)

  useEffect(() => {
    const socket: Socket = io('/?XTransformPort=3030', {
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 4,
      reconnectionDelay: 1000,
      timeout: 8000,
    })
    socketRef.current = socket

    socket.on('connect', () => {
      setConnected(true)
      socket.emit('live:join', { username: 'you' })
    })
    socket.on('disconnect', () => setConnected(false))
    socket.on('live:chat', (m: LiveMessage) => {
      setMessages((prev) => [...prev.slice(-60), m])
    })
    socket.on('live:stats', (s: { viewers: number; likes: number }) => {
      setViewers(s.viewers)
      setLikes(s.likes)
    })

    return () => { socket.disconnect() }
  }, [])

  useEffect(() => {
    chatRef.current?.scrollTo({ top: chatRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages])

  const send = () => {
    const t = text.trim()
    if (!t || !socketRef.current?.connected) return
    socketRef.current.emit('live:message', { content: t, username: 'you' })
    setText('')
  }

  const like = () => {
    socketRef.current?.emit('live:like')
    setLikes((l) => l + 1)
  }

  if (!stream) {
    return (
      <div className="min-h-[100dvh] flex items-center justify-center">
        <p className="text-txt3 text-sm">Loading live…</p>
      </div>
    )
  }

  return (
    <div className="min-h-[100dvh] flex flex-col relative keep-dark">
      <div className="flex-1 flex flex-col max-h-[100dvh]">
        {/* video area */}
        <div className="relative h-[340px] shrink-0">
          { }
          <img src={stream.cover} alt={stream.title} className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-b from-black/50 via-transparent to-black/85" />

          {/* top bar */}
          <div className="absolute top-[max(env(safe-area-inset-top),12px)] inset-x-3 flex items-center gap-2">
            <button
              onClick={pop}
              className="h-9 w-9 rounded-full bg-black/50 backdrop-blur flex items-center justify-center text-white"
              aria-label="Close live stream"
            >
              <svg viewBox="0 0 24 24" className="h-4.5 w-4.5 h-[18px] w-[18px]" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
                <path d="M18 6L6 18M6 6l12 12" />
              </svg>
            </button>
            <div className="flex items-center gap-2 bg-black/50 backdrop-blur rounded-full pl-1 pr-2.5 py-1 flex-1 min-w-0">
              { }
              <img src={stream.hostAvatar} alt={stream.host} className="h-7 w-7 rounded-full object-cover border border-s8ll" />
              <span className="text-[12px] font-bold text-white truncate">@{stream.host}</span>
              <BadgeCheck className="h-3.5 w-3.5 text-s8ll shrink-0" />
              <button className="ml-auto s8ll-btn text-[10px] font-black px-2.5 py-1 rounded-full shrink-0">
                Follow
              </button>
            </div>
          </div>

          {/* live badges */}
          <div className="absolute top-[calc(max(env(safe-area-inset-top),12px)+44px)] left-3 flex flex-col gap-1.5 items-start">
            <span className="bg-live text-white text-[10px] font-black px-2 py-0.5 rounded-md flex items-center gap-1.5 tracking-wide">
              <span className="live-dot h-1.5 w-1.5 rounded-full bg-white inline-block" /> LIVE
            </span>
            <span className="bg-black/50 backdrop-blur text-white text-[10px] font-bold px-2 py-0.5 rounded-md flex items-center gap-1">
              <Eye className="h-3 w-3" /> {viewers.toLocaleString()}
            </span>
            <span className={cn(
              'text-[9px] font-black px-2 py-0.5 rounded-full',
              connected ? 'bg-success/20 text-success' : 'bg-black/50 text-txt2',
            )}>
              {connected ? '● REALTIME' : 'connecting…'}
            </span>
          </div>

          {/* right controls */}
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex flex-col gap-3">
            <button
              onClick={() => setMuted((m) => !m)}
              aria-label={muted ? 'Unmute' : 'Mute'}
              className="h-10 w-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center text-white"
            >
              {muted ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
            </button>
            <button
              onClick={() => toast({ title: 'Fullscreen mode', description: 'Best viewed in the mobile app.' })}
              aria-label="Fullscreen"
              className="h-10 w-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center text-white"
            >
              <Maximize2 className="h-4 w-4" />
            </button>
            <motion.button
              whileTap={{ scale: 1.3 }}
              onClick={like}
              aria-label="Like"
              className="h-11 w-11 rounded-full bg-live/90 flex items-center justify-center text-white relative"
            >
              <Heart className="h-5 w-5 fill-white" />
              <span className="absolute -bottom-5 text-[9px] font-black text-white tabular-nums">
                {(likes / 1000).toFixed(1)}k
              </span>
            </motion.button>
          </div>

          {/* title + pinned product */}
          <div className="absolute bottom-3 inset-x-3">
            <div className="s8ll-card rounded-2xl p-2.5 flex items-center gap-2.5 pop-in">
              { }
              <img src={featured[0]?.image} alt={featured[0]?.title ?? 'featured'} className="h-11 w-11 rounded-xl object-cover shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-[11px] font-bold text-white truncate">{featured[0]?.title ?? 'Featured item'}</p>
                <p className="text-[12px] font-black text-s8ll">£{featured[0]?.price ?? 24} <span className="text-[9px] text-txt3 line-through font-medium">£{featured[0]?.originalPrice ?? 42}</span></p>
              </div>
              <Button
                onClick={() => featured[0] && push({ name: 'product', id: featured[0].id })}
                className="s8ll-btn h-9 px-4 rounded-xl text-[12px] shrink-0"
              >
                <ShoppingBag className="h-3.5 w-3.5 mr-1" /> Buy
              </Button>
            </div>
          </div>
        </div>

        {/* chat area */}
        <div className="flex-1 flex flex-col min-h-0 bg-background">
          <div className="px-4 py-2.5 border-b border-border flex items-center justify-between">
            <h3 className="text-[12px] font-bold text-white flex items-center gap-1.5">
              <Users2 className="h-3.5 w-3.5 text-s8ll" /> Live chat
              <span className="text-[10px] text-txt3 font-medium">({viewers.toLocaleString()} watching)</span>
            </h3>
            <Gift className="h-4 w-4 text-gold" />
          </div>

          <div ref={chatRef} className="flex-1 px-4 py-3 overflow-y-auto s8ll-scroll max-h-[calc(100dvh-540px)] space-y-1.5">
            <AnimatePresence initial={false}>
              {messages.map((m) => (
                <motion.div
                  key={m.id}
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  className={cn(
                    'text-[12px] leading-relaxed',
                    m.type === 'system' && 'text-txt3 italic',
                    m.type === 'pinned' && 'text-s8ll font-semibold',
                    m.type === 'gift' && 'text-gold',
                  )}
                >
                  {m.type === 'user' || m.type === 'gift' ? (
                    <>
                      <span className={cn('font-bold', m.username === 'you' ? 'text-s8ll' : 'text-white')}>
                        {m.username}
                      </span>
                      {m.type === 'gift' ? (
                        <span> {m.content} 🎁</span>
                      ) : (
                        <span className="text-txt2">: {m.content}</span>
                      )}
                    </>
                  ) : (
                    <span>{m.type === 'pinned' ? `📌 ${m.content}` : m.content}</span>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>
          </div>

          {/* featured products carousel */}
          <div className="py-2.5 border-t border-border">
            <div className="flex gap-2.5 overflow-x-auto no-scrollbar px-4">
              {featured.map((p) => (
                <button
                  key={p.id}
                  onClick={() => push({ name: 'product', id: p.id })}
                  className="shrink-0 w-[96px] s8ll-card rounded-xl overflow-hidden text-left"
                >
                  { }
                  <img src={p.image} alt={p.title} className="h-[64px] w-full object-cover" />
                  <div className="p-1.5">
                    <p className="text-[9px] font-semibold text-white truncate">{p.title}</p>
                    <p className="text-[11px] font-black text-s8ll">£{p.price}</p>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* chat input */}
          <div className="px-3 py-3 pb-[max(env(safe-area-inset-bottom),12px)] border-t border-border bg-background/95 backdrop-blur-xl">
            <div className="flex items-center gap-2">
              <Input
                placeholder="Say something nice…"
                value={text}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && send()}
                className="flex-1 h-10 bg-surface border-border rounded-full text-[13px]"
              />
              <Button
                onClick={() => socketRef.current?.emit('live:message', { content: '❤️', username: 'you' })}
                variant="outline"
                aria-label="Send heart"
                className="h-10 w-10 rounded-full p-0 border-border bg-surface"
              >
                <Heart className="h-4 w-4 text-live" />
              </Button>
              <Button onClick={send} disabled={!text.trim()} aria-label="Send" className="s8ll-btn h-10 w-10 rounded-full p-0">
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
