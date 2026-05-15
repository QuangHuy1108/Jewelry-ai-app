import 'package:flutter/material.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/services/address_service.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  String _selectedType = 'Home';
  final _addressController = TextEditingController();
  final _floorController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _addressService = AddressService();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _floorController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Map Placeholder
          _buildMapPlaceholder(),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context),
          ),
          
          // Bottom Sheet Form
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      color: const Color(0xFFF0F2F5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Real OpenStreetMap static tile as background
          Positioned.fill(
            child: Image.network(
              'https://tile.openstreetmap.org/13/6584/3833.png',
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8EAF0),
                child: const Center(
                  child: Icon(Icons.map_outlined, size: 64, color: Color(0xFFBBBBBB)),
                ),
              ),
            ),
          ),
          // Darkened overlay for readability
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.3)),
          ),
          // Location Pin
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(
              Icons.location_on,
              size: 56,
              color: Color(0xFFE53935),
            ),
          ),
          // "Tap to select location" prompt
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Color(0xFF777777)),
                  SizedBox(width: 6),
                  Text(
                    'Select location on map',
                    style: TextStyle(fontSize: 13, color: Color(0xFF555555), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Save address as *'),
                  const SizedBox(height: 12),
                  _buildTypeChips(),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Complete address'),
                  const SizedBox(height: 8),
                  _buildTextField(hint: 'Enter address *', maxLines: 4, controller: _addressController),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Floor'),
                  const SizedBox(height: 8),
                  _buildTextField(hint: 'Enter Floor', controller: _floorController),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Landmark'),
                  const SizedBox(height: 8),
                  _buildTextField(hint: 'Enter Landmark', controller: _landmarkController),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTypeChips() {
    final types = ['Home', "Parent's House", 'Farm House', 'Other'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF777777) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({required String hint, int maxLines = 1, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () async {
              if (_addressController.text.trim().isEmpty) {
                LuxuryToast.show(context, message: 'Please enter a complete address');
                return;
              }
              setState(() => _isLoading = true);
              try {
                await _addressService.addAddress(
                  type: _selectedType,
                  address: _addressController.text.trim(),
                  floor: _floorController.text.trim(),
                  landmark: _landmarkController.text.trim(),
                );
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Address Saved successfully');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  LuxuryToast.show(context, message: 'Failed to save address');
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
              'Save address',
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
