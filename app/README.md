# S8LL

Snap it, sell it. A mobile-first, social-native marketplace app: point the
camera, publish a listing in seconds, done.

Backed by Firebase (auth, Firestore, Storage) and Stripe Connect for
marketplace payments. Core loop: **Sign in → Feed → Camera → Publish →
Buy / Message**.

See [`SETUP.md`](../SETUP.md) at the repo root for the Stripe and Firebase
accounts you need before this actually runs — the code compiles and
analyzes cleanly without them, but Firebase.initializeApp() needs real
project config to work at runtime.

## Getting Started

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
