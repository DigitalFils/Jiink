import { createServer } from 'http'
import { Server } from 'socket.io'

const httpServer = createServer()
const io = new Server(httpServer, {
  // DO NOT change the path, it is used by Caddy to forward the request to the correct port
  path: '/',
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
})

// ---------------------------------------------------------------------------
// S8LL Live Commerce realtime service
// - Live stream chat: simulated viewers chatting + real user messages
// - Viewer count + likes ticker
// - Group buy participant ticker
// ---------------------------------------------------------------------------

interface LiveMessage {
  id: string
  username: string
  content: string
  type: 'user' | 'system' | 'pinned' | 'gift'
  timestamp: number
}

const genId = () => Math.random().toString(36).slice(2, 11)

const VIEWERS = [
  'sneakerhead22', 'kicks_daily', 'miau', 'dropz', 'oleg_k', 'davey', 'yuki_',
  'freshfit', 'travis_fan', 'grailhunter', 'laceless', 'solesearcher',
  'annie_w', 'beacollector', 'airmax_addict', 'vintagelord', 'copthrill',
]

const CHAT_LINES = [
  'W shoes!!', 'need these in UK 9', 'price drop?', '🔥🔥🔥', 'authentic right?',
  'just copped, can\'t wait', 'that patina is insane', 'S8LL verified = instant cop',
  'group buy for these pls', 'AI assistant told me about this stream lol',
  'LIVE DROP incoming?', 'watching from Manchester 🇬🇧', 'from Moscow with love 🇷🇺',
  'how\'s the condition?', 'box + extras??', 'payment via wallet accepted?',
  'first time here, love this', 'that colorway is grail', 'argh missed the last drop',
  'can you show the size tag?', '10/10 condition fr', 'AR try-on these pls 🙏',
  'ship to EU?', 'adds to wishlist instantly', 'certificate shown yet?',
]

const GIFTS = ['🚀 Rocket', '👑 Crown', '💎 Diamond', '🎉 Party']

const viewers = new Map<string, string>()

let viewerCount = 2418
let likes = 12400

// Simulated live-stream chat
let chatTimer: ReturnType<typeof setInterval> | null = null

function startChatSimulation() {
  if (chatTimer) return
  chatTimer = setInterval(() => {
    const username = VIEWERS[Math.floor(Math.random() * VIEWERS.length)]
    const isGift = Math.random() < 0.06
    const isPinned = Math.random() < 0.04
    const msg: LiveMessage = {
      id: genId(),
      username,
      content: isGift
        ? `sent ${GIFTS[Math.floor(Math.random() * GIFTS.length)]}`
        : CHAT_LINES[Math.floor(Math.random() * CHAT_LINES.length)],
      type: isGift ? 'gift' : isPinned ? 'pinned' : 'user',
      timestamp: Date.now(),
    }
    io.emit('live:chat', msg)

    if (isGift) {
      likes += 250 + Math.floor(Math.random() * 500)
    }
  }, 2600)
}

function stopChatSimulation() {
  if (chatTimer) {
    clearInterval(chatTimer)
    chatTimer = null
  }
}

// Viewer count ticker
setInterval(() => {
  const delta = Math.floor(Math.random() * 21) - 8
  viewerCount = Math.max(200, viewerCount + delta)
  io.emit('live:stats', { viewers: viewerCount, likes: likes + Math.floor(Math.random() * 40) })
}, 3000)

// Group buy participant ticker
const GROUPBUYS: Record<string, number> = {
  'earbuds': 7,
  'watch': 11,
  'af1': 3,
  'dinner': 5,
  'keyboard': 9,
}
let gbTimer: ReturnType<typeof setInterval> | null = null

function startGroupBuyTicker() {
  if (gbTimer) return
  gbTimer = setInterval(() => {
    const keys = Object.keys(GROUPBUYS)
    const key = keys[Math.floor(Math.random() * keys.length)]
    if (GROUPBUYS[key] < 20 && Math.random() < 0.5) {
      GROUPBUYS[key] += 1
      const username = VIEWERS[Math.floor(Math.random() * VIEWERS.length)]
      io.emit('groupbuy:update', { id: key, participants: GROUPBUYS[key], username })
    }
  }, 5000)
}

io.on('connection', (socket) => {
  const username = `guest_${Math.floor(Math.random() * 900 + 100)}`
  viewers.set(socket.id, username)
  startChatSimulation()
  startGroupBuyTicker()

  socket.emit('live:stats', { viewers: viewerCount, likes })
  socket.emit('live:chat', {
    id: genId(),
    username: 'System',
    content: `Welcome to the stream! ${viewers.size} watching together.`,
    type: 'system',
    timestamp: Date.now(),
  })

  socket.on('live:join', (data: { username: string }) => {
    viewers.set(socket.id, data.username || username)
    socket.emit('groupbuy:state', GROUPBUYS)
  })

  socket.on('live:message', (data: { content: string; username: string }) => {
    const msg: LiveMessage = {
      id: genId(),
      username: data.username || viewers.get(socket.id) || 'you',
      content: (data.content || '').slice(0, 300),
      type: 'user',
      timestamp: Date.now(),
    }
    io.emit('live:chat', msg)
  })

  socket.on('live:like', () => {
    likes += 1
    io.emit('live:stats', { viewers: viewerCount, likes })
  })

  socket.on('disconnect', () => {
    viewers.delete(socket.id)
    if (viewers.size === 0) {
      stopChatSimulation()
      if (gbTimer) {
        clearInterval(gbTimer)
        gbTimer = null
      }
    }
  })
})

const PORT = 3030
httpServer.listen(PORT, () => {
  console.log(`S8LL live service running on port ${PORT}`)
})
