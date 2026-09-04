import 'dart:io';

enum DeliveryMethod {
  meetup('Meet up'),
  shipping('Ship it'),
  both('Meet up or ship');

  const DeliveryMethod(this.label);

  final String label;
}

class Seller {
  const Seller({required this.id, required this.name, required this.city});

  final String id;
  final String name;
  final String city;
}

class Listing {
  Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.seller,
    required this.delivery,
    required this.postedAt,
    this.description = '',
    this.photoPath,
    Duration? liveFor,
  }) : liveFor = liveFor ?? const Duration(hours: 8);

  final String id;
  final String title;
  final double price;
  final Seller seller;
  final DeliveryMethod delivery;
  final DateTime postedAt;
  final String description;

  /// Path to a photo captured on-device. Null for seeded/mock listings,
  /// which fall back to a placeholder in the UI.
  final String? photoPath;

  /// How long this listing stays live in the feed before it needs bumping.
  final Duration liveFor;

  DateTime get expiresAt => postedAt.add(liveFor);

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(DateTime now) => remaining(now) == Duration.zero;

  File? get photoFile => photoPath == null ? null : File(photoPath!);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromSelf,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final bool fromSelf;
  final String text;
  final DateTime sentAt;
}

class ChatThread {
  ChatThread({required this.listing, List<ChatMessage>? messages})
      : messages = messages ?? [];

  final Listing listing;
  final List<ChatMessage> messages;

  String get id => listing.id;
}
