import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _globalPush = true;
  bool _ordersPush = true;
  bool _chatPush = true;
  bool _promotionsPush = false;
  bool _financePush = true;
  bool _securityPush = true;

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final prefs =
            data['notificationPreferences'] as Map<String, dynamic>? ?? {};
        final channels = prefs['channels'] as Map<String, dynamic>? ?? {};
        final categories = prefs['categories'] as Map<String, dynamic>? ?? {};

        setState(() {
          _globalPush = channels['push'] ?? true;
          _ordersPush =
              (categories['orders'] as Map<String, dynamic>?)?['push'] ?? true;
          _chatPush =
              (categories['chat'] as Map<String, dynamic>?)?['push'] ?? true;
          _promotionsPush =
              (categories['promotions'] as Map<String, dynamic>?)?['push'] ??
              false;
          _financePush =
              (categories['finance'] as Map<String, dynamic>?)?['push'] ?? true;
          _securityPush =
              (categories['security'] as Map<String, dynamic>?)?['push'] ??
              true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String keyPath, bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Build dynamic deep parameter target update map mapping perfectly to enterprise schema
      Map<String, dynamic> updateMap = {};
      if (keyPath == 'global') {
        updateMap = {'notificationPreferences.channels.push': value};
      } else {
        updateMap = {'notificationPreferences.categories.$keyPath.push': value};
      }

      await _firestore.collection('users').doc(user.uid).update(updateMap);
    } catch (_) {
      // Document might not be structured yet, execute explicit drop-in root mapping set
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'notificationPreferences': {
            'channels': {'push': _globalPush},
            'categories': {
              'orders': {'push': _ordersPush},
              'chat': {'push': _chatPush},
              'promotions': {'push': _promotionsPush},
              'finance': {'push': _financePush},
              'security': {'push': _securityPush},
            },
          },
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF333333),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildSectionTitle('Global Configuration'),
                          _buildSwitchItem(
                            'Master Push Dispatch',
                            _globalPush,
                            (val) {
                              setState(() => _globalPush = val);
                              _updatePreference('global', val);
                            },
                          ),
                          const Divider(height: 32, color: Color(0xFFEEEEEE)),
                          _buildSectionTitle('Role & Category Channels'),
                          _buildSwitchItem(
                            'Order Lifecycle Updates',
                            _ordersPush,
                            (val) {
                              setState(() => _ordersPush = val);
                              _updatePreference('orders', val);
                            },
                          ),
                          _buildSwitchItem(
                            'Live Messaging & Concierge',
                            _chatPush,
                            (val) {
                              setState(() => _chatPush = val);
                              _updatePreference('chat', val);
                            },
                          ),
                          _buildSwitchItem(
                            'Affiliate Finance & Payouts',
                            _financePush,
                            (val) {
                              setState(() => _financePush = val);
                              _updatePreference('finance', val);
                            },
                          ),
                          _buildSwitchItem(
                            'Marketing Vouchers & Drops',
                            _promotionsPush,
                            (val) {
                              setState(() => _promotionsPush = val);
                              _updatePreference('promotions', val);
                            },
                          ),
                          _buildSwitchItem(
                            'Account Security Alerts',
                            _securityPush,
                            (val) {
                              setState(() => _securityPush = val);
                              _updatePreference('security', val);
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF999999),
          letterSpacing: 1.2,
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
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF333333),
                size: 20,
              ),
            ),
          ),
          const Text(
            'Notification Preferences',
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

  Widget _buildSwitchItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF333333),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }
}
