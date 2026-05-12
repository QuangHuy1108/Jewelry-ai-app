import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat session between a user and a seller.
/// Maps to Firestore: chats/{chatId}
class ChatModel {
  final String id;
  final String userId;
  final String sellerId;
  final String? productId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;

  ChatModel({
    required this.id,
    required this.userId,
    required this.sellerId,
    this.productId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.participants,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sellerId': sellerId,
    'productId': productId,
    'lastMessage': lastMessage,
    'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    'participants': participants,
  };
}

/// Represents a single message inside a chat.
/// Maps to Firestore: chats/{chatId}/messages/{messageId}
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': isRead,
  };
}
