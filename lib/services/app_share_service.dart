import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppShareService {
  static final AppShareService _instance = AppShareService._internal();
  factory AppShareService() => _instance;
  AppShareService._internal();

  /// Generates a standard deep link and tracks the share
  Future<String> generateProductShareLink({
    required Map<String, dynamic> product,
    required String userId,
    String? note,
  }) async {
    final productId = product['id']?.toString() ?? '';
    
    // Generate a standard web URL that can act as a Universal Link/App Link
    final deepLink = 'https://zink-app.com/product/$productId';

    // Track the share in Firestore
    await _trackShare(
      userId: userId,
      type: 'product',
      targetId: productId,
      shareCode: deepLink,
    );

    return deepLink;
  }

  Future<void> _trackShare({
    required String userId,
    required String type,
    required String targetId,
    required String shareCode,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('shares').add({
        'user_id': userId,
        'type': type,
        'target_id': targetId,
        'share_code': shareCode,
        'click_count': 0,
        'conversion_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint('Successfully tracked share in Firestore!');
    } catch (e) {
      debugPrint('Failed to track share in Firestore: $e');
    }
  }
}
