import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<AppState>().threads.where((t) => t.messages.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threads.isEmpty
          ? const Center(
              child: Text('No conversations yet', style: TextStyle(color: S8llColors.grey)),
            )
          : ListView.builder(
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                final last = thread.messages.last;
                return ListTile(
                  title: Text(thread.listing.seller.name),
                  subtitle: Text(
                    last.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('£${thread.listing.price.toStringAsFixed(0)}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(listing: thread.listing)),
                  ),
                );
              },
            ),
    );
  }
}
