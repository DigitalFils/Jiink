import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin";
import { getStripeClient, stripeSecretKey } from "./stripeClient";

/**
 * Creates (or reuses) a Stripe Connect Express account for the calling
 * seller and returns a hosted onboarding link. The client opens this URL in
 * a browser tab — Stripe collects the identity/bank details, not us.
 */
export const createPayoutOnboardingLink = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const returnUrl = request.data?.returnUrl;
    const refreshUrl = request.data?.refreshUrl;
    if (typeof returnUrl !== "string" || typeof refreshUrl !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "returnUrl and refreshUrl are required."
      );
    }

    const stripe = getStripeClient();
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const userData = userSnap.data() ?? {};

    let accountId: string | undefined = userData.stripeAccountId;

    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email: request.auth?.token?.email ?? undefined,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
      });
      accountId = account.id;
      await userRef.set(
        { stripeAccountId: accountId, payoutsEnabled: false },
        { merge: true }
      );
    }

    const link = await stripe.accountLinks.create({
      account: accountId,
      type: "account_onboarding",
      return_url: returnUrl,
      refresh_url: refreshUrl,
    });

    return { url: link.url };
  }
);
