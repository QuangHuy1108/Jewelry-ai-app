import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';
import 'seller_bank_info_screen.dart';

class SellerFinanceScreen extends StatefulWidget {
  final String sellerId;
  const SellerFinanceScreen({super.key, required this.sellerId});

  @override
  State<SellerFinanceScreen> createState() => _SellerFinanceScreenState();
}

class _SellerFinanceScreenState extends State<SellerFinanceScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isWithdrawing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
        title: const Text('Finance & Withdrawals', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Balance Overview ───
            _buildBalanceCard(),
            const SizedBox(height: 20),

            // ─── Bank Info ───
            _buildBankInfoSection(),
            const SizedBox(height: 24),

            // ─── Transaction History ───
            const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            _buildTransactionHistory(),
            const SizedBox(height: 24),

            // ─── Withdrawal History ───
            const Text('Withdrawal Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            _buildWithdrawalHistory(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('sellers').doc(widget.sellerId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final available = (data['availableBalance'] as num?)?.toDouble() ?? 0;
        final pending = (data['pendingCommission'] as num?)?.toDouble() ?? 0;
        final total = (data['totalEarnings'] as num?)?.toDouble() ?? 0;
        final hasBankInfo = (data['bankAccount'] ?? '').toString().isNotEmpty;
        final canWithdraw = available >= 500000 && hasBankInfo;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A8B4A), Color(0xFF2ECC71)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF1A8B4A).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_formatVND(available), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMiniStat('Pending', _formatVND(pending), Colors.white70),
                  const SizedBox(width: 24),
                  _buildMiniStat('All-time', _formatVND(total), Colors.white70),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canWithdraw ? () => _showWithdrawDialog(available) : null,
                  icon: Icon(_isWithdrawing ? null : Icons.account_balance_wallet, size: 18),
                  label: _isWithdrawing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          !hasBankInfo
                              ? 'Add bank info first'
                              : available < 500000
                                  ? 'Min. 500,000 ₫ to withdraw'
                                  : 'Withdraw',
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A8B4A),
                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBankInfoSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('sellers').doc(widget.sellerId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final bankName = data['bankName'] ?? '';
        final bankAccount = data['bankAccount'] ?? '';
        final bankHolder = data['bankHolder'] ?? '';
        final hasBankInfo = bankAccount.toString().isNotEmpty;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SellerBankInfoScreen(sellerId: widget.sellerId),
          )),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasBankInfo ? AppColors.hairline.withOpacity(0.5) : Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: hasBankInfo ? AppColors.primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance, color: hasBankInfo ? AppColors.primary : Colors.orange, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasBankInfo ? bankName.toString() : 'Bank Information', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      Text(
                        hasBankInfo
                            ? '$bankHolder • ****${bankAccount.toString().length > 4 ? bankAccount.toString().substring(bankAccount.toString().length - 4) : bankAccount}'
                            : 'Tap to add your bank details',
                        style: TextStyle(fontSize: 12, color: AppColors.inkMuted48),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.inkMuted48),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('seller_transactions')
          .where('sellerId', isEqualTo: widget.sellerId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState('No transactions yet');
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildTransactionTile(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> data) {
    final type = data['type'] ?? 'commission';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final status = data['status'] ?? '';
    final desc = data['description'] ?? '';
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    final isPositive = amount >= 0;
    final iconData = type == 'withdrawal' ? Icons.arrow_upward : type == 'bonus' ? Icons.card_giftcard : Icons.arrow_downward;
    final color = type == 'withdrawal' ? Colors.red : const Color(0xFF1A8B4A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(iconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: TextStyle(fontSize: 11, color: AppColors.inkMuted48)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.canvasParchment, borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(fontSize: 9, color: AppColors.inkMuted48)),
                ),
              ]),
            ]),
          ),
          Text(
            '${isPositive ? '+' : ''}${_formatVND(amount)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('withdrawals')
          .where('sellerId', isEqualTo: widget.sellerId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState('No withdrawal requests');
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final status = data['status'] ?? 'pending';
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final bank = data['bankName'] ?? '';

            Color statusColor;
            switch (status) {
              case 'completed': statusColor = const Color(0xFF1A8B4A); break;
              case 'processing': statusColor = const Color(0xFF0066CC); break;
              case 'rejected': statusColor = Colors.red; break;
              default: statusColor = const Color(0xFFFF8C00);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.account_balance_wallet, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Withdraw to $bank', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: TextStyle(fontSize: 11, color: AppColors.inkMuted48)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_formatVND(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message, style: TextStyle(color: AppColors.inkMuted48, fontSize: 14))),
    );
  }

  void _showWithdrawDialog(double available) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Withdraw Funds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Available: ${_formatVND(available)}', style: TextStyle(fontSize: 14, color: AppColors.inkMuted48)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount (min 500,000 ₫)',
                prefixIcon: const Icon(Icons.payments_outlined),
                filled: true,
                fillColor: AppColors.canvasParchment,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [500000, 1000000, 2000000].map((amt) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.text = amt.toString(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.canvasParchment, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.hairline)),
                        child: Text(_formatVND(amt.toDouble()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
              ).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount < 500000) {
                    LuxuryToast.show(context, message: 'Minimum withdrawal is 500,000 ₫');
                    return;
                  }
                  Navigator.pop(ctx);
                  _processWithdrawal(amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A8B4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Confirm Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    setState(() => _isWithdrawing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('processWithdrawalRequest');
      await callable.call({'amount': amount});
      if (mounted) LuxuryToast.show(context, message: 'Withdrawal request submitted!');
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  String _formatVND(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    return '${amount.toStringAsFixed(0)} ₫';
  }
}
