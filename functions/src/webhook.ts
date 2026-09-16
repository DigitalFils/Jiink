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

          // Three genuinely different things can be true by the time a
          // payment succeeds, and collapsing them into one "did we write
          // an order?" boolean quietly kept a buyer's money:
          //
          //  - Stripe redelivered an event we already processed. A no-op.
          //  - This payment won the item. Mark it sold, record the order.
          //  - This payment LOST. Nothing reserves a listing at checkout
          //    time — status only moves to "sold" here, after payment — so
          //    two people tapping Buy on the same one-off item within a few
          //    seconds of each other both get a PaymentIntent and both
          //    confirm. One gets the item; the other has been charged, and
          //    the money has already moved to the seller's connected
          //    account, for something they will never receive. Same if the
          //    listing was deleted mid-checkout.
          //
          // The order doc is keyed by PaymentIntent id, so whether it
          // exists is what separates a redelivery from a losing race — the
          // listing reads "sold" in both cases.
          const orderFields = {
            listingId,
            buyerId,
            sellerId,
            amountCents: intent.amount,
            applicationFeeCents: intent.application_fee_amount ?? 0,
            paymentIntentId: intent.id,
          };
          const outcome = await db.runTransaction(async (tx) => {
            const listingSnap = await tx.get(listingRef);
            const orderSnap = await tx.get(orderRef);
            const existingOrder = orderSnap.data();
            // "refund_pending" means a previous delivery of this event got
            // as far as recording the loss but not as far as Stripe. That
            // is the one existing order we must not treat as finished.
            if (existingOrder && existingOrder.status !== "refund_pending") {
              return "already-handled" as const;
            }
            if (listingSnap.exists && listingSnap.data()?.status !== "sold") {
              tx.set(listingRef, { status: "sold", soldAt: new Date() }, { merge: true });
              tx.set(orderRef, { ...orderFields, status: "paid", createdAt: new Date() });
              return "won" as const;
            }
            tx.set(
              orderRef,
              {
                ...orderFields,
                status: "refund_pending",
                refundReason: listingSnap.exists ? "already-sold" : "listing-missing",
                createdAt: new Date(),
              },
              { merge: true }
            );
            return "lost" as const;
          });

          if (outcome === "won") {
            logger.info("Marked listing sold and recorded order", {
              ...logContext,
              listingId,
              paymentIntentId: intent.id,
            });
          } else if (outcome === "lost") {
            // reverse_transfer pulls the money back out of the seller's
            // connected account (transfer_data.destination already moved it
            // there); refund_application_fee returns our platform cut too.
            // Nothing was delivered, so the buyer gets all of it back.
            // The idempotency key makes a Stripe retry of this same event
            // safe — a second call returns the first refund rather than
            // issuing another one.
            await getStripeClient().refunds.create(
              {
                payment_intent: intent.id,
                reverse_transfer: true,
                refund_application_fee: true,
              },
              { idempotencyKey: `s8ll_refund_${intent.id}` }
            );
            await orderRef.set({ status: "refunded", refundedAt: new Date() }, { merge: true });
            logger.warn("Refunded a payment that lost the race for a listing", {
              ...logContext,
              listingId,
              buyerId,
              paymentIntentId: intent.id,
              amountCents: intent.amount,
            });
          } else {
            // Expected under Stripe's at-least-once delivery.
            logger.info("Ignored a redelivered payment_intent.succeeded", {
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
