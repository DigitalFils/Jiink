'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import {
  Plus, ArrowDownLeft, ArrowUpRight, ShieldCheck, CreditCard, Gift, Sparkles, Loader2,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger,
} from '@/components/ui/dialog'
import { ScreenHeader } from './screen-header'
import { useToast } from '@/hooks/use-toast'
import { api } from '@/lib/session'
import { cn } from '@/lib/utils'

const METHODS = [
  { label: 'Visa •• 4521', tint: 'bg-sky-500/15 text-sky-400 border-sky-500/30' },
  { label: 'WeChat Pay', tint: 'bg-success/15 text-success border-success/30' },
  { label: 'Yandex Money', tint: 'bg-warn/15 text-warn border-warn/30' },
  { label: 'Apple Pay', tint: 'bg-foreground/10 text-foreground border-foreground/25' },
]

const TYPE_META: Record<string, { icon: typeof Plus; tint: string; sign: string }> = {
  purchase: { icon: ArrowUpRight, tint: 'text-live', sign: '-' },
  sale: { icon: ArrowDownLeft, tint: 'text-success', sign: '+' },
  topup: { icon: Plus, tint: 'text-s8ll', sign: '+' },
  refund: { icon: ArrowDownLeft, tint: 'text-warn', sign: '+' },
  payout: { icon: ArrowDownLeft, tint: 'text-s8ll', sign: '+' },
  auth: { icon: ShieldCheck, tint: 'text-gold', sign: '-' },
}

async function fetchWallet() {
  return api<{ balance: number; points: number; transactions: any[] }>('/api/wallet')
}

