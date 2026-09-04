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
firebase use --add          # pick your new project, alias it "default"
```

This replaces the placeholder in `.firebaserc`.

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

## 5. Point Stripe at the webhook

After deploying, `firebase deploy` prints the `stripeWebhook` function's
URL. In the Stripe Dashboard, go to **Developers → Webhooks → Add
endpoint**, paste that URL, and subscribe it to `account.updated` and
`payment_intent.succeeded`. Stripe gives you a signing secret
(`whsec_...`) — that's the `STRIPE_WEBHOOK_SECRET` from step 4.

## What's still manual after this

- `app/lib/screens/payouts_setup_screen.dart` uses placeholder
  `return_url`/`refresh_url` values (`https://s8ll.app/...`). Point them at
  a real page, or set up Android App Links, so Stripe can hand a seller
  back into the app after onboarding instead of leaving them in a browser
  tab.
- The 8% platform fee lives in `functions/src/constants.ts`
  (`PLATFORM_FEE_BPS`) — change it there if the number in the pitch deck
  changes.
