import 'package:flutter/material.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/services/wallet_service.dart';

class TopUpWalletScreen extends StatefulWidget {
  const TopUpWalletScreen({super.key});

  @override
  State<TopUpWalletScreen> createState() => _TopUpWalletScreenState();
}

class _TopUpWalletScreenState extends State<TopUpWalletScreen> {
  String _selectedOption = '';
  bool _isLoading = false;

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
                    const SizedBox(height: 20),
                    const Text('Credit & Debit Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 12),
                    _buildAddCardButton(context),
                    const SizedBox(height: 32),
                    const Text('Payment Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 12),
                    _buildOptionsList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
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
            'Top Up E-Wallet',
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

  Widget _buildAddCardButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.addCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.credit_card, color: Color(0xFF777777)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Add Card',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF777777)),
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildOptionItem('Paypal', Icons.payment, showDivider: true),
          _buildOptionItem('Apple Pay', Icons.apple, showDivider: true),
          _buildOptionItem('Google Pay', Icons.g_mobiledata, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildOptionItem(String title, IconData icon, {required bool showDivider}) {
    final isSelected = _selectedOption == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = title),
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF333333), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF777777)),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF777777) : const Color(0xFFDDDDDD),
                        width: isSelected ? 6 : 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () async {
              if (_selectedOption.isEmpty) {
                LuxuryToast.show(context, message: 'Please select a payment option');
                return;
              }
              setState(() => _isLoading = true);
              try {
                // Fixed $500 top up for demonstration
                await WalletService().topUp(500.0, _selectedOption);
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Wallet Top Up Successful (\$500.00)');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Top up failed');
                }
              } finally {
                if (context.mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF777777),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Confirm Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
