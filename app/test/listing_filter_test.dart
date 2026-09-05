import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/models.dart';
import 'package:s8ll/services/listing_filter.dart';

Listing _listing({
  required String id,
  required String title,
  required int priceCents,
  ListingCategory category = ListingCategory.other,
}) {
  return Listing(
    id: id,
    sellerId: 'seller-1',
    sellerName: 'jordan_m',
    sellerCity: 'Manchester',
    title: title,
    priceCents: priceCents,
    delivery: DeliveryMethod.both,
    postedAt: DateTime.now(),
    category: category,
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
}
