'use client'

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'

/** The shape `/api/auth/me` returns. Mirrors `SessionUser` in lib/auth.ts —
 * the server decides what a client is allowed to know about itself. */
export type SessionUser = {
  id: string
  username: string
  email: string | null
  avatar: string
  bio: string
  isVerified: boolean
  balance: number
  points: number
  level: number
  xp: number
  sales: number
  rating: number
  followers: number
}

export const sessionKey = ['session'] as const

/**
 * An API error that carries the server's own message and, for form
 * validation, which field it belongs to.
 *
 * Without this the UI can only say "something went wrong", which is how the
 * wallet screen ended up reporting a deliberate 501 as "Top-up failed". The
 * routes already return a readable `error`; this is what gets it to the
 * user.
 */
export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly field?: string,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { ...(init?.body ? { 'Content-Type': 'application/json' } : {}), ...init?.headers },
  })

  let body: any = null
  try {
    body = await res.json()
  } catch {
    // A non-JSON response (a proxy error page, say) is still a failure we
    // want to report with its status rather than crashing on the parse.
  }

  if (!res.ok) {
    throw new ApiError(body?.error ?? `Request failed (${res.status})`, res.status, body?.field)
  }
  return body as T
}

/**
 * Who is signed in.
 *
 * `/api/auth/me` answers 200 with `user: null` when nobody is, so an empty
 * session is data rather than an error — `isPending` means "we don't know
 * yet", which is what the shell needs to avoid flashing the sign-in screen
 * at someone who is already signed in.
 *
 * `staleTime: Infinity` because a session doesn't change behind the app's
 * back; the mutations below write the new user straight into the cache.
 */
export function useSession() {
  const query = useQuery({
    queryKey: sessionKey,
    queryFn: () => api<{ user: SessionUser | null }>('/api/auth/me'),
    staleTime: Infinity,
    retry: false,
  })

  return {
    user: query.data?.user ?? null,
    /** True only while the first answer is in flight. */
    loading: query.isPending,
    error: query.error as ApiError | null,
  }
}

export function useSignIn() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { email: string; password: string }) =>
      api<{ user: SessionUser }>('/api/auth/login', { method: 'POST', body: JSON.stringify(input) }),
    onSuccess: ({ user }) => qc.setQueryData(sessionKey, { user }),
  })
}

export function useSignUp() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { username: string; email: string; password: string }) =>
      api<{ user: SessionUser }>('/api/auth/register', { method: 'POST', body: JSON.stringify(input) }),
    onSuccess: ({ user }) => qc.setQueryData(sessionKey, { user }),
  })
}

export function useSignOut() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: () => api<{ ok: true }>('/api/auth/logout', { method: 'POST' }),
    onSuccess: () => {
      qc.setQueryData(sessionKey, { user: null })
      // Everything else in the cache belonged to the person who just left —
      // their wallet, their chats, their wishlist. Clearing it is the
      // difference between signing out and hiding the profile screen.
      qc.clear()
      qc.setQueryData(sessionKey, { user: null })
    },
  })
}
