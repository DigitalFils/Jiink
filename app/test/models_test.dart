import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/models.dart';

Listing _listing({
  required DateTime postedAt,
  Duration liveFor = const Duration(hours: 8),
  DeliveryMethod delivery = DeliveryMethod.both,
  ListingStatus status = ListingStatus.live,
}) {
  return Listing(
    id: 'l1',
    sellerId: 'seller-1',
    sellerName: 'jordan_m',
    sellerCity: 'Manchester',
    title: 'Nike Air Max 90',
    priceCents: 4500,
    delivery: delivery,
    postedAt: postedAt,
    status: status,
    liveFor: liveFor,
  );
}

void main() {
  group('Listing timing', () {
    test('remaining() counts down and never goes negative', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final listing = _listing(
        postedAt: now.subtract(const Duration(hours: 1)),
        liveFor: const Duration(hours: 8),
      );

      expect(listing.remaining(now), const Duration(hours: 7));
      expect(listing.isExpired(now), isFalse);

      final wayLater = now.add(const Duration(days: 1));
      expect(listing.remaining(wayLater), Duration.zero);
      expect(listing.isExpired(wayLater), isTrue);
    });

    test('priceInPounds converts pence correctly', () {
      final listing = _listing(postedAt: DateTime.now());
      expect(listing.priceInPounds, 45.0);
    });
  });

  group('canBuyInApp', () {
    test('meet-up-only listings cannot be bought in app', () {
      final listing = _listing(
        postedAt: DateTime.now(),
        delivery: DeliveryMethod.meetup,
      );
      expect(listing.canBuyInApp, isFalse);
    });

    test('shippable live listings can be bought in app', () {
      final listing = _listing(
        postedAt: DateTime.now(),
        delivery: DeliveryMethod.shipping,
      );
      expect(listing.canBuyInApp, isTrue);
    });

    test('sold listings can never be bought again, regardless of delivery', () {
      final listing = _listing(
        postedAt: DateTime.now(),
        delivery: DeliveryMethod.both,
        status: ListingStatus.sold,
      );
      expect(listing.canBuyInApp, isFalse);
    });
  });
}
