import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getAddressesStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addAddress({
    required String type,
    required String address,
    required String floor,
    required String landmark,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).collection('addresses').add({
      'type': type,
      'address': address,
      'floor': floor,
      'landmark': landmark,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
