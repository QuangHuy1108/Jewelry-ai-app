import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/ai_scan_provider.dart';
import '../../product/widgets/product_card.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/product_grid_constants.dart';

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});

  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiScanProvider>().reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Audit Note: Removed root context.watch to completely prevent Scaffold rebuilds.
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('AI Jewelry Scanner', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Consumer<AiScanProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                _buildImagePickerBox(provider),
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (provider.isLoading)
                  _buildLoadingState()
                else if (provider.result != null)
                  _buildResultCard(provider),
                
                if (provider.result != null)
                  _buildSimilarProducts(provider.result!.type, provider.result!.material, provider.result!.gemstone),
                
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<AiScanProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: (provider.selectedImage == null || provider.isLoading) ? null : () => provider.scanImage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Analyze Jewelry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox(AiScanProvider provider) {
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.none),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: provider.selectedImage != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(provider.selectedImage!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: provider.reset,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                )
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Upload or capture a photo\nof your jewelry', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => provider.pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.black),
          const SizedBox(height: 20),
          Text('AI is analyzing your jewelry...', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultCard(AiScanProvider provider) {
    if (provider.result == null) return const SizedBox.shrink();
    final result = provider.result!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text('AI Analysis Complete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const Divider(height: 32),
          _buildResultRow('Type', result.type),
          _buildResultRow('Material', result.material),
          _buildResultRow('Gemstone', result.gemstone),
          _buildResultRow('Style', result.style),
          const Divider(height: 32),
          _buildResultRow('Est. Price', result.estimatedPriceRange, isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? const Color(0xFFD4AF37) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(String type, String material, String gemstone) {
    // Replaced fake logic with a physical stream to Firebase.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 24, bottom: 16),
          child: Text('Similar Pieces from our Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        SizedBox(
          height: ProductGridConstants.horizontalListHeight,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: type)
                // Filter logic matches tags loosely based on backend tags explicitly
                .limit(5)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No exact matches, but browse our collections!', style: TextStyle(color: Colors.grey)));
              }
              
              final products = snapshot.data!.docs;
              
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: ProductGridConstants.horizontalListPadding,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: ProductGridConstants.horizontalCardSpacing),
                itemBuilder: (context, index) {
                  final data = products[index].data() as Map<String, dynamic>;
                  data['id'] = products[index].id;
                  
                  return SizedBox(
                    width: ProductGridConstants.horizontalCardWidth,
                    child: ProductCard(
                      product: data,
                      onTap: () {
                        AppNavigation.toProductDetail(context, product: data);
                      },
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
