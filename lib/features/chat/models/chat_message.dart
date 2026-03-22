enum MessageStatus { sending, sent, delivered, seen }

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  MessageStatus status;
  final bool isPinned;
  final Map<String, dynamic>? attachedProduct;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.isPinned = false,
    this.attachedProduct,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    String? senderId,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isPinned,
    Map<String, dynamic>? attachedProduct,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      attachedProduct: attachedProduct ?? this.attachedProduct,
    );
  }
}
