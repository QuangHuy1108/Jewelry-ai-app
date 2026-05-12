import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentProvider extends ChangeNotifier {
  Map<String, dynamic>? _savedCard;
  String? _pin;
  bool _isLoaded = false;

  Map<String, dynamic>? get savedCard => _savedCard;
  bool get hasCard => _savedCard != null;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;
  bool get isLoaded => _isLoaded;

  /// Load saved card and PIN from local storage
  Future<void> loadSavedPayment() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final lastFour = prefs.getString('card_lastFour');
    final type = prefs.getString('card_type');
    final holder = prefs.getString('card_holder');
    final expiry = prefs.getString('card_expiry');
    _pin = prefs.getString('card_pin');

    if (lastFour != null) {
      _savedCard = {
        'lastFour': lastFour,
        'type': type ?? '',
        'holder': holder ?? '',
        'expiry': expiry ?? '',
        'maskedNumber': '**** **** **** $lastFour',
      };
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Save card + PIN securely
  Future<void> saveCard(Map<String, dynamic> cardData, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFour = cardData['lastFour'] ?? '';
    await prefs.setString('card_lastFour', lastFour);
    await prefs.setString('card_type', cardData['type'] ?? '');
    await prefs.setString('card_holder', cardData['holder'] ?? '');
    await prefs.setString('card_expiry', cardData['expiry'] ?? '');
    await prefs.setString('card_pin', pin);

    _savedCard = {
      'lastFour': lastFour,
      'type': cardData['type'] ?? '',
      'holder': cardData['holder'] ?? '',
      'expiry': cardData['expiry'] ?? '',
      'maskedNumber': '**** **** **** $lastFour',
    };
    _pin = pin;
    notifyListeners();
  }

  /// Verify PIN
  bool verifyPin(String input) {
    return _pin != null && _pin == input;
  }

  /// Remove saved card
  Future<void> removeCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('card_lastFour');
    await prefs.remove('card_type');
    await prefs.remove('card_holder');
    await prefs.remove('card_expiry');
    await prefs.remove('card_pin');
    _savedCard = null;
    _pin = null;
    notifyListeners();
  }

  /// Card type icon label for UI
  String get cardTypeLabel {
    switch (_savedCard?['type']) {
      case 'visa': return 'VISA';
      case 'mastercard': return 'Mastercard';
      case 'amex': return 'AMEX';
      case 'discover': return 'Discover';
      default: return 'Card';
    }
  }
}
