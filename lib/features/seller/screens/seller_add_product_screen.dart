import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/luxury_toast.dart';

class SellerAddProductScreen extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic>? editProduct;

  const SellerAddProductScreen({super.key, required this.sellerId, this.editProduct});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = 'Rings';
  bool _isBestSeller = false;
  bool _isPopular = false;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.editProduct != null;

  final _categories = ['Rings', 'Necklaces', 'Bracelets', 'Earrings', 'Watches', 'Pendants'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.editProduct!;
      _nameController.text = p['name'] ?? '';
      _priceController.text = '${p['price'] ?? ''}';
      _descriptionController.text = p['description'] ?? '';
      _imageController.text = p['image'] ?? '';
      _stockController.text = '${p['stock'] ?? 0}';
      _selectedCategory = p['category'] ?? 'Rings';
      _isBestSeller = p['isBestSeller'] ?? false;
      _isPopular = p['isPopular'] ?? false;
      _isActive = p['isActive'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'description': _descriptionController.text.trim(),
      'image': _imageController.text.trim(),
      'images': [_imageController.text.trim()],
      'category': _selectedCategory,
      'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      'isBestSeller': _isBestSeller,
      'isPopular': _isPopular,
      'isActive': _isActive,
      'sellerId': widget.sellerId,
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.editProduct!['id'])
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }
      if (mounted) {
        LuxuryToast.show(context, message: _isEditing ? 'Product updated!' : 'Product created!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        LuxuryToast.show(context, message: 'Error: $e');
      }
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back, color: AppColors.ink, size: 22),
          ),
        ),
        title: Text(_isEditing ? 'Edit Product' : 'Add Product', style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3,
        )),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              _buildImagePreview(),
              const SizedBox(height: 24),

              _buildLabel('Product Name'),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'Enter product name', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),

              _buildLabel('Image URL'),
              const SizedBox(height: 8),
              _buildTextField(_imageController, 'https://...', onChanged: (_) => setState(() {})),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price (\$)'),
                      const SizedBox(height: 8),
                      _buildTextField(_priceController, '0.00', keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Stock'),
                      const SizedBox(height: 8),
                      _buildTextField(_stockController, '0', keyboardType: TextInputType.number),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Category'),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(_descriptionController, 'Describe your product...', maxLines: 4),
              const SizedBox(height: 24),

              // Toggles
              _buildToggleRow('Best Seller', _isBestSeller, (v) => setState(() => _isBestSeller = v)),
              _buildToggleRow('Popular', _isPopular, (v) => setState(() => _isPopular = v)),
              _buildToggleRow('Active', _isActive, (v) => setState(() => _isActive = v)),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bodyOnDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Update Product' : 'Create Product', style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.374,
                        )),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final url = _imageController.text.trim();
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder())
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.image_outlined, size: 48, color: AppColors.inkMuted48),
          SizedBox(height: 8),
          Text('Enter image URL below', style: TextStyle(fontSize: 14, color: AppColors.inkMuted48)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.224,
    ));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inkMuted48, fontSize: 15),
        filled: true,
        fillColor: AppColors.canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.hairline),
            ),
            child: Text(cat, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.bodyOnDark : AppColors.ink,
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.ink, letterSpacing: -0.224)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
