import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { db, messaging } from "./admin";

const COMPONENT = "notifications";

/**
 * Sends a push to every device registered for [uid]. Prunes tokens FCM
 * reports as no-longer-registered (the device was uninstalled, signed out,
 * etc.) so `fcmTokens` doesn't grow stale forever.
 */
export async function sendPushToUser(
  uid: string,
  notification: { title: string; body: string },
  data: Record<string, string> = {}
): Promise<void> {
  const userSnap = await db.collection("users").doc(uid).get();
  const tokens = (userSnap.data()?.fcmTokens as string[] | undefined) ?? [];
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({ tokens, notification, data });

  const staleTokens = tokens.filter(
    (_, i) => response.responses[i]?.error?.code === "messaging/registration-token-not-registered"
  );
  if (staleTokens.length > 0) {
    // arrayRemove is a server-side atomic transform, not a read-modify-write
    // — unlike overwriting the whole array from this stale read, it composes
    // safely with a concurrent AppState.registerFcmToken() arrayUnion on
    // another device instead of racing it and dropping the new token.
    await userSnap.ref.set({ fcmTokens: FieldValue.arrayRemove(...staleTokens) }, { merge: true });
  }
}

/** Notifies the other participant in a thread — never the sender. */
export const onNewChatMessage = onDocumentCreated(
  "chatThreads/{threadId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const threadSnap = await db.collection("chatThreads").doc(event.params.threadId).get();
    const thread = threadSnap.data();
    if (!thread) return;

    const participantIds = (thread.participantIds as string[] | undefined) ?? [];
    const recipientId = participantIds.find((id) => id !== message.senderId);
    if (!recipientId) return;

    await sendPushToUser(
      recipientId,
      { title: (thread.listingTitle as string | undefined) ?? "New message", body: message.text as string },
      { type: "message", threadId: event.params.threadId }
    );
    logger.info("Sent new-message push", { component: COMPONENT, threadId: event.params.threadId });
  }
);

/** Notifies the seller a buyer has made an offer. */
export const onNewOffer = onDocumentCreated("offers/{offerId}", async (event) => {
  const offer = event.data?.data();
  if (!offer) return;

  const listingSnap = await db.collection("listings").doc(offer.listingId as string).get();
  const listingTitle = (listingSnap.data()?.title as string | undefined) ?? "your listing";

  await sendPushToUser(
    offer.sellerId as string,
    { title: "New offer", body: `£${((offer.offerCents as number) / 100).toFixed(0)} on ${listingTitle}` },
    { type: "offer", listingId: offer.listingId as string }
  );
  logger.info("Sent new-offer push", { component: COMPONENT, listingId: offer.listingId });
});

/** Notifies the buyer once the seller accepts or declines — never on the initial pending write. */
export const onOfferResponded = onDocumentUpdated("offers/{offerId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status !== "pending" || after.status === "pending") return;

  const listingSnap = await db.collection("listings").doc(after.listingId as string).get();
  const listingTitle = (listingSnap.data()?.title as string | undefined) ?? "the listing";
  const accepted = after.status === "accepted";

  await sendPushToUser(
    after.buyerId as string,
    {
      title: accepted ? "Offer accepted!" : "Offer declined",
      body: accepted
        ? `Your offer on ${listingTitle} was accepted — you can buy now.`
        : `Your offer on ${listingTitle} was declined.`,
    },
    { type: "offer-response", listingId: after.listingId as string }
  );
  logger.info("Sent offer-response push", {
    component: COMPONENT,
    listingId: after.listingId,
    accepted,
  });
});

/** Notifies both sides once the webhook records a completed sale. */
export const onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data?.data();
  if (!order) return;

  const listingSnap = await db.collection("listings").doc(order.listingId as string).get();
  const listingTitle = (listingSnap.data()?.title as string | undefined) ?? "your item";

  await Promise.all([
    sendPushToUser(
      order.sellerId as string,
      { title: "Sold!", body: `${listingTitle} just sold.` },
      { type: "sale", listingId: order.listingId as string }
    ),
    sendPushToUser(
      order.buyerId as string,
      { title: "Payment confirmed", body: `Your purchase of ${listingTitle} is confirmed.` },
      { type: "purchase", listingId: order.listingId as string }
    ),
  ]);
  logger.info("Sent sale push to buyer and seller", { component: COMPONENT, listingId: order.listingId });
});

interface ListingFields {
  title: string;
  category?: string;
  priceCents: number;
}

interface SearchCriteria {
  query?: string;
  category?: string;
  maxPriceCents?: number;
}

interface SavedSearchFields extends SearchCriteria {
  buyerId: string;
}

/** Pure so it can be unit-tested without any Firestore involved at all. */
export function matchesSavedSearch(listing: ListingFields, search: SearchCriteria): boolean {
  const query = (search.query ?? "").trim().toLowerCase();
  if (query.length > 0 && !listing.title.toLowerCase().includes(query)) return false;
  if (search.category && listing.category !== search.category) return false;
  if (search.maxPriceCents != null && listing.priceCents > search.maxPriceCents) return false;
  return true;
}

/**
 * A small demo-scale shortcut: this fetches every saved search rather than
 * querying for matches, since Firestore can't express "title contains" or
 * "category is null or X" in one query. Fine at this app's scale; a larger
 * one would denormalize/index differently.
 */
export const onNewListingMatchSavedSearches = onDocumentCreated(
  "listings/{listingId}",
  async (event) => {
    const listing = event.data?.data();
    if (!listing) return;

    const listingFields: ListingFields = {
      title: listing.title as string,
      category: listing.category as string | undefined,
      priceCents: listing.priceCents as number,
    };

    const searchesSnap = await db.collection("savedSearches").get();
    const matches = searchesSnap.docs.filter((doc) =>
      matchesSavedSearch(listingFields, doc.data() as SavedSearchFields)
    );

    await Promise.all(
      matches.map((doc) => {
        const search = doc.data() as SavedSearchFields;
        return sendPushToUser(
          search.buyerId,
          { title: "New match", body: `${listingFields.title} matches your saved search` },
          { type: "saved-search", listingId: event.params.listingId }
        );
      })
    );
    if (matches.length > 0) {
      logger.info("Sent saved-search match pushes", {
        component: COMPONENT,
        listingId: event.params.listingId,
        matchCount: matches.length,
      });
    }
  }
);
