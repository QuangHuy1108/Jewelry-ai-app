import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:jewelry_app/services/wallet_service.dart';

class WalletScreen extends StatelessWidget {
  WalletScreen({super.key});

  final WalletService _walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    StreamBuilder<double>(
                      stream: _walletService.getBalanceStream(),
                      builder: (context, snapshot) {
                        return _buildWalletBalanceCard(context, snapshot.data ?? 0.0);
                      }
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _walletService.getTransactionsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('No transactions yet.', style: TextStyle(color: Color(0xFF999999)))),
                          );
                        }
                        
                        Map<String, List<Map<String, dynamic>>> grouped = {};
                        for (var doc in docs) {
                           final data = doc.data();
                           final timestamp = data['timestamp'] as Timestamp?;
                           if (timestamp == null) continue;
                           final date = timestamp.toDate();
                           final dateTitle = _formatDateTitle(date);
                           
                           if (!grouped.containsKey(dateTitle)) {
                             grouped[dateTitle] = [];
                           }
                           
                           final amount = data['amount'] as num;
                           final isPositive = data['isPositive'] ?? false;
                           final balanceAfter = data['balanceAfter'] as num? ?? 0.0;
                           final sign = isPositive ? '+' : '-';
                           
                           final timeStr = _formatTime(date);
                           
                           grouped[dateTitle]!.add({
                             'title': data['title'] ?? 'Transaction',
                             'amount': '$sign \$${amount.toStringAsFixed(2)}',
                             'date': '${date.day.toString().padLeft(2, '0')} ${_monthString(date.month)} | $timeStr',
                             'balance': 'Balance \$${balanceAfter.toStringAsFixed(2)}',
                             'isPositive': isPositive,
                           });
                        }
                        
                        return Column(
                          children: grouped.entries.map((entry) {
                             return _buildTransactionSection(entry.key, entry.value);
                          }).toList(),
                        );
                      }
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Text(
            'Wallet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceCard(BuildContext context, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(fontSize: 14, color: Color(0xFF777777), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Color(0xFF777777), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.topUpWallet),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF777777),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Money',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(String dateTitle, List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            dateTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
        ),
        ...transactions.map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final isPositive = tx['isPositive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx['title'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              Text(
                tx['amount'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0xFF777777) : const Color(0xFF777777),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx['date'],
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              Text(
                tx['balance'],
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);
    
    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')} ${_monthString(date.month)} ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    final String ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _monthString(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
