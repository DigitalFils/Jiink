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

  /// 24-hour clock, zero-padded. Written out rather than pulled from
  /// `intl` — the app doesn't depend on it, and this is the only place
  /// that formats a time.
  String _timeLabel(DateTime sentAt) {
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                // An initial, not a photo — profiles carry no avatar, and
                // the prototype's "online • responds fast" line has no
                // presence data behind it, so neither is drawn.
                CircleAvatar(
                  radius: 16,
                  backgroundColor: S8llColors.limeSoft,
                  child: Text(
                    otherName.isEmpty ? '?' : otherName[0].toUpperCase(),
                    style: const TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.s8ll.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                          style: TextStyle(color: context.s8ll.textSecondary),
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
                            margin: const EdgeInsets.only(bottom: 10),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: fromSelf ? S8llColors.lime : context.s8ll.surfaceHigh,
                              // Square off the corner nearest the sender so
                              // each bubble points back at whoever wrote it.
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(fromSelf ? 18 : 4),
                                bottomRight: Radius.circular(fromSelf ? 4 : 18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    height: 1.3,
                                    fontSize: 15,
                                    color: fromSelf
                                        ? S8llColors.black
                                        : context.s8ll.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Real send time off the message document.
                                // No read receipts here — nothing records
                                // whether the other side has seen it.
                                Text(
                                  _timeLabel(message.sentAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fromSelf
                                        ? S8llColors.black.withValues(alpha: 0.6)
                                        : context.s8ll.textTertiary,
                                  ),
                                ),
                              ],
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
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor: context.s8ll.surfaceHigh,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: S8llSpacing.lg,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(S8llRadius.pill),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(S8llRadius.pill),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(S8llRadius.pill),
                              borderSide: const BorderSide(color: S8llColors.lime),
                            ),
                          ),
                          onSubmitted: (_) => _send(listing, selfName, uid),
                        ),
                      ),
                      const SizedBox(width: S8llSpacing.sm),
                      Material(
                        color: S8llColors.lime,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _send(listing, selfName, uid),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.arrow_upward, color: S8llColors.black, size: 20),
                          ),
                        ),
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
