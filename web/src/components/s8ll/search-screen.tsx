'use client'

import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { Search, TrendingUp, Clock, Sparkles, SlidersHorizontal, X, Bot } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { ProductCard } from './product-card'
import { useAppStore } from '@/store/useAppStore'
import { cn } from '@/lib/utils'
import type { Product } from '@/lib/types'

const CATEGORIES = ['All', 'Electronics', 'Fashion', 'Sneakers', 'Home & Garden', 'Collectibles']
const CONDITIONS = ['Any', 'New', 'Like New', 'Excellent', 'Great', 'Sealed']
const SORTS = [
  ['trending', 'Trending'],
  ['price-asc', 'Price ↑'],
  ['price-desc', 'Price ↓'],
  ['newest', 'Newest'],
] as const

const TRENDING = ['jordan 1', 'vintage camera', 'air force', 'noise cancelling', 'leather bag', 'north face']
const RECENT = ['polaroid', 'sneakers uk 9', 'terracotta pot']

type Filters = {
  category: string
  condition: string
  verifiedOnly: boolean
  maxPrice: string
  sort: string
}

export function SearchScreen() {
  const { pop } = useAppStore()
  const [query, setQuery] = useState('')
  const [showFilters, setShowFilters] = useState(false)
  const [searched, setSearched] = useState(false)
  const [recent, setRecent] = useState(RECENT)
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [filters, setFilters] = useState<Filters>({
    category: 'All',
    condition: 'Any',
    verifiedOnly: false,
    maxPrice: '',
    sort: 'trending',
  })

  const search = useMutation({
    mutationFn: async (q: string) => {
      const res = await fetch('/api/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: q,
          filters: {
            category: filters.category,
            condition: filters.condition,
            verifiedOnly: filters.verifiedOnly,
            maxPrice: filters.maxPrice ? Number(filters.maxPrice) : null,
            sort: filters.sort,
          },
        }),
      })
      if (!res.ok) throw new Error('Search failed')
      return res.json()
    },
    onSuccess: (data) => {
      setSuggestions(data.suggestions ?? [])
      setSearched(true)
    },
  })

  const products: Product[] = search.data?.products ?? []

  const runSearch = (q: string) => {
    if (q.trim()) {
      setRecent((r) => [q.trim(), ...r.filter((x) => x !== q.trim())].slice(0, 5))
    }
    setQuery(q)
    search.mutate(q)
  }

  return (
    <div className="min-h-[100dvh] flex flex-col">
      <header className="sticky top-0 z-30 bg-background/85 backdrop-blur-xl border-b border-border">
        <div className="px-4 pt-[max(env(safe-area-inset-top),12px)] pb-3 space-y-3">
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-txt3" />
              <Input
                autoFocus
                placeholder="Search anything… natural language works"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && runSearch(query)}
                className="h-11 pl-10 pr-10 bg-surface border-border rounded-full"
              />
              {query && (
                <button
                  onClick={() => { setQuery(''); setSearched(false) }}
                  aria-label="Clear"
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-txt3 hover:text-white"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
            <Button
              onClick={() => runSearch(query)}
              className="s8ll-btn h-11 px-5 rounded-full text-[13px]"
            >
              Go
            </Button>
            <button
              onClick={() => setShowFilters((v) => !v)}
              aria-label="Filters"
              className={cn(
                'h-11 w-11 rounded-full border flex items-center justify-center transition-colors',
                showFilters ? 'bg-s8ll text-black border-s8ll' : 'bg-surface border-border text-txt2',
              )}
            >
              <SlidersHorizontal className="h-4 w-4" />
            </button>
          </div>

          {/* category chips */}
          <div className="flex gap-2 overflow-x-auto no-scrollbar">
            {CATEGORIES.map((c) => (
              <button
                key={c}
                onClick={() => { setFilters({ ...filters, category: c }); setTimeout(() => search.mutate(query), 0) }}
                className={cn(
                  'shrink-0 px-3.5 py-1.5 rounded-full text-[12px] font-semibold border transition-all',
                  filters.category === c
                    ? 'bg-s8ll text-black border-s8ll'
                    : 'bg-surface text-txt2 border-border hover:border-s8ll/30',
                )}
              >
                {c}
              </button>
            ))}
          </div>

          <AnimatePresence>
            {showFilters && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 'auto', opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                className="overflow-hidden"
              >
                <div className="s8ll-card rounded-2xl p-3.5 space-y-3.5">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-[11px] font-bold text-txt2 mb-1.5">Condition</p>
                      <div className="flex gap-1.5 flex-wrap">
                        {CONDITIONS.map((c) => (
                          <button
                            key={c}
                            onClick={() => setFilters({ ...filters, condition: c })}
                            className={cn(
                              'px-2.5 py-1 rounded-lg text-[11px] font-semibold border',
                              filters.condition === c ? 'bg-s8ll/15 text-s8ll border-s8ll/40' : 'bg-surface text-txt2 border-border',
                            )}
                          >
                            {c}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 flex-wrap">
                    <div className="flex-1 min-w-[140px]">
                      <p className="text-[11px] font-bold text-txt2 mb-1.5">Max price £</p>
                      <Input
                        type="number"
                        min="0"
                        placeholder="e.g. 100"
                        value={filters.maxPrice}
                        onChange={(e) => setFilters({ ...filters, maxPrice: e.target.value })}
                        className="h-9 bg-surface border-border rounded-lg"
                      />
                    </div>
                    <div>
                      <p className="text-[11px] font-bold text-txt2 mb-1.5">Verified only</p>
                      <button
                        onClick={() => setFilters({ ...filters, verifiedOnly: !filters.verifiedOnly })}
                        className={cn(
                          'h-9 px-3 rounded-lg text-[11px] font-bold border flex items-center gap-1.5',
                          filters.verifiedOnly ? 'bg-s8ll/15 text-s8ll border-s8ll/40' : 'bg-surface text-txt2 border-border',
                        )}
                      >
                        <Sparkles className="h-3.5 w-3.5" /> Verified
                      </button>
                    </div>
                  </div>
                  <div>
                    <p className="text-[11px] font-bold text-txt2 mb-1.5">Sort</p>
                    <div className="flex gap-1.5 flex-wrap">
                      {SORTS.map(([v, l]) => (
                        <button
                          key={v}
                          onClick={() => setFilters({ ...filters, sort: v })}
                          className={cn(
                            'px-2.5 py-1 rounded-lg text-[11px] font-semibold border',
                            filters.sort === v ? 'bg-s8ll/15 text-s8ll border-s8ll/40' : 'bg-surface text-txt2 border-border',
                          )}
                        >
                          {l}
                        </button>
                      ))}
                    </div>
                  </div>
                  <Button onClick={() => search.mutate(query)} className="s8ll-btn w-full h-9 rounded-xl text-[12px]">
                    Apply filters
                  </Button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </header>

      <div className="flex-1 px-4 py-4 s8ll-scroll overflow-y-auto">
        {!searched && !search.isPending && (
          <div className="space-y-6">
            <section>
              <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-3">
                <TrendingUp className="h-4 w-4 text-s8ll" /> Trending searches
              </h3>
              <div className="flex flex-wrap gap-2">
                {TRENDING.map((t) => (
                  <button
                    key={t}
                    onClick={() => runSearch(t)}
                    className="px-3.5 py-2 rounded-full bg-surface border border-border text-[12px] text-txt2 hover:border-s8ll/40 hover:text-white transition-colors"
                  >
                    {t}
                  </button>
                ))}
              </div>
            </section>
            <section>
              <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-3">
                <Clock className="h-4 w-4 text-txt2" /> Recent
              </h3>
              <div className="space-y-1">
                {recent.map((r) => (
                  <button
                    key={r}
                    onClick={() => runSearch(r)}
                    className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-surface text-left"
                  >
                    <Clock className="h-3.5 w-3.5 text-txt3" />
                    <span className="text-[13px] text-txt2">{r}</span>
                  </button>
                ))}
              </div>
            </section>
            <section className="s8ll-card rounded-2xl p-4">
              <h3 className="flex items-center gap-1.5 text-[13px] font-bold text-white mb-1.5">
                <Bot className="h-4 w-4 text-s8ll" /> AI search tips
              </h3>
              <ul className="text-[12px] text-txt2 space-y-1.5 leading-relaxed">
                <li>• Try natural language: <span className="text-s8ll">“verified jordans under 150”</span></li>
                <li>• Ask for categories: <span className="text-s8ll">“home & garden deals”</span></li>
                <li>• Mention condition: <span className="text-s8ll">“like new cameras”</span></li>
              </ul>
            </section>
          </div>
        )}

        {search.isPending && (
          <div className="grid grid-cols-2 gap-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="s8ll-card rounded-2xl overflow-hidden">
                <Skeleton className="aspect-square rounded-none bg-surface-light" />
                <div className="p-3 space-y-2">
                  <Skeleton className="h-3 w-full bg-surface-light" />
                  <Skeleton className="h-4 w-14 bg-surface-light" />
                </div>
              </div>
            ))}
          </div>
        )}

        {searched && !search.isPending && (
          <>
            {suggestions.length > 0 && (
              <div className="s8ll-card rounded-2xl p-3 mb-4 space-y-1.5">
                <p className="flex items-center gap-1.5 text-[11px] font-bold text-s8ll">
                  <Sparkles className="h-3.5 w-3.5" /> S8LL AI understood
                </p>
                {suggestions.map((s) => (
                  <p key={s} className="text-[12px] text-txt2">— {s}</p>
                ))}
              </div>
            )}

            <div className="flex items-center justify-between mb-3">
              <p className="text-[12px] text-txt2">
                <span className="text-white font-bold">{products.length}</span> results
                {query && <> for <span className="text-s8ll">“{query}”</span></>}
              </p>
            </div>

            {products.length === 0 ? (
              <div className="text-center py-14">
                <p className="text-4xl mb-3">🔍</p>
                <p className="text-sm font-bold text-white">No matches</p>
                <p className="text-[12px] text-txt2 mt-1">Try broader filters or different keywords</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3">
                {products.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}
