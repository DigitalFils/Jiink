import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';
import 'auth_service.dart';
import 'listings_repository.dart';

/// A fixed demo account: same email/password every time, so "Try a demo
/// account" signs into the *same* account (and whatever it's already
/// seeded) on repeat visits and on any device, rather than creating a new
/// throwaway user each time.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.displayName,
    required this.city,
  });

  final String email;
  final String password;
  final String displayName;
  final String city;
}

const demoAccounts = <DemoAccount>[
  DemoAccount(email: 'demo.alex@s8ll.app', password: 'S8llDemo1!', displayName: 'Alex', city: 'Manchester'),
  DemoAccount(email: 'demo.sam@s8ll.app', password: 'S8llDemo1!', displayName: 'Sam', city: 'Manchester'),
  DemoAccount(email: 'demo.jordan@s8ll.app', password: 'S8llDemo1!', displayName: 'Jordan', city: 'Manchester'),
];

class _DemoListing {
  const _DemoListing(this.title, this.priceCents, this.category, this.delivery, this.photoSeed);

  final String title;
  final int priceCents;
  final ListingCategory category;
  final DeliveryMethod delivery;
  final String photoSeed;
}

// Spread across the demo sellers so there's something real for a second
// demo account to watch, offer on, or chat about.
const _demoListingsByAccount = <List<_DemoListing>>[
  [
    _DemoListing('Carbon road bike, 54cm', 32000, ListingCategory.sportsAndOutdoors, DeliveryMethod.meetup, 's8ll-bike'),
    _DemoListing('PS5 + 2 controllers', 28000, ListingCategory.electronics, DeliveryMethod.both, 's8ll-ps5'),
    _DemoListing('Leather jacket, size M', 6500, ListingCategory.clothing, DeliveryMethod.shipping, 's8ll-jacket'),
  ],
  [
    _DemoListing('IKEA 2-seater sofa', 12000, ListingCategory.home, DeliveryMethod.meetup, 's8ll-sofa'),
    _DemoListing('Nike Air Max 90, UK9', 4500, ListingCategory.clothing, DeliveryMethod.both, 's8ll-trainers'),
    _DemoListing('Nintendo Switch OLED', 18000, ListingCategory.electronics, DeliveryMethod.shipping, 's8ll-switch'),
  ],
  [
    _DemoListing('Lego Millennium Falcon', 22000, ListingCategory.toysAndGames, DeliveryMethod.shipping, 's8ll-lego'),
    _DemoListing('Standing desk, electric', 15000, ListingCategory.home, DeliveryMethod.meetup, 's8ll-desk'),
    _DemoListing('Canon DSLR + 2 lenses', 35000, ListingCategory.electronics, DeliveryMethod.both, 's8ll-camera'),
  ],
];

String _demoPhotoUrl(String seed) => 'https://picsum.photos/seed/$seed/900/1200';

/// What a demo account needs on sign-in to have something live to show.
enum DemoSeedAction {
  /// Its listings are still within their window — leave them alone.
  none,

  /// It has listings, but every one of them has timed out. Bumping resets
  /// `postedAt`, which is all expiry is measured from, so they come back
  /// without piling up duplicates in Firestore every time someone demos.
  bumpExpired,

  /// Nothing live to bump — first ever use, or everything since sold.
  seedStarterListings,
}

/// Decides what [useDemoAccount] should do, given what the account already
/// owns. Pure and clock-injected so the rule is testable without Firebase.
///
/// The 8-hour window is the point: seeding only when a demo account has
/// *zero* listings leaves it looking permanently empty the morning after
/// someone first tries it — which is exactly when it gets demoed.
DemoSeedAction demoSeedActionFor(List<Listing> mine, DateTime now) {
  final live = mine.where((l) => l.status == ListingStatus.live);
  if (live.any((l) => !l.isExpired(now))) return DemoSeedAction.none;
  if (live.isNotEmpty) return DemoSeedAction.bumpExpired;
  return DemoSeedAction.seedStarterListings;
}

/// Signs into demo account [index] — creating it on first use anywhere,
/// signing straight in on every use after — then makes sure it has
/// something live to show, per [demoSeedActionFor].
Future<void> useDemoAccount(AuthServiceBase authService, int index, {ListingsRepository? repository}) async {
  final account = demoAccounts[index];
  try {
    await authService.signIn(email: account.email, password: account.password);
  } on FirebaseAuthException {
    await authService.signUp(
      email: account.email,
      password: account.password,
      displayName: account.displayName,
      city: account.city,
    );
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final listings = repository ?? ListingsRepository();
  final mine = await listings.listingsBySeller(uid).first;

  switch (demoSeedActionFor(mine, DateTime.now())) {
    case DemoSeedAction.none:
      return;
    case DemoSeedAction.bumpExpired:
      for (final listing in mine.where((l) => l.status == ListingStatus.live)) {
        await listings.bump(listing.id);
      }
    case DemoSeedAction.seedStarterListings:
      for (final template in _demoListingsByAccount[index]) {
        await listings.publishWithPhotoUrl(
          sellerId: uid,
          sellerName: account.displayName,
          sellerCity: account.city,
          title: template.title,
          priceCents: template.priceCents,
          delivery: template.delivery,
          category: template.category,
          photoUrl: _demoPhotoUrl(template.photoSeed),
        );
      }
  }
}
