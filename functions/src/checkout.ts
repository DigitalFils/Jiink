import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin";
import { getStripeClient, stripeSecretKey } from "./stripeClient";
import { CURRENCY, applicationFeeFor } from "./constants";

/**
 * Creates a PaymentIntent for a single listing, split between the seller's
 * connected Stripe account and the platform fee. The client confirms it
 * with Stripe's PaymentSheet — the buyer's card details never touch our
 * server or the app.
 */
export const createListingPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const buyerId = request.auth?.uid;
    if (!buyerId) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const listingId = request.data?.listingId;
    if (typeof listingId !== "string" || listingId.length === 0) {
      throw new HttpsError("invalid-argument", "listingId is required.");
    }

    const listingRef = db.collection("listings").doc(listingId);
    const listingSnap = await listingRef.get();
    if (!listingSnap.exists) {
      throw new HttpsError("not-found", "Listing not found.");
    }
    const listing = listingSnap.data()!;

    if (listing.status !== "live") {
      throw new HttpsError(
        "failed-precondition",
        "This listing is no longer available."
      );
    }
    if (listing.sellerId === buyerId) {
      throw new HttpsError(
        "failed-precondition",
        "You can't buy your own listing."
      );
    }
    if (listing.delivery === "meetup") {
      throw new HttpsError(
        "failed-precondition",
        "This listing is meet-up only — pay the seller in person instead."
      );
    }

    const sellerSnap = await db.collection("users").doc(listing.sellerId).get();
    const sellerAccountId = sellerSnap.data()?.stripeAccountId;
    const payoutsEnabled = sellerSnap.data()?.payoutsEnabled === true;
    if (!sellerAccountId || !payoutsEnabled) {
      throw new HttpsError(
        "failed-precondition",
        "This seller hasn't finished setting up payouts yet."
      );
    }

    // A buyer who had an offer accepted pays that price instead of the
    // listing price. The offer doc's id is deterministic (listingId_buyerId)
    // so this is a single get, not a query — and its status can only ever
    // have been flipped to "accepted" by the seller (firestore.rules), so a
    // buyer can't grant themselves a discount by writing the offer alone.
    const offerSnap = await db.collection("offers").doc(`${listingId}_${buyerId}`).get();
    const offerData = offerSnap.data();
    const amount: number =
      offerData?.status === "accepted" ? (offerData.offerCents as number) : listing.priceCents;

    const stripe = getStripeClient();
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: CURRENCY,
      application_fee_amount: applicationFeeFor(amount),
      transfer_data: { destination: sellerAccountId },
      metadata: {
        listingId,
        buyerId,
        sellerId: listing.sellerId,
      },
    });

    return { clientSecret: paymentIntent.client_secret };
  }
);
