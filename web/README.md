# S8LL — web

The Next.js marketplace app: React front end, App Router API routes, Prisma
over SQLite. It shares a name and a design language with the Flutter app in
[`../app`](../app) but is a separate codebase — the Flutter app talks to
Firebase, this one talks to the routes under `src/app/api`.

## Running it

```sh
npm install
cp .env.example .env     # DATABASE_URL, relative to prisma/
npm run db:setup         # create the schema, generate the client, seed demo data
npm run dev              # http://localhost:3000
```

`npm run db:setup` is destructive: the seed clears every table before it
writes. Use `npm run db:push` on its own to apply a schema change without
losing data.

The database file lives at `db/custom.db` and is **not** committed. It is
written on every sign-in, so a tracked copy would show up dirty after any
use of the app; `npm run db:seed` rebuilds it.

## Accounts and sessions

Sign-in is email and password, held in an opaque server-side session.

- Passwords are hashed with scrypt (`node:crypto`), salted per user, and
  compared with `timingSafeEqual`. Node's default cost parameters are
  roughly 16MB of memory per hash.
- The session cookie carries a 256-bit random token; the `Session` table
  stores only its SHA-256 digest, so a dump of that table grants nobody a
  session. Signing out deletes the row, not just the cookie, which means a
  token copied off the device beforehand is dead too.
- Credential routes are rate limited per IP — in production, 10 sign-ins
  per 15 minutes and 5 registrations per hour. The limits are raised
  outside production so the end-to-end suite can run twice in an hour; see
  `LIMITS` in `src/lib/auth.ts`. The limiter is **in-memory**, so it is per
  process and does not survive a restart. That is fine for one instance and
  needs to move to Redis or the database before there are two.

The seeded demo users have no email and no password hash, so none of them
can be signed in to. Create an account instead.

### What the routes owe you

| Route | |
| --- | --- |
| `POST /api/auth/register` | 201 and a session, or 400/409 with the offending `field` |
| `POST /api/auth/login` | 200 and a session, or 401 — one message for a wrong password and an unknown email alike |
| `POST /api/auth/logout` | 200, session row deleted |
| `GET /api/auth/me` | 200 with `user`, or `user: null` — not being signed in is an answer, not an error |

`GET /api/wallet` and `POST /api/products` are scoped to the session user
and answer 401 without one.

## Tests

```sh
npm run dev &
node scripts/e2e/auth.mjs          # or pass a base URL
```

25 checks against the real HTTP surface: registration validation, session
issue and revocation, cookie replay after sign-out, email enumeration
through the login error, and the unauthenticated `POST /api/wallet` that
used to mint money. No framework and no dependencies — it runs anywhere
Node does, and it is what CI runs.

## Known gaps

These are deliberate and load-bearing, not oversights:

- **`POST /api/wallet` returns 501.** It used to accept an unauthenticated
  request and increment a balance by whatever number it was sent. There is
  no payment provider wired up yet, so there is no such thing as a genuine
  top-up — any endpoint that raises a balance without money arriving is a
  mint. It comes back when Stripe does, driven by a verified webhook rather
  than by the client.
- **The wallet's saved cards are decoration.** "Visa •• 4521", WeChat Pay,
  Yandex Money and Apple Pay are hardcoded in `wallet-screen.tsx` and
  belong to nobody.
- **"Dewu Authentication" on the profile menu** names a third party and a
  verification service this app does not have.
- **SQLite, single file.** Fine for one process; it will not survive being
  deployed to more than one.
