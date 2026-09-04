import { FakeFirestore } from "./helpers/fakeFirestore";
import { makeFakeStripe } from "./helpers/fakeStripe";

const fakeDb = new FakeFirestore();
const fakeStripe = makeFakeStripe();

jest.mock("../admin", () => ({ db: fakeDb }));
jest.mock("../stripeClient", () => ({
  stripeSecretKey: { value: () => "sk_test_fake" },
  getStripeClient: () => fakeStripe,
}));

import { createPayoutOnboardingLink } from "../connect";

const SELLER = "seller-1";
const urls = { returnUrl: "https://s8ll.app/return", refreshUrl: "https://s8ll.app/refresh" };

async function expectHttpsError(promise: Promise<unknown>, code: string) {
  await expect(promise).rejects.toMatchObject({ code });
}

beforeEach(() => {
  fakeDb.store.clear();
  fakeStripe.accounts.create.mockClear();
  fakeStripe.accountLinks.create.mockClear();
});

describe("createPayoutOnboardingLink", () => {
  it("rejects an unauthenticated caller", async () => {
    await expectHttpsError(
      createPayoutOnboardingLink.run({ data: urls } as never),
      "unauthenticated"
    );
  });

  it("rejects missing return/refresh URLs", async () => {
    await expectHttpsError(
      createPayoutOnboardingLink.run({ data: {}, auth: { uid: SELLER } } as never),
      "invalid-argument"
    );
  });

  it("creates a new Express account for a first-time seller", async () => {
    const result = (await createPayoutOnboardingLink.run({
      data: urls,
      auth: { uid: SELLER, token: { email: "seller@example.com" } },
    } as never)) as { url: string };

    expect(result.url).toBe("https://connect.stripe.com/setup/test");
    expect(fakeStripe.accounts.create).toHaveBeenCalledTimes(1);
    const seeded = fakeDb.store.get(`users/${SELLER}`);
    expect(seeded).toMatchObject({ stripeAccountId: "acct_test_123", payoutsEnabled: false });
  });

  it("reuses an existing Stripe account instead of creating a second one", async () => {
    fakeDb.seed(`users/${SELLER}`, { stripeAccountId: "acct_existing", payoutsEnabled: true });

    await createPayoutOnboardingLink.run({
      data: urls,
      auth: { uid: SELLER },
    } as never);

    expect(fakeStripe.accounts.create).not.toHaveBeenCalled();
    expect(fakeStripe.accountLinks.create).toHaveBeenCalledWith(
      expect.objectContaining({ account: "acct_existing" })
    );
  });
});
