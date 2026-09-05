import { EventEmitter } from "events";
import { logger } from "firebase-functions";
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

afterEach(() => {
  jest.restoreAllMocks();
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
    const infoSpy = jest.spyOn(logger, "info").mockImplementation(() => undefined);
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
    expect(infoSpy).toHaveBeenCalledWith(
      "Ignoring unhandled Stripe event type",
      expect.objectContaining({ eventType: "charge.refunded" })
    );
  });

  it("logs loudly and acks without writing when a payment_intent.succeeded is missing metadata", async () => {
    const errorSpy = jest.spyOn(logger, "error").mockImplementation(() => undefined);
    fakeStripe.webhooks.constructEvent.mockReturnValue(
      makePaymentIntentEvent({ metadata: { listingId: LISTING } }) // buyerId/sellerId missing
    );

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(fakeDb.store.size).toBe(0);
    expect(errorSpy).toHaveBeenCalledWith(
      "payment_intent.succeeded missing expected metadata",
      expect.objectContaining({ paymentIntentId: "pi_test_1" })
    );
  });

  it("logs a warning when account.updated references an account with no matching user", async () => {
    const warnSpy = jest.spyOn(logger, "warn").mockImplementation(() => undefined);
    fakeStripe.webhooks.constructEvent.mockReturnValue({
      type: "account.updated",
      data: { object: { id: "acct_orphan", charges_enabled: true, payouts_enabled: true } },
    });

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(200);
    expect(warnSpy).toHaveBeenCalledWith(
      "account.updated for a Stripe account with no matching user",
      expect.objectContaining({ stripeAccountId: "acct_orphan" })
    );
  });

  it("returns 500 and logs an error when processing throws, so Stripe retries", async () => {
    const errorSpy = jest.spyOn(logger, "error").mockImplementation(() => undefined);
    jest.spyOn(fakeDb, "runTransaction").mockRejectedValueOnce(new Error("Firestore is down"));
    fakeDb.seed(`listings/${LISTING}`, { status: "live", sellerId: SELLER });
    fakeStripe.webhooks.constructEvent.mockReturnValue(makePaymentIntentEvent());

    const res = makeRes();
    await stripeWebhook(
      { headers: { "stripe-signature": "ok" }, rawBody: Buffer.from("{}") } as never,
      res as never
    );

    expect(res._code).toBe(500);
    expect(errorSpy).toHaveBeenCalledWith(
      "Failed to process Stripe webhook event",
      expect.objectContaining({ error: "Firestore is down" })
    );
  });
});
