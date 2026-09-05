import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/chat_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.uid;
    final blocked = appState.profile?.blockedUserIds ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ChatThreadSummary>>(
        stream: context.read<ChatRepository>().threadsFor(uid),
        builder: (context, snapshot) {
          final threads =
              (snapshot.data ?? const []).where((t) => !blocked.contains(t.otherPartyId)).toList();
          if (threads.isEmpty) {
            return Center(
              child: Text('No conversations yet', style: TextStyle(color: context.s8ll.textSecondary)),
            );
          }
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              return ListTile(
                title: Text(thread.otherPartyName),
                subtitle: Text(
                  thread.lastMessageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  thread.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.s8ll.textSecondary, fontSize: 12),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      listingId: thread.listingId,
                      buyerId: thread.buyerId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
