# S8LL v2 — UI preview

The v2 design prototype, made to compile. **This is a look-and-feel build,
not the product.** Nothing here talks to a backend: every listing, price,
balance, order and countdown on screen comes from `lib/data/sample_data.dart`.
There is no sign-in, no database, no payments, and nothing you do in it is
saved.

The working app — Firebase Auth, Firestore, Stripe Connect payments, chat,
offers, reviews, push — lives in `../app`. Wiring these screens onto that
backend is the job this preview exists to make reviewable, screen by screen.

## What compiling it needed

The zip did not build against current Flutter. Four API renames, nine errors:

- `CardTheme` → `CardThemeData`, `TabBarTheme` → `TabBarThemeData` and
  `DialogTheme` → `DialogThemeData` on `ThemeData` — the theme data classes
  were split off the widget types.
- `ChipThemeData` has no `selectedLabelStyle`; the selected-state label is
  `secondaryLabelStyle`. (`BottomNavigationBarThemeData` *does* have
  `selectedLabelStyle`, so this rename is per-call-site, not global.)

## Claims on these screens that the product cannot currently keep

The onboarding and product screens promise things that do not exist behind
them. These need removing or building before any of this reaches a buyer:

- "Every item verified by our expert team", "Dewu-grade authentication with
  detailed certificates" — there is no authentication team or process.
- "10x money-back guarantee" — no such policy exists, and it is a consumer
  guarantee, not a slogan.
- AR try-on, live-stream commerce and group buying are screens with no
  service behind them.

Fonts come from `google_fonts`, which downloads at runtime. On venue wifi, or
offline, the app silently falls back to the system font. The real app bundles
Inter in `app/assets/fonts` for exactly this reason.
