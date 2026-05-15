import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class SellerMarketingScreen extends StatefulWidget {
  final String sellerId;
  const SellerMarketingScreen({super.key, required this.sellerId});

  @override
  State<SellerMarketingScreen> createState() => _SellerMarketingScreenState();
}

class _SellerMarketingScreenState extends State<SellerMarketingScreen> {
  final _linkController = TextEditingController();
  String _generatedLink = '';
  Map<String, dynamic>? _promoCodeData;

  @override
  void initState() {
    super.initState();
    _loadPromoCode();
  }

  Future<void> _loadPromoCode() async {
    final query = await FirebaseFirestore.instance
        .collection('promo_codes')
        .where('sellerId', isEqualTo: widget.sellerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() => _promoCodeData = query.docs.first.data());
    }
  }

  void _generateLink() {
    final baseUrl = _linkController.text.trim();
    if (baseUrl.isEmpty || !baseUrl.startsWith('http')) {
      LuxuryToast.show(context, message: 'Please enter a valid product URL');
      return;
    }
    setState(() {
      _generatedLink = baseUrl.contains('?') 
          ? '$baseUrl&ref=${widget.sellerId}'
          : '$baseUrl?ref=${widget.sellerId}';
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
        title: const Text('Marketing Tools', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate Referral Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            _buildLinkGenerator(),
            const SizedBox(height: 32),

            const Text('Your Exclusive Promo Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            _buildPromoCodeCard(),
            const SizedBox(height: 32),

            const Text('Share via QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            _buildQrCodeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkGenerator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'Paste product link here (e.g., https://zink.vn/ring123)',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.inkMuted48),
              filled: true,
              fillColor: AppColors.canvasParchment,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Generate Tracking Link'),
            ),
          ),
          if (_generatedLink.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.hairline),
            const SizedBox(height: 16),
            const Text('Your tracking link:', style: TextStyle(fontSize: 12, color: AppColors.ink)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1A8B4A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(child: Text(_generatedLink, style: const TextStyle(fontSize: 12, color: Color(0xFF1A8B4A)), maxLines: 2)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF1A8B4A), size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedLink));
                      LuxuryToast.show(context, message: 'Link copied!');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF1A8B4A), size: 18),
                    onPressed: () => Share.share('Check out this jewelry: $_generatedLink'),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPromoCodeCard() {
    if (_promoCodeData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
        ),
        child: const Center(child: Text('No active promo code found.', style: TextStyle(color: AppColors.inkMuted48))),
      );
    }

    final code = _promoCodeData!['code'] ?? '';
    final discount = (_promoCodeData!['discountPercentage'] as num?)?.toDouble() ?? 0;
    final usageCount = (_promoCodeData!['usageCount'] as num?)?.toInt() ?? 0;
    final maxTotalUsage = (_promoCodeData!['maxTotalUsage'] as num?)?.toInt() ?? 0;
    final exp = (_promoCodeData!['expirationDate'] as Timestamp?)?.toDate();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0066CC), Color(0xFF004C99)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0066CC).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${discount.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  const Text('For your followers', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Text(code, style: const TextStyle(color: Color(0xFF0066CC), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        LuxuryToast.show(context, message: 'Code copied!');
                      },
                      child: const Icon(Icons.copy, color: Color(0xFF0066CC), size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPromoStat('Used', '$usageCount${maxTotalUsage > 0 ? '/$maxTotalUsage' : ''} times'),
              _buildPromoStat('Limit', '1 per user'),
              _buildPromoStat('Expires', exp != null ? '${exp.day}/${exp.month}/${exp.year}' : 'Never'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPromoStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQrCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.canvasParchment,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 60, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Directs users to your seller profile and automatically tracks referrals.', style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => LuxuryToast.show(context, message: 'Saved to gallery'),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Save'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.hairline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Share.share('Check out my store on Zink!'),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
