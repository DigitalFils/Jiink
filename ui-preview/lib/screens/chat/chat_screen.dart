import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<double> _quickOffers = [0.9, 0.8, 0.7];
  final double _originalPrice = 85;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: SampleData.chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = SampleData.chatMessages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
            _buildQuickOffers(),
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
          const SizedBox(width: 4),
          Icon(
            Icons.diamond_outlined,
            color: AppTheme.accent,
            size: 22,
          ),
          const SizedBox(width: 4),
          const Text(
            'S8LL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Chat',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
            backgroundColor: AppTheme.surfaceLight,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jordan_L',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'онлайн • отвечает быстро',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(msg) {
    final isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: isMe ? AppTheme.background : AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.time),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isMe ? AppTheme.background.withOpacity(0.6) : AppTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, color: AppTheme.background.withOpacity(0.6), size: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOffers() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'БЫСТРЫЕ ПРЕДЛОЖЕНИЯ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _quickOffers.map((discount) {
              final price = (_originalPrice * discount).toStringAsFixed(2);
              final percent = (discount * 100).toInt();
              final isSelected = false;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : AppTheme.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppTheme.background : AppTheme.accent,
                        ),
                      ),
                      Text(
                        '— £$price',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Написать сообщение...',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: AppTheme.background),
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    _messageController.clear();
                  }
                },
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
