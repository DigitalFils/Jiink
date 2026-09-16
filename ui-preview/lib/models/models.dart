class Product {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String location;
  final String seller;
  final String sellerAvatar;
  final double sellerRating;
  final int sellerSales;
  final String timeLeft;
  final String condition;
  final String description;
  final bool isVerified;
  final bool isLive;
  final int? watchers;
  final int? bids;
  final String category;
  final List<String>? tags;

  Product({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.location,
    required this.seller,
    required this.sellerAvatar,
    this.sellerRating = 4.8,
    this.sellerSales = 0,
    required this.timeLeft,
    this.condition = 'New',
    this.description = '',
    this.isVerified = false,
    this.isLive = false,
    this.watchers,
    this.bids,
    required this.category,
    this.tags,
  });
}

class LiveDrop {
  final String brand;
  final String imageUrl;
  final bool isLive;

  LiveDrop({
    required this.brand,
    required this.imageUrl,
    this.isLive = false,
  });
}

class FeedItem {
  final String id;
  final String seller;
  final String sellerAvatar;
  final String timeAgo;
  final bool isVerified;
  final String title;
  final double price;
  final List<String> images;
  final String action;
  final int? bids;
  final int? watching;
  final String condition;
  final int? ordersToday;

  FeedItem({
    required this.id,
    required this.seller,
    required this.sellerAvatar,
    required this.timeAgo,
    this.isVerified = false,
    required this.title,
    required this.price,
    required this.images,
    required this.action,
    this.bids,
    this.watching,
    required this.condition,
    this.ordersToday,
  });
}

class ChatMessage {
  final String sender;
  final String text;
  final DateTime time;
  final bool isMe;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.isMe = false,
  });
}

class StoryItem {
  final String username;
  final String avatarUrl;
  final String time;
  final bool isLive;

  StoryItem({
    required this.username,
    required this.avatarUrl,
    required this.time,
    this.isLive = false,
  });
}
