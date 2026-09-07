import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:s8ll/models.dart';
import 'package:s8ll/screens/drops_screen.dart';
import 'package:s8ll/screens/feed_screen.dart';
import 'package:s8ll/screens/messages_screen.dart';
import 'package:s8ll/screens/profile_screen.dart';
import 'package:s8ll/screens/publish_screen.dart';
import 'package:s8ll/services/chat_repository.dart';
import 'package:s8ll/services/reviews_repository.dart';
import 'package:s8ll/services/saved_searches_repository.dart';
import 'package:s8ll/state/app_state.dart';
import 'package:s8ll/state/theme_controller.dart';
import 'package:s8ll/theme.dart';
import 'package:s8ll/widgets/drop_card.dart';

/// Layout regressions are the ones this project keeps shipping: a price
/// sliced in half because the grid cell was too short, a Publish button
/// parked under the floating nav, a list row that demanded infinite height
/// and silently rendered nothing at all. `flutter analyze` sees none of
/// them and neither did any test — each was found by a human looking at a
/// screenshot, and only after it had shipped.
///
/// These pump the real screens at real phone size. An overflow throws in a
/// widget test, so "no exception" genuinely means "nothing overflowed", and
/// asserting the content is actually on screen catches the rows-render-
/// nothing case that no overflow check would.
void main() {
  const phone = Size(412, 915);

  final now = DateTime.now();

  Listing listing({
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
      postedAt: now.subtract(const Duration(hours: 8) - left),
      status: status,
      watcherIds: List.generate(watchers, (i) => 'w$i'),
    );
  }

  // Ordinary listings plus every case that has broken a layout before: a
  // four-figure price, a title long enough to wrap, an about-to-end pill,
  // a sold card, and a listing with no city.
  final listings = [
    listing(title: 'Vintage Film Camera', pounds: 220, left: const Duration(hours: 6), watchers: 12),
    listing(title: 'Noise Cancelling Headphones', pounds: 180, left: const Duration(hours: 6), seller: 'Sam'),
    listing(title: 'Carbon road bike, 54cm, full Ultegra groupset', pounds: 3200, left: const Duration(minutes: 42), watchers: 41),
    listing(title: 'PS5', pounds: 280, left: const Duration(seconds: 30), seller: 'Sam'),
    listing(title: 'Nike Air Max 90, UK9', pounds: 45, left: const Duration(hours: 2), status: ListingStatus.sold),
    listing(title: 'Standing desk', pounds: 150, left: const Duration(hours: 7), city: ''),
  ];

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => AppState.preview(
            uid: 'uid',
            profile: const Profile(
              uid: 'uid',
              displayName: 'Alex',
              city: 'Manchester',
              payoutsEnabled: false,
            ),
            listings: listings,
            myListings: listings,
          ),
        ),
        Provider<SavedSearchesRepository>(create: (_) => _StubSavedSearches()),
        Provider<ChatRepository>(create: (_) => _StubChat()),
        Provider<ReviewsRepository>(create: (_) => _StubReviews()),
      ],
      child: MaterialApp(theme: buildS8llTheme(), home: child),
    );
  }

  /// Screens hold a one-second ticker; replacing the tree disposes them so
  /// the test doesn't end with a timer still pending.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // ThemeController reads the stored light/dark preference on
    // construction; without a platform behind it, building any screen that
    // provides one throws.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('the feed grid renders every listing without overflowing', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const FeedScreen()));
    await tester.pump();

    // The price is the thing that used to get clipped, so assert it's
    // really on screen rather than just that nothing threw.
    expect(find.text('£220'), findsOneWidget);
    expect(find.text('£3200'), findsOneWidget);
    expect(find.textContaining('live now'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('a drop card shows price, title and remaining time in a real grid cell',
      (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildS8llTheme(),
        home: Scaffold(
          body: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 0.58,
            children: [
              for (final l in listings) DropCard(listing: l, now: now, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('£220'), findsOneWidget);
    expect(find.text('Vintage Film Camera'), findsOneWidget);
    expect(find.text('6h left'), findsWidgets);
    // Sold replaces the countdown rather than sitting next to it.
    expect(find.text('SOLD'), findsOneWidget);
  });

  testWidgets('the drops list renders its rows, not empty space', (tester) async {
    // The regression this exists for: the row used CrossAxisAlignment.stretch,
    // which asks for infinite height inside a sliver. Nothing overflowed and
    // nothing threw — the rows simply weren't there.
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DropsScreen()));
    await tester.pump();

    expect(find.text('All drops'), findsOneWidget);
    expect(find.text('£280'), findsOneWidget);
    expect(find.textContaining('ENDING SOON'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('a sold drop is labelled sold rather than counting down', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DropsScreen()));
    await tester.pump();

    // Scroll the sold listing (2h left, so well down the list) into view.
    await tester.scrollUntilVisible(
      find.text('Sold'),
      200,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 20,
    );
    expect(find.text('Sold'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('the sell screen renders its whole form, Publish button included',
      (tester) async {
    // The Publish button was once entirely under the floating nav — the
    // whole point of the screen, invisible, and only found by scrolling to
    // the bottom of a screenshot. This doesn't assert it's above the fold
    // (the test font is far wider than Inter, so everything sits lower
    // here than on a device); it asserts the form builds without
    // overflowing and the button is reachable.
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A path that doesn't resolve, which also exercises the fallback for a
    // camera capture the OS evicted before publish.
    await tester.pumpWidget(wrap(const PublishScreen(photoPath: '/dev/null/none.jpg')));
    await tester.pump();

    expect(find.text('Goes live for 8h'), findsOneWidget);
    expect(find.text('£'), findsOneWidget);
    // Every category and delivery option is a chip, not buried in a menu.
    expect(find.text('Sports & outdoors'), findsOneWidget);
    expect(find.text('Meet up or ship'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Publish now'),
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    expect(find.text('Publish now'), findsOneWidget);
  });

  testWidgets('the sell screen refuses a listing with no name and no price', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const PublishScreen(photoPath: '/dev/null/none.jpg')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Publish now'),
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.tap(find.text('Publish now'));
    await tester.pump();

    expect(find.text('Give it a name'), findsOneWidget);
    expect(find.text('Set a price'), findsOneWidget);
  });

  testWidgets('the inbox renders a thread row per conversation', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const MessagesScreen()));
    await tester.pump();

    expect(find.text('Sam'), findsOneWidget);
    expect(find.textContaining('50mm'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('profile renders the stat row and the seller\'s own listings', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const ProfileScreen()));
    await tester.pump();

    expect(find.text('Alex'), findsWidgets);
    expect(find.text('Live now'), findsOneWidget);
    expect(find.text('Sold'), findsOneWidget);
    expect(find.text('Watchers'), findsOneWidget);
    // One of the six is sold, so five are still live.
    expect(find.text('5'), findsOneWidget);
    await settle(tester);
  });
}

class _StubSavedSearches extends SavedSearchesRepository {
  @override
  Stream<List<SavedSearch>> savedSearchesFor(String buyerId) => Stream.value(const []);
}

class _StubChat extends ChatRepository {
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
      ]);
}

class _StubReviews extends ReviewsRepository {
  @override
  Future<SellerRating> sellerRating(String sellerId) async =>
      const SellerRating(average: 4.8, count: 23);
}
