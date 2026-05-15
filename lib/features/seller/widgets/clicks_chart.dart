import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ClicksChart extends StatelessWidget {
  final int totalClicks;
  final int totalConversions;

  const ClicksChart({super.key, required this.totalClicks, required this.totalConversions});

  @override
  Widget build(BuildContext context) {
    final conversionRate = totalClicks > 0 ? (totalConversions / totalClicks * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Clicks & Conversions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: conversionRate > 5 ? const Color(0xFF1A8B4A).withOpacity(0.1) : AppColors.canvasParchment,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${conversionRate.toStringAsFixed(1)}% CVR',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: conversionRate > 5 ? const Color(0xFF1A8B4A) : AppColors.inkMuted48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple bar visualization
          Row(
            children: [
              Expanded(
                child: _buildBar('Clicks', totalClicks, const Color(0xFF0066CC), 1.0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBar('Conversions', totalConversions, const Color(0xFF1A8B4A),
                    totalClicks > 0 ? totalConversions / totalClicks : 0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Referral Clicks', const Color(0xFF0066CC)),
              const SizedBox(width: 24),
              _buildLegend('Purchases', const Color(0xFF1A8B4A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color, double ratio) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
        const SizedBox(height: 10),
        Container(
          height: 8,
          decoration: BoxDecoration(color: AppColors.canvasParchment, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11, color: AppColors.inkMuted48)),
      ],
    );
  }
}
