#!/usr/bin/env bash
# Package the deployable S8LL web app source bundle
# Includes: source, prisma schema + seed, mini live-service, gateway config, deploy guide
# Excludes: node_modules, .next, .git, logs, work files, real .env
set -euo pipefail

ROOT=/home/z/my-project
STAGE=$(mktemp -d)/s8ll-web
OUT=$ROOT/download/s8ll_web_deploy.zip
mkdir -p "$STAGE"

cd "$ROOT"

# ---- source & config ----
cp -r src "$STAGE"/
cp -r public "$STAGE"/
cp -r prisma "$STAGE"/
# mini-service source without its node_modules (install on target host)
mkdir -p "$STAGE"/mini-services/live-service
cp mini-services/live-service/package.json mini-services/live-service/index.ts mini-services/live-service/tsconfig.json "$STAGE"/mini-services/live-service/ 2>/dev/null || true
mkdir -p "$STAGE"/scripts
cp scripts/seed.ts "$STAGE"/scripts/seed.ts
cp scripts/e2e-regression.sh scripts/gen-brand-assets.py "$STAGE"/scripts/ 2>/dev/null || true
cp package.json next.config.ts tsconfig.json tailwind.config.ts postcss.config.mjs eslint.config.mjs components.json Caddyfile "$STAGE"/
cp next-env.d.ts "$STAGE"/ 2>/dev/null || true

# ---- seeded database (demo data, ready to run) ----
mkdir -p "$STAGE"/db
cp db/custom.db "$STAGE"/db/custom.db

# ---- env example (no secrets committed) ----
cat > "$STAGE"/.env.example <<'EOF'
# SQLite database (use an absolute path on your deployment host)
DATABASE_URL=file:/absolute/path/to/s8ll-web/db/custom.db
# Optional: GLM API key for the AI assistant (/api/ai)
# GLM_API_KEY=your-key
EOF

# ---- deploy guide ----
cat > "$STAGE"/DEPLOY.md <<'EOF'
# S8LL Web — Deployment Guide

Next.js 16 (standalone output) + Prisma/SQLite + socket.io live-service + Caddy gateway.

## 1. Requirements
- Node.js 20+ (or Bun 1.1+)
- Ports: 3000 (web), 3030 (live-service), 81 (gateway, optional)

## 2. Install & Database
```bash
bun install                # or npm install
cp .env.example .env       # then edit DATABASE_URL to an ABSOLUTE path
bunx prisma generate       # generate Prisma client
# option A: use the bundled demo database (already seeded, 14 users / 18 products)
#   -> just keep db/custom.db
# option B: start fresh:
bunx prisma db push
bunx tsx scripts/seed.ts
```

## 3. Build & Run (production)
```bash
bun run build   # next build + copies static/public into .next/standalone
bun run start   # NODE_ENV=production, serves .next/standalone/server.js on :3000
# (npm users: npm run build && npm start)
```

## 4. Live service (realtime chat / stats)
```bash
cd mini-services/live-service
bun install && bun run dev    # socket.io on :3030
```

## 5. Gateway (Caddy, optional but recommended)
The frontend connects to the live service via same-origin path `/?XTransformPort=3030`,
so both must share one origin. The provided Caddyfile does exactly that:
- `:81` -> reverse proxy to `:3000`
- any request with query `XTransformPort=3030` -> proxied to `:3030` (socket.io websocket-safe)

```bash
caddy run --config Caddyfile
```
Then open http://your-host:81/ — live chat connects automatically (REALTIME badge).

## 6. Verification checklist
- GET / returns 200 (static prerendered shell)
- GET /api/home returns seeded JSON
- Profile -> Appearance toggle switches dark/light (#0A0A0A <-> #F5F5F7) and persists
- Live screen shows "● REALTIME" badge and streaming chat
- AR Try-On: pick a shoe, drag / pinch / wheel-zoom / double-tap reset
EOF

# ---- zip ----
rm -f "$OUT"
cd "$(dirname "$STAGE")"
zip -qr "$OUT" "$(basename "$STAGE")"
echo "OK -> $OUT ($(du -h "$OUT" | cut -f1)) — $(find "$STAGE" -type f | wc -l) files"
