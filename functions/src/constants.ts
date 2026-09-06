/** Platform fee taken from every completed sale, in basis points (800 = 8%). */
export const PLATFORM_FEE_BPS = 800;

/** Stripe processes amounts in the smallest currency unit — pence for GBP. */
export const CURRENCY = "gbp";

/**
 * How long a drop stays live when the document doesn't say — 8 hours,
 * matching the `liveFor` default on the client's Listing model. Older
 * listings predate the field, so anything reading expiry needs a fallback
 * and both sides have to agree on it.
 */
export const DEFAULT_LIVE_FOR_SECONDS = 28_800;

export function applicationFeeFor(amountPence: number): number {
  return Math.round((amountPence * PLATFORM_FEE_BPS) / 10_000);
}
