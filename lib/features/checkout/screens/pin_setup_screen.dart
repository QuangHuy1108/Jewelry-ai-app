import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import '../providers/payment_provider.dart';

class PinSetupScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  const PinSetupScreen({super.key, required this.cardData});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<TextEditingController> _pinControllers = List.generate(6, (_) => TextEditingController());
  final List<TextEditingController> _confirmControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _confirmFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isConfirmPhase = false;
  bool _isLoading = false;
  String _enteredPin = '';

  @override
  void dispose() {
    for (final c in _pinControllers) { c.dispose(); }
    for (final c in _confirmControllers) { c.dispose(); }
    for (final f in _pinFocusNodes) { f.dispose(); }
    for (final f in _confirmFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Lock icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Icon(Icons.lock_outline, size: 32, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isConfirmPhase ? 'Confirm Your PIN' : 'Create Your PIN',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConfirmPhase
                          ? 'Enter your PIN again to confirm'
                          : 'Set a 6-digit PIN to secure your payments',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    // PIN input
                    _buildPinRow(
                      controllers: _isConfirmPhase ? _confirmControllers : _pinControllers,
                      focusNodes: _isConfirmPhase ? _confirmFocusNodes : _pinFocusNodes,
                      onComplete: _isConfirmPhase ? _handleConfirm : _handlePinEntered,
                    ),
                    const SizedBox(height: 40),
                    if (_isLoading)
                      const CircularProgressIndicator(color: Color(0xFF333333), strokeWidth: 2.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              child: Text('Secure PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPinRow({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required VoidCallback onComplete,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: 44,
          height: 52,
          margin: EdgeInsets.only(right: i < 5 ? 10 : 0),
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            obscureText: true,
            maxLength: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && i < 5) {
                focusNodes[i + 1].requestFocus();
              } else if (value.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
              // Check if all 6 digits entered
              final allFilled = controllers.every((c) => c.text.isNotEmpty);
              if (allFilled) {
                onComplete();
              }
            },
          ),
        );
      }),
    );
  }

  void _handlePinEntered() {
    _enteredPin = _pinControllers.map((c) => c.text).join();
    setState(() => _isConfirmPhase = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _confirmFocusNodes[0].requestFocus();
    });
  }

  void _handleConfirm() async {
    final confirmPin = _confirmControllers.map((c) => c.text).join();

    if (confirmPin != _enteredPin) {
      LuxuryToast.show(context, message: 'PINs do not match. Try again.');
      for (final c in _confirmControllers) { c.clear(); }
      _confirmFocusNodes[0].requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = context.read<PaymentProvider>();
      await payment.saveCard(widget.cardData, _enteredPin);

      if (mounted) {
        LuxuryToast.show(context, message: 'Card saved securely');
        Navigator.pop(context, true); // success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        LuxuryToast.show(context, message: 'Failed to save card');
      }
    }
  }
}
