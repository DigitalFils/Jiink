import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  bool _isTyping = false;

  final List<AIMessage> _messages = [
    AIMessage(
      content: 'Hey! I\'m your S8LL AI Shopping Assistant 👋\n\nI can help you:\n• Find the best deals\n• Compare products\n• Get style recommendations\n• Answer product questions\n\nWhat are you looking for today?',
      isAI: true,
      timestamp: DateTime.now(),
    ),
  ];

  final List<String> _quickPrompts = [
    '🔥 Best sneakers under £100',
    '👕 Winter jacket recommendations',
    '💰 Find group buy deals',
    '✨ Vintage camera suggestions',
    '🎁 Gift ideas for sneakerheads',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(AIMessage(
        content: text,
        isAI: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_generateAIResponse(text));
        });
        _scrollToBottom();
      }
    });
  }

  AIMessage _generateAIResponse(String query) {
    final queryLower = query.toLowerCase();
    String response;

    if (queryLower.contains('sneaker') || queryLower.contains('shoe')) {
      response = 'Great choice! Here are my top sneaker recommendations:\n\n👟 **Nike Dunk Low "Panda"** - £129\nClassic black/white colorway, versatile for any outfit. Currently trending up 15% this month.\n\n👟 **Adidas Samba OG** - £89\nTimeless design, perfect for smart-casual looks. Best value option.\n\n👟 **New Balance 550** - £110\nRetro basketball style, very comfortable. Limited stock available!\n\nWant me to find the best prices for any of these?';
    } else if (queryLower.contains('jacket') || queryLower.contains('winter')) {
      response = 'Here are winter jacket picks for different styles:\n\n🧥 **Carhartt WIP Detroit** - £75\nWorkwear classic, durable and stylish. 7 bids currently active.\n\n🧥 **The North Face Nuptse** - £180\nPremium warmth, iconic puffer style. Verified sellers only.\n\n🧥 **Stussy Hoodie** - £142\nStreetwear essential, cozy and fashionable. Group buy available!\n\nWould you like to see AR previews of these?';
    } else if (queryLower.contains('deal') || queryLower.contains('cheap') || queryLower.contains('under')) {
      response = 'I found some amazing deals for you! 🔥\n\n⚡ **Flash Sale**: Adidas Stan Smith - £24 (was £42)\n⚡ **Group Buy**: Stainless Steel Bottle - £10 (need 2 more people)\n⚡ **Ending Soon**: Vintage Camera - £25 (7h left)\n⚡ **New Listing**: Leather Belt - £12\n\nWant me to set up price alerts for any specific items?';
    } else if (queryLower.contains('camera') || queryLower.contains('vintage')) {
      response = 'Vintage camera recommendations:\n\n📷 **Polaroid 600** - £25\nSealed film pack included. Perfect for instant photography lovers.\n\n📷 **Vintage Film Camera** - £320\nProfessional grade, excellent condition. From a verified Gold Seller.\n\n💡 Pro tip: Check the "Buyer Protection" badge for added security on vintage items.\n\nWant me to show you similar listings on the map?';
    } else if (queryLower.contains('gift')) {
      response = '🎁 Gift ideas for sneakerheads:\n\n1. **Sneaker Cleaning Kit** - £18\n   Essential maintenance for their collection\n\n2. **Limited Edition Poster** - £25\n   Iconic sneaker art prints\n\n3. **Shoe Trees** - £15\n   Keep their kicks in perfect shape\n\n4. **S8LL Gift Card** - Any amount\n   Let them choose their perfect pair!\n\nWant more personalized recommendations? Tell me their style!';
    } else {
      response = 'That\'s an interesting query! Let me help you find what you\'re looking for.\n\nI can search across:\n• 50K+ verified listings\n• Live streaming deals\n• Group buy opportunities\n• Nearby sellers on the map\n\nCould you tell me more about:\n• Your budget range?\n• Preferred style or brand?\n• New or pre-owned items?\n\nOr try one of the quick prompts below!';
    }

    return AIMessage(
      content: response,
      isAI: true,
      timestamp: DateTime.now(),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppAnimations.medium,
          curve: AppAnimations.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _messages.length <= 1
                  ? _buildWelcomeView()
                  : _buildChatView(),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildQuickPrompts(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.background, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'S8LL AI Assistant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: AppTheme.success, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Online • Powered by Advanced AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.background, size: 50),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'I can find deals, recommend products, compare prices, and more. Just ask!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildCapabilityCard(
            icon: Icons.search,
            title: 'Smart Search',
            desc: 'Find products using natural language',
            color: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          _buildCapabilityCard(
            icon: Icons.insights,
            title: 'Price Analysis',
            desc: 'Get market insights and price trends',
            color: AppTheme.info,
          ),
          const SizedBox(height: 12),
          _buildCapabilityCard(
            icon: Icons.palette,
            title: 'Style Advice',
            desc: 'Personalized outfit recommendations',
            color: AppTheme.warning,
          ),
          const SizedBox(height: 12),
          _buildCapabilityCard(
            icon: Icons.shield,
            title: 'Authenticity Check',
            desc: 'Verify product legitimacy before buying',
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(AIMessage msg) {
    final isAI = msg.isAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.background, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isAI ? AppTheme.surface : AppTheme.accent,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(18),
                  bottomRight: isAI ? const Radius.circular(18) : const Radius.circular(4),
                ),
                border: isAI ? Border.all(color: AppTheme.border) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: isAI ? AppTheme.textPrimary : AppTheme.background,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: isAI ? AppTheme.textMuted : AppTheme.background.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=68'),
              backgroundColor: AppTheme.surfaceLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(58, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withOpacity(
                          0.3 + 0.7 * ((_typingController.value + index * 0.3) % 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    if (_messages.length > 3) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(_quickPrompts[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  _quickPrompts[index],
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppTheme.textMuted),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything about shopping...',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppTheme.background, size: 20),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class AIMessage {
  final String content;
  final bool isAI;
  final DateTime timestamp;

  AIMessage({
    required this.content,
    required this.isAI,
    required this.timestamp,
  });
}
