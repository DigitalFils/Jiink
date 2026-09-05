import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryMethod {
  meetup('Meet up'),
  shipping('Ship it'),
  both('Meet up or ship');

  const DeliveryMethod(this.label);

  final String label;
}

enum ListingStatus { live, sold }

class Listing {
  Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerCity,
    required this.title,
    required this.priceCents,
    required this.delivery,
    required this.postedAt,
    this.description = '',
    this.photoUrl,
    this.status = ListingStatus.live,
    Duration? liveFor,
    List<String>? watcherIds,
  })  : liveFor = liveFor ?? const Duration(hours: 8),
        watcherIds = watcherIds ?? const [];

  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerCity;
  final String title;

  /// Price in pence — the unit Stripe actually charges in. Never do money
  /// math in pounds; round-trip through this field.
  final int priceCents;

  final DeliveryMethod delivery;
  final DateTime postedAt;
  final String description;
  final String? photoUrl;
  final ListingStatus status;

  /// How long this listing stays live in the feed before it needs bumping.
  final Duration liveFor;

  /// Buyers who are watching this listing. S8LL has no "likes" — watching
  /// is the only passive social signal, and unlike a like it means
  /// something: a watcher gets outbid-style urgency as the drop timer
  /// counts down, not just a vanity count.
  final List<String> watcherIds;

  int get watcherCount => watcherIds.length;

  bool isWatchedBy(String uid) => watcherIds.contains(uid);

  double get priceInPounds => priceCents / 100;

  DateTime get expiresAt => postedAt.add(liveFor);

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(DateTime now) => remaining(now) == Duration.zero;

  bool get canBuyInApp =>
      status == ListingStatus.live && delivery != DeliveryMethod.meetup;

  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Listing(
      id: doc.id,
      sellerId: data['sellerId'] as String,
      sellerName: data['sellerName'] as String,
      sellerCity: data['sellerCity'] as String,
      title: data['title'] as String,
      priceCents: data['priceCents'] as int,
      delivery: DeliveryMethod.values.byName(data['delivery'] as String),
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: ListingStatus.values.byName(data['status'] as String? ?? 'live'),
      liveFor: Duration(seconds: data['liveForSeconds'] as int? ?? 28800),
      watcherIds: (data['watcherIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerCity': sellerCity,
        'title': title,
        'priceCents': priceCents,
        'delivery': delivery.name,
        'postedAt': Timestamp.fromDate(postedAt),
        'description': description,
        'photoUrl': photoUrl,
        'status': status.name,
        'liveForSeconds': liveFor.inSeconds,
        'watcherIds': watcherIds,
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A completed purchase — written only by the Stripe webhook (Admin SDK),
/// never by a client. Doc id is the Stripe PaymentIntent id.
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;

  factory PurchaseOrder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PurchaseOrder(
      id: doc.id,
      listingId: data['listingId'] as String,
      buyerId: data['buyerId'] as String,
      sellerId: data['sellerId'] as String,
    );
  }
}

/// A buyer's rating of a seller, left after a completed purchase. Doc id is
/// the listingId — a listing sells at most once, so that's already a
/// unique key per transaction, and it's what the client has on hand
/// without an extra lookup.
class Review {
  const Review({
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.orderId,
    required this.rating,
    required this.createdAt,
    this.comment = '',
  });

  final String listingId;
  final String sellerId;
  final String buyerId;
  final String orderId;

  /// 1-5. Enforced server-side by firestore.rules, not just here.
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Review(
      listingId: doc.id,
      sellerId: data['sellerId'] as String,
      buyerId: data['buyerId'] as String,
      orderId: data['orderId'] as String,
      rating: data['rating'] as int,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'sellerId': sellerId,
        'buyerId': buyerId,
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// A seller's aggregate rating, computed live from `reviews` via Firestore
/// aggregation queries — never denormalized/stored, so there's no counter
/// to keep in sync and nothing for a client to tamper with.
class SellerRating {
  const SellerRating({required this.average, required this.count});

  final double average;
  final int count;

  bool get hasRatings => count > 0;
}

enum OfferStatus { pending, accepted, declined }

/// A buyer's offer on a listing. Doc id is listingId_buyerId, so a buyer
/// gets exactly one active offer per listing — see firestore.rules. If
/// accepted, checkout charges offerCents instead of the listing price;
/// nothing on the client needs to pass that along, the backend looks the
/// accepted offer up itself.
class Offer {
  const Offer({
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.offerCents,
    required this.status,
    required this.createdAt,
  });

  final String listingId;
  final String buyerId;
  final String sellerId;
  final int offerCents;
  final OfferStatus status;
  final DateTime createdAt;

  double get offerInPounds => offerCents / 100;

  factory Offer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Offer(
      listingId: data['listingId'] as String,
      buyerId: data['buyerId'] as String,
      sellerId: data['sellerId'] as String,
      offerCents: data['offerCents'] as int,
      status: OfferStatus.values.byName(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'listingId': listingId,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'offerCents': offerCents,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// One row in the buyer/seller inbox — denormalized onto the thread doc so
/// the list screen doesn't have to read every message subcollection.
class ChatThreadSummary {
  const ChatThreadSummary({
    required this.threadId,
    required this.listingId,
    required this.buyerId,
    required this.listingTitle,
    required this.otherPartyName,
    required this.lastMessageText,
    required this.lastMessageAt,
  });

  final String threadId;
  final String listingId;
  final String buyerId;
  final String listingTitle;
  final String otherPartyName;
  final String lastMessageText;
  final DateTime lastMessageAt;
}
