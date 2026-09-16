'use client'

import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { Camera, Sparkles, CheckCircle2, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useToast } from '@/hooks/use-toast'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'

const CATEGORIES = ['Electronics', 'Fashion', 'Sneakers', 'Home & Garden', 'Collectibles', 'Sports']
const CONDITIONS = ['New', 'Like New', 'Excellent', 'Great', 'Good', 'Sealed']
const LOCATIONS = ['Manchester', 'Manchester • Northern Quarter', 'Manchester • Piccadilly', 'Manchester • Ancoats', 'London', 'Online']

export function SellScreen() {
  const { setTab } = useAppStore()
  const { toast } = useToast()
  const qc = useQueryClient()
  const [form, setForm] = useState({
    title: '',
    price: '',
    category: 'Electronics',
    condition: 'New',
    location: 'Manchester',
    description: '',
    image: '',
  })
  const [done, setDone] = useState(false)

  const mutation = useMutation({
    mutationFn: async () => {
      const res = await fetch('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, price: Number(form.price) }),
      })
      if (!res.ok) {
        const e = await res.json().catch(() => ({}))
        throw new Error(e.error || 'Failed to list item')
      }
      return res.json()
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['home'] })
      qc.invalidateQueries({ queryKey: ['products'] })
      setDone(true)
      toast({ title: 'Listing published! 🎉', description: 'Your item is now live on the marketplace.' })
    },
    onError: (e: Error) => toast({ title: 'Could not list item', description: e.message, variant: 'destructive' }),
  })

  if (done) {
    return (
      <div className="min-h-[100dvh] flex flex-col items-center justify-center px-8 text-center">
        <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: 'spring', stiffness: 260, damping: 16 }}>
          <div className="h-20 w-20 s8ll-btn rounded-full flex items-center justify-center mx-auto">
            <CheckCircle2 className="h-10 w-10 text-black" />
          </div>
        </motion.div>
        <h2 className="text-2xl font-black text-white mt-6">You&apos;re selling!</h2>
        <p className="text-sm text-txt2 mt-2">Your listing is live. Buyers can now discover it in search, feed and trending.</p>
        <Button className="s8ll-btn h-12 rounded-2xl mt-8 px-8" onClick={() => setTab('home')}>
          Back to Home
        </Button>
      </div>
    )
  }

  return (
    <div className="pb-28">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-4 pt-[max(env(safe-area-inset-top),14px)] pb-3 flex items-center gap-2">
          <h1 className="text-xl font-black tracking-tight text-white">Sell an item</h1>
          <span className="flex items-center gap-1 bg-s8ll/10 border border-s8ll/25 text-s8ll text-[9px] font-black px-2 py-0.5 rounded-full">
            <Sparkles className="h-3 w-3" /> 0% FEE
          </span>
        </div>
      </header>

      <div className="px-4 mt-4 space-y-5">
        {/* image */}
        <div>
          <Label className="text-txt2 text-xs mb-2 block">Cover image (URL)</Label>
          <div className="flex gap-3">
            <div className="h-24 w-24 rounded-2xl border-2 border-dashed border-border bg-surface flex items-center justify-center overflow-hidden shrink-0">
              {form.image ? (
                 
                <img src={form.image} alt="preview" className="h-full w-full object-cover" />
              ) : (
                <Camera className="h-7 w-7 text-txt3" />
              )}
            </div>
            <Input
              placeholder="https://… (leave empty for auto)"
              value={form.image}
              onChange={(e) => setForm({ ...form, image: e.target.value })}
              className="h-11 bg-surface border-border rounded-xl"
            />
          </div>
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Title *</Label>
          <Input
            placeholder="e.g. Vintage Film Camera"
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            className="h-11 bg-surface border-border rounded-xl"
          />
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Price £ *</Label>
          <Input
            type="number"
            min="1"
            placeholder="e.g. 120"
            value={form.price}
            onChange={(e) => setForm({ ...form, price: e.target.value })}
            className="h-11 bg-surface border-border rounded-xl"
          />
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Category</Label>
          <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
            {CATEGORIES.map((c) => (
              <button
                key={c}
                onClick={() => setForm({ ...form, category: c })}
                className={cn(
                  'shrink-0 px-3.5 py-2 rounded-full text-[12px] font-semibold border transition-all',
                  form.category === c
                    ? 'bg-s8ll text-black border-s8ll'
                    : 'bg-surface text-txt2 border-border hover:border-s8ll/30',
                )}
              >
                {c}
              </button>
            ))}
          </div>
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Condition</Label>
          <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
            {CONDITIONS.map((c) => (
              <button
                key={c}
                onClick={() => setForm({ ...form, condition: c })}
                className={cn(
                  'shrink-0 px-3.5 py-2 rounded-full text-[12px] font-semibold border transition-all',
                  form.condition === c
                    ? 'bg-s8ll text-black border-s8ll'
                    : 'bg-surface text-txt2 border-border hover:border-s8ll/30',
                )}
              >
                {c}
              </button>
            ))}
          </div>
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Location</Label>
          <div className="flex gap-2 flex-wrap">
            {LOCATIONS.map((l) => (
              <button
                key={l}
                onClick={() => setForm({ ...form, location: l })}
                className={cn(
                  'px-3.5 py-2 rounded-full text-[12px] font-semibold border transition-all',
                  form.location === l
                    ? 'bg-s8ll text-black border-s8ll'
                    : 'bg-surface text-txt2 border-border hover:border-s8ll/30',
                )}
              >
                {l}
              </button>
            ))}
          </div>
        </div>

        <div>
          <Label className="text-txt2 text-xs mb-2 block">Description</Label>
          <Textarea
            placeholder="Describe your item — condition, history, what's included…"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
            className="bg-surface border-border rounded-xl min-h-[110px] resize-none"
          />
        </div>

        <Button
          onClick={() => mutation.mutate()}
          disabled={!form.title || !form.price || mutation.isPending}
          className="s8ll-btn w-full h-13 py-4 rounded-2xl text-[15px] disabled:opacity-40"
        >
          {mutation.isPending ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" /> Publishing…
            </>
          ) : (
            'Publish Listing'
          )}
        </Button>

        <p className="text-center text-[11px] text-txt3 pb-2">
          Listings are screened by S8LL AI before going live. Verified items sell 3x faster.
        </p>
      </div>
    </div>
  )
}
