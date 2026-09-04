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
});
