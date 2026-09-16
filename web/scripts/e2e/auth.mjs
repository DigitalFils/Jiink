/**
 * End-to-end checks for accounts and sessions, against a running server.
 *
 *   npx next dev &
 *   node scripts/e2e/auth.mjs [base-url]
 *
 * These are the things that were actually wrong, not a tour of the happy
 * path. Chief among them: `POST /api/wallet` once took an unauthenticated
 * request and incremented a balance by whatever number it was sent. That
 * exact call is at the bottom of this file, and it has to be refused.
 *
 * Written against fetch and the real HTTP surface rather than through a
 * test framework, so it runs anywhere Node does and needs no dependencies.
 */

const BASE = process.argv[2] ?? process.env.BASE_URL ?? 'http://localhost:3000'

let failures = 0
let checks = 0

function check(label, ok, detail) {
  checks++
  if (ok) {
    console.log(`  ok   ${label}`)
  } else {
    failures++
    console.log(`  FAIL ${label}${detail ? ` — ${detail}` : ''}`)
  }
}

/** Keeps cookies across calls, which is the whole point of a session test. */
function agent() {
  const jar = new Map()
  return {
    get cookie() {
      return [...jar].map(([k, v]) => `${k}=${v}`).join('; ')
    },
    clear: () => jar.clear(),
    async call(path, init = {}) {
      const res = await fetch(BASE + path, {
        ...init,
        headers: {
          ...(init.body ? { 'Content-Type': 'application/json' } : {}),
          ...(jar.size ? { cookie: this.cookie } : {}),
          ...init.headers,
        },
        redirect: 'manual',
      })
      for (const raw of res.headers.getSetCookie?.() ?? []) {
        const [pair] = raw.split(';')
        const eq = pair.indexOf('=')
        const name = pair.slice(0, eq)
        const value = pair.slice(eq + 1)
        // An expired or emptied cookie is a deletion, not a value.
        if (!value || /expires=Thu, 01 Jan 1970/i.test(raw)) jar.delete(name)
        else jar.set(name, value)
      }
      let body = null
      try {
        body = await res.json()
      } catch {}
      return { status: res.status, body }
    },
  }
}

const unique = `e2e_${Date.now().toString(36)}${Math.floor(Math.random() * 1e4)}`
const EMAIL = `${unique}@example.com`
const PASSWORD = 'correct horse battery staple'

const a = agent()

console.log(`auth e2e against ${BASE}\n`)

// ---------------------------------------------------------------- signed out
console.log('signed out')
{
  const me = await a.call('/api/auth/me')
  check('GET /api/auth/me is 200 with user: null', me.status === 200 && me.body?.user === null, `got ${me.status} ${JSON.stringify(me.body)}`)

  const wallet = await a.call('/api/wallet')
  check('GET /api/wallet is 401', wallet.status === 401, `got ${wallet.status}`)

  const listing = await a.call('/api/products', {
    method: 'POST',
    body: JSON.stringify({ title: 'ghost listing', price: 10, category: 'other' }),
  })
  check('POST /api/products is 401', listing.status === 401, `got ${listing.status}`)

  // The original hole, exactly as it was exploited.
  const mint = await a.call('/api/wallet', {
    method: 'POST',
    body: JSON.stringify({ type: 'topup', amount: 250000, description: 'free money' }),
  })
  check('POST /api/wallet cannot mint money unauthenticated', mint.status === 401, `got ${mint.status}`)
}

