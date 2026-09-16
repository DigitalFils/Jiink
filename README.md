# Jiink

S8LL — a marketplace where every listing is a drop that runs for eight hours
and then expires.

| | |
| --- | --- |
| [`app/`](app) | The Flutter app (Android/iOS), backed by Firebase Auth, Firestore, Storage and Cloud Functions. |
| [`functions/`](functions) | Cloud Functions — Stripe Connect checkout, the payment webhook and escrow refunds. |
| [`firestore.rules`](firestore.rules), [`firestore-tests/`](firestore-tests) | Firestore security rules and their test suite. |
| [`web/`](web) | The Next.js web app: React front end, App Router API routes, Prisma over SQLite. See [`web/README.md`](web/README.md). |
| [`ui-preview/`](ui-preview) | A design harness that renders the Flutter screens against fixture data, for screenshotting in CI. |
| [`prototype/`](prototype) | The original static mockups. |

`app/` and `web/` share a name and a design language but are separate
codebases with separate backends — the Flutter app talks to Firebase, the
web app talks to its own API routes.
