import { assertStripeKeyMatchesMode } from "../stripeClient";

describe("assertStripeKeyMatchesMode", () => {
  it("allows a test key in test mode", () => {
    expect(() => assertStripeKeyMatchesMode("sk_test_abc123", "test")).not.toThrow();
  });

  it("allows a live key in live mode", () => {
    expect(() => assertStripeKeyMatchesMode("sk_live_abc123", "live")).not.toThrow();
  });

  it("refuses a live key when the environment says test — the dangerous direction", () => {
    expect(() => assertStripeKeyMatchesMode("sk_live_abc123", "test")).toThrow(/STRIPE_MODE/);
  });

  it("refuses a test key when the environment says live", () => {
    expect(() => assertStripeKeyMatchesMode("sk_test_abc123", "live")).toThrow(/STRIPE_MODE/);
  });

  it("refuses an unset or misspelled mode outright", () => {
    expect(() => assertStripeKeyMatchesMode("sk_test_abc123", "")).toThrow(/must be "test" or "live"/);
    expect(() => assertStripeKeyMatchesMode("sk_test_abc123", "Live")).toThrow(/must be "test" or "live"/);
  });
});