// --------------------------------------------------------------- registration
console.log('\nregistration')
{
  const short = await a.call('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username: unique, email: EMAIL, password: 'abc' }),
  })
  check('rejects a password under 8 characters', short.status === 400 && short.body?.field === 'password', `got ${short.status} ${JSON.stringify(short.body)}`)

  const punct = await a.call('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username: 'bad name!', email: EMAIL, password: PASSWORD }),
  })
  check('rejects a username outside [A-Za-z0-9_]', punct.status === 400 && punct.body?.field === 'username', `got ${punct.status} ${JSON.stringify(punct.body)}`)

  const created = await a.call('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username: unique, email: EMAIL, password: PASSWORD }),
  })
  check('creates the account (201)', created.status === 201, `got ${created.status} ${JSON.stringify(created.body)}`)
  check('never returns the password hash', !JSON.stringify(created.body ?? {}).includes('scrypt'))
  check('a new account starts at zero, not the demo balance',
    created.body?.user?.balance === 0 && created.body?.user?.points === 0 && created.body?.user?.sales === 0,
    JSON.stringify(created.body?.user))
  check('sets a session cookie', a.cookie.includes('s8ll_session'), a.cookie || '(none)')

  const dupe = await a.call('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username: unique, email: `other.${EMAIL}`, password: PASSWORD }),
  })
  check('refuses a duplicate username (409)', dupe.status === 409 && dupe.body?.field === 'username', `got ${dupe.status} ${JSON.stringify(dupe.body)}`)
}

// ------------------------------------------------------------- signed-in view
console.log('\nsigned in')
let sessionCookie
{
  const me = await a.call('/api/auth/me')
  check('GET /api/auth/me returns the account', me.body?.user?.email === EMAIL, JSON.stringify(me.body))

  const wallet = await a.call('/api/wallet')
  check('GET /api/wallet is the caller’s own, and empty', wallet.status === 200 && wallet.body?.balance === 0 && Array.isArray(wallet.body?.transactions) && wallet.body.transactions.length === 0, JSON.stringify(wallet.body))

  const mint = await a.call('/api/wallet', {
    method: 'POST',
    body: JSON.stringify({ type: 'topup', amount: 250000 }),
  })
  check('POST /api/wallet refuses even authenticated (501)', mint.status === 501, `got ${mint.status}`)

  const after = await a.call('/api/wallet')
  check('the balance did not move', after.body?.balance === 0, JSON.stringify(after.body))

  sessionCookie = a.cookie
}

// -------------------------------------------------------------------- signing out
console.log('\nsign out')
{
  const out = await a.call('/api/auth/logout', { method: 'POST' })
  check('POST /api/auth/logout is 200', out.status === 200, `got ${out.status}`)
  check('clears the cookie', !a.cookie.includes('s8ll_session'), a.cookie || '(none)')

  const me = await a.call('/api/auth/me')
  check('GET /api/auth/me is empty again', me.body?.user === null, JSON.stringify(me.body))

  // The session row must be gone, not just the cookie: a token copied off
  // the device before logout would otherwise still be a valid session.
  const replay = await fetch(BASE + '/api/auth/me', { headers: { cookie: sessionCookie } })
  const replayed = await replay.json()
  check('replaying the pre-logout cookie does not restore the session', replayed?.user === null, JSON.stringify(replayed))
}

// -------------------------------------------------------------------- signing in
console.log('\nsign in')
{
  const b = agent()

  const wrong = await b.call('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: EMAIL, password: 'not the password' }),
  })
  check('rejects a wrong password (401)', wrong.status === 401, `got ${wrong.status}`)

  const unknown = await b.call('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: `nobody.${EMAIL}`, password: 'not the password' }),
  })
  check('rejects an unknown email (401)', unknown.status === 401, `got ${unknown.status}`)
  check('says the same thing for both, so emails cannot be enumerated',
    unknown.body?.error === wrong.body?.error,
    `${JSON.stringify(wrong.body)} vs ${JSON.stringify(unknown.body)}`)

  const ok = await b.call('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
  })
  check('accepts the right password (200)', ok.status === 200, `got ${ok.status} ${JSON.stringify(ok.body)}`)
  check('issues a fresh session', b.cookie.includes('s8ll_session') && b.cookie !== sessionCookie)

  const me = await b.call('/api/auth/me')
  check('the new session is the same account', me.body?.user?.email === EMAIL, JSON.stringify(me.body))
}

console.log(`\n${checks - failures}/${checks} checks passed`)
process.exit(failures === 0 ? 0 : 1)
