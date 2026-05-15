import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // ─── Step 1: Personal Info ──────────────────────
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ─── Step 2: Marketing Channels ─────────────────
  String _mainPlatform = 'TikTok';
  final _channelLinkCtrl = TextEditingController();
  final _referralCodeCtrl = TextEditingController();
  final _platforms = ['TikTok', 'YouTube', 'Instagram', 'Facebook', 'Twitter/X', 'Other'];

  // ─── Step 3: Payment Info ───────────────────────
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();

  // ─── Step 4: Identification (Optional) ──────────
  final _citizenIdCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();

  final _stepTitles = ['Personal', 'Marketing', 'Payment', 'ID & Tax'];

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fullNameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
    // Also try Firestore profile
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data()!;
          if (_fullNameCtrl.text.isEmpty) _fullNameCtrl.text = data['name'] ?? '';
          if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = data['phone'] ?? '';
          if (_emailCtrl.text.isEmpty) _emailCtrl.text = data['email'] ?? '';
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _channelLinkCtrl.dispose();
    _referralCodeCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _citizenIdCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3 && _formKeys[_currentStep].currentState!.validate()) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      // Check for duplicate referral code
      if (_referralCodeCtrl.text.trim().isNotEmpty) {
        final existing = await FirebaseFirestore.instance
            .collection('seller_applications')
            .where('referralCode', isEqualTo: _referralCodeCtrl.text.trim().toUpperCase())
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty && existing.docs.first['userId'] != user.uid) {
          if (mounted) LuxuryToast.show(context, message: 'This referral code is already taken');
          setState(() => _isSaving = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('seller_applications').doc(user.uid).set({
        'userId': user.uid,
        'fullName': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'mainPlatform': _mainPlatform,
        'channelLink': _channelLinkCtrl.text.trim(),
        'referralCode': _referralCodeCtrl.text.trim().toUpperCase(),
        'bankName': _bankNameCtrl.text.trim(),
        'accountNumber': _accountNumberCtrl.text.trim(),
        'accountHolderName': _accountHolderCtrl.text.trim(),
        'citizenId': _citizenIdCtrl.text.trim(),
        'taxId': _taxIdCtrl.text.trim(),
        'status': 'pending',
        'rejectionReason': '',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'avatarUrl': user.photoURL ?? '',
      });

      if (mounted) {
        LuxuryToast.show(context, message: 'Application submitted! We\'ll review it soon.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) LuxuryToast.show(context, message: 'Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: _prevStep),
        title: const Text('Become a Seller', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1PersonalInfo(),
                _buildStep2Marketing(),
                _buildStep3Payment(),
                _buildStep4Identification(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─── Step Indicator ─────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      color: AppColors.canvas,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: i < _currentStep ? () {
                _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                setState(() => _currentStep = i);
              } : null,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (i > 0) Expanded(child: Container(height: 2, color: isActive ? AppColors.primary : AppColors.hairline)),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.canvas,
                          shape: BoxShape.circle,
                          border: Border.all(color: isActive ? AppColors.primary : AppColors.hairline, width: 1.5),
                        ),
                        child: Center(
                          child: i < _currentStep
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.inkMuted48)),
                        ),
                      ),
                      if (i < 3) Expanded(child: Container(height: 2, color: i < _currentStep ? AppColors.primary : AppColors.hairline)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_stepTitles[i], style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isCurrent ? AppColors.primary : AppColors.inkMuted48)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Personal Info ──────────────────────
  Widget _buildStep1PersonalInfo() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Personal Information', 'Auto-filled from your account. Please verify.'),
            const SizedBox(height: 20),
            _buildField('Full Name', _fullNameCtrl, 'Must match your bank account', validator: _required, icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneCtrl, '+84 xxx xxx xxx', validator: _required, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('Email', _emailCtrl, 'your@email.com', validator: _validateEmail, icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Marketing ──────────────────────────
  Widget _buildStep2Marketing() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Marketing Channels', 'Help us understand your reach and audience.'),
            const SizedBox(height: 20),
            _buildLabel('Main Social Platform'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _platforms.map((p) {
                final isSelected = _mainPlatform == p;
                return GestureDetector(
                  onTap: () => setState(() => _mainPlatform = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_platformIcon(p), size: 16, color: isSelected ? Colors.white : AppColors.inkMuted48),
                        const SizedBox(width: 6),
                        Text(p, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.ink)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildField('Channel / Profile Link', _channelLinkCtrl, 'https://tiktok.com/@yourchannel', validator: _required, icon: Icons.link),
            const SizedBox(height: 16),
            _buildField('Desired Referral Code', _referralCodeCtrl, 'e.g. HUY-ZINK26', icon: Icons.confirmation_number_outlined),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text('Customers will use this code for discounts on your referrals.', style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Payment ────────────────────────────
  Widget _buildStep3Payment() {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Commission Payment', 'Where should we send your earnings?'),
            const SizedBox(height: 20),
            _buildField('Bank Name', _bankNameCtrl, 'e.g. Vietcombank', validator: _required, icon: Icons.account_balance_outlined),
            const SizedBox(height: 16),
            _buildField('Account Number', _accountNumberCtrl, '0123456789', validator: _required, icon: Icons.credit_card_outlined, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Account Holder Name', _accountHolderCtrl, 'Must match your full name above', validator: _required, icon: Icons.badge_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF57C00)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Account holder name must match your registered full name for verification.', style: TextStyle(fontSize: 12, color: Color(0xFFF57C00)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: ID & Tax ───────────────────────────
  Widget _buildStep4Identification() {
    return Form(
      key: _formKeys[3],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Identification & Tax', 'Optional now — required for first withdrawal.'),
            const SizedBox(height: 20),
            _buildField('Citizen ID Number', _citizenIdCtrl, 'Your national ID number', icon: Icons.perm_identity),
            const SizedBox(height: 16),
            _buildField('Tax Identification Number', _taxIdCtrl, 'Required when income exceeds threshold', icon: Icons.receipt_long_outlined),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(children: [
                    Icon(Icons.security, size: 16, color: Color(0xFF1976D2)),
                    SizedBox(width: 8),
                    Text('Privacy Notice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                  ]),
                  SizedBox(height: 6),
                  Text(
                    'Your identification data is encrypted and only used for tax compliance. You can provide these later before your first withdrawal.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1976D2), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Bar ─────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -1), blurRadius: 6)],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : (isLast ? _submitApplication : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bodyOnDark,
              disabledBackgroundColor: AppColors.hairline,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLast ? 'Submit Application' : 'Continue', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.374)),
          ),
        ),
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────
  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.inkMuted48, height: 1.3)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink));
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    String? Function(String?)? validator,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          validator: validator,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.inkMuted48, fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.inkMuted48) : null,
            filled: true,
            fillColor: AppColors.canvas,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.errorRed)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'TikTok': return Icons.music_note;
      case 'YouTube': return Icons.play_circle_outline;
      case 'Instagram': return Icons.camera_alt_outlined;
      case 'Facebook': return Icons.facebook;
      case 'Twitter/X': return Icons.alternate_email;
      default: return Icons.language;
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
    return null;
  }
}
