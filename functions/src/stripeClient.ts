import Stripe from "stripe";
import { defineSecret } from "firebase-functions/params";

/**
 * Set these once per environment with:
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 * Use test-mode values (sk_test_..., whsec_...) until this is ready to take
 * real payments.
 */
export const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
export const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

let cachedClient: Stripe | null = null;

export function getStripeClient(): Stripe {
  if (!cachedClient) {
    cachedClient = new Stripe(stripeSecretKey.value(), {
      apiVersion: "2024-06-20",
    });
  }
  return cachedClient;
}
