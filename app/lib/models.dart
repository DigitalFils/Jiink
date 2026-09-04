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
  }) : liveFor = liveFor ?? const Duration(hours: 8);

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
