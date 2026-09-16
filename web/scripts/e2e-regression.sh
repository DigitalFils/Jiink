#!/usr/bin/env bash
# S8LL E2E regression suite — runs against the PRODUCTION build via the Caddy gateway.
# Prereqs: production server on :3000, live-service on :3030, Caddy on :81.
# Usage:   bash /home/z/my-project/scripts/e2e-regression.sh
set -uo pipefail

BASE="http://localhost:81"
SHOTS=/home/z/my-project/scripts/e2e
mkdir -p "$SHOTS"
PASS=0; FAIL=0
declare -a FAILURES=()

ok()   { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad()  { FAIL=$((FAIL+1)); FAILURES+=("$1"); echo "  ✗ $1"; }

# eval helper: runs JS, returns raw stdout (single line, JSON quotes stripped)
ev() { agent-browser eval "$1" 2>/dev/null | head -1 | sed 's/^"//;s/"$//'; }

echo "== S8LL E2E Regression Suite =="
echo "-- target: $BASE (production) --"

# ---------- 0. API health ----------
echo "[0] API health"
for ep in /api/home "/api/products?ar=true"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$ep")
  [ "$code" = "200" ] && ok "GET $ep -> 200" || bad "GET $ep -> $code"
done

# ---------- 1. Cold start: splash -> onboarding -> home ----------
echo "[1] Splash / onboarding / home"
agent-browser close >/dev/null 2>&1
agent-browser set viewport 420 900 >/dev/null
agent-browser open "$BASE/" >/dev/null
agent-browser wait 2500 >/dev/null
title=$(ev "document.title")
echo "$title" | grep -q "S8LL" && ok "title contains S8LL ($title)" || bad "unexpected title: $title"
mlink=$(ev "document.querySelectorAll('link[rel=manifest]').length")
[ "$mlink" = "1" ] && ok "manifest link present" || bad "manifest link missing"

# click through onboarding (Next x4 + Get Started)
for i in $(seq 1 6); do
  ev "(() => { const b=[...document.querySelectorAll('button')].find(x=>/next|get started/i.test(x.textContent||'')); if(b){b.click(); return 1} return 0 })()" >/dev/null
  agent-browser wait 700 >/dev/null
done
home=$(ev "(() => { const t=document.body.textContent; return (t.includes('Flash')||t.includes('Live Drops')) ? 'HOME' : 'NOT-HOME' })()")
[ "$home" = "HOME" ] && ok "home rendered (stories/drops/flash)" || bad "home not rendered after onboarding"

# ---------- 2. Theme toggle round-trip ----------
echo "[2] Theme toggle (Profile -> Appearance)"
ev "(() => { const b=[...document.querySelectorAll('button')].find(x=>/profile/i.test(x.getAttribute('aria-label')||'')||/profile/i.test(x.textContent||'')); if(b){b.click(); return 1} return 0 })()" >/dev/null
agent-browser wait 1000 >/dev/null
swres=$(ev "(() => { const s=document.querySelector('button[role=switch]'); if(!s) return 'no-switch'; s.click(); return 'toggled' })()")
[ "$swres" = "toggled" ] || bad "appearance switch not found"
agent-browser wait 900 >/dev/null
light=$(ev "(() => { const c=getComputedStyle(document.body); return document.documentElement.getAttribute('data-theme')+' '+c.backgroundColor+' '+c.color })()")
echo "$light" | grep -q "light rgb(245, 245, 247) rgb(26, 26, 30)" && ok "light palette exact (#F5F5F7 / #1A1A1E)" || bad "light palette wrong: $light"
agent-browser screenshot "$SHOTS/e2e-light.png" >/dev/null
# toggle back to dark
ev "document.querySelector('button[role=switch]').click()" >/dev/null
agent-browser wait 900 >/dev/null
dark=$(ev "(() => { const c=getComputedStyle(document.body); return document.documentElement.getAttribute('data-theme')+' '+c.backgroundColor })()")
echo "$dark" | grep -q "dark rgb(10, 10, 10)" && ok "dark palette restored (#0A0A0A)" || bad "dark palette wrong: $dark"

# ---------- 3. Live socket (REALTIME + chat flow) ----------
echo "[3] Live stream socket"
# back to home via nav, then open live banner
ev "(() => { const b=[...document.querySelectorAll('button')].find(x=>/home/i.test(x.getAttribute('aria-label')||'')); if(b){b.click(); return 1} return 0 })()" >/dev/null
agent-browser wait 800 >/dev/null
ev "(() => { const b=[...document.querySelectorAll('button')].find(x=>/RARE Jordan|live unboxing/i.test(x.textContent||'')); if(b){b.click(); return 1} return 0 })()" >/dev/null
agent-browser wait 4000 >/dev/null
badge=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); if(!ov) return 'no-overlay'; const b=[...ov.querySelectorAll('span,div')].find(e=>e.children.length===0&&/REALTIME|connecting/i.test(e.textContent||'')); return b?b.textContent.trim():'none' })()")
echo "$badge" | grep -q "REALTIME" && ok "socket connected (● REALTIME)" || bad "socket badge: $badge"
msgs=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const chat=ov?.querySelector('div.s8ll-scroll, [class*=overflow-y-auto]'); return String((chat?.children||[]).length) })()")
[ "${msgs:-0}" -ge 3 ] && ok "chat stream flowing ($msgs msgs)" || bad "chat not flowing ($msgs msgs)"
# send a message
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const i=ov.querySelector('input'); const set=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; set.call(i,'e2e ping '+Date.now()); i.dispatchEvent(new Event('input',{bubbles:true})); return 1 })()" >/dev/null
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); [...ov.querySelectorAll('button')].find(b=>b.getAttribute('aria-label')==='Send')?.click(); return 1 })()" >/dev/null
agent-browser wait 1500 >/dev/null
sent=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const chat=ov?.querySelector('div.s8ll-scroll, [class*=overflow-y-auto]'); return [...(chat?.children||[])].some(m=>/e2e ping/.test(m.textContent)) ? 'echoed' : 'missing' })()")
[ "$sent" = "echoed" ] && ok "sent message echoed back" || bad "sent message $sent"
agent-browser screenshot "$SHOTS/e2e-live.png" >/dev/null
# close live overlay via back button
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const b=[...ov.querySelectorAll('button')].find(x=>/back/i.test(x.getAttribute('aria-label')||'')); if(b){b.click(); return 1} return 0 })()" >/dev/null
agent-browser wait 800 >/dev/null

