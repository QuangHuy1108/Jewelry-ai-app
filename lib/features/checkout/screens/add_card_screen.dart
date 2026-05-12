import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/services/payment_service.dart';
import 'pin_setup_screen.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _saveCard = true;
  bool _isLoading = false;
  String _cardType = '';

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _numberController.addListener(_detectCardType);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _detectCardType() {
    final digits = _numberController.text.replaceAll(' ', '');
    String type = '';
    if (digits.startsWith('4')) {
      type = 'visa';
    } else if (digits.startsWith('5') || digits.startsWith('2')) {
      type = 'mastercard';
    } else if (digits.startsWith('3')) {
      type = 'amex';
    } else if (digits.startsWith('6')) {
      type = 'discover';
    }
    if (type != _cardType) {
      setState(() => _cardType = type);
    }
  }

  bool _luhnCheck(String number) {
    final digits = number.replaceAll(' ', '');
    if (digits.length < 13 || digits.length > 19) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.tryParse(digits[i]) ?? 0;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildCardPreview(),
                        const SizedBox(height: 28),
                        _buildLabel('Card Holder Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _holderController,
                          hint: 'John Doe',
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter card holder name' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Card Number'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _numberController,
                          hint: '0000 0000 0000 0000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberFormatter(),
                          ],
                          validator: (v) {
                            final raw = (v ?? '').replaceAll(' ', '');
                            if (raw.length < 13) return 'Enter a valid card number';
                            if (!_luhnCheck(v ?? '')) return 'Invalid card number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Expiry Date'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _expiryController,
                                    hint: 'MM/YY',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                      _ExpiryDateFormatter(),
                                    ],
                                    validator: (v) {
                                      final raw = (v ?? '').replaceAll('/', '');
                                      if (raw.length < 4) return 'Enter MM/YY';
                                      final month = int.tryParse(raw.substring(0, 2)) ?? 0;
                                      if (month < 1 || month > 12) return 'Invalid month';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('CVV'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _cvvController,
                                    hint: '•••',
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(_cardType == 'amex' ? 4 : 3),
                                    ],
                                    validator: (v) {
                                      final len = (v ?? '').length;
                                      if (len < 3) return 'Enter CVV';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Save Card checkbox
                        GestureDetector(
                          onTap: () => setState(() => _saveCard = !_saveCard),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _saveCard ? const Color(0xFF333333) : Colors.white,
                                  border: Border.all(color: _saveCard ? const Color(0xFF333333) : const Color(0xFFCCCCCC), width: 1.5),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: _saveCard
                                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              const Text('Save Card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildFooterButton(),
    );
  }

  // ===== HEADER =====
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Add Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ===== VISUAL CREDIT CARD =====
  Widget _buildCardPreview() {
    final number = _numberController.text.isEmpty ? 'XXXX XXXX XXXX XXXX' : _formatDisplayNumber(_numberController.text);
    final holder = _holderController.text.isEmpty ? 'YOUR NAME' : _holderController.text.toUpperCase();
    final expiry = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(60), offset: const Offset(0, 8), blurRadius: 24),
        ],
      ),
      child: Stack(
        children: [
          // Subtle curve pattern
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(15), width: 1),
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(10), width: 1),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: chip + logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Chip
                    Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withAlpha(200),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withAlpha(100), width: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    _buildCardLogo(),
                  ],
                ),
                // Card number
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
                // Bottom row: name + expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARD HOLDER', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(130), letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(holder, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EXPIRES', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(130), letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(expiry, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                      ],
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

  Widget _buildCardLogo() {
    switch (_cardType) {
      case 'visa':
        return const Text('VISA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontStyle: FontStyle.italic));
      case 'mastercard':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withAlpha(200))),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withAlpha(180))),
            ),
          ],
        );
      case 'amex':
        return const Text('AMEX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
      case 'discover':
        return const Text('DISCOVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6600)));
      default:
        return Icon(Icons.credit_card, color: Colors.white.withAlpha(130), size: 28);
    }
  }

  String _formatDisplayNumber(String input) {
    final raw = input.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    // Pad with X
    final formatted = buffer.toString();
    final parts = formatted.split(' ');
    while (parts.length < 4) {
      parts.add('XXXX');
    }
    for (int i = 0; i < parts.length; i++) {
      while (parts[i].length < 4) {
        parts[i] += 'X';
      }
    }
    return parts.take(4).join(' ');
  }

  // ===== FORM HELPERS =====
  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (_) => setState(() {}), // real-time mirror
      style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
      ),
    );
  }

  // ===== FOOTER BUTTON =====
  Widget _buildFooterButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -1), blurRadius: 6)],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: GestureDetector(
            onTapDown: (_) => setState(() {}),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAddCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF808080),
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Add Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawNumber = _numberController.text.replaceAll(' ', '');
    final cardData = {
      'holder': _holderController.text.trim(),
      'number': rawNumber,
      'lastFour': rawNumber.substring(rawNumber.length - 4),
      'expiry': _expiryController.text,
      'type': _cardType,
      'saved': _saveCard,
    };

    if (_saveCard) {
      try {
        await PaymentService().addPaymentMethod(
          holderName: _holderController.text.trim(),
          cardNumber: rawNumber,
          expiry: _expiryController.text,
          cardType: _cardType,
        );
      } catch (e) {
        // ignore
      }

      // Navigate to PIN setup
      if (mounted) {
        setState(() => _isLoading = false);
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => PinSetupScreen(cardData: cardData)),
        );
        if (result == true && mounted) {
          Navigator.pop(context, cardData);
        }
      }
    } else {
      // No save - just return card data
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isLoading = false);
        LuxuryToast.show(context, message: 'Card added successfully');
        Navigator.pop(context, cardData);
      }
    }
  }
}

// ===== INPUT FORMATTERS =====

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
