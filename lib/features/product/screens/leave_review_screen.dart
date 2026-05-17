import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';

class LeaveReviewScreen extends StatefulWidget {
  const LeaveReviewScreen({super.key});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _selectedTabIndex = 0;
  bool _isProductReviewed = false;
  bool _isSellerReviewed = false;

  int _rating = 0;

  int _honesty = 0;
  int _attitude = 0;
  int _consultingSkill = 0;
  int _afterSalesService = 0;
  int _productKnowledge = 0;

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _sellerReviewController = TextEditingController();
  bool _isSubmitting = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _reviewController.addListener(_onReviewChanged);
    _sellerReviewController.addListener(_onSellerReviewChanged);
  }

  void _onReviewChanged() {
    setState(() {});
  }

  void _onSellerReviewChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _reviewController.removeListener(_onReviewChanged);
    _reviewController.dispose();
    _sellerReviewController.removeListener(_onSellerReviewChanged);
    _sellerReviewController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _product = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args['orderId'] != null &&
          args['orderId'].toString().isNotEmpty) {
        setState(() {
          _isProductReviewed = args['isProductReviewed'] == true;
          _isSellerReviewed = args['isSellerReviewed'] == true;

          if (_isProductReviewed && !_isSellerReviewed) {
            _selectedTabIndex = 1;
          } else if (!_isProductReviewed && _isSellerReviewed) {
            _selectedTabIndex = 0;
          } else {
            _selectedTabIndex = (args['isSellerReview'] == true) ? 1 : 0;
          }

          final items = args['items'] as List<dynamic>? ?? [];
          final firstItem = items.isNotEmpty
              ? items[0] as Map<String, dynamic>
              : <String, dynamic>{};

          _product = {
            "orderId": args['orderId'] ?? '',
            "id": firstItem['productId'] ?? firstItem['id'] ?? '',
            "sellerId":
                args['affiliateId'] ??
                args['sellerId'] ??
                firstItem['sellerId'] ??
                '',
            "sellerName": args['sellerName'] ?? 'your consultant',
            "name": firstItem['name'] ?? 'Product Name',
            "category": firstItem['category'] ?? '',
            "price": (args['totalAmount'] is num)
                ? (args['totalAmount'] as num).toDouble()
                : (double.tryParse(
                        args['totalAmount']?.toString().replaceAll('\$', '') ??
                            '',
                      ) ??
                      (firstItem['price'] is num
                          ? (firstItem['price'] as num).toDouble()
                          : (double.tryParse(
                                  firstItem['price']?.toString().replaceAll('\$', '') ??
                                      '0',
                                ) ??
                                0))),
            "image": firstItem['image'] ?? '',
            "quantity": firstItem['quantity'] ?? firstItem['qty'] ?? 1,
          };
        });

        final sellerId = _product['sellerId'] ?? '';
        if (sellerId.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('sellers')
              .doc(sellerId)
              .get()
              .then((doc) {
                if (doc.exists && mounted) {
                  setState(() {
                    _product['sellerName'] =
                        doc.data()?['name'] ?? 'your consultant';
                  });
                }
              })
              .catchError((_) {});
        }
      } else {
        // Fallback: Query the user's latest order directly from Firestore to ensure no grey card/crashes!
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get()
              .then((snapshot) {
                if (snapshot.docs.isNotEmpty && mounted) {
                  final orderDoc = snapshot.docs.first;
                  final orderData = orderDoc.data();
                  final orderId = orderDoc.id;
                  final items = orderData['items'] as List<dynamic>? ?? [];
                  final firstItem = items.isNotEmpty
                      ? items[0] as Map<String, dynamic>
                      : <String, dynamic>{};

                  setState(() {
                    _isProductReviewed = orderData['isProductReviewed'] == true;
                    _isSellerReviewed = orderData['isSellerReviewed'] == true;

                    if (_isProductReviewed && !_isSellerReviewed) {
                      _selectedTabIndex = 1;
                    } else if (!_isProductReviewed && _isSellerReviewed) {
                      _selectedTabIndex = 0;
                    } else {
                      _selectedTabIndex = 0;
                    }

                    _product = {
                      "orderId": orderId,
                      "id": firstItem['productId'] ?? firstItem['id'] ?? '',
                      "sellerId":
                          orderData['affiliateId'] ??
                          orderData['sellerId'] ??
                          firstItem['sellerId'] ??
                          '',
                      "sellerName":
                          orderData['sellerName'] ?? 'your consultant',
                      "name": firstItem['name'] ?? 'Product Name',
                      "category": firstItem['category'] ?? '',
                      "price": (orderData['totalAmount'] is num)
                          ? (orderData['totalAmount'] as num).toDouble()
                          : (double.tryParse(
                                  orderData['totalAmount']?.toString().replaceAll('\$', '') ??
                                      '',
                                ) ??
                                (firstItem['price'] is num
                                    ? (firstItem['price'] as num).toDouble()
                                    : (double.tryParse(
                                            firstItem['price']?.toString().replaceAll('\$', '') ??
                                                '0',
                                          ) ??
                                          0))),
                      "image": firstItem['image'] ?? '',
                      "quantity":
                          firstItem['quantity'] ?? firstItem['qty'] ?? 1,
                    };
                  });

                  final sellerId = _product['sellerId'] ?? '';
                  if (sellerId.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('sellers')
                        .doc(sellerId)
                        .get()
                        .then((doc) {
                          if (doc.exists && mounted) {
                            setState(() {
                              _product['sellerName'] =
                                  doc.data()?['name'] ?? 'your consultant';
                            });
                          }
                        })
                        .catchError((_) {});
                  }
                }
              })
              .catchError((_) {});
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<void> _submitReview() async {
    final isSeller = _selectedTabIndex == 1;

    if (isSeller) {
      if (_honesty == 0 ||
          _attitude == 0 ||
          _consultingSkill == 0 ||
          _afterSalesService == 0 ||
          _productKnowledge == 0 ||
          _sellerReviewController.text.trim().isEmpty)
        return;
    } else {
      if (_rating == 0 || _reviewController.text.trim().isEmpty) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('submitReview');
      await callable.call({
        'orderId': _product['orderId'],
        'productId': _product['id'],
        'sellerId': isSeller ? _product['sellerId'] : null,
        'isSellerReview': isSeller,
        'rating': _rating,
        'comment': isSeller
            ? _sellerReviewController.text.trim()
            : _reviewController.text.trim(),
        'hasMedia': _selectedImage != null,
        if (isSeller) 'honesty': _honesty,
        if (isSeller) 'attitude': _attitude,
        if (isSeller) 'consultingSkill': _consultingSkill,
        if (isSeller) 'afterSalesService': _afterSalesService,
        if (isSeller) 'productKnowledge': _productKnowledge,
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (isSeller) {
            _isSellerReviewed = true;
            _sellerReviewController.clear();
            _honesty = 0;
            _attitude = 0;
            _consultingSkill = 0;
            _afterSalesService = 0;
            _productKnowledge = 0;
          } else {
            _isProductReviewed = true;
            _reviewController.clear();
            _rating = 0;
          }
          _selectedImage = null;
        });

        LuxuryToast.show(
          context,
          message: isSeller
              ? 'Seller Review submitted!'
              : 'Product Review submitted!',
        );

        if (_isProductReviewed && _isSellerReviewed) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          setState(() {
            _selectedTabIndex = isSeller ? 0 : 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String msg = e.toString();
        final match = RegExp(r'\] (.*)').firstMatch(msg);
        if (match != null) {
          msg = match.group(1) ?? msg;
        }
        LuxuryToast.show(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (_selectedTabIndex == 1)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are reviewing the service quality of consultant: ${_product['sellerName']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildProductSummaryCard(),
            const SizedBox(height: 32),
            const Text(
              'How is your order?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            _buildTabToggle(),
            const SizedBox(height: 24),
            _buildRatingPicker(),
            const SizedBox(height: 32),
            _buildFeedbackInput(),
            const SizedBox(height: 40),
            _buildFooterButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF333333),
              size: 20,
            ),
          ),
        ),
      ),
      title: const Text(
        'Leave Review',
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProductSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (_product['image'] as String?)?.isNotEmpty == true
                ? Image.network(
                    _product['image']!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product['name'] ?? 'Product Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _product['category'] ?? 'Category',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${(_product['price'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${_product['quantity'] ?? 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.addToCart(_product);
              LuxuryToast.show(context, message: 'Added back to cart');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF808080),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text('Re-Order', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF5F5F5).withOpacity(0.8),
            const Color(0xFFE0E0E0).withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? Colors.white.withOpacity(0.9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: _selectedTabIndex == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Product Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFF333333)
                                    : const Color(0xFF888888),
                              ),
                            ),
                            if (_isProductReviewed) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? Colors.white.withOpacity(0.9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: _selectedTabIndex == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Seller Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFF333333)
                                    : const Color(0xFF888888),
                              ),
                            ),
                            if (_isSellerReviewed) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingPicker() {
    final isSeller = _selectedTabIndex == 1;
    if (isSeller) {
      return Column(
        children: [
          _buildCriteriaRow(
            'Honesty',
            _honesty,
            (v) => setState(() => _honesty = v),
          ),
          const SizedBox(height: 16),
          _buildCriteriaRow(
            'Attitude',
            _attitude,
            (v) => setState(() => _attitude = v),
          ),
          const SizedBox(height: 16),
          _buildCriteriaRow(
            'Consulting Skill',
            _consultingSkill,
            (v) => setState(() => _consultingSkill = v),
          ),
          const SizedBox(height: 16),
          _buildCriteriaRow(
            'After-sales Service',
            _afterSalesService,
            (v) => setState(() => _afterSalesService = v),
          ),
          const SizedBox(height: 16),
          _buildCriteriaRow(
            'Product Knowledge',
            _productKnowledge,
            (v) => setState(() => _productKnowledge = v),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          'Your overall rating',
          style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = _rating >= starIndex;
            return GestureDetector(
              onTap: () => setState(() => _rating = starIndex),
              child: AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 44,
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCriteriaRow(
    String title,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = value >= starIndex;
            return GestureDetector(
              onTap: () => onChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFE0E0E0),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeedbackInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add detailed review',
          style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _selectedTabIndex == 1
                ? _sellerReviewController
                : _reviewController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter here',
              hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedImage != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(_selectedImage!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _pickImage,
            child: Row(
              children: const [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF808080),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'add photo',
                  style: TextStyle(
                    color: Color(0xFF808080),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              foregroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed:
                ((_selectedTabIndex == 1
                    ? (_honesty > 0 &&
                          _attitude > 0 &&
                          _consultingSkill > 0 &&
                          _afterSalesService > 0 &&
                          _productKnowledge > 0 &&
                          _sellerReviewController.text.trim().isNotEmpty)
                    : (_rating > 0 &&
                          _reviewController.text.trim().isNotEmpty)))
                ? _submitReview
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF808080),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