# ---------- 4. AR gestures ----------
echo "[4] AR try-on gestures"
ev "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent.trim().startsWith('AR Try-On')); if(b){b.click(); return 1} return 0 })()" >/dev/null
agent-browser wait 2000 >/dev/null
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const p=[...ov.querySelectorAll('button')].filter(b=>b.querySelector('img')||/nike|jordan|adidas|vans/i.test(b.textContent||'')); if(p.length){p[0].click(); return 'picked'} return 'no-picker' })()" >/dev/null
agent-browser wait 7000 >/dev/null   # scan phase cycle
shoe=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const s=ov.querySelector('[class*=shoe-ar]'); return s?'present':'missing' })()")
[ "$shoe" = "present" ] && ok "shoe overlay rendered" || bad "shoe overlay $shoe"
# drag +40/+40
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); const s=vp.querySelector('[class*=shoe-ar]'); const r=s.getBoundingClientRect(); const cx=r.x+r.width/2, cy=r.y+r.height/2; vp.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,clientX:cx,clientY:cy,pointerId:7,isPrimary:true})); vp.dispatchEvent(new PointerEvent('pointermove',{bubbles:true,clientX:cx+40,clientY:cy+40,pointerId:7,isPrimary:true})); vp.dispatchEvent(new PointerEvent('pointerup',{bubbles:true,clientX:cx+40,clientY:cy+40,pointerId:7,isPrimary:true})); return 1 })()" >/dev/null
agent-browser wait 700 >/dev/null
drag=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); return vp.querySelector('[class*=shoe-ar]').parentElement.style.transform||'none' })()")
echo "$drag" | grep -q "translateX(40px) translateY(40px)" && ok "drag exact (+40/+40)" || bad "drag transform: $drag"
# wheel zoom -240
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); vp.dispatchEvent(new WheelEvent('wheel',{bubbles:true,cancelable:true,clientX:210,clientY:300,deltaY:-240})); return 1 })()" >/dev/null
agent-browser wait 700 >/dev/null
zoom=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); return vp.querySelector('[class*=shoe-ar]').parentElement.style.transform||'none' })()")
echo "$zoom" | grep -q "scale(1.288)" && ok "wheel zoom exact (scale 1.288)" || bad "zoom transform: $zoom"
# double-tap reset
ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); const s=vp.querySelector('[class*=shoe-ar]'); const r=s.getBoundingClientRect(); const cx=r.x+r.width/2, cy=r.y+r.height/2; for (const t of [0,180]) { setTimeout(()=>{ vp.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,clientX:cx,clientY:cy,pointerId:9,isPrimary:true})); vp.dispatchEvent(new PointerEvent('pointerup',{bubbles:true,clientX:cx,clientY:cy,pointerId:9,isPrimary:true})); }, t) } return 1 })()" >/dev/null
agent-browser wait 900 >/dev/null
reset=$(ev "(() => { const ov=[...document.querySelectorAll('div')].filter(d=>String(d.className||'').includes('fixed')).pop(); const vp=ov.querySelector('div[class*=touch-none]'); return vp.querySelector('[class*=shoe-ar]').parentElement.style.transform||'none' })()")
echo "$reset" | grep -qE "^(none|translateX\(0px\) translateY\(0px\) scale\(1\) rotate\(0deg\))$" || echo "$reset" | grep -qE "translateX\(0px\)|scale\(1\)"
rc=$?
[ $rc -eq 0 ] && ok "double-tap reset (transform: $reset)" || bad "reset failed: $reset"
agent-browser screenshot "$SHOTS/e2e-ar.png" >/dev/null

# ---------- 5. Console / page errors ----------
echo "[5] Error hygiene"
errs=$(agent-browser errors 2>/dev/null | grep -c . || true)
[ "${errs:-0}" = "0" ] && ok "0 page errors" || bad "$errs page errors"
cons=$(agent-browser console 2>/dev/null | grep -iv favicon | grep -c . || true)
[ "${cons:-0}" = "0" ] && ok "0 console errors" || bad "$cons console messages"

agent-browser close >/dev/null 2>&1

echo ""
echo "== RESULT: $PASS passed, $FAIL failed =="
if [ $FAIL -gt 0 ]; then printf '  - %s\n' "${FAILURES[@]}"; exit 1; fi
exit 0
