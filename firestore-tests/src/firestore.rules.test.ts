import { readFileSync } from "fs";
import path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

let testEnv: RulesTestEnvironment;

const ALICE = "alice";
const BOB = "bob";
const CAROL = "carol";

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-s8ll-rules-test",
    firestore: {
      rules: readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

type TestFirestore = ReturnType<RulesTestEnvironment["unauthenticatedContext"]>["firestore"];

/** Writes data directly, bypassing security rules — for test setup only. */
async function seed(fn: (db: ReturnType<TestFirestore>) => Promise<unknown>) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

function dbAs(uid: string | null) {
  return uid === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();
}

describe("users/{uid}", () => {
  it("lets a user read and write their own profile", async () => {
    const alice = dbAs(ALICE);
    await assertSucceeds(alice.doc(`users/${ALICE}`).set({ displayName: "Alice" }));
    await assertSucceeds(alice.doc(`users/${ALICE}`).get());
  });

  it("never exposes another user's profile — the Stripe account id must stay private", async () => {
    await seed((db) => db.doc(`users/${ALICE}`).set({ stripeAccountId: "acct_secret" }));
    const bob = dbAs(BOB);
    await assertFails(bob.doc(`users/${ALICE}`).get());
    await assertFails(bob.doc(`users/${ALICE}`).set({ payoutsEnabled: true }));
  });

  it("blocks an unauthenticated caller entirely", async () => {
    const anon = dbAs(null);
    await assertFails(anon.doc(`users/${ALICE}`).set({ displayName: "x" }));
    await assertFails(anon.doc(`users/${ALICE}`).get());
  });
});

describe("listings/{listingId}", () => {
  it("lets any signed-in user read the public feed", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertSucceeds(dbAs(BOB).doc("listings/l1").get());
  });

  it("blocks reads for a signed-out visitor", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertFails(dbAs(null).doc("listings/l1").get());
  });

  it("lets a user create a listing under their own sellerId as 'live'", async () => {
    await assertSucceeds(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: ALICE, status: "live", priceCents: 500 })
    );
  });

  it("blocks creating a listing under someone else's sellerId", async () => {
    await assertFails(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: BOB, status: "live" })
    );
  });

  it("blocks creating a listing with a status other than 'live'", async () => {
    await assertFails(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: ALICE, status: "sold" })
    );
  });

  it("lets the owner edit their own listing's non-status fields", async () => {
    await seed((db) =>
      db.doc("listings/l1").set({ sellerId: ALICE, status: "live", priceCents: 500 })
    );
    await assertSucceeds(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: ALICE, status: "live", priceCents: 450 })
    );
  });

  it("blocks the owner from flipping status themselves — only the payment webhook may", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertFails(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: ALICE, status: "sold" })
    );
  });

  it("blocks the owner from reassigning sellerId to someone else", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertFails(
      dbAs(ALICE).doc("listings/l1").set({ sellerId: BOB, status: "live" })
    );
  });

  it("blocks a non-owner from editing someone else's listing", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertFails(
      dbAs(BOB).doc("listings/l1").set({ sellerId: ALICE, status: "live", priceCents: 1 })
    );
  });

  it("blocks deletion outright, even by the owner", async () => {
    await seed((db) => db.doc("listings/l1").set({ sellerId: ALICE, status: "live" }));
    await assertFails(dbAs(ALICE).doc("listings/l1").delete());
  });

  it("lets a non-owner watch a listing — the only signal they may leave on it", async () => {
    await seed((db) =>
      db.doc("listings/l1").set({ sellerId: ALICE, status: "live", watcherIds: [] })
    );
    await assertSucceeds(dbAs(BOB).doc("listings/l1").update({ watcherIds: [BOB] }));
  });

  it("lets a non-owner unwatch a listing they're already watching", async () => {
    await seed((db) =>
      db.doc("listings/l1").set({ sellerId: ALICE, status: "live", watcherIds: [BOB] })
    );
    await assertSucceeds(dbAs(BOB).doc("listings/l1").update({ watcherIds: [] }));
  });

  it("blocks using the watch path to sneak in any other field change", async () => {
    await seed((db) =>
      db.doc("listings/l1").set({ sellerId: ALICE, status: "live", priceCents: 500, watcherIds: [] })
    );
    await assertFails(
      dbAs(BOB).doc("listings/l1").update({ watcherIds: [BOB], priceCents: 1 })
    );
    await assertFails(
      dbAs(BOB).doc("listings/l1").update({ watcherIds: [BOB], status: "sold" })
    );
  });
});

