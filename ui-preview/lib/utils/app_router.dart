import 'package:flutter/material.dart';

import '../utils/app_animations.dart';
import '../models/models.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/drop/drop_screen.dart';
import '../screens/sell/sell_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/map/map_view_screen.dart';
import '../screens/auth/auth_verification_screen.dart';
import '../screens/live/live_stream_screen.dart';
import '../screens/ar/ar_tryon_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/ai/ai_assistant_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/group_buy/group_buy_screen.dart';
import '../screens/flash_sale/flash_sale_screen.dart';
import '../screens/product_detail/product_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';

/// S8LL v2.0 — Centralized named-route registry.
///
/// Every screen in the app is registered here exactly once and opened
/// exclusively through [Navigator.pushNamed], so call sites never
/// construct routes by hand and every transition is guaranteed to use
/// the standardized v2.0 motion system.
class AppRoutes {
  // --- core flow -----------------------------------------------------------
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String main = '/main';

  // --- shopping ------------------------------------------------------------
  static const String search = '/search';
  static const String product = '/product';
  static const String wishlist = '/wishlist';
  static const String groupBuy = '/groupbuy';
  static const String flashSale = '/flashsale';

  // --- discovery & trust ---------------------------------------------------
  static const String map = '/map';
  static const String auth = '/auth';

  // --- immersive commerce --------------------------------------------------
  static const String live = '/live';
  static const String ar = '/ar';

  // --- money & assistant ---------------------------------------------------
  static const String wallet = '/wallet';
  static const String ai = '/ai';

  /// Screens that feel like immersive overlays rather than pages.
  static const Set<String> _immersive = <String>{live, ar, wallet};

  /// Route names that expect a [Product] in [RouteSettings.arguments].
  static const Set<String> _productArg = <String>{product};

  static final Map<String, WidgetBuilder> _builders = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    main: (_) => const MainScreen(),
    search: (_) => const SearchScreen(),
    map: (_) => const MapViewScreen(),
    auth: (_) => const AuthVerificationScreen(),
    live: (_) => const LiveStreamScreen(),
    ar: (_) => const ARTryOnScreen(),
    wallet: (_) => const WalletScreen(),
    ai: (_) => const AIAssistantScreen(),
    wishlist: (_) => const WishlistScreen(),
    groupBuy: (_) => const GroupBuyScreen(),
    flashSale: (_) => const FlashSaleScreen(),
  };

  /// The single [onGenerateRoute] wired into [MaterialApp].
  ///
  /// Unknown names fall back to the main tabs so a stale deep link can
  /// never dead-end the navigator.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String name = settings.name ?? main;

    // Screens injected by the app shell (main tabs).
    if (name == main) {
      return FadeBouncePageRoute<void>(
        settings: settings,
        builder: (_) => const MainScreen(),
      );
    }

    // Product detail — requires a Product argument.
    if (_productArg.contains(name)) {
      final Object? args = settings.arguments;
      if (args is Product) {
        return FadeBouncePageRoute<void>(
          settings: settings,
          builder: (_) => ProductDetailScreen(product: args),
        );
      }
      // Defensive: called without arguments -> land on main tabs.
      return FadeBouncePageRoute<void>(
        settings: settings,
        builder: (_) => const MainScreen(),
      );
    }

    final WidgetBuilder? builder = _builders[name];
    if (builder == null) {
      return FadeBouncePageRoute<void>(
        settings: settings,
        builder: (_) => const MainScreen(),
      );
    }

    // Immersive commerce screens get the slide-up flavor.
    if (_immersive.contains(name)) {
      return SlideUpRoute<void>(settings: settings, builder: builder);
    }

    return FadeBouncePageRoute<void>(settings: settings, builder: builder);
  }

  /// Convenience: pushes any named route with the standardized transition.
  static Future<T?> push<T extends Object?>(BuildContext context, String route,
      {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
  }

  /// Convenience: pushes a route and removes everything below it
  /// (splash -> onboarding -> main flow).
  static Future<T?> pushAndClearStack<T extends Object?>(
      BuildContext context, String route) {
    return Navigator.of(context)
        .pushNamedAndRemoveUntil<T>(route, (Route<dynamic> r) => false);
  }
}

/// The persistent app shell hosting the five main tabs
/// (Home / Drop / Sell / Chat / Profile) on an [IndexedStack] so each
/// tab keeps its scroll position and live timers while switching.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    DropScreen(),
    SellScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
