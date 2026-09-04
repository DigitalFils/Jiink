import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// A thread is keyed by the listing plus the buyer who started it, so a
  /// listing with several interested buyers gets a separate thread each —
  /// not one thread that whoever messages last overwrites.
  String threadIdFor({required String listingId, required String buyerId}) =>
      '${listingId}_$buyerId';

  DocumentReference<Map<String, dynamic>> _thread(String threadId) =>
      _firestore.collection('chatThreads').doc(threadId);

  Stream<List<ChatMessage>> messages(String threadId) {
    return _thread(threadId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Threads the given user is a participant in (as buyer or seller),
  /// newest activity first.
  Stream<List<ChatThreadSummary>> threadsFor(String uid) {
    return _firestore
        .collection('chatThreads')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final participants =
                  Map<String, String>.from(data['participantNames'] as Map);
              final otherName = participants.entries
                  .firstWhere((entry) => entry.key != uid,
                      orElse: () => const MapEntry('', 'Seller'))
                  .value;
              return ChatThreadSummary(
                threadId: doc.id,
                listingId: data['listingId'] as String,
                buyerId: data['buyerId'] as String,
                listingTitle: data['listingTitle'] as String,
                otherPartyName: otherName,
                lastMessageText: data['lastMessageText'] as String? ?? '',
                lastMessageAt:
                    (data['lastMessageAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
              );
            }).toList());
  }

  Future<void> sendMessage({
    required Listing listing,
    required String buyerId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final threadId = threadIdFor(listingId: listing.id, buyerId: buyerId);
    final threadRef = _thread(threadId);
    await threadRef.set({
      'listingId': listing.id,
      'buyerId': buyerId,
      // Fixed by role, not by who happens to be sending right now — a
      // seller's reply must never overwrite the buyer's id with their own.
      'participantIds': [listing.sellerId, buyerId],
      // Dotted paths so each side only ever writes its own name into the
      // map — a plain nested-map merge would replace the whole map and
      // let the seller's reply clobber the buyer's stored name.
      'participantNames.${listing.sellerId}': listing.sellerName,
      'participantNames.$senderId': senderName,
      'listingTitle': listing.title,
      'lastMessageText': trimmed,
      'lastMessageAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await threadRef.collection('messages').add({
      'senderId': senderId,
      'text': trimmed,
      'sentAt': Timestamp.now(),
    });
  }
}
