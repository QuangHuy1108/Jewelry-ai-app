import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/app_share_service.dart';

class GlassShareModal extends StatefulWidget {
  final Map<String, dynamic> product;

  const GlassShareModal({super.key, required this.product});

  static Future<void> show(BuildContext context, {required Map<String, dynamic> product}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GlassShareModal(product: product),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Spring-like animation
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlassShareModal> createState() => _GlassShareModalState();
}

class _GlassShareModalState extends State<GlassShareModal> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _noteController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _shareProduct(BuildContext context) async {
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      
      // 1. Generate Deep Link via AppShareService
      final deepLink = await AppShareService().generateProductShareLink(
        product: widget.product,
        userId: userId,
        note: _noteController.text,
      );

      // 2. Capture the UI as an Image
      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes != null) {
        // 3. Save to temp directory
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/share_preview_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // 4. Share using Share Plus
        final String textToShare = _noteController.text.isNotEmpty 
            ? 'I picked this out for you: ${_noteController.text}\n\n$deepLink'
            : 'Check out this gorgeous ${widget.product['name']} on Zink!\n\n$deepLink';

        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close modal before opening share sheet

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: textToShare,
        );
      } else {
        // Fallback to text only if image capture fails
        if (!context.mounted) return;
        Navigator.of(context).pop();
        
        // ignore: deprecated_member_use
        await Share.share('Check out this gorgeous ${widget.product['name']} on Zink!\n\n$deepLink');
      }

    } catch (e) {
      debugPrint('Share Error: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate share link. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine image URL
    final imageList = widget.product['images'] as List<dynamic>?;
    final String imageUrl = widget.product['image'] ?? 
      (imageList?.isNotEmpty == true ? imageList!.first.toString() : '');
    final price = widget.product['price'] ?? widget.product['basePrice'] ?? '';

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
              top: 12,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7), // Glass effect
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: -5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                const Text(
                  'Gift Share Experience',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Premium Preview Card to be Captured
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product['name'] ?? 'Luxury Item',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                price != '' ? '\$$price' : '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png', // Assuming a logo exists
                                    width: 12,
                                    height: 12,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.diamond, size: 12, color: Color(0xFF999999)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Shared from Zink',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Add a Note
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a special note (e.g. "Thought you\'d love this!")',
                    hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Share Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () => _shareProduct(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ios_share, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Share as Gift',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
}
