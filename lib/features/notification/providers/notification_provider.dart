import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationItem> _notifications = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    final user = _auth.currentUser;
    if (user == null) {
      // No authenticated user — notifications list remains empty.
      return;
    }

    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _notifications = snapshot.docs
              .map((doc) => NotificationItem.fromJson(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });
  }

  Future<void> addNotification(NotificationItem item) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Idempotent write using message ID to prevent duplicate notification rendering
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(item.id)
          .set(item.toJson(), SetOptions(merge: true));
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});

        // Broadcast telemetry lifecycle packet down to decoupled clusters
        _logTelemetryEvent(id, 'OPENED');
      }
    }
  }

  Future<void> toggleReadStatus(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final newStatus = !_notifications[index].isRead;
      _notifications[index] = _notifications[index].copyWith(isRead: newStatus);
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': newStatus});
      }
    }
  }

  Future<void> markAllAsRead(String type) async {
    bool changed = false;
    final user = _auth.currentUser;
    final batch = _firestore.batch();

    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].type == type && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;

        if (user != null) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(_notifications[i].id);
          batch.update(docRef, {'isRead': true});
        }
      }
    }

    if (changed) {
      notifyListeners();
      if (user != null) {
        await batch.commit();
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .delete();

        // Broadcast dismissal telemetry event downstream
        _logTelemetryEvent(id, 'DISMISSED');
      }
    }
  }

  Future<void> _logTelemetryEvent(
    String notificationId,
    String eventType,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('notification_events').add({
        'notificationId': notificationId,
        'userId': user.uid,
        'eventType': eventType,
        'clientPlatform': 'Flutter',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> undoDelete(NotificationItem item) async {
    _notifications.add(item);
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(item.id)
          .set(item.toJson());
    }
  }
}
