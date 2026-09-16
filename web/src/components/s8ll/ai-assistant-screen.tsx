'use client'

import { useEffect, useRef, useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { Bot, Send, Sparkles, RotateCcw, BadgeCheck, Zap, LineChart, User } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { ScreenHeader } from './screen-header'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'
import type { Product } from '@/lib/types'

const QUICK_PROMPTS = [
  { icon: '🔥', label: 'Best sneakers under £100', text: 'What are the best sneaker deals under £100 right now?' },
  { icon: '👕', label: 'Winter jacket recommendations', text: 'Recommend me a winter jacket' },
  { icon: '💰', label: 'Find group buy deals', text: 'Which group buys are close to unlocking a deal?' },
  { icon: '✨', label: 'Vintage camera suggestions', text: 'Show me vintage cameras worth buying' },
  { icon: '🎁', label: 'Gift ideas for sneakerheads', text: 'Gift ideas for a sneakerhead friend' },
]

const CAPS = [
  { icon: Zap, label: 'Natural language search', desc: 'Find products by describing them' },
  { icon: LineChart, label: 'Market insights', desc: 'Price trends & deal analysis' },
  { icon: BadgeCheck, label: 'Authenticity check', desc: 'Verify legitimacy before buying' },
]

type Msg =
  | { id: string; role: 'user'; content: string; time: string }
  | { id: string; role: 'assistant'; content: string; time: string; products?: Product[] }

function now() {
  return new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
}
const genId = () => Math.random().toString(36).slice(2, 10)

export function AIAssistantScreen() {
  const { push } = useAppStore()
  const [messages, setMessages] = useState<Msg[]>([])
  const [text, setText] = useState('')
  const scrollRef = useRef<HTMLDivElement>(null)

  const ask = useMutation({
    mutationFn: async (history: { role: 'user' | 'assistant'; content: string }[]) => {
      const res = await fetch('/api/ai', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: history }),
      })
      if (!res.ok) {
        const e = await res.json().catch(() => ({}))
        throw new Error(e.error || 'AI unavailable')
      }
      return res.json()
    },
    onSuccess: (data) => {
      setMessages((m) => [
        ...m,
        { id: genId(), role: 'assistant', content: data.reply, time: now(), products: data.products ?? [] },
      ])
    },
    onError: (e: Error) => {
      setMessages((m) => [
        ...m,
        {
          id: genId(),
          role: 'assistant',
          content: `Sorry — I couldn't reach the AI engine (${e.message}). Please try again in a moment.`,
          time: now(),
        },
      ])
    },
  })

  const send = (t: string) => {
    const content = t.trim()
    if (!content || ask.isPending) return
    setText('')
    setMessages((m) => [...m, { id: genId(), role: 'user', content, time: now() }])
    const history = [...messages, { role: 'user' as const, content }].map((m) => ({
      role: m.role,
      content: m.content,
    }))
    ask.mutate(history)
  }

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, ask.isPending])

  return (
    <div className="min-h-[100dvh] flex flex-col">
      <ScreenHeader
        title="S8LL AI Assistant"
        subtitle="Online • Powered by GLM"
        right={
          messages.length > 0 ? (
            <button
              onClick={() => setMessages([])}
              aria-label="Reset chat"
              className="h-10 w-10 rounded-full bg-surface border border-border flex items-center justify-center text-txt2 hover:text-white"
            >
              <RotateCcw className="h-4 w-4" />
            </button>
          ) : undefined
        }
      />

      <div ref={scrollRef} className="flex-1 px-4 py-4 overflow-y-auto s8ll-scroll max-h-[calc(100dvh-140px)]">
        {messages.length === 0 ? (
          <div className="pt-6 space-y-6">
            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="flex flex-col items-center text-center">
              <div className="h-20 w-20 s8ll-btn rounded-3xl flex items-center justify-center mb-4 relative">
                <Bot className="h-10 w-10 text-black" />
                <motion.span
                  animate={{ scale: [1, 1.15, 1], opacity: [0.6, 1, 0.6] }}
                  transition={{ duration: 2, repeat: Infinity }}
                  className="absolute -inset-2 rounded-[26px] border-2 border-s8ll/30"
                />
              </div>
              <h2 className="text-xl font-black text-white">How can I help you today?</h2>
              <p className="text-[12px] text-txt2 mt-1.5 max-w-[280px] leading-relaxed">
                I can find deals, recommend products, compare prices and more — just ask.
              </p>
            </motion.div>

            <div className="grid grid-cols-3 gap-2.5">
              {CAPS.map((c, i) => (
                <motion.div
                  key={c.label}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.15 + i * 0.08 }}
                  className="s8ll-card rounded-2xl p-3 text-center"
                >
                  <c.icon className="h-5 w-5 text-s8ll mx-auto mb-1.5" />
                  <p className="text-[10.5px] font-bold text-white leading-tight">{c.label}</p>
                  <p className="text-[8.5px] text-txt3 mt-0.5 leading-tight">{c.desc}</p>
                </motion.div>
              ))}
            </div>

            <div>
              <p className="text-[11px] font-bold text-txt2 mb-2.5 uppercase tracking-widest">Try asking</p>
              <div className="space-y-2">
                {QUICK_PROMPTS.map((p, i) => (
                  <motion.button
                    key={p.label}
                    initial={{ opacity: 0, x: -12 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + i * 0.06 }}
                    onClick={() => send(p.text)}
                    className="w-full s8ll-card rounded-2xl px-4 py-3 flex items-center gap-3 text-left hover:border-s8ll/40 transition-colors"
                  >
                    <span className="text-lg">{p.icon}</span>
                    <span className="text-[13px] font-semibold text-white">{p.label}</span>
                    <Sparkles className="h-3.5 w-3.5 text-s8ll ml-auto shrink-0" />
                  </motion.button>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <AnimatePresence initial={false}>
              {messages.map((m) => (
                <motion.div
                  key={m.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={cn('flex gap-2.5', m.role === 'user' ? 'justify-end' : 'justify-start')}
                >
                  {m.role === 'assistant' && (
                    <div className="h-8 w-8 s8ll-btn rounded-xl flex items-center justify-center shrink-0 mt-1">
                      <Bot className="h-4.5 w-4.5 h-[18px] w-[18px] text-black" />
                    </div>
                  )}
                  <div className={cn('max-w-[82%]', m.role === 'user' ? 'items-end' : 'items-start')}>
                    <div
                      className={cn(
                        'px-4 py-3 text-[13px] leading-relaxed whitespace-pre-wrap',
                        m.role === 'user'
                          ? 's8ll-btn rounded-2xl rounded-br-md text-black'
                          : 'bg-surface border border-border text-white rounded-2xl rounded-bl-md',
                      )}
                    >
                      {m.content}
                    </div>

                    {/* product cards attached to AI answers */}
                    {m.role === 'assistant' && m.products && m.products.length > 0 && (
                      <div className="flex gap-2.5 overflow-x-auto no-scrollbar mt-2.5 pb-1">
                        {m.products.map((p) => (
                          <button
                            key={p.id}
                            onClick={() => push({ name: 'product', id: p.id })}
                            className="shrink-0 w-[140px] s8ll-card rounded-2xl overflow-hidden text-left hover:border-s8ll/40 transition-colors"
                          >
                            { }
                            <img src={p.image} alt={p.title} className="h-[92px] w-full object-cover" />
                            <div className="p-2.5">
                              <p className="text-[11px] font-semibold text-white line-clamp-2 leading-tight min-h-[28px]">{p.title}</p>
                              <p className="text-[13px] font-black text-s8ll mt-1">£{p.price}</p>
                            </div>
                          </button>
                        ))}
                      </div>
                    )}

                    <span className="block text-[9px] text-txt3 mt-1 px-1">{m.time}</span>
                  </div>
                  {m.role === 'user' && (
                    <div className="h-8 w-8 bg-surface-light border border-border rounded-xl flex items-center justify-center shrink-0 mt-1">
                      <User className="h-4 w-4 text-txt2" />
                    </div>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>

            {ask.isPending && (
              <div className="flex gap-2.5">
                <div className="h-8 w-8 s8ll-btn rounded-xl flex items-center justify-center shrink-0 mt-1">
                  <Bot className="h-[18px] w-[18px] text-black" />
                </div>
                <div className="bg-surface border border-border rounded-2xl rounded-bl-md px-4 py-3.5 flex gap-1.5 items-center">
                  <span className="tdot h-1.5 w-1.5 rounded-full bg-s8ll inline-block" />
                  <span className="tdot h-1.5 w-1.5 rounded-full bg-s8ll inline-block" />
                  <span className="tdot h-1.5 w-1.5 rounded-full bg-s8ll inline-block" />
                  <span className="text-[10px] text-txt3 ml-1.5">AI is thinking…</span>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="sticky bottom-0 bg-background/95 backdrop-blur-xl border-t border-border px-3 py-3 pb-[max(env(safe-area-inset-bottom),12px)]">
        <div className="flex items-center gap-2">
          <Input
            placeholder="Ask anything about shopping…"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && send(text)}
            disabled={ask.isPending}
            className="flex-1 h-11 bg-surface border-border rounded-full"
          />
          <Button
            onClick={() => send(text)}
            disabled={!text.trim() || ask.isPending}
            aria-label="Send"
            className="s8ll-btn h-11 w-11 rounded-full p-0"
          >
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}
