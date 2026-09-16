'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Send, MoreVertical, BadgeCheck, Package } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'
import type { ChatSessionData, ChatMessageData } from '@/lib/types'

async function fetchSessions() {
  const res = await fetch('/api/chat')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function ChatScreen() {
  const { push } = useAppStore()
  const { data, isLoading } = useQuery({ queryKey: ['chats'], queryFn: fetchSessions })
  const sessions: ChatSessionData[] = data?.sessions ?? []

  return (
    <div className="pb-28">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-4 pt-[max(env(safe-area-inset-top),14px)] pb-3 flex items-center justify-between">
          <h1 className="text-xl font-black tracking-tight text-white">Messages</h1>
          <span className="text-[11px] text-txt2">{sessions.length} conversations</span>
        </div>
      </header>

      <div className="px-4 mt-2">
        {isLoading && Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="flex items-center gap-3 py-4">
            <Skeleton className="h-14 w-14 rounded-2xl bg-surface-light" />
            <div className="flex-1 space-y-2">
              <Skeleton className="h-3.5 w-1/3 bg-surface-light" />
              <Skeleton className="h-3 w-2/3 bg-surface-light" />
            </div>
          </div>
        ))}

        {sessions.map((s, i) => (
          <motion.button
            key={s.id}
            initial={{ opacity: 0, x: -14 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.06 }}
            onClick={() => push({ name: 'chatDetail', sessionId: s.id })}
            className="w-full flex items-center gap-3 py-3.5 border-b border-border/60 hover:bg-surface/40 rounded-xl px-2 -mx-2 transition-colors text-left"
          >
            <div className="relative shrink-0">
              { }
              <img src={s.avatar} alt={s.name} className="h-14 w-14 rounded-2xl object-cover border border-border" />
              {s.unread > 0 && (
                <span className="absolute -top-1 -right-1 h-5 w-5 bg-live rounded-full text-[10px] font-black text-white flex items-center justify-center">
                  {s.unread}
                </span>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 min-w-0">
                  <span className="font-bold text-white text-sm truncate">{s.name}</span>
                  {s.name === 'soledrop.co' && <BadgeCheck className="h-3.5 w-3.5 text-s8ll shrink-0" />}
                </div>
                <span className="text-[10px] text-txt3 shrink-0">{s.lastTime}</span>
              </div>
              <p className="text-[12px] text-txt2 truncate mt-0.5">{s.lastMessage}</p>
              {s.productTitle && (
                <span className="inline-flex items-center gap-1 mt-1 bg-surface-light text-txt2 text-[10px] px-2 py-0.5 rounded-md">
                  <Package className="h-3 w-3" /> {s.productTitle}
                </span>
              )}
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  )
}

export function ChatDetailScreen({ sessionId }: { sessionId: string }) {
  const { pop } = useAppStore()
  const qc = useQueryClient()
  const [text, setText] = useState('')
  const { data, isLoading } = useQuery({
    queryKey: ['chat', sessionId],
    queryFn: async () => {
      const res = await fetch(`/api/chat/${sessionId}`)
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
  })
  const session: ChatSessionData | undefined = data?.session
  const messages: ChatMessageData[] = data?.messages ?? []

  const send = useMutation({
    mutationFn: async (t: string) => {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sessionId, text: t }),
      })
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['chat', sessionId] })
      qc.invalidateQueries({ queryKey: ['chats'] })
    },
  })

  const submit = () => {
    const t = text.trim()
    if (!t || send.isPending) return
    setText('')
    send.mutate(t)
  }

  return (
    <div className="min-h-[100dvh] flex flex-col">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-3 pt-[max(env(safe-area-inset-top),12px)] pb-3 flex items-center gap-3">
          <button onClick={pop} aria-label="Back" className="h-10 w-10 rounded-full bg-surface border border-border flex items-center justify-center text-txt2 hover:text-white transition-colors">
            <ArrowLeft className="h-5 w-5" />
          </button>
          { }
          <img src={session?.avatar} alt={session?.name ?? 'chat'} className="h-10 w-10 rounded-full object-cover" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-white truncate">{session?.name ?? '…'}</p>
            <p className="text-[10px] text-success">online • typically replies in 2m</p>
          </div>
          <button aria-label="More" className="h-10 w-10 rounded-full flex items-center justify-center text-txt3">
            <MoreVertical className="h-5 w-5" />
          </button>
        </div>
      </header>

      {session?.productTitle && (
        <div className="mx-4 mt-3 p-3 s8ll-card rounded-2xl flex items-center gap-3">
          {session.productImage && (
             
            <img src={session.productImage} alt={session.productTitle} className="h-12 w-12 rounded-xl object-cover" />
          )}
          <div className="flex-1 min-w-0">
            <p className="text-[12px] font-bold text-white truncate">{session.productTitle}</p>
            <p className="text-[10px] text-txt3">Discussing this item</p>
          </div>
        </div>
      )}

      <div className="flex-1 px-4 py-4 space-y-3 s8ll-scroll overflow-y-auto max-h-[calc(100dvh-230px)]">
        {isLoading && <Skeleton className="h-8 w-2/3 bg-surface-light rounded-xl" />}
        <AnimatePresence initial={false}>
          {messages.map((m) => (
            <motion.div
              key={m.id}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              className={cn('flex', m.isMe ? 'justify-end' : 'justify-start')}
            >
              <div
                className={cn(
                  'max-w-[78%] px-3.5 py-2.5 text-[13px] leading-relaxed',
                  m.isMe
                    ? 's8ll-btn rounded-2xl rounded-br-md text-black'
                    : 'bg-surface border border-border text-white rounded-2xl rounded-bl-md',
                )}
              >
                {m.text}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
        {send.isPending && (
          <div className="flex justify-end">
            <div className="bg-surface-light border border-border rounded-2xl px-4 py-3 flex gap-1">
              <span className="tdot h-1.5 w-1.5 rounded-full bg-txt3 inline-block" />
              <span className="tdot h-1.5 w-1.5 rounded-full bg-txt3 inline-block" />
              <span className="tdot h-1.5 w-1.5 rounded-full bg-txt3 inline-block" />
            </div>
          </div>
        )}
      </div>

      <div className="sticky bottom-0 bg-background/95 backdrop-blur-xl border-t border-border px-3 py-3 pb-[max(env(safe-area-inset-bottom),12px)]">
        <div className="flex items-center gap-2">
          <Input
            placeholder="Message…"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
            className="flex-1 h-11 bg-surface border-border rounded-full"
          />
          <Button onClick={submit} disabled={!text.trim() || send.isPending} aria-label="Send" className="s8ll-btn h-11 w-11 rounded-full p-0">
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}
