'use client'

import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { AtSign, Eye, EyeOff, KeyRound, Loader2, User } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Logo } from './logo'
import { ApiError, useSignIn, useSignUp } from '@/lib/session'
import { cn } from '@/lib/utils'

type Mode = 'in' | 'up'

/**
 * The gate between onboarding and the app.
 *
 * One screen for both sign in and create account, because the fields
 * overlap and a tab swap is cheaper than a second route in a shell that
 * has no router. The server owns every rule — length, username charset,
 * uniqueness — and its message is what gets shown, so the two can't drift
 * apart into a form that accepts something the API then rejects.
 */
export function SignInScreen() {
  const [mode, setMode] = useState<Mode>('in')
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [reveal, setReveal] = useState(false)

  const signIn = useSignIn()
  const signUp = useSignUp()
  const busy = signIn.isPending || signUp.isPending
  const failure = (signIn.error ?? signUp.error) as ApiError | null

  const swap = (next: Mode) => {
    setMode(next)
    signIn.reset()
    signUp.reset()
  }

  const submit = (e: React.FormEvent) => {
    e.preventDefault()
    if (busy) return
    if (mode === 'in') signIn.mutate({ email, password })
    else signUp.mutate({ username, email, password })
  }

  // Which field the server blamed, so the offending box can be outlined
  // instead of the error sitting at the bottom detached from its cause.
  const blamed = failure?.field

  return (
    <div className="min-h-[100dvh] flex flex-col px-7 pt-[max(env(safe-area-inset-top),40px)] pb-[max(env(safe-area-inset-bottom),28px)]">
      <div className="flex-1 flex flex-col justify-center">
        <div className="mb-9">
          <Logo size="lg" />
        </div>

        {/* mode switch */}
        <div className="grid grid-cols-2 gap-1 p-1 rounded-2xl bg-surface border border-border mb-6">
          {(['in', 'up'] as const).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => swap(m)}
              className={cn(
                'relative h-10 rounded-xl text-[13px] font-bold transition-colors',
                mode === m ? 'text-black' : 'text-txt2 hover:text-white',
              )}
            >
              {mode === m && (
                <motion.span
                  layoutId="auth-tab"
                  transition={{ type: 'spring', stiffness: 420, damping: 34 }}
                  className="absolute inset-0 s8ll-btn rounded-xl"
                />
              )}
              <span className="relative">{m === 'in' ? 'Sign in' : 'Create account'}</span>
            </button>
          ))}
        </div>

        <form onSubmit={submit} className="space-y-3">
          <AnimatePresence initial={false}>
            {mode === 'up' && (
              <motion.div
                key="username"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
                className="overflow-hidden"
              >
                <Field
                  icon={User}
                  invalid={blamed === 'username'}
                  input={
                    <Input
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="Username"
                      autoComplete="username"
                      autoCapitalize="none"
                      spellCheck={false}
                      required
                      className="border-0 bg-transparent h-12 pl-11 text-[15px] focus-visible:ring-0"
                    />
                  }
                />
              </motion.div>
            )}
          </AnimatePresence>

          <Field
            icon={AtSign}
            invalid={blamed === 'email'}
            input={
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email"
                autoComplete="email"
                autoCapitalize="none"
                spellCheck={false}
                required
                className="border-0 bg-transparent h-12 pl-11 text-[15px] focus-visible:ring-0"
              />
            }
          />

          <Field
            icon={KeyRound}
            invalid={blamed === 'password'}
            input={
              <>
                <Input
                  type={reveal ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={mode === 'up' ? 'Password — at least 8 characters' : 'Password'}
                  // Tells a password manager to offer a new password on
                  // sign-up and the saved one on sign-in.
                  autoComplete={mode === 'up' ? 'new-password' : 'current-password'}
                  required
                  className="border-0 bg-transparent h-12 pl-11 pr-11 text-[15px] focus-visible:ring-0"
                />
                <button
                  type="button"
                  onClick={() => setReveal((r) => !r)}
                  aria-label={reveal ? 'Hide password' : 'Show password'}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-txt3 hover:text-txt2 transition-colors"
                >
                  {reveal ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </>
            }
          />

          {failure && (
            <motion.p
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              role="alert"
              className="text-[12px] font-semibold text-live px-1"
            >
              {failure.message}
            </motion.p>
          )}

          <Button type="submit" disabled={busy} className="s8ll-btn w-full h-12 rounded-2xl text-[15px] mt-1">
            {busy && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
            {mode === 'in' ? 'Sign in' : 'Create account'}
          </Button>
        </form>
      </div>

      <p className="text-center text-[11px] text-txt3 leading-relaxed">
        {mode === 'up'
          ? 'By creating an account you agree to our Terms & Privacy Policy.'
          : 'Your password is never stored in readable form.'}
      </p>
    </div>
  )
}

function Field({
  icon: Icon,
  input,
  invalid,
}: {
  icon: typeof AtSign
  input: React.ReactNode
  invalid?: boolean
}) {
  return (
    <div
      className={cn(
        'relative rounded-2xl bg-surface border transition-colors',
        invalid ? 'border-live/60' : 'border-border focus-within:border-s8ll/50',
      )}
    >
      <Icon className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-txt3 pointer-events-none" />
      {input}
    </div>
  )
}
