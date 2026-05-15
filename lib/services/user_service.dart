import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    required String gender,
    String? avatar,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (user.displayName != name) {
      await user.updateDisplayName(name);
    }

    final Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'gender': gender,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (avatar != null) {
      data['avatar'] = avatar;
    }

    await _firestore.collection('users').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// Update online status for the current user
  Future<void> setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
