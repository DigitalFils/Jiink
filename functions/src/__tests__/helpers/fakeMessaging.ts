/** A hand-rolled stand-in for the slice of firebase-admin's Messaging our
 * functions actually call. Defaults to reporting every send as a success;
 * tests override `sendEachForMulticast`'s mock implementation to exercise
 * the stale-token-pruning path. */
interface FakeSendResponse {
  success: boolean;
  error?: { code: string };
}

export function makeFakeMessaging() {
  return {
    sendEachForMulticast: jest.fn(async (message: { tokens: string[] }) => ({
      responses: message.tokens.map((): FakeSendResponse => ({ success: true })),
      successCount: message.tokens.length,
      failureCount: 0,
    })),
  };
}

export type FakeMessaging = ReturnType<typeof makeFakeMessaging>;
