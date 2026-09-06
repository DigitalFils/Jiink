import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/models.dart';
import 'package:s8ll/services/demo_data.dart';

Listing _listing({
  required String id,
  required DateTime postedAt,
  ListingStatus status = ListingStatus.live,
}) {
  return Listing(
    id: id,
    sellerId: 'demo-seller',
    sellerName: 'Alex',
    sellerCity: 'Manchester',
    title: 'Demo item',
    priceCents: 1000,
    delivery: DeliveryMethod.both,
    postedAt: postedAt,
    status: status,
  );
}

void main() {
  final now = DateTime(2026, 1, 1, 12);

  group('demoSeedActionFor', () {
    test('seeds the starter set for an account that has never listed', () {
      expect(demoSeedActionFor([], now), DemoSeedAction.seedStarterListings);
    });

    test('leaves an account alone while any listing is still within its window', () {
      final mine = [
        _listing(id: 'a', postedAt: now.subtract(const Duration(hours: 9))),
        _listing(id: 'b', postedAt: now.subtract(const Duration(hours: 1))),
      ];
      expect(demoSeedActionFor(mine, now), DemoSeedAction.none);
    });

    test('bumps rather than reseeds when every listing has timed out', () {
      // The point of bumping: demoing on day two must not pile up a fresh
      // copy of the starter set in Firestore every single time.
      final mine = [
        _listing(id: 'a', postedAt: now.subtract(const Duration(hours: 9))),
        _listing(id: 'b', postedAt: now.subtract(const Duration(hours: 30))),
      ];
      expect(demoSeedActionFor(mine, now), DemoSeedAction.bumpExpired);
    });

    test('seeds again when everything it ever listed has sold', () {
      // Sold listings can't be bumped back to life — status never returns
      // to live — so there'd be nothing to show without a fresh set.
      final mine = [
        _listing(
          id: 'a',
          postedAt: now.subtract(const Duration(hours: 2)),
          status: ListingStatus.sold,
        ),
      ];
      expect(demoSeedActionFor(mine, now), DemoSeedAction.seedStarterListings);
    });

    test('ignores sold listings when deciding whether anything is still live', () {
      final mine = [
        _listing(
          id: 'sold-but-recent',
          postedAt: now.subtract(const Duration(hours: 1)),
          status: ListingStatus.sold,
        ),
        _listing(id: 'expired', postedAt: now.subtract(const Duration(hours: 9))),
      ];
      expect(demoSeedActionFor(mine, now), DemoSeedAction.bumpExpired);
    });
  });

  test('every demo account has a distinct sign-in', () {
    final emails = demoAccounts.map((a) => a.email).toSet();
    expect(emails.length, demoAccounts.length);
  });
}
