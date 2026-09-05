import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class ReviewsRepository {
  ReviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  /// The order that would make [buyerId] eligible to review [listingId], if
  /// they actually bought it. Orders only ever come from the Stripe
  /// webhook, so finding one here is proof of a real completed purchase.
  Future<PurchaseOrder?> orderForPurchase({required String buyerId, required String listingId}) async {
    final query = await _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return PurchaseOrder.fromFirestore(query.docs.first);
  }

  /// Whether — and how — [buyerId] already reviewed this listing's sale.
  Stream<Review?> reviewForListing(String listingId) {
    return _reviews
        .doc(listingId)
        .snapshots()
        .map((doc) => doc.exists ? Review.fromFirestore(doc) : null);
  }

  Future<void> leaveReview({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required String orderId,
    required int rating,
    String comment = '',
  }) {
    assert(rating >= 1 && rating <= 5);
    final review = Review(
      listingId: listingId,
      sellerId: sellerId,
      buyerId: buyerId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    // .set() without merge, matching the doc-id-is-the-key pattern used for
    // listings/chatThreads — firestore.rules classifies a second attempt at
    // the same listingId as an update, and update is unconditionally denied,
    // so a listing can only ever be reviewed once.
    return _reviews.doc(listingId).set(review.toCreateMap());
  }

  /// Computed live via a Firestore aggregation query — no denormalized
  /// counter to keep in sync, and nothing for a client to tamper with: the
  /// number is only ever as trustworthy as the reviews it's built from, and
  /// those are gated by firestore.rules on a real completed purchase.
  ///
  /// A one-shot fetch, not a stream — aggregation queries don't support
  /// live updates, and a rating that changes at most once per sale doesn't
  /// need them. Screens re-fetch on their own re-navigation/refresh.
  Future<SellerRating> sellerRating(String sellerId) async {
    final query = _reviews.where('sellerId', isEqualTo: sellerId);
    final snapshot = await query.aggregate(count(), average('rating')).get();
    return SellerRating(
      count: snapshot.count ?? 0,
      average: snapshot.getAverage('rating') ?? 0,
    );
  }
}
