import '../models.dart';

/// Drops listings whose 8-hour window has run out.
///
/// A listing's `status` field only ever moves to `sold` (by the payment
/// webhook) — nothing anywhere flips it when the timer runs out, so
/// `listings` still carries every expired drop it ever streamed. Expiry is
/// therefore purely a function of `postedAt + liveFor`, evaluated here at
/// read time rather than stored. Without this the whole 8-hour mechanic is
/// decorative: dead listings sit in the feed forever showing "Expired", and
/// they're counted in the "N live now" pill.
///
/// [now] is injected rather than read from the clock so this stays testable.
List<Listing> stillLive(List<Listing> listings, {required DateTime now}) {
  return listings.where((listing) => !listing.isExpired(now)).toList();
}

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
