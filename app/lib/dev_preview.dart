import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'screens/drops_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/publish_screen.dart';
import 'screens/splash_screen.dart';
import 'services/chat_repository.dart';
import 'services/offers_repository.dart';
import 'services/reviews_repository.dart';
import 'services/saved_searches_repository.dart';
import 'services/trust_safety_repository.dart';
import 'state/app_state.dart';
import 'state/theme_controller.dart';
import 'theme.dart';
import 'widgets/bottom_nav_bar.dart';

/// A design harness, not a second app.
///
/// The real entry point can't start without Firebase credentials, so there
/// was no way to *look* at any signed-in screen while building it — and
/// layout bugs (a price sliced in half, a Publish button hidden under the
/// nav bar) are invisible to `flutter analyze` and to the test suite alike.
/// Every one of those shipped at least once before anyone saw it.
///
/// This runs the real screens against a fixed [AppState.preview] and stub
/// repositories, so what renders here is what ships — same widgets, same
/// theme, same layout maths, only the data is fixed:
///
///   flutter build web -t lib/dev_preview.dart --release --no-web-resources-cdn
///
/// Nothing in the app imports it, so it is tree-shaken out of the real
/// build entirely.
void main() => runApp(const DevPreviewApp());

// The real clock, not a fixed date: every screen filters out listings whose
// eight hours are up, so a hardcoded date makes the whole harness read as
// expired and each screen renders its empty state. Sampled once at startup
// so the countdowns tick down from here.
final _now = DateTime.now();

Listing _listing({
  required String title,
  required int pounds,
  required Duration left,
  String seller = 'Alex',
  String city = 'Manchester',
  int watchers = 0,
  ListingStatus status = ListingStatus.live,
}) {
  return Listing(
    id: title,
    sellerId: 'seller-$seller',
    sellerName: seller,
    sellerCity: city,
    title: title,
    priceCents: pounds * 100,
    delivery: DeliveryMethod.both,
    // liveFor minus the time remaining puts postedAt far enough back that
    // `remaining` comes out at exactly `left`.
    postedAt: _now.subtract(const Duration(hours: 8) - left),
    status: status,
    watcherIds: List.generate(watchers, (i) => 'watcher-$i'),
  );
}

/// Ordinary listings, plus the four cases that break layouts: a four-figure
/// price, a title long enough to wrap, an ending-in-seconds pill, and a
/// sold card.
final _listings = [
  _listing(title: 'Vintage Film Camera', pounds: 220, left: const Duration(hours: 6), watchers: 12),
  _listing(
      title: 'Noise Cancelling Headphones',
      pounds: 180,
      left: const Duration(hours: 6),
      seller: 'Sam'),
  _listing(
      title: 'Ceramic Succulent Planter', pounds: 43, left: const Duration(hours: 6), watchers: 3),
  _listing(title: 'Leather Tote Bag', pounds: 95, left: const Duration(hours: 6), seller: 'Jordan'),
  _listing(
      title: 'Carbon road bike, 54cm, full Ultegra groupset',
      pounds: 3200,
      left: const Duration(minutes: 42),
      watchers: 41),
  _listing(title: 'PS5', pounds: 280, left: const Duration(seconds: 30), seller: 'Sam'),
  _listing(
      title: 'Nike Air Max 90, UK9',
      pounds: 45,
      left: const Duration(hours: 2),
      status: ListingStatus.sold),
  _listing(title: 'Standing desk', pounds: 150, left: const Duration(hours: 7), city: ''),
];

const _profile = Profile(
  uid: 'preview-uid',
  displayName: 'Alex',
  city: 'Manchester',
  payoutsEnabled: false,
);

class _PreviewSavedSearches extends SavedSearchesRepository {
  @override
  Stream<List<SavedSearch>> savedSearchesFor(String buyerId) => Stream.value(const []);
}

