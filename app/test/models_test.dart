import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/models.dart';

Listing _listing({
  required DateTime postedAt,
  Duration liveFor = const Duration(hours: 8),
  DeliveryMethod delivery = DeliveryMethod.both,
  ListingStatus status = ListingStatus.live,
  ListingCategory category = ListingCategory.other,
  String title = 'Nike Air Max 90',
  int priceCents = 4500,
  List<String>? watcherIds,
}) {
  return Listing(
    id: 'l1',
    sellerId: 'seller-1',
    sellerName: 'jordan_m',
    sellerCity: 'Manchester',
    title: title,
    priceCents: priceCents,
    delivery: delivery,
    postedAt: postedAt,
    status: status,
    category: category,
    liveFor: liveFor,
    watcherIds: watcherIds,
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

  group('watching', () {
    test('a listing with no watchers has a zero count and no watcher is watching', () {
      final listing = _listing(postedAt: DateTime.now());
      expect(listing.watcherCount, 0);
      expect(listing.isWatchedBy('anyone'), isFalse);
    });

    test('watcherCount and isWatchedBy reflect the watcher list', () {
      final listing = _listing(
        postedAt: DateTime.now(),
        watcherIds: ['buyer-1', 'buyer-2'],
      );
      expect(listing.watcherCount, 2);
      expect(listing.isWatchedBy('buyer-1'), isTrue);
      expect(listing.isWatchedBy('someone-else'), isFalse);
    });
  });

  group('SellerRating', () {
    test('has no ratings when the review count is zero', () {
      const rating = SellerRating(average: 0, count: 0);
      expect(rating.hasRatings, isFalse);
    });

    test('has ratings once at least one review exists', () {
      const rating = SellerRating(average: 4.5, count: 2);
      expect(rating.hasRatings, isTrue);
    });
  });

  group('Offer', () {
    test('offerInPounds converts pence correctly', () {
      final offer = Offer(
        listingId: 'l1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        offerCents: 3500,
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(offer.offerInPounds, 35.0);
    });

    test('toCreateMap round-trips status as its name', () {
      final offer = Offer(
        listingId: 'l1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        offerCents: 3500,
        status: OfferStatus.accepted,
        createdAt: DateTime.now(),
      );
      expect(offer.toCreateMap()['status'], 'accepted');
    });
  });

  group('PurchaseOrder tracking', () {
    test('has no tracking when trackingNumber is unset', () {
      const order = PurchaseOrder(id: 'o1', listingId: 'l1', buyerId: 'b1', sellerId: 's1');
      expect(order.hasTracking, isFalse);
    });

    test('has no tracking when trackingNumber is empty', () {
      const order = PurchaseOrder(
        id: 'o1',
        listingId: 'l1',
        buyerId: 'b1',
        sellerId: 's1',
        trackingNumber: '',
      );
      expect(order.hasTracking, isFalse);
    });

    test('has tracking once a non-empty tracking number is set', () {
      const order = PurchaseOrder(
        id: 'o1',
        listingId: 'l1',
        buyerId: 'b1',
        sellerId: 's1',
        trackingNumber: '1Z999',
      );
      expect(order.hasTracking, isTrue);
    });
  });

  group('Report', () {
    test('toCreateMap round-trips targetType as its name', () {
      final report = Report(
        reporterId: 'buyer-1',
        targetType: ReportTargetType.listing,
        targetId: 'l1',
        reason: 'Counterfeit item',
        createdAt: DateTime.now(),
      );
      expect(report.toCreateMap()['targetType'], 'listing');
    });
  });

  group('SavedSearch', () {
    test('toCreateMap includes a null category when none was chosen', () {
      final search = SavedSearch(
        id: '',
        buyerId: 'buyer-1',
        query: 'trainers',
        createdAt: DateTime.now(),
      );
      final map = search.toCreateMap();
      expect(map['category'], isNull);
      expect(map['query'], 'trainers');
    });

    test('fromFirestore round-trips a category', () {
      final search = SavedSearch(
        id: '',
        buyerId: 'buyer-1',
        query: 'trainers',
        category: ListingCategory.clothing,
        maxPriceCents: 5000,
        createdAt: DateTime.now(),
      );
      expect(search.toCreateMap()['category'], 'clothing');
      expect(search.toCreateMap()['maxPriceCents'], 5000);
    });
  });
}
