/** Platform fee taken from every completed sale, in basis points (800 = 8%). */
export const PLATFORM_FEE_BPS = 800;

/** Stripe processes amounts in the smallest currency unit — pence for GBP. */
export const CURRENCY = "gbp";

export function applicationFeeFor(amountPence: number): number {
  return Math.round((amountPence * PLATFORM_FEE_BPS) / 10_000);
}
