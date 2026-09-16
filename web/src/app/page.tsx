'use client'

import { AnimatePresence, motion } from 'framer-motion'
import { useAppStore } from '@/store/useAppStore'
import { useSession } from '@/lib/session'
import { SignInScreen } from '@/components/s8ll/sign-in-screen'
import { BottomNav } from '@/components/s8ll/bottom-nav'
import { SplashScreen } from '@/components/s8ll/splash-screen'
import { OnboardingScreen } from '@/components/s8ll/onboarding-screen'
import { HomeScreen } from '@/components/s8ll/home-screen'
import { DropScreen } from '@/components/s8ll/drop-screen'
import { SellScreen } from '@/components/s8ll/sell-screen'
import { ChatScreen, ChatDetailScreen } from '@/components/s8ll/chat-screens'
import { ProfileScreen } from '@/components/s8ll/profile-screen'
import { SearchScreen } from '@/components/s8ll/search-screen'
import { ProductDetailScreen } from '@/components/s8ll/product-detail-screen'
import { MapViewScreen } from '@/components/s8ll/map-view-screen'
import { AuthVerificationScreen } from '@/components/s8ll/auth-verification-screen'
import { LiveStreamScreen } from '@/components/s8ll/live-stream-screen'
import { ARTryOnScreen } from '@/components/s8ll/ar-tryon-screen'
import { WalletScreen } from '@/components/s8ll/wallet-screen'
import { AIAssistantScreen } from '@/components/s8ll/ai-assistant-screen'
import { WishlistScreen } from '@/components/s8ll/wishlist-screen'
import { GroupBuyScreen } from '@/components/s8ll/group-buy-screen'
import { FlashSaleScreen } from '@/components/s8ll/flash-sale-screen'

export default function Page() {
  const { booted, onboarded, tab, overlay } = useAppStore()
  const { user, loading } = useSession()

  // Splash → Onboarding → Sign in → Main app
  let content: React.ReactNode
  if (!booted) {
    content = <SplashScreen />
  } else if (!onboarded) {
    content = <OnboardingScreen />
  } else if (loading) {
    // We don't yet know whether there's a session. Holding the splash for
    // the one request beats flashing the sign-in screen at somebody who is
    // already signed in and then yanking it away.
    content = <SplashScreen />
  } else if (!user) {
    content = <SignInScreen />
  } else {
    content = (
      <>
        <main>
          {tab === 'home' && <HomeScreen />}
          {tab === 'drop' && <DropScreen />}
          {tab === 'sell' && <SellScreen />}
          {tab === 'chat' && <ChatScreen />}
          {tab === 'profile' && <ProfileScreen />}
        </main>
        <BottomNav />

        {/* Overlay screens — slide in over the shell */}
        <AnimatePresence>
          {overlay && (
            <motion.div
              key={overlay.name + ('id' in overlay ? overlay.id : '') + ('sessionId' in overlay ? overlay.sessionId : '')}
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', stiffness: 340, damping: 34 }}
              className="fixed inset-0 z-50 mx-auto max-w-[480px] bg-background overflow-y-auto s8ll-scroll"
            >
              {overlay.name === 'search' && <SearchScreen />}
              {overlay.name === 'product' && <ProductDetailScreen id={overlay.id} />}
              {overlay.name === 'map' && <MapViewScreen />}
              {overlay.name === 'auth' && <AuthVerificationScreen />}
              {overlay.name === 'live' && <LiveStreamScreen />}
              {overlay.name === 'ar' && <ARTryOnScreen />}
              {overlay.name === 'wallet' && <WalletScreen />}
              {overlay.name === 'ai' && <AIAssistantScreen />}
              {overlay.name === 'wishlist' && <WishlistScreen />}
              {overlay.name === 'groupbuy' && <GroupBuyScreen />}
              {overlay.name === 'flashsale' && <FlashSaleScreen />}
              {overlay.name === 'chatDetail' && <ChatDetailScreen sessionId={overlay.sessionId} />}
            </motion.div>
          )}
        </AnimatePresence>
      </>
    )
  }

  return (
    <div className="min-h-[100dvh] bg-background">
      <div className="app-frame">{content}</div>
    </div>
  )
}
