import { FakeFirestore } from "./helpers/fakeFirestore";
import { makeFakeMessaging } from "./helpers/fakeMessaging";

const fakeDb = new FakeFirestore();
const fakeMessaging = makeFakeMessaging();

jest.mock("../admin", () => ({ db: fakeDb, messaging: fakeMessaging }));

import {
  sendPushToUser,
  onNewChatMessage,
  onNewOffer,
  onOfferResponded,
  onOrderCreated,
  matchesSavedSearch,
  onNewListingMatchSavedSearches,
} from "../notifications";

const BUYER = "buyer-1";
const SELLER = "seller-1";
const LISTING = "listing-1";

beforeEach(() => {
  fakeDb.store.clear();
  fakeMessaging.sendEachForMulticast.mockClear();
  fakeMessaging.sendEachForMulticast.mockImplementation(async (message: { tokens: string[] }) => ({
    responses: message.tokens.map(() => ({ success: true })),
    successCount: message.tokens.length,
    failureCount: 0,
  }));
});

function docSnapshot(data: Record<string, unknown> | undefined) {
  return { data: () => data };
}

describe("sendPushToUser", () => {
  it("does nothing when the user has no registered devices", async () => {
    fakeDb.seed(`users/${BUYER}`, {});
    await sendPushToUser(BUYER, { title: "t", body: "b" });
    expect(fakeMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });

  it("sends to every registered token", async () => {
    fakeDb.seed(`users/${BUYER}`, { fcmTokens: ["tok-1", "tok-2"] });
    await sendPushToUser(BUYER, { title: "Hi", body: "there" });
    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ tokens: ["tok-1", "tok-2"], notification: { title: "Hi", body: "there" } })
    );
  });

  it("prunes tokens FCM reports as no longer registered", async () => {
    fakeDb.seed(`users/${BUYER}`, { fcmTokens: ["tok-good", "tok-stale"] });
    fakeMessaging.sendEachForMulticast.mockResolvedValueOnce({
      responses: [
        { success: true },
        { success: false, error: { code: "messaging/registration-token-not-registered" } },
      ],
      successCount: 1,
      failureCount: 1,
    });

    await sendPushToUser(BUYER, { title: "Hi", body: "there" });

    const stored = fakeDb.store.get(`users/${BUYER}`);
    expect(stored?.fcmTokens).toEqual(["tok-good"]);
  });
});

describe("onNewChatMessage", () => {
  it("notifies the other participant, not the sender", async () => {
    fakeDb.seed("chatThreads/t1", {
      participantIds: [SELLER, BUYER],
      listingTitle: "Nike Air Max 90",
    });
    fakeDb.seed(`users/${SELLER}`, { fcmTokens: ["seller-token"] });
    fakeDb.seed(`users/${BUYER}`, { fcmTokens: ["buyer-token"] });

    await onNewChatMessage.run({
      data: docSnapshot({ senderId: BUYER, text: "Still available?" }),
      params: { threadId: "t1", messageId: "m1" },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ tokens: ["seller-token"] })
    );
  });
});

describe("onNewOffer", () => {
  it("notifies the seller with the offer amount and listing title", async () => {
    fakeDb.seed(`listings/${LISTING}`, { title: "Nike Air Max 90" });
    fakeDb.seed(`users/${SELLER}`, { fcmTokens: ["seller-token"] });

    await onNewOffer.run({
      data: docSnapshot({ listingId: LISTING, sellerId: SELLER, buyerId: BUYER, offerCents: 3500 }),
      params: { offerId: `${LISTING}_${BUYER}` },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        tokens: ["seller-token"],
        notification: expect.objectContaining({ body: "£35 on Nike Air Max 90" }),
      })
    );
  });
});

describe("onOfferResponded", () => {
  beforeEach(() => {
    fakeDb.seed(`listings/${LISTING}`, { title: "Nike Air Max 90" });
    fakeDb.seed(`users/${BUYER}`, { fcmTokens: ["buyer-token"] });
  });

  it("notifies the buyer when an offer is accepted", async () => {
    await onOfferResponded.run({
      data: {
        before: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "pending" }),
        after: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "accepted" }),
      },
      params: { offerId: `${LISTING}_${BUYER}` },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ notification: expect.objectContaining({ title: "Offer accepted!" }) })
    );
  });

  it("notifies the buyer when an offer is declined", async () => {
    await onOfferResponded.run({
      data: {
        before: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "pending" }),
        after: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "declined" }),
      },
      params: { offerId: `${LISTING}_${BUYER}` },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ notification: expect.objectContaining({ title: "Offer declined" }) })
    );
  });

  it("does not notify on an update that isn't a pending-to-resolved transition", async () => {
    await onOfferResponded.run({
      data: {
        before: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "accepted" }),
        after: docSnapshot({ listingId: LISTING, buyerId: BUYER, status: "accepted" }),
      },
      params: { offerId: `${LISTING}_${BUYER}` },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });
});

describe("onOrderCreated", () => {
  it("notifies both the seller and the buyer", async () => {
    fakeDb.seed(`listings/${LISTING}`, { title: "Nike Air Max 90" });
    fakeDb.seed(`users/${SELLER}`, { fcmTokens: ["seller-token"] });
    fakeDb.seed(`users/${BUYER}`, { fcmTokens: ["buyer-token"] });

    await onOrderCreated.run({
      data: docSnapshot({ listingId: LISTING, sellerId: SELLER, buyerId: BUYER }),
      params: { orderId: "pi_test_1" },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledTimes(2);
    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ tokens: ["seller-token"] })
    );
    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ tokens: ["buyer-token"] })
    );
  });
});

describe("matchesSavedSearch", () => {
  const listing = { title: "Nike Air Max 90", category: "clothing", priceCents: 4500 };

  it("matches an empty search (no filters set)", () => {
    expect(matchesSavedSearch(listing, {})).toBe(true);
  });

  it("matches on a case-insensitive title substring", () => {
    expect(matchesSavedSearch(listing, { query: "air max" })).toBe(true);
    expect(matchesSavedSearch(listing, { query: "playstation" })).toBe(false);
  });

  it("matches on category", () => {
    expect(matchesSavedSearch(listing, { category: "clothing" })).toBe(true);
    expect(matchesSavedSearch(listing, { category: "electronics" })).toBe(false);
  });

  it("matches on max price", () => {
    expect(matchesSavedSearch(listing, { maxPriceCents: 4500 })).toBe(true);
    expect(matchesSavedSearch(listing, { maxPriceCents: 1000 })).toBe(false);
  });
});

describe("onNewListingMatchSavedSearches", () => {
  it("notifies only buyers whose saved search matches the new listing", async () => {
    fakeDb.seed("savedSearches/s1", { buyerId: "buyer-match", query: "nike" });
    fakeDb.seed("savedSearches/s2", { buyerId: "buyer-nomatch", query: "playstation" });
    fakeDb.seed("users/buyer-match", { fcmTokens: ["match-token"] });
    fakeDb.seed("users/buyer-nomatch", { fcmTokens: ["nomatch-token"] });

    await onNewListingMatchSavedSearches.run({
      data: docSnapshot({ title: "Nike Air Max 90", category: "clothing", priceCents: 4500 }),
      params: { listingId: LISTING },
    } as never);

    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect(fakeMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({ tokens: ["match-token"] })
    );
  });
});
