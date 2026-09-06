import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/chat_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/logo.dart';
import 'chat_screen.dart';

/// The inbox. Every row is a real thread from Firestore, keyed to the
/// listing it started on — on a marketplace the item is the context, so it
/// stays on the row rather than being something you have to open the
/// conversation to recover.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.uid;
    final blocked = appState.profile?.blockedUserIds ?? const [];

    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: S8llScreenHeading('Chat'),
            ),
            Expanded(
              child: StreamBuilder<List<ChatThreadSummary>>(
                stream: context.read<ChatRepository>().threadsFor(uid),
                builder: (context, snapshot) {
                  final threads = (snapshot.data ?? const [])
                      .where((t) => !blocked.contains(t.otherPartyId))
                      .toList();
                  if (threads.isEmpty) return const _EmptyInbox();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      S8llBottomNavBar.clearance,
                    ),
                    itemCount: threads.length,
                    itemBuilder: (context, index) => _ThreadRow(thread: threads[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread});

  final ChatThreadSummary thread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              listingId: thread.listingId,
              buyerId: thread.buyerId,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: S8llColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: S8llColors.divider, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Initial(name: thread.otherPartyName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.otherPartyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: S8llColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _ago(thread.lastMessageAt),
                          style: const TextStyle(color: S8llColors.greyLow, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: S8llColors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: S8llColors.charcoalHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        thread.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: S8llColors.lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

/// No avatar uploads exist, so a monogram on the brand tint stands in
/// rather than a stock face pulled off the internet.
class _Initial extends StatelessWidget {
  const _Initial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: S8llColors.limeSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: S8llColors.lime,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: S8llSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: S8llColors.greyLow),
            SizedBox(height: S8llSpacing.md),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: S8llColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: S8llSpacing.sm),
            Text(
              'Message a seller from any listing and it lands here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: S8llColors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
