import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import Stripe from "stripe";
import { db } from "./admin";
import { getStripeClient, stripeSecretKey, stripeWebhookSecret } from "./stripeClient";

/**
 * Every log line from this function carries this so a Cloud Logging query
 * (or a log-based alerting policy — see SETUP.md) can isolate webhook
 * activity from everything else Cloud Functions emits.
 */
const COMPONENT = "stripeWebhook";

/**
 * Stripe calls this after every event on our account. We only act on the
 * two that matter to S8LL: a seller finishing Connect onboarding, and a
 * buyer's payment succeeding. Every other subscribed event type is
 * acknowledged (200) but otherwise ignored — logged at info so an
 * unexpected surge of some other event type is still visible.
 */
export const stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret], cors: false },
  async (req, res) => {
    const signature = req.headers["stripe-signature"];
    if (typeof signature !== "string") {
      logger.warn("Stripe webhook request missing Stripe-Signature header", {
        component: COMPONENT,
      });
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
      logger.warn("Stripe webhook signature verification failed", {
        component: COMPONENT,
        error: err instanceof Error ? err.message : String(err),
      });
      res.status(400).send("Invalid signature");
      return;
    }

    const logContext = { component: COMPONENT, eventId: event.id, eventType: event.type };

    try {
      switch (event.type) {
        case "account.updated": {
          const account = event.data.object as Stripe.Account;
          const usersQuery = await db
            .collection("users")
            .where("stripeAccountId", "==", account.id)
            .limit(1)
            .get();
          if (usersQuery.empty) {
            // Not necessarily a bug — Stripe fans this event out for every
            // change on the account, including ones from before we start
            // tracking it — but worth seeing if it happens a lot.
            logger.warn("account.updated for a Stripe account with no matching user", {
              ...logContext,
              stripeAccountId: account.id,
            });
            break;
          }
          const payoutsEnabled = account.charges_enabled && account.payouts_enabled;
          await usersQuery.docs[0].ref.set({ payoutsEnabled }, { merge: true });
          logger.info("Updated seller payouts status", {
            ...logContext,
            stripeAccountId: account.id,
            payoutsEnabled,
          });
          break;
        }

        case "payment_intent.succeeded": {
          const intent = event.data.object as Stripe.PaymentIntent;
          const { listingId, buyerId, sellerId } = intent.metadata;
          if (!listingId || !buyerId || !sellerId) {
            // Every PaymentIntent we create (checkout.ts) sets all three —
            // if one's missing, something is wrong on our side, not
            // Stripe's, and retrying won't fix it. Log loudly, ack anyway.
            logger.error("payment_intent.succeeded missing expected metadata", {
              ...logContext,
              paymentIntentId: intent.id,
            });
            break;
          }
          const listingRef = db.collection("listings").doc(listingId);
          const orderRef = db.collection("orders").doc(intent.id);
          const applied = await db.runTransaction(async (tx) => {
            const listingSnap = await tx.get(listingRef);
            if (!listingSnap.exists || listingSnap.data()?.status === "sold") {
              return false;
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
            return true;
          });
          if (applied) {
            logger.info("Marked listing sold and recorded order", {
              ...logContext,
              listingId,
              paymentIntentId: intent.id,
            });
          } else {
            // Stripe redelivered an event we've already handled, or the
            // listing doesn't exist. Expected under at-least-once delivery
            // — info, not a warning.
            logger.info("Ignored payment_intent.succeeded for a listing that isn't live-sellable", {
              ...logContext,
              listingId,
              paymentIntentId: intent.id,
            });
          }
          break;
        }

        default:
          logger.info("Ignoring unhandled Stripe event type", logContext);
          break;
      }
    } catch (err) {
      // Something genuinely broke processing a recognized event (a
      // Firestore error, for instance) — 500 so Stripe retries, and log at
      // error so it surfaces on whatever alert SETUP.md has you wire up.
      logger.error("Failed to process Stripe webhook event", {
        ...logContext,
        error: err instanceof Error ? err.message : String(err),
      });
      res.status(500).send("Internal error processing webhook");
      return;
    }

    res.status(200).send("ok");
  }
);
