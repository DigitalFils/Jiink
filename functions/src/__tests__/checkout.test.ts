import { Timestamp } from "firebase-admin/firestore";
import { FakeFirestore } from "./helpers/fakeFirestore";
import { makeFakeStripe } from "./helpers/fakeStripe";

const fakeDb = new FakeFirestore();
const fakeStripe = makeFakeStripe();

jest.mock("../admin", () => ({ db: fakeDb }));
jest.mock("../stripeClient", () => ({
  stripeSecretKey: { value: () => "sk_test_fake" },
  getStripeClient: () => fakeStripe,
}));

// Imported after the mocks above so createListingPaymentIntent picks them up.
import { createListingPaymentIntent } from "../checkout";

const BUYER = "buyer-1";
const SELLER = "seller-1";
const LISTING = "listing-1";

function seedLiveListing(overrides: Record<string, unknown> = {}) {
  fakeDb.seed(`listings/${LISTING}`, {
    sellerId: SELLER,
    status: "live",
    delivery: "shipping",
    priceCents: 2500,
    ...overrides,
  });
}

function seedPayoutReadySeller() {
  fakeDb.seed(`users/${SELLER}`, {
    stripeAccountId: "acct_seller_1",
    payoutsEnabled: true,
  });
}

async function expectHttpsError(promise: Promise<unknown>, code: string) {
  await expect(promise).rejects.toMatchObject({ code });
}

beforeEach(() => {
  fakeDb.store.clear();
  fakeStripe.paymentIntents.create.mockClear();
});

describe("createListingPaymentIntent", () => {
  it("rejects an unauthenticated caller", async () => {
    await expectHttpsError(
      createListingPaymentIntent.run({ data: { listingId: LISTING } } as never),
      "unauthenticated"
    );
  });

  it("rejects a missing listingId", async () => {
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: {},
        auth: { uid: BUYER },
      } as never),
      "invalid-argument"
    );
  });

  it("rejects a listing that doesn't exist", async () => {
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: "does-not-exist" },
        auth: { uid: BUYER },
      } as never),
      "not-found"
    );
  });

  it("rejects a listing that isn't live", async () => {
    seedLiveListing({ status: "sold" });
    seedPayoutReadySeller();
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never),
      "failed-precondition"
    );
  });

  it("rejects buying your own listing", async () => {
    seedLiveListing();
    seedPayoutReadySeller();
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: SELLER },
      } as never),
      "failed-precondition"
    );
  });

  it("rejects a meetup-only listing", async () => {
    seedLiveListing({ delivery: "meetup" });
    seedPayoutReadySeller();
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never),
      "failed-precondition"
    );
  });

  it("rejects a drop whose 8 hours have run out, though its status still reads live", async () => {
    // Nothing ever writes an "expired" status — only the webhook touches
    // status, and only to mark a listing sold. So an ended drop looks live
    // here forever, and without the expiry check we would charge the buyer
    // for something the seller has already watched leave the feed.
    seedLiveListing({
      postedAt: Timestamp.fromMillis(Date.now() - 9 * 60 * 60 * 1000),
      liveForSeconds: 28_800,
    });
    seedPayoutReadySeller();
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never),
      "failed-precondition"
    );
  });

  it("allows a drop still inside its window", async () => {
    seedLiveListing({
      postedAt: Timestamp.fromMillis(Date.now() - 60 * 60 * 1000),
      liveForSeconds: 28_800,
    });
    seedPayoutReadySeller();
    await expect(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never)
    ).resolves.toBeDefined();
  });

  it("falls back to the 8 hour default when liveForSeconds is absent", async () => {
    // Listings created before the field existed carry no liveForSeconds.
    seedLiveListing({
      postedAt: Timestamp.fromMillis(Date.now() - 9 * 60 * 60 * 1000),
    });
    seedPayoutReadySeller();
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never),
      "failed-precondition"
    );
  });

  it("lets a listing with no postedAt through rather than blocking on missing data", async () => {
    // Deliberately fail-open: with no postedAt there is nothing to measure
    // expiry against, and refusing the sale over a field a real listing
    // always has would break checkout on corrupt data instead of on an
    // ended drop.
    seedLiveListing();
    seedPayoutReadySeller();
    await expect(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never)
    ).resolves.toBeDefined();
  });

  it("rejects a seller who hasn't finished payout onboarding", async () => {
    seedLiveListing();
    fakeDb.seed(`users/${SELLER}`, { stripeAccountId: "acct_seller_1", payoutsEnabled: false });
    await expectHttpsError(
      createListingPaymentIntent.run({
        data: { listingId: LISTING },
        auth: { uid: BUYER },
      } as never),
      "failed-precondition"
    );
  });

  it("creates a destination-charge PaymentIntent for a valid purchase", async () => {
    seedLiveListing({ priceCents: 2500 });
    seedPayoutReadySeller();

    const result = (await createListingPaymentIntent.run({
      data: { listingId: LISTING },
      auth: { uid: BUYER },
    } as never)) as { clientSecret: string };

    expect(result.clientSecret).toBe("pi_test_123_secret_abc");
    expect(fakeStripe.paymentIntents.create).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 2500,
        currency: "gbp",
        application_fee_amount: 200, // 8% of 2500
        transfer_data: { destination: "acct_seller_1" },
        metadata: { listingId: LISTING, buyerId: BUYER, sellerId: SELLER },
      })
    );
  });

  it("charges the accepted offer price instead of the listing price", async () => {
    seedLiveListing({ priceCents: 2500 });
    seedPayoutReadySeller();
    fakeDb.seed(`offers/${LISTING}_${BUYER}`, {
      listingId: LISTING,
      buyerId: BUYER,
      sellerId: SELLER,
      offerCents: 2000,
      status: "accepted",
    });

    await createListingPaymentIntent.run({
      data: { listingId: LISTING },
      auth: { uid: BUYER },
    } as never);

    expect(fakeStripe.paymentIntents.create).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 2000,
        application_fee_amount: 160, // 8% of 2000, not of the original 2500
      })
    );
  });

  it("ignores a pending offer and charges the full listing price", async () => {
    seedLiveListing({ priceCents: 2500 });
    seedPayoutReadySeller();
    fakeDb.seed(`offers/${LISTING}_${BUYER}`, {
      listingId: LISTING,
      buyerId: BUYER,
      sellerId: SELLER,
      offerCents: 2000,
      status: "pending",
    });

    await createListingPaymentIntent.run({
      data: { listingId: LISTING },
      auth: { uid: BUYER },
    } as never);

    expect(fakeStripe.paymentIntents.create).toHaveBeenCalledWith(
      expect.objectContaining({ amount: 2500 })
    );
  });

  it("ignores a declined offer and charges the full listing price", async () => {
    seedLiveListing({ priceCents: 2500 });
    seedPayoutReadySeller();
    fakeDb.seed(`offers/${LISTING}_${BUYER}`, {
      listingId: LISTING,
      buyerId: BUYER,
      sellerId: SELLER,
      offerCents: 2000,
      status: "declined",
    });

    await createListingPaymentIntent.run({
      data: { listingId: LISTING },
      auth: { uid: BUYER },
    } as never);

    expect(fakeStripe.paymentIntents.create).toHaveBeenCalledWith(
      expect.objectContaining({ amount: 2500 })
    );
  });
});
