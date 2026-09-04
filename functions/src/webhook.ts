import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import Stripe from "stripe";
import { db } from "./admin";
import { getStripeClient, stripeSecretKey, stripeWebhookSecret } from "./stripeClient";

/**
 * Stripe calls this after every event on our account. We only act on the
 * two that matter to S8LL: a seller finishing Connect onboarding, and a
 * buyer's payment succeeding.
 */
export const stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret], cors: false },
  async (req, res) => {
    const signature = req.headers["stripe-signature"];
    if (typeof signature !== "string") {
      res.status(400).send("Missing Stripe-Signature header");
      return;
    }

    let event: Stripe.Event;
    try {
      event = getStripeClient().webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value()
      );
    } catch (err) {
      logger.warn("Stripe webhook signature verification failed", err);
      res.status(400).send("Invalid signature");
      return;
    }

    switch (event.type) {
      case "account.updated": {
        const account = event.data.object as Stripe.Account;
        const usersQuery = await db
          .collection("users")
          .where("stripeAccountId", "==", account.id)
          .limit(1)
          .get();
        if (!usersQuery.empty) {
          await usersQuery.docs[0].ref.set(
            {
              payoutsEnabled: account.charges_enabled && account.payouts_enabled,
            },
            { merge: true }
          );
        }
        break;
      }

      case "payment_intent.succeeded": {
        const intent = event.data.object as Stripe.PaymentIntent;
        const { listingId, buyerId, sellerId } = intent.metadata;
        if (listingId && buyerId && sellerId) {
          const listingRef = db.collection("listings").doc(listingId);
          const orderRef = db.collection("orders").doc(intent.id);
          await db.runTransaction(async (tx) => {
            const listingSnap = await tx.get(listingRef);
            if (!listingSnap.exists || listingSnap.data()?.status === "sold") {
              return;
            }
            tx.set(
              listingRef,
              { status: "sold", soldAt: new Date() },
              { merge: true }
            );
            tx.set(orderRef, {
              listingId,
              buyerId,
              sellerId,
              amountCents: intent.amount,
              applicationFeeCents: intent.application_fee_amount ?? 0,
              paymentIntentId: intent.id,
              status: "paid",
              createdAt: new Date(),
            });
          });
        }
        break;
      }

      default:
        break;
    }

    res.status(200).send("ok");
  }
);
