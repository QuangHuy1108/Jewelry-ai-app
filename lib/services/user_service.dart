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
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (user.displayName != name) {
      await user.updateDisplayName(name);
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'phone': phone,
      'gender': gender,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
