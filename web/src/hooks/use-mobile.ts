import * as React from "react"

const MOBILE_BREAKPOINT = 768

const query = `(max-width: ${MOBILE_BREAKPOINT - 1}px)`

function subscribe(onChange: () => void) {
  const mql = window.matchMedia(query)
  mql.addEventListener("change", onChange)
  return () => mql.removeEventListener("change", onChange)
}

/**
 * Whether the viewport is narrower than the mobile breakpoint.
 *
 * `useSyncExternalStore` rather than state written from an effect: the
 * effect version returned `false` on the very first render even on a phone,
 * because the state only arrived a commit later — so a mobile layout
 * rendered its desktop branch first and then swapped. This reads the media
 * query during render instead, and the server snapshot is `false` because
 * there is no viewport to measure there.
 */
export function useIsMobile() {
  return React.useSyncExternalStore(
    subscribe,
    () => window.matchMedia(query).matches,
    () => false,
  )
}
