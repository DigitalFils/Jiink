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
  });

  final String uid;
  final String displayName;
  final String city;
  final bool payoutsEnabled;
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
    );
  }

  Future<void> bumpListing(String listingId) => _repository.bump(listingId);

  Future<void> setWatching(String listingId, {required bool watching}) =>
      _repository.setWatching(listingId, uid, watching: watching);

  @override
  void dispose() {
    _profileSub.cancel();
    _listingsSub.cancel();
    _myListingsSub.cancel();
    super.dispose();
  }
}
