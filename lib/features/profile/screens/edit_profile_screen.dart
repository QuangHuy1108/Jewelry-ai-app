import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = true;
  String _selectedGender = 'Select';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['name'] != null && data['name'].toString().isNotEmpty) _nameController.text = data['name'];
          if (data['phone'] != null && data['phone'].toString().isNotEmpty) _phoneController.text = data['phone'];
          if (data['gender'] != null) _selectedGender = data['gender'];
        }
      } catch (e) {
        // ignore
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
                    _buildProfileAvatar(),
                    const SizedBox(height: 32),
                    _buildLabel('Name'),
                    _buildTextField(_nameController),
                    const SizedBox(height: 20),
                    _buildLabel('Phone Number'),
                    _buildTextField(
                      _phoneController,
                      trailing: GestureDetector(
                        onTap: () => LuxuryToast.show(context, message: 'Change Phone Number coming soon'),
                        child: const Text('Change', style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email'),
                    _buildTextField(_emailController, enabled: false), // usually email isn't directly editable
                    const SizedBox(height: 20),
                    _buildLabel('Gender'),
                    _buildDropdownField(),
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
            'Your Profile',
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

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E0E0),
              image: FirebaseAuth.instance.currentUser?.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF777777),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFAFAFA), width: 3),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {Widget? trailing, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: trailing != null ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [trailing],
            ),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender == 'Select' ? null : _selectedGender,
          hint: const Text('Select', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF999999)),
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selectedGender = newValue);
            }
          },
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
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await _userService.updateUserProfile(
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  gender: _selectedGender,
                );
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Profile Updated');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Failed to update profile');
                }
              } finally {
                if (context.mounted) {
                  setState(() => _isLoading = false);
                }
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
              'Update',
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
