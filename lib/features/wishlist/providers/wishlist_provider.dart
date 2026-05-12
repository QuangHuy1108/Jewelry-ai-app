import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WishlistProvider() {
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .get();
    _items.clear();
    for (var doc in snap.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      _items.add(data);
    }
    notifyListeners();
  }

  Future<void> _addItemToFirestore(Map<String, dynamic> item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dataToSave = Map<String, dynamic>.from(item)..remove('docId');
    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .add(dataToSave);
    item['docId'] = docRef.id;
  }

  Future<void> _removeItemFromFirestore(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(docId)
        .delete();
  }

  List<Map<String, dynamic>> get items => _items;

  void removeFromWishlist(String id) {
    final index = _items.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      final docId = _items[index]['docId'];
      _items.removeAt(index);
      notifyListeners();
      if (docId != null) _removeItemFromFirestore(docId);
    }
  }

  void addToWishlist(Map<String, dynamic> item) {
    if (!_items.any((i) => i['id'] == item['id'])) {
      _items.add(item);
      notifyListeners();
      _addItemToFirestore(item);
    }
  }

  void toggleWishlist(Map<String, dynamic> item) {
    final String id = item['id'];
    if (isInWishlist(id)) {
      removeFromWishlist(id);
    } else {
      addToWishlist(item);
    }
  }

  bool isInWishlist(String id) {
    return _items.any((item) => item['id'] == id);
  }
}

