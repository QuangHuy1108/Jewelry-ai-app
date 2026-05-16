import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String type; // 'chat', 'order', 'promotion', etc.
  final String title;
  final String body;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;
  final String? productId;
  final String? sellerId;
  final String priority;
  final bool isPinned;
  final String? chatId;

  // Enterprise MVP fields
  final String? image;
  final String? deepLink;
  final String? status;
  final DateTime? expiresAt;
  final String? role;
  final String? level;
  final Map<String, dynamic>? metadata;

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
    this.image,
    this.deepLink,
    this.status,
    this.expiresAt,
    this.role,
    this.level,
    this.metadata,
    this.chatId,
  });

  static String _getDefaultPriority(String? type) {
    if (type == 'order' || type == 'security') return 'high';
    if (type == 'chat') return 'medium';
    return 'low';
  }

  int get relevanceScore {
    int score = 0;
    if (priority == 'high') score += 100;
    if (type == 'order' || type == 'security') score += 50;
    if (type == 'chat' && !isRead) score += 80;
    
    final hoursDiff = DateTime.now().difference(createdAt).inHours;
    if (hoursDiff < 1) score += 50;

    if (type == 'promotion') score += 10;
    
    // Phase 3 Intelligence & Calibration parameters integration
    if (metadata != null && metadata!['aiOptimalPriority'] != null) {
      final aiBoost = int.tryParse(metadata!['aiOptimalPriority'].toString()) ?? 0;
      score += aiBoost;
    }

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
      image: json['image'],
      deepLink: json['deepLink'],
      status: json['status'] ?? 'DELIVERED',
      expiresAt: json['expiresAt'] != null ? (json['expiresAt'] as Timestamp).toDate() : null,
      role: json['role'],
      level: json['level'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      chatId: json['chatId'],
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
      if (image != null) 'image': image,
      if (deepLink != null) 'deepLink': deepLink,
      if (status != null) 'status': status,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (role != null) 'role': role,
      if (level != null) 'level': level,
      if (metadata != null) 'metadata': metadata,
      if (chatId != null) 'chatId': chatId,
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
    String? image,
    String? deepLink,
    String? status,
    DateTime? expiresAt,
    String? role,
    String? level,
    Map<String, dynamic>? metadata,
    String? chatId,
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
      image: image ?? this.image,
      deepLink: deepLink ?? this.deepLink,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      role: role ?? this.role,
      level: level ?? this.level,
      metadata: metadata ?? this.metadata,
      chatId: chatId ?? this.chatId,
    );
  }
}
