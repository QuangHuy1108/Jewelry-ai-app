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

  /// Creates a new chat or returns the existing one.
  /// Matches on userId + sellerId + optional productId.
  Future<String> createOrGetChat({
    required String userId,
    required String sellerId,
    String? productId,
  }) async {
    // Look for an existing chat
    Query query = _db
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .where('sellerId', isEqualTo: sellerId);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    }

    final existing = await query.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create a new chat document
    final now = DateTime.now();
    final docRef = await _db.collection('chats').add({
      'userId': userId,
      'sellerId': sellerId,
      'productId': productId,
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(now),
      'participants': [userId, sellerId],
    });
    return docRef.id;
  }

  /// Sends a message and updates the chat's lastMessage metadata.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
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
    });

    // Update parent chat document
    final chatRef = _db.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Fetches a user document (name, avatar) from Firestore.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
