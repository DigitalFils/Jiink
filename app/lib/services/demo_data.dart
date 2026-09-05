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

/// Signs into demo account [index] — creating it on first use anywhere,
/// signing straight in on every use after — then seeds its starter
/// listings the very first time only (checked by whether it already has
/// any listings, not a separate flag).
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
  final existing = await listings.listingsBySeller(uid).first;
  if (existing.isNotEmpty) return;

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
