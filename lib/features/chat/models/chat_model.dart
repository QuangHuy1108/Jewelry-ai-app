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
  final String? lastMessageSenderId;
  final bool? lastMessageIsRead;
  final String? pinnedMessageId; // Task 1: Pinned message
  final List<String> participants;
  final List<String> deletedBy;

  ChatModel({
    required this.id,
    required this.userId,
    required this.sellerId,
    this.productId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageIsRead,
    this.pinnedMessageId,
    required this.participants,
    this.deletedBy = const [],
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
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageIsRead: data['lastMessageIsRead'],
      pinnedMessageId: data['pinnedMessageId'],
      participants: List<String>.from(data['participants'] ?? []),
      deletedBy: List<String>.from(data['deletedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sellerId': sellerId,
    'productId': productId,
    'lastMessage': lastMessage,
    'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
    if (lastMessageIsRead != null) 'lastMessageIsRead': lastMessageIsRead,
    if (pinnedMessageId != null) 'pinnedMessageId': pinnedMessageId,
    'participants': participants,
    'deletedBy': deletedBy,
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
  final String type; // 'text' or 'shared_product'
  final Map<String, dynamic>? metadata; // Product details or other info
  final String? replyToId;
  final bool isRecalled;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isRead,
    this.type = 'text',
    this.metadata,
    this.replyToId,
    this.isRecalled = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'text',
      metadata: data['metadata'],
      replyToId: data['replyToId'],
      isRecalled: data['isRecalled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': isRead,
    'type': type,
    if (metadata != null) 'metadata': metadata,
    if (replyToId != null) 'replyToId': replyToId,
    'isRecalled': isRecalled,
  };
}
