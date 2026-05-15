import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class SellerBankInfoScreen extends StatefulWidget {
  final String sellerId;
  const SellerBankInfoScreen({super.key, required this.sellerId});

  @override
  State<SellerBankInfoScreen> createState() => _SellerBankInfoScreenState();
}

class _SellerBankInfoScreenState extends State<SellerBankInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _holderController = TextEditingController();
  final _taxIdController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  Future<void> _loadBankInfo() async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(widget.sellerId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _bankNameController.text = data['bankName'] ?? '';
      _accountController.text = data['bankAccount'] ?? '';
      _holderController.text = data['bankHolder'] ?? '';
      _taxIdController.text = data['taxId'] ?? '';
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountController.dispose();
    _holderController.dispose();
    _taxIdController.dispose();
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
        title: const Text('Bank Information', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0066CC).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF0066CC), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Your bank info is used for commission withdrawals. Keep it accurate.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF0066CC))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField('Bank Name', _bankNameController, 'e.g., Vietcombank, BIDV, Techcombank', Icons.account_balance),
              const SizedBox(height: 16),
              _buildField('Account Number', _accountController, 'Your bank account number', Icons.credit_card, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField('Account Holder Name', _holderController, 'Name as on bank account', Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Tax ID (Optional)', _taxIdController, 'Mã số thuế (nếu có)', Icons.receipt_long_outlined, required: false),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBankInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Bank Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.inkMuted48, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.inkMuted48, size: 20),
            filled: true,
            fillColor: AppColors.canvas,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _saveBankInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('sellers').doc(widget.sellerId).update({
        'bankName': _bankNameController.text.trim(),
        'bankAccount': _accountController.text.trim(),
        'bankHolder': _holderController.text.trim(),
        'taxId': _taxIdController.text.trim(),
      });
      if (mounted) {
        LuxuryToast.show(context, message: 'Bank information saved!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
