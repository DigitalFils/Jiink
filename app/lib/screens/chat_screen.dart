import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/chat_repository.dart';
import '../services/listings_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.listingId, required this.buyerId});

  final String listingId;

  /// The buyer side of this conversation — always the non-seller party,
  /// regardless of who's currently viewing the screen.
  final String buyerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(Listing listing, String senderName, String senderId) {
    if (_controller.text.trim().isEmpty) return;
    context.read<ChatRepository>().sendMessage(
          listing: listing,
          buyerId: widget.buyerId,
          senderId: senderId,
          senderName: senderName,
          text: _controller.text,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().uid;
    final listingsRepo = context.read<ListingsRepository>();
    final chatRepo = context.read<ChatRepository>();
    final threadId =
        chatRepo.threadIdFor(listingId: widget.listingId, buyerId: widget.buyerId);

    return StreamBuilder<Listing?>(
      stream: listingsRepo.listing(widget.listingId),
      builder: (context, listingSnap) {
        final listing = listingSnap.data;
        if (listing == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isSeller = uid == listing.sellerId;
        final otherName = isSeller ? 'Buyer' : listing.sellerName;
        // The buyer's own display name is needed to seed the thread the
        // first time — fall back to a placeholder if their profile hasn't
        // loaded yet (only matters for the very first message).
        final selfName =
            context.watch<AppState>().profile?.displayName ?? 'S8LL user';

        return Scaffold(
          appBar: AppBar(title: Text(otherName)),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: chatRepo.messages(threadId),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? const [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Say hi about "${listing.title}"',
                          style: const TextStyle(color: S8llColors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final fromSelf = message.senderId == uid;
                        return Align(
                          alignment:
                              fromSelf ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: fromSelf ? S8llColors.lime : S8llColors.charcoal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: fromSelf ? S8llColors.black : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Message'),
                          onSubmitted: (_) => _send(listing, selfName, uid),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _send(listing, selfName, uid),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
