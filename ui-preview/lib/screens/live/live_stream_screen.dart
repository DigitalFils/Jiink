import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  late AnimationController _pulseController;
  int _viewerCount = 1247;
  int _likeCount = 8432;
  bool _isFollowing = false;
  final ScrollController _chatScrollController = ScrollController();

  final List<LiveChatMessage> _messages = [
    LiveChatMessage(user: 'SneakerHead_Jay', text: '🔥🔥🔥 These are fire!', color: AppTheme.accent),
    LiveChatMessage(user: 'kicks_collector', text: 'Size US 10 still available?', color: Colors.white),
    LiveChatMessage(user: 'hypebeast_99', text: 'Just copped a pair!', color: AppTheme.accent),
    LiveChatMessage(user: 'StreetStyle', text: 'How\'s the sizing run?', color: Colors.white),
    LiveChatMessage(user: 'MOD', text: '📢 Only 15 pairs left at this price!', color: AppTheme.gold, isMod: true),
    LiveChatMessage(user: 'NewBuyer', text: 'First time buying here, is it legit?', color: Colors.white),
    LiveChatMessage(user: 'VerifiedFan', text: '💯 Authentic, bought 3 pairs already', color: AppTheme.success),
  ];

  final List<StreamProduct> _products = [
    StreamProduct(
      id: '1',
      name: 'Nike Dunk Low "Panda"',
      price: 129,
      originalPrice: 189,
      image: 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=200',
      stock: 23,
      totalStock: 100,
      isFeatured: true,
    ),
    StreamProduct(
      id: '2',
      name: 'Adidas Samba OG',
      price: 89,
      originalPrice: 130,
      image: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=200',
      stock: 45,
      totalStock: 80,
    ),
    StreamProduct(
      id: '3',
      name: 'New Balance 550',
      price: 110,
      originalPrice: 150,
      image: 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=200',
      stock: 12,
      totalStock: 60,
    ),
  ];

  Timer? _viewerTimer;
  Timer? _chatTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Simulate viewer count changes
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _viewerCount += (DateTime.now().second % 3) - 1;
      });
    });

    // Simulate incoming chat messages
    _chatTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final randomMessages = [
        LiveChatMessage(user: 'user_${DateTime.now().second}', text: '🔥🔥', color: Colors.white),
        LiveChatMessage(user: 'shopper_42', text: 'Link in bio?', color: Colors.white),
        LiveChatMessage(user: 'dealoftheday', text: 'Amazing price!', color: AppTheme.accent),
      ];
      setState(() {
        _messages.add(randomMessages[DateTime.now().second % 3]);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _viewerTimer?.cancel();
    _chatTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildStreamBackground(),
          _buildTopBar(),
          _buildStreamerInfo(),
          _buildChatMessages(),
          _buildProductCarousel(),
          _buildRightActions(),
          _buildBottomInput(),
        ],
      ),
    );
  }

  Widget _buildStreamBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0F1A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Simulated streamer video area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.55,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Streamer avatar overlay
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=47'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8 + _pulseController.value * 4,
                          height: 8 + _pulseController.value * 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.liveRed,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.remove_red_eye, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatViewerCount(_viewerCount),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamerInfo() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.28,
      left: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '@sneakerqueen',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LV 4',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.background,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '🔥 Exclusive Drop • Limited Stock',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white70,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () => setState(() => _isFollowing = !_isFollowing),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isFollowing ? AppTheme.textSecondary : Colors.white,
                backgroundColor: _isFollowing ? Colors.transparent : AppTheme.accent,
                side: BorderSide(color: _isFollowing ? AppTheme.textMuted : AppTheme.accent),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isFollowing ? 'Following' : '+ Follow',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _isFollowing ? AppTheme.textSecondary : AppTheme.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return Positioned(
      left: 12,
      right: 80,
      bottom: 260,
      height: 200,
      child: ListView.builder(
        controller: _chatScrollController,
        reverse: false,
        itemCount: _messages.length,
        padding: const EdgeInsets.only(bottom: 8),
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: msg.isMod
                    ? AppTheme.gold.withOpacity(0.2)
                    : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${msg.user}: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: msg.color,
                      ),
                    ),
                    TextSpan(
                      text: msg.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCarousel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 120,
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            final soldPercent = ((product.totalStock - product.stock) / product.totalStock);
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: product.isFeatured ? AppTheme.surface : AppTheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: product.isFeatured ? AppTheme.accent : AppTheme.border,
                  width: product.isFeatured ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: AppTheme.surfaceLight);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (product.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.liveRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '£${product.price}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '£${product.originalPrice}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: soldPercent,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.stock} left',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 12,
      bottom: 260,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.favorite,
            count: _likeCount,
            onTap: () => setState(() => _likeCount++),
            color: AppTheme.liveRed,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.shopping_bag,
            count: null,
            badge: '3',
            onTap: () {},
            color: AppTheme.accent,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.card_giftcard,
            count: null,
            onTap: () {},
            color: AppTheme.gold,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.flag,
            count: null,
            onTap: () {},
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    int? count,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.liveRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (count != null)
            const SizedBox(height: 4),
          if (count != null)
            Text(
              _formatCount(count),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _messages.add(LiveChatMessage(
                            user: 'You',
                            text: value,
                            color: AppTheme.accent,
                          ));
                        });
                        _chatController.clear();
                        _scrollToBottom();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.background, size: 20),
                  onPressed: () {
                    if (_chatController.text.isNotEmpty) {
                      setState(() {
                        _messages.add(LiveChatMessage(
                          user: 'You',
                          text: _chatController.text,
                          color: AppTheme.accent,
                        ));
                      });
                      _chatController.clear();
                      _scrollToBottom();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatViewerCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(0)}k';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class LiveChatMessage {
  final String user;
  final String text;
  final Color color;
  final bool isMod;

  LiveChatMessage({
    required this.user,
    required this.text,
    required this.color,
    this.isMod = false,
  });
}

class StreamProduct {
  final String id;
  final String name;
  final double price;
  final double originalPrice;
  final String image;
  final int stock;
  final int totalStock;
  final bool isFeatured;

  StreamProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.stock,
    required this.totalStock,
    this.isFeatured = false,
  });
}
