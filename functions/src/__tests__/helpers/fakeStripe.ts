/** A hand-rolled stand-in for the handful of Stripe SDK calls our functions make. */
export function makeFakeStripe() {
  return {
    paymentIntents: {
      create: jest.fn(async (params: Record<string, unknown>) => ({
        id: "pi_test_123",
        client_secret: "pi_test_123_secret_abc",
        ...params,
      })),
    },
    refunds: {
      create: jest.fn(async (params: Record<string, unknown>) => ({
        id: "re_test_123",
        status: "succeeded",
        ...params,
      })),
    },
    accounts: {
      create: jest.fn(async (params: Record<string, unknown>) => ({
        id: "acct_test_123",
        ...params,
      })),
    },
    accountLinks: {
      create: jest.fn(async (params: Record<string, unknown>) => ({
        url: "https://connect.stripe.com/setup/test",
        ...params,
      })),
    },
    webhooks: {
      constructEvent: jest.fn(),
    },
  };
}

export type FakeStripe = ReturnType<typeof makeFakeStripe>;
