import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/chat/models/chat_model.dart';

/// Service layer that handles all Firestore operations for the Chat feature.
/// Designed as a standalone class that can be injected into providers or widgets.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Streams ───────────────────────────────────────────────────────────────

  /// Streams all chats where the given user is a participant.
  /// Ordered by lastMessageTime DESC.
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromDoc(d)).toList());
  }

  /// Streams all messages for a specific chat, ordered by createdAt ASC.
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  /// Standardizes ChatRoom ID generation by sorting UIDs alphabetically.
  /// Ensures symmetric IDs (A_B is the same as B_A).
  String getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Sort A-Z
    return ids.join('_');
  }

  /// Creates a new chat or returns the existing one.
  /// Matches on userId + sellerId.
  Future<String> createOrGetChat({
    required String userId,
    required String sellerId,
    String? productId,
  }) async {
    final chatId = getChatRoomId(userId, sellerId);
    final docRef = _db.collection('chats').doc(chatId);
    
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.set({
        'deletedBy': [],
      }, SetOptions(merge: true));
      return chatId;
    }

    // Create a new chat document with the deterministic ID
    final now = DateTime.now();
    await docRef.set({
      'userId': userId,
      'sellerId': sellerId,
      'productId': productId,
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(now),
      'participants': [userId, sellerId],
      'deletedBy': [],
    }, SetOptions(merge: true));
    
    return chatId;
  }

  /// Sends a message and updates the chat's lastMessage metadata.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    // Add the new message document
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(now),
      'isRead': false,
      'type': type,
      if (metadata != null) 'metadata': metadata,
      if (replyToId != null) 'replyToId': replyToId,
      'isRecalled': false,
    });

    // Update parent chat document (and reset deletedBy so it reappears if soft-deleted)
    final chatRef = _db.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': senderId,
      'lastMessageIsRead': false,
      'deletedBy': [],
    });

    await batch.commit();
  }

  /// Marks all unread messages from the OTHER participant as read.
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    final batch = _db.batch();

    // Find all unread messages not sent by the current user
    final unreadQuery = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (final doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Also update the parent chat document if the last message is from the other user
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chatData = chatDoc.data()!;
      if (chatData['lastMessageSenderId'] != currentUserId && chatData['lastMessageIsRead'] == false) {
        batch.update(chatDoc.reference, {'lastMessageIsRead': true});
      }
    }

    await batch.commit();
  }

  /// Soft deletes a chat for the given user.
  Future<void> deleteChat(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Task 1: Pin a message in a chat
  Future<void> pinMessage(String chatId, String? messageId) async {
    await _db.collection('chats').doc(chatId).update({
      'pinnedMessageId': messageId,
    });
  }

  /// Task 3: Recall a specific message
  Future<void> recallMessage(String chatId, String messageId) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'isRecalled': true,
    });
  }

  /// Task 4: Block a user
  Future<void> blockUser(String currentUserId, String targetUid) async {
    await _db.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> unblockUser(String currentUserId, String targetUid) async {
    await _db.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([targetUid]),
    });
  }

  /// Fetches a user document (name, avatar) from Firestore.
  /// Checks sellers collection first (for shop info), then falls back to users.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    // Check if this UID belongs to a seller to get Shop name/avatar
    final sellerQuery = await _db.collection('sellers').where('userId', isEqualTo: uid).limit(1).get();
    if (sellerQuery.docs.isNotEmpty) {
      return sellerQuery.docs.first.data();
    }

    // Fallback to regular user profile
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
