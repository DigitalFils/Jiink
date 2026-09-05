import '../models.dart';

/// Pure client-side filtering over an already-loaded listings list — no new
/// Firestore query/index needed, since AppState already streams every live
/// listing into memory for the feed.
List<Listing> filterListings(
  List<Listing> listings, {
  String query = '',
  ListingCategory? category,
  int? maxPriceCents,
}) {
  final needle = query.trim().toLowerCase();
  return listings.where((listing) {
    if (needle.isNotEmpty && !listing.title.toLowerCase().contains(needle)) {
      return false;
    }
    if (category != null && listing.category != category) {
      return false;
    }
    if (maxPriceCents != null && listing.priceCents > maxPriceCents) {
      return false;
    }
    return true;
  }).toList();
}
