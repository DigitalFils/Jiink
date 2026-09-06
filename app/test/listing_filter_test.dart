import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/models.dart';
import 'package:s8ll/services/listing_filter.dart';

Listing _listing({
  required String id,
  required String title,
  required int priceCents,
  ListingCategory category = ListingCategory.other,
  DateTime? postedAt,
  Duration? liveFor,
}) {
  return Listing(
    id: id,
    sellerId: 'seller-1',
    sellerName: 'jordan_m',
    sellerCity: 'Manchester',
    title: title,
    priceCents: priceCents,
    delivery: DeliveryMethod.both,
    postedAt: postedAt ?? DateTime.now(),
    category: category,
    liveFor: liveFor,
  );
}

void main() {
  final listings = [
    _listing(id: 'l1', title: 'Nike Air Max 90', priceCents: 4500, category: ListingCategory.clothing),
    _listing(id: 'l2', title: 'PS5 console', priceCents: 30000, category: ListingCategory.electronics),
    _listing(id: 'l3', title: 'Nike hoodie', priceCents: 2000, category: ListingCategory.clothing),
  ];

  test('with no filters, returns every listing', () {
    expect(filterListings(listings).length, 3);
  });

  test('filters by a case-insensitive title match', () {
    final result = filterListings(listings, query: 'nike');
    expect(result.map((l) => l.id), ['l1', 'l3']);
  });

  test('filters by category', () {
    final result = filterListings(listings, category: ListingCategory.electronics);
    expect(result.map((l) => l.id), ['l2']);
  });

  test('filters by max price, inclusive', () {
    final result = filterListings(listings, maxPriceCents: 4500);
    expect(result.map((l) => l.id), ['l1', 'l3']);
  });

  test('combines query, category, and max price', () {
    final result = filterListings(
      listings,
      query: 'nike',
      category: ListingCategory.clothing,
      maxPriceCents: 2500,
    );
    expect(result.map((l) => l.id), ['l3']);
  });

  group('stillLive', () {
    final now = DateTime(2026, 1, 1, 12);

    test('keeps a listing whose window is still open', () {
      final fresh = _listing(
        id: 'fresh',
        title: 'Fresh drop',
        priceCents: 1000,
        postedAt: now.subtract(const Duration(hours: 7)),
      );
      expect(stillLive([fresh], now: now).map((l) => l.id), ['fresh']);
    });

    test('drops a listing whose 8 hours have run out', () {
      // Nothing ever flips `status` when the timer ends, so an expired
      // listing keeps streaming in from Firestore forever — this is the
      // only thing keeping it out of the feed.
      final dead = _listing(
        id: 'dead',
        title: 'Yesterday',
        priceCents: 1000,
        postedAt: now.subtract(const Duration(hours: 9)),
      );
      expect(stillLive([dead], now: now), isEmpty);
    });

    test('drops a listing exactly at its expiry instant', () {
      final onTheLine = _listing(
        id: 'edge',
        title: 'On the line',
        priceCents: 1000,
        postedAt: now.subtract(const Duration(hours: 8)),
      );
      expect(stillLive([onTheLine], now: now), isEmpty);
    });

    test('honours a non-default liveFor rather than assuming 8 hours', () {
      final shortDrop = _listing(
        id: 'short',
        title: 'Quick one',
        priceCents: 1000,
        postedAt: now.subtract(const Duration(hours: 2)),
        liveFor: const Duration(hours: 1),
      );
      expect(stillLive([shortDrop], now: now), isEmpty);
    });
  });
}
