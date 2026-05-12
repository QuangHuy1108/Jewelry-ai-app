import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/services/payment_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedOption = '';

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
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: PaymentService().getPaymentMethodsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: docs.asMap().entries.map((entry) {
                              final isLast = entry.key == docs.length - 1;
                              final data = entry.value.data();
                              final number = data['cardNumber'] as String? ?? '';
                              final last4 = number.length >= 4 ? number.substring(number.length - 4) : '****';
                              final title = '•••• $last4';
                              return _buildOptionItem(title, Icons.credit_card, showDivider: !isLast);
                            }).toList(),
                          ),
                        );
                      }
                    ),
                    _buildAddCardButton(context),
                    const SizedBox(height: 32),
                    const Text('More Payment Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 12),
                    _buildMoreOptionsList(),
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
            'Payment Methods',
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

  Widget _buildMoreOptionsList() {
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
            onPressed: () {
              if (_selectedOption.isEmpty) {
                LuxuryToast.show(context, message: 'Please select a payment method');
              } else {
                LuxuryToast.show(context, message: 'Payment Confirmed');
                Navigator.pop(context);
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
