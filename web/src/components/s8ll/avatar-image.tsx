'use client'

import { useState } from 'react'
import { cn } from '@/lib/utils'

/**
 * A profile picture that degrades to the person's initial.
 *
 * Avatars are URLs on somebody else's server. They 404, they get hotlink
 * blocked, they time out on a bad connection — and a bare <img> answers
 * that with the browser's broken-image glyph and the alt text spilling out
 * of its rounded corners, which is what the profile screen was doing. This
 * swaps in a lettered tile instead.
 */
export function AvatarImage({
  src,
  name,
  className,
}: {
  src: string | null | undefined
  name: string
  className?: string
}) {
  // Remember *which* URL failed rather than a bare boolean: changing your
  // picture after one failure then gets a fresh attempt, without an effect
  // to reset the flag.
  const [failedSrc, setFailedSrc] = useState<string | null>(null)
  const failed = !!src && failedSrc === src

  const initial = name.trim().charAt(0).toUpperCase() || '?'

  if (!src || failed) {
    return (
      <div
        className={cn(
          'flex items-center justify-center bg-surface-light text-s8ll font-black select-none',
          className,
        )}
        aria-label={name}
        role="img"
      >
        {initial}
      </div>
    )
  }

  return (
    <img
      src={src}
      alt={name}
      onError={() => setFailedSrc(src)}
      className={cn('object-cover bg-surface-light', className)}
    />
  )
}