class _PreviewChat extends ChatRepository {
  @override
  Stream<List<ChatThreadSummary>> threadsFor(String uid) => Stream.value([
        ChatThreadSummary(
          threadId: 't1',
          listingId: 'Vintage Film Camera',
          buyerId: 'buyer-1',
          listingTitle: 'Vintage Film Camera',
          otherPartyId: 'seller-Sam',
          otherPartyName: 'Sam',
          lastMessageText: 'Is the 50mm included, or just the body?',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        ChatThreadSummary(
          threadId: 't2',
          listingId: 'Leather Tote Bag',
          buyerId: 'preview-uid',
          listingTitle: 'Leather Tote Bag',
          otherPartyId: 'seller-Jordan',
          otherPartyName: 'Jordan',
          lastMessageText: 'Can do £85 if you can collect from Thomas St today',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ]);
}

class _PreviewOffers extends OffersRepository {
  @override
  Stream<Offer?> offerFor({required String listingId, required String buyerId}) =>
      Stream.value(null);

  @override
  Stream<List<Offer>> pendingOffersForListing(String listingId, String sellerId) =>
      Stream.value(const []);
}

class _PreviewReviews extends ReviewsRepository {
  @override
  Future<SellerRating> sellerRating(String sellerId) async =>
      const SellerRating(average: 4.8, count: 23);

  @override
  Stream<PurchaseOrder?> orderForPurchaseStream({
    required String buyerId,
    required String listingId,
  }) =>
      Stream.value(null);

  @override
  Stream<PurchaseOrder?> orderForSaleStream({
    required String sellerId,
    required String listingId,
  }) =>
      Stream.value(null);

  @override
  Stream<Review?> reviewForListing(String listingId) => Stream.value(null);
}

class DevPreviewApp extends StatefulWidget {
  const DevPreviewApp({super.key});

  @override
  State<DevPreviewApp> createState() => _DevPreviewAppState();
}

class _DevPreviewAppState extends State<DevPreviewApp> {
  S8llTab _tab = S8llTab.home;

  /// The harness walks the same entry sequence the app does — splash, then
  /// onboarding, then the tabs — so the introduction can be looked at too.
  bool _splashDone = false;
  bool _onboardingDone = false;

  static const _screens = [
    FeedScreen(),
    DropsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => AppState.preview(
            uid: 'preview-uid',
            profile: _profile,
            listings: _listings,
            myListings: _listings.take(4).toList(),
          ),
        ),
        Provider<SavedSearchesRepository>(create: (_) => _PreviewSavedSearches()),
        Provider<ChatRepository>(create: (_) => _PreviewChat()),
        Provider<ReviewsRepository>(create: (_) => _PreviewReviews()),
        Provider<OffersRepository>(create: (_) => _PreviewOffers()),
        Provider<TrustSafetyRepository>(create: (_) => TrustSafetyRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildS8llTheme(),
        // Builder so the nav bar's callbacks get a context *below* the
        // MaterialApp. Without it Navigator.of() has nothing to find and
        // the publish button throws instead of opening anything. The real
        // shell doesn't need this — it is itself the MaterialApp's home.
        home: !_splashDone
            ? SplashScreen(onDone: () => setState(() => _splashDone = true))
            : !_onboardingDone
                ? OnboardingScreen(onDone: () => setState(() => _onboardingDone = true))
                : Builder(
          builder: (context) => Scaffold(
            backgroundColor: S8llColors.black,
            extendBody: true,
            body: Stack(
              children: [
                IndexedStack(index: _tab.index, children: _screens),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: S8llBottomNavBar(
                    current: _tab,
                    onSelect: (tab) => setState(() => _tab = tab),
                    // The real flow opens the camera first; there is none
                    // here, so this goes straight to the form with a path
                    // that doesn't resolve — which also exercises the
                    // missing-photo fallback.
                    onPublish: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PublishScreen(photoPath: '/dev/null/no-photo.jpg'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
