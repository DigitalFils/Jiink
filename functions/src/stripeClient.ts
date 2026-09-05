import Stripe from "stripe";
import { defineSecret, defineString } from "firebase-functions/params";

/**
 * Set these once per environment with:
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 * Use test-mode values (sk_test_..., whsec_...) until this is ready to take
 * real payments. See SETUP.md for running test and live side by side as
 * separate Firebase project aliases rather than ever switching one
 * project's secrets back and forth.
 */
export const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
export const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

/**
 * The Secret Manager prompt for STRIPE_SECRET_KEY looks identical whether
 * you paste a test or a live key — nothing stops a live key from ending up
 * in what's meant to be a safe staging environment, or vice versa. This
 * requires every environment to say which one it's supposed to be
 * (typically via a committed functions/.env.<project-id> file — it's not
 * sensitive, just "test" or "live") and refuses to serve any request if
 * the actual key doesn't match, rather than silently doing the wrong thing
 * with real money.
 */
export const stripeMode = defineString("STRIPE_MODE", {
  description: 'Must be "test" or "live", matching the mode of STRIPE_SECRET_KEY configured for this environment.',
});

/** Exported for testing; also used by getStripeClient(). */
export function assertStripeKeyMatchesMode(secretKey: string, mode: string): void {
  if (mode !== "test" && mode !== "live") {
    throw new Error(`STRIPE_MODE must be "test" or "live" — got "${mode}".`);
  }
  const expectedPrefix = mode === "live" ? "sk_live_" : "sk_test_";
  if (!secretKey.startsWith(expectedPrefix)) {
    throw new Error(
      `STRIPE_MODE is "${mode}" but STRIPE_SECRET_KEY doesn't start with "${expectedPrefix}" — ` +
        "refusing to start rather than risk processing a payment in the wrong mode."
    );
  }
}

let cachedClient: Stripe | null = null;

export function getStripeClient(): Stripe {
  if (!cachedClient) {
    const secretKey = stripeSecretKey.value();
    assertStripeKeyMatchesMode(secretKey, stripeMode.value());
    cachedClient = new Stripe(secretKey, {
      apiVersion: "2024-06-20",
    });
  }
  return cachedClient;
}