export function WalletScreen() {
  const { toast } = useToast()
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['wallet'], queryFn: fetchWallet })
  const [amount, setAmount] = useState('50')
  const [open, setOpen] = useState(false)

  const topUp = useMutation({
    mutationFn: async () => {
      return api('/api/wallet', {
        method: 'POST',
        body: JSON.stringify({ title: 'Wallet Top-up', amount: Number(amount), type: 'topup', method: 'Visa •• 4521' }),
      })
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['wallet'] })
      setOpen(false)
      toast({ title: 'Top-up successful 💳', description: `£${amount} added to your balance.` })
    },
    // Show what the server actually said. It currently refuses top-ups with
    // a 501 and an explanation; swallowing that into "Top-up failed" told
    // the user nothing and read like a bug rather than a deliberate answer.
    onError: (e) =>
      toast({
        title: 'Top-up unavailable',
        description: e instanceof Error ? e.message : undefined,
        variant: 'destructive',
      }),
  })

  const transactions = data?.transactions ?? []
  const income = transactions.filter((t: any) => t.amount > 0).reduce((a: number, t: any) => a + t.amount, 0)
  const spend = Math.abs(transactions.filter((t: any) => t.amount < 0).reduce((a: number, t: any) => a + t.amount, 0))

  return (
    <div className="min-h-[100dvh] pb-10">
      <ScreenHeader title="Smart Wallet" subtitle="Payments, rewards & transactions" />

      <div className="px-4 mt-4 space-y-5">
        {/* balance card — dark gold gradient (stays dark in light theme) */}
        <motion.section
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative rounded-3xl p-5 overflow-hidden s8ll-glow keep-dark"
          style={{ background: 'linear-gradient(135deg, #1e2a0d 0%, #141418 60%)' }}
        >
          <div className="absolute -right-10 -top-10 h-32 w-32 rounded-full bg-s8ll/20 blur-3xl" />
          <div className="flex items-center justify-between mb-1">
            <span className="text-[11px] text-txt2 font-semibold uppercase tracking-widest">Available balance</span>
            <Sparkles className="h-4 w-4 text-s8ll" />
          </div>
          {isLoading ? (
            <Skeleton className="h-10 w-36 bg-black/30" />
          ) : (
            <p className="text-4xl font-black text-white tracking-tight">
              £{(data?.balance ?? 0).toLocaleString('en-GB', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </p>
          )}
          <div className="flex items-center gap-3 mt-4">
            <span className="bg-s8ll/15 border border-s8ll/30 text-s8ll text-[11px] font-bold px-2.5 py-1 rounded-full flex items-center gap-1">
              <Gift className="h-3 w-3" /> {(data?.points ?? 0).toLocaleString()} pts
            </span>
            <span className="text-[10px] text-txt3">1,000 pts = £10 off</span>
          </div>
          <div className="grid grid-cols-2 gap-2.5 mt-5">
            <Dialog open={open} onOpenChange={setOpen}>
              <DialogTrigger asChild>
                <Button className="s8ll-btn h-11 rounded-xl text-[13px]">
                  <Plus className="h-4 w-4 mr-1.5" /> Top up
                </Button>
              </DialogTrigger>
              <DialogContent className="bg-surface border-border rounded-3xl max-w-[340px]">
                <DialogHeader>
                  <DialogTitle className="text-white">Top up wallet</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 pt-2">
                  <div className="flex gap-2">
                    {[25, 50, 100, 250].map((v) => (
                      <button
                        key={v}
                        onClick={() => setAmount(String(v))}
                        className={cn(
                          'flex-1 py-2.5 rounded-xl text-[13px] font-bold border transition-all',
                          amount === String(v) ? 'bg-s8ll text-black border-s8ll' : 'bg-surface-light text-txt2 border-border',
                        )}
                      >
                        £{v}
                      </button>
                    ))}
                  </div>
                  <Input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    className="h-11 bg-surface-light border-border rounded-xl"
                  />
                  <Button
                    onClick={() => topUp.mutate()}
                    disabled={topUp.isPending || !Number(amount)}
                    className="s8ll-btn w-full h-11 rounded-xl"
                  >
                    {topUp.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : `Add £${amount || 0}`}
                  </Button>
                  <p className="text-[10px] text-txt3 text-center flex items-center justify-center gap-1">
                    <ShieldCheck className="h-3 w-3" /> Secured by S8LL Escrow
                  </p>
                </div>
              </DialogContent>
            </Dialog>
            <Button
              variant="outline"
              className="h-11 rounded-xl border-s8ll/40 text-s8ll text-[13px] hover:bg-s8ll/10"
              onClick={() => toast({ title: 'Send flow', description: 'P2P transfers coming in the next release.' })}
            >
              Send money
            </Button>
          </div>
        </motion.section>

        {/* payment methods */}
        <section>
          <h3 className="text-[13px] font-bold text-white mb-3">Payment methods</h3>
          <div className="grid grid-cols-2 gap-2.5">
            {METHODS.map((m) => (
              <button
                key={m.label}
                className={cn('rounded-2xl border p-3.5 flex items-center gap-2.5 text-left', m.tint)}
                onClick={() => toast({ title: `${m.label} connected ✓` })}
              >
                <CreditCard className="h-4.5 w-4.5 h-[18px] w-[18px] shrink-0" />
                <span className="text-[12px] font-bold">{m.label}</span>
              </button>
            ))}
          </div>
        </section>

        {/* summary strip */}
        <section className="grid grid-cols-2 gap-2.5">
          <div className="s8ll-card rounded-2xl p-3.5">
            <p className="text-[10px] text-txt3 uppercase tracking-widest">Money in</p>
            <p className="text-lg font-black text-success mt-0.5">+£{income.toFixed(0)}</p>
          </div>
          <div className="s8ll-card rounded-2xl p-3.5">
            <p className="text-[10px] text-txt3 uppercase tracking-widest">Money out</p>
            <p className="text-lg font-black text-live mt-0.5">-£{spend.toFixed(0)}</p>
          </div>
        </section>

        {/* transactions */}
        <section>
          <h3 className="text-[13px] font-bold text-white mb-3">Transactions</h3>
          <div className="s8ll-card rounded-3xl overflow-hidden divide-y divide-border/60 max-h-96 overflow-y-auto s8ll-scroll">
            {isLoading && Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="flex items-center gap-3 p-4">
                <Skeleton className="h-10 w-10 rounded-xl bg-surface-light" />
                <div className="flex-1 space-y-1.5">
                  <Skeleton className="h-3 w-2/3 bg-surface-light" />
                  <Skeleton className="h-2.5 w-1/3 bg-surface-light" />
                </div>
              </div>
            ))}
            {transactions.map((t: any, i: number) => {
              const meta = TYPE_META[t.type] ?? TYPE_META.purchase
              return (
                <motion.div
                  key={t.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.03 }}
                  className="flex items-center gap-3.5 p-4"
                >
                  <div className={cn('h-10 w-10 rounded-xl bg-surface-light border border-border flex items-center justify-center shrink-0', meta.tint)}>
                    <meta.icon className="h-4.5 w-4.5 h-[18px] w-[18px]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-[13px] font-semibold text-white truncate">{t.title}</p>
                    <p className="text-[10px] text-txt3">
                      {t.method} • {new Date(t.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                    </p>
                  </div>
                  <span className={cn('text-[14px] font-black tabular-nums', t.amount > 0 ? 'text-success' : 'text-live')}>
                    {meta.sign}£{Math.abs(t.amount).toFixed(2)}
                  </span>
                </motion.div>
              )
            })}
          </div>
        </section>
      </div>
    </div>
  )
}
