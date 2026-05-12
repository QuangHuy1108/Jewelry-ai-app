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
    _initDemoData();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _initDemoData() {
    // Injecting some demo data for immediate visual testing if Firestore is empty
    _notifications = [
      NotificationItem(
        id: 'mock1',
        type: 'order',
        title: 'Order Shipped',
        body: 'Your order GU-20260322-7F3A has been shipped and is on its way.',
        targetId: 'order123',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        priority: 'high',
        isPinned: true,
      ),
      NotificationItem(
        id: 'mock2',
        type: 'promotion',
        title: 'Flash Sale is Live!',
        body: 'Get up to 30% off on all Diamond rings. Limited time offer!',
        targetId: 'promo123',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        priority: 'low',
        isPinned: false,
      ),
      NotificationItem(
        id: 'mock3',
        type: 'chat',
        title: 'Jenny Doe',
        body: 'Thanks for reaching out! Let me check that for you.',
        targetId: 'seller456',
        sellerId: 'seller456',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'medium',
        isPinned: false,
      ),
    ];
  }

  void _startListening() {
    final user = _auth.currentUser;
    if (user == null) {
      // For this demo, we'll continue using mock data if no user is authenticated.
      // But in a real app, we would wait for auth.
      return; 
    }

    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _notifications = snapshot.docs.map((doc) => NotificationItem.fromJson(doc.data(), doc.id)).toList();
        notifyListeners();
      }
    });
  }

  Future<void> addNotification(NotificationItem item) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(item.toJson());
    } else {
      // Mock mode fallback
      _notifications.insert(0, item);
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      
      final user = _auth.currentUser;
      if (user != null && !id.startsWith('mock')) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
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
      if (user != null && !id.startsWith('mock')) {
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

            if (user != null && !_notifications[i].id.startsWith('mock')) {
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
      if (user != null && !id.startsWith('mock')) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .delete();
      }
    }
  }

  Future<void> undoDelete(NotificationItem item) async {
    _notifications.add(item);
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null && !item.id.startsWith('mock')) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(item.id)
          .set(item.toJson());
    }
  }
}
