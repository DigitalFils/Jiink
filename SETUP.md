# S8LL — payments setup

The app and backend code are complete and compile cleanly, but nothing here
actually moves money until two accounts exist. Both are free to create and
neither requires real business verification in test mode.

## 1. Stripe

1. Sign up at [stripe.com](https://dashboard.stripe.com/register) — a few
   minutes, email + password.
2. In the Dashboard, go to **Settings → Connect** and enable Connect.
3. Go to **Developers → API keys** and copy the **test-mode** publishable
   key (`pk_test_...`) and secret key (`sk_test_...`). Never use the live
   keys until you're actually ready to take real payments.

## 2. Firebase

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Upgrade it to the **Blaze** (pay-as-you-go) plan — Cloud Functions
   require it. It's free at this scale; it just needs a card on file.
3. In the project, enable **Authentication** (Email/Password provider),
   **Firestore Database**, and **Storage**.

## 3. Wire the project up

From the repo root:

```sh
npm install -g firebase-tools
firebase login
firebase use --add          # pick your new project, alias it "staging"
```

This replaces the placeholder in `.firebaserc`. (Naming it `staging` now,
not `default`, is what makes step 7 — adding a separate `production`
project later — a clean addition instead of a rename.)

From `app/`:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

This overwrites `app/lib/firebase_options.dart` with your project's real
values.

In `app/lib/main.dart`, replace `_stripePublishableKey` with your real test
publishable key.

## 4. Set the backend's secrets and deploy

```sh
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET   # see step 5

firebase deploy --only functions,firestore:rules,storage
```

Deploy will also prompt for `STRIPE_MODE` the first time — answer `test`
for now. It's not a secret, just a safety check (see step 7) that the key
you just set above is actually a test key; the deploy fails loudly instead
of silently if it isn't.

## 5. Point Stripe at the webhook

After deploying, `firebase deploy` prints the `stripeWebhook` function's
URL. In the Stripe Dashboard, go to **Developers → Webhooks → Add
endpoint**, paste that URL, and subscribe it to `account.updated` and
`payment_intent.succeeded`. Stripe gives you a signing secret
(`whsec_...`) — that's the `STRIPE_WEBHOOK_SECRET` from step 4.

## 6. Monitoring & alerts

`stripeWebhook` logs every event it processes — every log line carries
`component: "stripeWebhook"` plus `severity` (INFO/WARNING/ERROR), which
Cloud Logging understands natively without any extra setup. Worth alerting
on before this takes real payments:

- **`severity>=ERROR`** — something in the payment flow actually failed
  (a Firestore write, most likely). The function returns 500 on this so
  Stripe retries automatically, but you want to know if it's happening.
- **The message `payment_intent.succeeded missing expected metadata`**
  specifically — this means a bug in `checkout.ts` stopped setting
  required metadata, not a Stripe hiccup; retries will never fix it.

To get an email on either, no extra service required:

1. Firebase/GCP Console → **Logging → Logs Explorer**.
2. Query: `severity>=ERROR AND resource.labels.function_name="stripeWebhook"`
3. **Create alert** → pick email as the notification channel → save.

Cloud Logging keeps 30 days of logs by default, which is plenty at
pop-up scale — nothing further to provision.

## 7. Before you take a real payment: separate test and live

Everything above sets up one Firebase project running Stripe in test mode
— the right way to build and demo this. Before switching to live keys,
don't just swap the secret on that same project: create a second one.

1. `firebase use --add` again, pointing at a **new** Firebase project,
   aliased `production`.
2. In Stripe, toggle **Viewing test data** off in the Dashboard, and repeat
   step 1's key setup for the live key (`sk_live_...`) and step 5's webhook
   for a second endpoint — Stripe requires separate webhook endpoints and
   signing secrets per mode.
3. Set that project's secrets and mode:
   ```sh
   firebase functions:secrets:set STRIPE_SECRET_KEY --project production
   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET --project production
   ```
   When deploy prompts for `STRIPE_MODE` on this project, answer `live`.

That prompt is the actual safety net: `stripeClient.ts` refuses to start
if the key it finds doesn't match the mode you declared for that
environment — a live key deployed to a project you meant to keep in test
mode (or a stale test key deployed to `production`) fails loudly at the
first request instead of silently doing the wrong thing with real money.
Deploy to whichever project with `--project staging` / `--project
production`; day-to-day development stays on `staging`.

## What's still manual after this

- `app/lib/screens/payouts_setup_screen.dart` uses placeholder
  `return_url`/`refresh_url` values (`https://s8ll.app/...`). Point them at
  a real page, or set up Android App Links, so Stripe can hand a seller
  back into the app after onboarding instead of leaving them in a browser
  tab.
- The 8% platform fee lives in `functions/src/constants.ts`
  (`PLATFORM_FEE_BPS`) — change it there if the number in the pitch deck
  changes.
