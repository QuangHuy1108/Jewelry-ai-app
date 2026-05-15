import 'package:flutter/material.dart';

class CommissionCard extends StatelessWidget {
  final double pendingCommission;
  final double availableBalance;
  final double totalEarnings;

  const CommissionCard({
    super.key,
    required this.pendingCommission,
    required this.availableBalance,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.diamond_outlined, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('Seller Wallet', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.4), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Total Earnings', style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            _formatVND(totalEarnings),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSubStat('Pending', _formatVND(pendingCommission), const Color(0xFFFFB74D)),
              ),
              Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
              Expanded(
                child: _buildSubStat('Available', _formatVND(availableBalance), const Color(0xFF66BB6A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w400)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatVND(double amount) {
    if (amount == 0) return '0 ₫';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    return '${amount.toStringAsFixed(0)} ₫';
  }
}
