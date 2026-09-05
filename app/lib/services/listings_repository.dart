import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'storage_service.dart';

class ListingsRepository {
  ListingsRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  /// The public feed: everything still live, newest first.
  Stream<List<Listing>> liveListings() {
    return _listings
        .where('status', isEqualTo: ListingStatus.live.name)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromFirestore).toList());
  }

  Stream<List<Listing>> listingsBySeller(String sellerId) {
    return _listings
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromFirestore).toList());
  }

  Stream<Listing?> listing(String listingId) {
    return _listings
        .doc(listingId)
        .snapshots()
        .map((doc) => doc.exists ? Listing.fromFirestore(doc) : null);
  }

  Future<void> publish({
    required String sellerId,
    required String sellerName,
    required String sellerCity,
    required String title,
    required int priceCents,
    required DeliveryMethod delivery,
    required File photo,
    String description = '',
    ListingCategory category = ListingCategory.other,
  }) async {
    final photoUrl = await _storage.uploadListingPhoto(uid: sellerId, file: photo);
    final listing = Listing(
      id: '', // assigned by Firestore
      sellerId: sellerId,
      sellerName: sellerName,
      sellerCity: sellerCity,
      title: title,
      priceCents: priceCents,
      delivery: delivery,
      postedAt: DateTime.now(),
      description: description,
      photoUrl: photoUrl,
      category: category,
    );
    await _listings.add(listing.toCreateMap());
  }

  /// Re-lists an item at the top of the feed by resetting its post time.
  Future<void> bump(String listingId) {
    return _listings.doc(listingId).update({
      'postedAt': Timestamp.now(),
    });
  }

  /// Adds or removes [uid] from a listing's watcher list. Firestore rules
  /// allow this specific field to change on someone else's listing —
  /// nothing else about it — which is what lets a buyer watch an item
  /// without being able to touch its price, status, or anything else.
  Future<void> setWatching(String listingId, String uid, {required bool watching}) {
    return _listings.doc(listingId).update({
      'watcherIds': watching ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    });
  }
}