describe("chatThreads/{threadId}", () => {
  const THREAD = "listing1_bob";

  it("lets a participant create a thread they belong to", async () => {
    await assertSucceeds(
      dbAs(BOB)
        .doc(`chatThreads/${THREAD}`)
        .set({ participantIds: [ALICE, BOB], listingId: "listing1" })
    );
  });

  it("blocks creating a thread you're not a participant of", async () => {
    await assertFails(
      dbAs(CAROL)
        .doc(`chatThreads/${THREAD}`)
        .set({ participantIds: [ALICE, BOB], listingId: "listing1" })
    );
  });

  it("lets participants read and update the thread, blocks everyone else", async () => {
    await seed((db) =>
      db.doc(`chatThreads/${THREAD}`).set({ participantIds: [ALICE, BOB] })
    );
    await assertSucceeds(dbAs(ALICE).doc(`chatThreads/${THREAD}`).get());
    await assertSucceeds(dbAs(BOB).doc(`chatThreads/${THREAD}`).update({ lastMessageText: "hi" }));
    await assertFails(dbAs(CAROL).doc(`chatThreads/${THREAD}`).get());
  });

  describe("messages subcollection", () => {
    beforeEach(async () => {
      await seed((db) => db.doc(`chatThreads/${THREAD}`).set({ participantIds: [ALICE, BOB] }));
    });

    it("lets a participant post a message as themselves", async () => {
      await assertSucceeds(
        dbAs(BOB)
          .doc(`chatThreads/${THREAD}/messages/m1`)
          .set({ senderId: BOB, text: "hey" })
      );
    });

    it("blocks posting a message impersonating another sender", async () => {
      await assertFails(
        dbAs(BOB)
          .doc(`chatThreads/${THREAD}/messages/m1`)
          .set({ senderId: ALICE, text: "hey" })
      );
    });

    it("blocks a non-participant from reading or posting", async () => {
      await seed((db) =>
        db.doc(`chatThreads/${THREAD}/messages/m1`).set({ senderId: BOB, text: "hey" })
      );
      await assertFails(dbAs(CAROL).doc(`chatThreads/${THREAD}/messages/m1`).get());
      await assertFails(
        dbAs(CAROL).doc(`chatThreads/${THREAD}/messages/m2`).set({ senderId: CAROL, text: "hi" })
      );
    });

    it("blocks editing or deleting a message once sent, even by its sender", async () => {
      await seed((db) =>
        db.doc(`chatThreads/${THREAD}/messages/m1`).set({ senderId: BOB, text: "hey" })
      );
      await assertFails(dbAs(BOB).doc(`chatThreads/${THREAD}/messages/m1`).update({ text: "edited" }));
      await assertFails(dbAs(BOB).doc(`chatThreads/${THREAD}/messages/m1`).delete());
    });
  });
});

describe("orders/{orderId}", () => {
  beforeEach(async () => {
    await seed((db) => db.doc("orders/o1").set({ buyerId: BOB, sellerId: ALICE }));
  });

  it("lets the buyer and the seller read the order", async () => {
    await assertSucceeds(dbAs(BOB).doc("orders/o1").get());
    await assertSucceeds(dbAs(ALICE).doc("orders/o1").get());
  });

  it("blocks a third party from reading the order", async () => {
    await assertFails(dbAs(CAROL).doc("orders/o1").get());
  });

  it("blocks every client write — orders only ever come from the webhook", async () => {
    await assertFails(dbAs(BOB).doc("orders/o1").update({ status: "refunded" }));
    await assertFails(dbAs(ALICE).doc("orders/o2").set({ buyerId: BOB, sellerId: ALICE }));
    await assertFails(dbAs(BOB).doc("orders/o1").delete());
  });
});

describe("reviews/{listingId}", () => {
  const LISTING = "listing-1";
  const ORDER = "order-1";

  beforeEach(async () => {
    await seed((db) =>
      db.doc(`orders/${ORDER}`).set({ buyerId: BOB, sellerId: ALICE, listingId: LISTING })
    );
  });

  function validReview(overrides: Record<string, unknown> = {}) {
    return {
      sellerId: ALICE,
      buyerId: BOB,
      orderId: ORDER,
      rating: 5,
      comment: "Great seller, fast shipping",
      ...overrides,
    };
  }

  it("lets the real buyer of a completed sale leave a review", async () => {
    await assertSucceeds(dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview()));
  });

  it("rejects a rating outside 1-5", async () => {
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ rating: 0 })));
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ rating: 6 })));
  });

  it("rejects a non-integer rating", async () => {
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ rating: "5" })));
  });

  it("blocks writing a review under someone else's identity", async () => {
    // CAROL didn't buy anything — there's no order making her eligible —
    // and even naming herself as buyer doesn't help, since the order this
    // points at says the buyer was BOB, not her.
    await assertFails(
      dbAs(CAROL).doc(`reviews/${LISTING}`).set(validReview({ buyerId: CAROL }))
    );
  });

  it("blocks a fabricated review with an orderId that doesn't back it up", async () => {
    await assertFails(
      dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ orderId: "no-such-order" }))
    );
  });

  it("blocks a review pointing at an order for a different listing", async () => {
    await seed((db) =>
      db.doc("orders/order-2").set({ buyerId: BOB, sellerId: ALICE, listingId: "listing-2" })
    );
    await assertFails(
      dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ orderId: "order-2" }))
    );
  });

  it("blocks attributing the review to a seller the order doesn't name", async () => {
    await assertFails(
      dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ sellerId: CAROL }))
    );
  });

  it("blocks editing or replacing a review once it's been left", async () => {
    await seed((db) => db.doc(`reviews/${LISTING}`).set(validReview()));
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).update({ rating: 1 }));
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).set(validReview({ rating: 1 })));
    await assertFails(dbAs(BOB).doc(`reviews/${LISTING}`).delete());
  });

  it("lets any signed-in user read reviews", async () => {
    await seed((db) => db.doc(`reviews/${LISTING}`).set(validReview()));
    await assertSucceeds(dbAs(CAROL).doc(`reviews/${LISTING}`).get());
  });
});
