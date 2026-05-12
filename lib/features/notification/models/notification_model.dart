import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String type; // 'chat', 'order', 'promotion'
  final String title;
  final String body;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;
  final String? productId;
  final String? sellerId;
  final String priority;
  final bool isPinned;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
    this.productId,
    this.sellerId,
    required this.priority,
    required this.isPinned,
  });

  static String _getDefaultPriority(String? type) {
    if (type == 'order') return 'high';
    if (type == 'chat') return 'medium';
    return 'low';
  }

  int get relevanceScore {
    int score = 0;
    if (type == 'order') score += 100;
    if (type == 'chat' && !isRead) score += 80;
    
    final hoursDiff = DateTime.now().difference(createdAt).inHours;
    if (hoursDiff < 1) score += 50;

    if (type == 'promotion') score += 10;
    return score;
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json, String docId) {
    final type = json['type'] ?? 'unknown';
    final priority = json['priority'] ?? _getDefaultPriority(type);
    
    return NotificationItem(
      id: docId,
      type: type,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetId: json['targetId'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      productId: json['productId'],
      sellerId: json['sellerId'],
      priority: priority,
      isPinned: json['isPinned'] ?? (priority == 'high'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'productId': productId,
      'sellerId': sellerId,
      'priority': priority,
      'isPinned': isPinned,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
    String? productId,
    String? sellerId,
    String? priority,
    bool? isPinned,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
