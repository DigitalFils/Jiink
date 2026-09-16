'use client'

import { useEffect, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { io, type Socket } from 'socket.io-client'
import { Users2, Clock, Crown, Flame, Check, Share2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { ScreenHeader } from './screen-header'
import { pad2, useCountdown } from './hooks'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import type { GroupBuyData } from '@/lib/types'

// Map db ids to short keys the live service broadcasts on
const GB_KEY = (g: GroupBuyData) => {
  const t = g.title.toLowerCase()
  if (t.includes('earbud')) return 'earbuds'
  if (t.includes('watch')) return 'watch'
  if (t.includes('force') || t.includes('nike')) return 'af1'
  if (t.includes('dinner')) return 'dinner'
  if (t.includes('keyboard')) return 'keyboard'
  return null
}

async function fetchGroupBuys() {
  const res = await fetch('/api/groupbuys')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

export function GroupBuyScreen() {
  const { toast } = useToast()
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['groupbuys'], queryFn: fetchGroupBuys })
  const [liveCounts, setLiveCounts] = useState<Record<string, number>>({})

  // realtime participant updates via socket.io mini-service
  useEffect(() => {
    const socket: Socket = io('/?XTransformPort=3030', {
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 3,
      timeout: 8000,
    })
    socket.on('groupbuy:update', (u: { id: string; participants: number; username: string }) => {
      setLiveCounts((c) => ({ ...c, [u.id]: u.participants }))
    })
    return () => { socket.disconnect() }
  }, [])

  const join = useMutation({
    mutationFn: async (id: string) => {
      const res = await fetch(`/api/groupbuys/${id}`, { method: 'POST' })
      if (!res.ok) throw new Error('Failed')
      return res.json()
    },
    onSuccess: (d) => {
      qc.invalidateQueries({ queryKey: ['groupbuys'] })
      toast({
        title: d.joined ? 'You joined the group! 🎉' : 'You left the group',
        description: d.joined
          ? 'You\'ll get the group price once the team fills up. Invite friends to speed it up!'
          : undefined,
      })
    },
  })

  const groupBuys: GroupBuyData[] = data?.groupBuys ?? []

  return (
    <div className="min-h-[100dvh] pb-10">
      <ScreenHeader title="Group Buy" subtitle="Team up • Unlock bulk prices" />

      <div className="px-4 mt-4 space-y-4">
        {/* hero */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-3xl p-4 relative overflow-hidden keep-dark"
          style={{ background: 'linear-gradient(135deg, #2a1e0a 0%, #141418 65%)' }}
        >
          <div className="absolute -right-8 -top-8 h-28 w-28 rounded-full bg-warn/20 blur-3xl" />
          <div className="flex items-center gap-3">
            <div className="h-12 w-12 rounded-2xl bg-warn/15 border border-warn/30 flex items-center justify-center shrink-0">
              <Users2 className="h-6 w-6 text-warn" />
            </div>
            <div>
              <h2 className="text-[15px] font-black text-white">Save up to 60% together</h2>
              <p className="text-[11px] text-txt2 mt-0.5">Live participant updates via realtime feed</p>
            </div>
          </div>
          <div className="flex items-center gap-2 mt-3">
            <span className="live-dot h-2 w-2 rounded-full bg-success inline-block" />
            <span className="text-[10px] text-success font-bold">REALTIME</span>
            <span className="text-[10px] text-txt3">• participants update as people join</span>
          </div>
        </motion.div>

        {isLoading && Array.from({ length: 2 }).map((_, i) => (
          <div key={i} className="s8ll-card rounded-3xl p-4">
            <div className="flex gap-3">
              <Skeleton className="h-20 w-20 rounded-2xl bg-surface-light" />
              <div className="flex-1 space-y-2 py-1">
                <Skeleton className="h-4 w-3/4 bg-surface-light" />
                <Skeleton className="h-3 w-1/2 bg-surface-light" />
              </div>
            </div>
            <Skeleton className="h-2 w-full bg-surface-light rounded-full mt-4" />
          </div>
        ))}

        {groupBuys.map((g, i) => (
          <GroupBuyCard
            key={g.id}
            g={g}
            index={i}
            liveCount={liveCounts[GB_KEY(g) ?? '']}
            onJoin={() => join.mutate(g.id)}
            onShare={() => toast({ title: 'Invite link copied 🔗', description: 'Share with friends to fill the group faster.' })}
            joining={join.isPending && join.variables === g.id}
          />
        ))}
      </div>
    </div>
  )
}

function GroupBuyCard({
  g, index, liveCount, onJoin, onShare, joining,
}: {
  g: GroupBuyData
  index: number
  liveCount?: number
  onJoin: () => void
  onShare: () => void
  joining?: boolean
}) {
  const participants = liveCount ?? g.participants
  const pct = Math.min(100, Math.round((participants / g.target) * 100))
  const save = Math.round((1 - g.price / g.originalPrice) * 100)
  const cd = useCountdown(new Date(g.endsAt).getTime())
  const needs = Math.max(0, g.target - participants)

  return (
    <motion.article
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.07 }}
      className={cn('s8ll-card rounded-3xl overflow-hidden', g.joined && 'border-s8ll/50')}
    >
      <div className="p-4 flex gap-3.5">
        <div className="relative shrink-0">
          { }
          <img src={g.image} alt={g.title} className="h-[84px] w-[84px] rounded-2xl object-cover" />
          <span className="absolute -top-1.5 -left-1.5 bg-live text-white text-[9px] font-black px-1.5 py-0.5 rounded-md">
            -{save}%
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="text-[14px] font-bold text-white leading-snug line-clamp-2">{g.title}</h3>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-[17px] font-black text-s8ll">£{g.price}</span>
            <span className="text-[11px] text-txt3 line-through">£{g.originalPrice}</span>
          </div>
          <div className="flex items-center gap-1.5 mt-1.5 text-[10px] text-warn font-bold">
            <Clock className="h-3 w-3" />
            {pad2(cd.hours)}:{pad2(cd.minutes)}:{pad2(cd.seconds)} left
          </div>
        </div>
      </div>

      <div className="px-4 pb-4 space-y-3">
        {/* progress */}
        <div>
          <div className="flex items-center justify-between text-[10px] mb-1.5">
            <span className="text-txt2">
              <span className="text-white font-black">{participants}</span> / {g.target} joined
              {liveCount != null && <span className="text-success ml-1">• live</span>}
            </span>
            {needs > 0 ? (
              <span className="text-warn font-bold">{needs} more needed</span>
            ) : (
              <span className="text-success font-bold flex items-center gap-1">
                <Flame className="h-3 w-3" /> DEAL UNLOCKED
              </span>
            )}
          </div>
          <div className="h-2.5 rounded-full bg-surface-light overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${pct}%` }}
              transition={{ duration: 0.8, ease: 'easeOut' }}
              className={cn('h-full rounded-full', pct >= 100 ? 'bg-success' : 's8ll-btn')}
            />
          </div>
        </div>

        {/* participants avatars + leader */}
        <div className="flex items-center justify-between">
          <div className="flex items-center -space-x-2.5">
            <div className="h-8 w-8 rounded-full border-2 border-gold bg-gold/20 flex items-center justify-center z-10">
              <Crown className="h-3.5 w-3.5 text-gold" />
            </div>
            {[1, 2, 3, 4].slice(0, Math.min(4, participants - 1)).map((n) => (
              <div key={n} className="h-8 w-8 rounded-full bg-surface-light border-2 border-card flex items-center justify-center">
                { }
                <img
                  src={`https://i.pravatar.cc/80?img=${(n * 11 + 5) % 70}`}
                  alt={`participant ${n}`}
                  className="h-full w-full rounded-full object-cover"
                />
              </div>
            ))}
            {participants > 5 && (
              <div className="h-8 w-8 rounded-full bg-surface-light border-2 border-card flex items-center justify-center text-[9px] font-black text-txt2">
                +{participants - 5}
              </div>
            )}
          </div>
          <div className="flex items-center gap-1.5 text-[10px] text-txt2">
            <span className="truncate max-w-[90px]">leader: {g.leader}</span>
          </div>
        </div>

        <div className="flex gap-2.5">
          <Button
            onClick={onJoin}
            disabled={joining}
            variant={g.joined ? 'outline' : 'default'}
            className={cn(
              'flex-1 h-11 rounded-2xl text-[14px]',
              g.joined ? 'border-s8ll/50 text-s8ll bg-transparent hover:bg-s8ll/10' : 's8ll-btn',
            )}
          >
            {joining ? '…' : g.joined ? (
              <>
                <Check className="h-4 w-4 mr-1.5" /> Joined — invite friends
              </>
            ) : (
              `Join group • £${g.price}`
            )}
          </Button>
          <Button
            onClick={onShare}
            variant="outline"
            aria-label="Share"
            className="h-11 w-11 rounded-2xl p-0 border-border bg-surface hover:bg-surface-light"
          >
            <Share2 className="h-4 w-4 text-txt2" />
          </Button>
        </div>
      </div>
    </motion.article>
  )
}
