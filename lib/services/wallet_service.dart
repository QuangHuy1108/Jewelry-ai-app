import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<double> getBalanceStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists && doc.data()!.containsKey('wallet_balance')) {
        return (doc.data()!['wallet_balance'] as num).toDouble();
      }
      return 0.0;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> topUp(double amount, String paymentMethod) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final userRef = _firestore.collection('users').doc(user.uid);
    final txRef = userRef.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      double currentBalance = 0.0;
      if (snapshot.exists && snapshot.data()!.containsKey('wallet_balance')) {
        currentBalance = (snapshot.data()!['wallet_balance'] as num).toDouble();
      }

      final newBalance = currentBalance + amount;

      transaction.set(userRef, {'wallet_balance': newBalance}, SetOptions(merge: true));
      transaction.set(txRef, {
        'title': 'Money Added to Wallet',
        'amount': amount,
        'isPositive': true,
        'paymentMethod': paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'balanceAfter': newBalance,
      });
    });
  }
}
