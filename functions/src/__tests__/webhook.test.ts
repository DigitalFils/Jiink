import { EventEmitter } from "events";
import { FakeFirestore } from "./helpers/fakeFirestore";
import { makeFakeStripe } from "./helpers/fakeStripe";

const fakeDb = new FakeFirestore();
const fakeStripe = makeFakeStripe();

jest.mock("../admin", () => ({ db: fakeDb }));
jest.mock("../stripeClient", () => ({
  stripeSecretKey: { value: () => "sk_test_fake" },
  stripeWebhookSecret: { value: () => "whsec_fake" },
  getStripeClient: () => fakeStripe,
}));

import { stripeWebhook } from "../webhook";

// firebase-functions v2's onRequest wrapper instruments the response with
// res.on('finish', ...) for tracing, so the fake needs to be a real
// EventEmitter, not just a plain object with status()/send().
class FakeResponse extends EventEmitter {
  _code = 0;
  _body: unknown;
  status(code: number) {
    this._code = code;
    return this;
  }
  send(body: unknown) {
    this._body = body;
    this.emit("finish");
  }
}

function makeRes() {
  return new FakeResponse();
}

const LISTING = "listing-1";
const BUYER = "buyer-1";
const SELLER = "seller-1";

function makePaymentIntentEvent(overrides: Record<string, unknown> = {}) {
  return {
    type: "payment_intent.succeeded",
    data: {
      object: {
        id: "pi_test_1",
        amount: 2500,
        application_fee_amount: 200,
        metadata: { listingId: LISTING, buyerId: BUYER, sellerId: SELLER },
        ...overrides,
      },
    },
  };
}

beforeEach(() => {
  fakeDb.store.clear();
  fakeStripe.webhooks.constructEvent.mockReset();
});

describe("stripeWebhook", () => {
  it("rejects a request with no Stripe-Signature header", async () => {
    const res = makeRes();
    await stripeWebhook({ headers: {}, rawBody: Buffer.from("{}") } as never, res as never);
    expect(res._code).toBe(400);
  });

  it("rejects a request whose signature doesn't verify", async () => {
    fakeStripe.webhooks.constructEvent.mockImplementation(() => {
      throw new Error("bad signature");
    });
    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "bad" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );
    expect(res._code).toBe(400);
  });

  it("marks a seller's payouts enabled on account.updated", async () => {
    fakeDb.seed(`users/${SELLER}`, { stripeAccountId: "acct_1", payoutsEnabled: false });
    fakeStripe.webhooks.constructEvent.mockReturnValue({
      type: "account.updated",
      data: { object: { id: "acct_1", charges_enabled: true, payouts_enabled: true } },
    });

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(fakeDb.store.get(`users/${SELLER}`)).toMatchObject({ payoutsEnabled: true });
  });

  it("marks the listing sold and writes an order on payment_intent.succeeded", async () => {
    fakeDb.seed(`listings/${LISTING}`, { status: "live", sellerId: SELLER });
    fakeStripe.webhooks.constructEvent.mockReturnValue(makePaymentIntentEvent());

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(fakeDb.store.get(`listings/${LISTING}`)).toMatchObject({ status: "sold" });
    expect(fakeDb.store.get("orders/pi_test_1")).toMatchObject({
      listingId: LISTING,
      buyerId: BUYER,
      sellerId: SELLER,
      amountCents: 2500,
      applicationFeeCents: 200,
      status: "paid",
    });
  });

  it("is idempotent: a redelivered event against an already-sold listing writes no order", async () => {
    // Simulates Stripe retrying the same event after it already succeeded once.
    fakeDb.seed(`listings/${LISTING}`, { status: "sold", sellerId: SELLER, soldAt: new Date() });
    fakeStripe.webhooks.constructEvent.mockReturnValue(makePaymentIntentEvent());

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(fakeDb.store.has("orders/pi_test_1")).toBe(false);
  });

  it("acknowledges an event type it doesn't handle without side effects", async () => {
    fakeStripe.webhooks.constructEvent.mockReturnValue({
      type: "charge.refunded",
      data: { object: {} },
    });

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(fakeDb.store.size).toBe(0);
  });
});
