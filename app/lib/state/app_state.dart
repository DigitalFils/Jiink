import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models.dart';
import '../services/listings_repository.dart';

/// The signed-in seller's own profile — kept separate from FirebaseAuth's
/// User so screens have one place to read displayName/city/payoutsEnabled
/// without caring where each came from.
class Profile {
  const Profile({
    required this.uid,
    required this.displayName,
    required this.city,
    required this.payoutsEnabled,
    this.blockedUserIds = const [],
  });

  final String uid;
  final String displayName;
  final String city;
  final bool payoutsEnabled;

  /// Sellers this user has blocked — their listings and chat threads are
  /// filtered out client-side. This lives on the blocker's own profile doc,
  /// which they already have full read/write access to, so blocking needs
  /// no new Firestore rule at all.
  final List<String> blockedUserIds;

  bool hasBlocked(String uid) => blockedUserIds.contains(uid);
}

class AppState extends ChangeNotifier {
  AppState({required this.uid, ListingsRepository? repository})
      : _repository = repository ?? ListingsRepository() {
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(_onProfileSnapshot);
    _listingsSub = _repository.liveListings().listen(_onListingsSnapshot);
    _myListingsSub =
        _repository.listingsBySeller(uid).listen(_onMyListingsSnapshot);
  }

  final String uid;
  final ListingsRepository _repository;

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _profileSub;
  late final StreamSubscription<List<Listing>> _listingsSub;
  late final StreamSubscription<List<Listing>> _myListingsSub;

  Profile? _profile;
  List<Listing> _listings = [];
  List<Listing> _myListings = [];

  Profile? get profile => _profile;
  List<Listing> get listings => List.unmodifiable(_listings);
  List<Listing> get myListings => List.unmodifiable(_myListings);

  void _onProfileSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return;
    _profile = Profile(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Seller',
      city: data['city'] as String? ?? '',
      payoutsEnabled: data['payoutsEnabled'] as bool? ?? false,
      blockedUserIds: (data['blockedUserIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
    notifyListeners();
  }

  void _onListingsSnapshot(List<Listing> listings) {
    _listings = listings;
    notifyListeners();
  }

  void _onMyListingsSnapshot(List<Listing> listings) {
    _myListings = listings;
    notifyListeners();
  }

  Future<void> publishListing({
    required String title,
    required int priceCents,
    required DeliveryMethod delivery,
    required File photo,
    String description = '',
    ListingCategory category = ListingCategory.other,
  }) {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Profile not loaded yet.');
    }
    return _repository.publish(
      sellerId: uid,
      sellerName: profile.displayName,
      sellerCity: profile.city,
      title: title,
      priceCents: priceCents,
      delivery: delivery,
      photo: photo,
      description: description,
      category: category,
    );
  }

  Future<void> bumpListing(String listingId) => _repository.bump(listingId);

  Future<void> setWatching(String listingId, {required bool watching}) =>
      _repository.setWatching(listingId, uid, watching: watching);

  /// Blocking is just an update to this user's own profile doc, which they
  /// already have full read/write access to — no Firestore rule needed.
  Future<void> setBlocked(String otherUid, {required bool blocked}) {
    return FirebaseFirestore.instance.collection('users').doc(uid).update({
      'blockedUserIds':
          blocked ? FieldValue.arrayUnion([otherUid]) : FieldValue.arrayRemove([otherUid]),
    });
  }

  /// Registers this device's FCM token so Cloud Functions can push to it —
  /// stored as a set (arrayUnion) since the same account can be signed in
  /// on more than one device.
  Future<void> registerFcmToken(String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmTokens': FieldValue.arrayUnion([token])},
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    _profileSub.cancel();
    _listingsSub.cancel();
    _myListingsSub.cancel();
    super.dispose();
  }
}
