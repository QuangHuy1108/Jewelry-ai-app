import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentMethodsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('payment_methods')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addPaymentMethod({
    required String holderName,
    required String token,
    required String cardType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).collection('payment_methods').add({
      'holderName': holderName,
      'token': token,
      'cardType': cardType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
