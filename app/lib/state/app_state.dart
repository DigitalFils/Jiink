import 'package:flutter/foundation.dart';

import '../models.dart';

const currentUser = Seller(id: 'me', name: 'You', city: 'Manchester');

class AppState extends ChangeNotifier {
  AppState() {
    _listings.addAll(_seedListings());
  }

  final List<Listing> _listings = [];
  final Map<String, ChatThread> _threads = {};

  List<Listing> get listings => List.unmodifiable(_listings);

  List<Listing> get myListings =>
      _listings.where((l) => l.seller.id == currentUser.id).toList();

  List<ChatThread> get threads => List.unmodifiable(_threads.values);

  void publishListing({
    required String title,
    required double price,
    required DeliveryMethod delivery,
    String description = '',
    String? photoPath,
  }) {
    final listing = Listing(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      price: price,
      seller: currentUser,
      delivery: delivery,
      postedAt: DateTime.now(),
      description: description,
      photoPath: photoPath,
    );
    _listings.insert(0, listing);
    notifyListeners();
  }

  void bumpListing(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    final old = _listings.removeAt(index);
    _listings.insert(
      0,
      Listing(
        id: old.id,
        title: old.title,
        price: old.price,
        seller: old.seller,
        delivery: old.delivery,
        postedAt: DateTime.now(),
        description: old.description,
        photoPath: old.photoPath,
        liveFor: old.liveFor,
      ),
    );
    notifyListeners();
  }

  ChatThread threadFor(Listing listing) {
    return _threads.putIfAbsent(listing.id, () => ChatThread(listing: listing));
  }

  void sendMessage(Listing listing, String text) {
    if (text.trim().isEmpty) return;
    final thread = threadFor(listing);
    thread.messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fromSelf: true,
      text: text.trim(),
      sentAt: DateTime.now(),
    ));
    notifyListeners();
  }

  List<Listing> _seedListings() {
    final now = DateTime.now();
    return [
      Listing(
        id: 'seed-1',
        title: 'Nike Air Max 90, worn twice',
        price: 45,
        seller: const Seller(id: 's1', name: 'jordan_m', city: 'Manchester'),
        delivery: DeliveryMethod.both,
        postedAt: now.subtract(const Duration(hours: 1)),
        description: 'Size 9. No box, still in great shape.',
      ),
      Listing(
        id: 'seed-2',
        title: 'Vintage denim jacket',
        price: 28,
        seller: const Seller(id: 's2', name: 'freya.k', city: 'Manchester'),
        delivery: DeliveryMethod.shipping,
        postedAt: now.subtract(const Duration(hours: 3)),
        description: 'Y2K era, oversized fit.',
      ),
      Listing(
        id: 'seed-3',
        title: 'PS5 controller — barely used',
        price: 35,
        seller: const Seller(id: 's3', name: 'ammar_', city: 'Manchester'),
        delivery: DeliveryMethod.meetup,
        postedAt: now.subtract(const Duration(hours: 6)),
        description: 'Pickup near Thomas St.',
      ),
    ];
  }
}
