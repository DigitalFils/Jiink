import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class OffersRepository {
  OffersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  /// A buyer gets exactly one offer per listing — same composite-key
  /// pattern as ChatRepository's threadIdFor.
  String offerIdFor({required String listingId, required String buyerId}) =>
      '${listingId}_$buyerId';

  /// This buyer's own offer on this listing, if they've made one.
  Stream<Offer?> offerFor({required String listingId, required String buyerId}) {
    return _offers
        .doc(offerIdFor(listingId: listingId, buyerId: buyerId))
        .snapshots()
        .map((doc) => doc.exists ? Offer.fromFirestore(doc) : null);
  }

  /// Pending offers a seller has received on one of their listings, for
  /// them to accept or decline.
  ///
  /// Filtering by [sellerId] isn't just belt-and-braces — firestore.rules
  /// can only allow a list query when every field it checks (here,
  /// `sellerId == request.auth.uid`) is also a filter on the query itself,
  /// so Firestore can prove the rule holds for every possible result.
  /// Without this filter the query is provably unsafe from Firestore's
  /// point of view and the whole request is denied, even for the listing's
  /// actual seller.
  Stream<List<Offer>> pendingOffersForListing(String listingId, String sellerId) {
    return _offers
        .where('listingId', isEqualTo: listingId)
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: OfferStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map(Offer.fromFirestore).toList());
  }

  Future<void> makeOffer({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required int offerCents,
  }) {
    final offer = Offer(
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      offerCents: offerCents,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
    );
    return _offers
        .doc(offerIdFor(listingId: listingId, buyerId: buyerId))
        .set(offer.toCreateMap());
  }

  Future<void> respondToOffer({
    required String listingId,
    required String buyerId,
    required bool accept,
  }) {
    return _offers.doc(offerIdFor(listingId: listingId, buyerId: buyerId)).update({
      'status': accept ? OfferStatus.accepted.name : OfferStatus.declined.name,
      'respondedAt': Timestamp.now(),
    });
  }
}
