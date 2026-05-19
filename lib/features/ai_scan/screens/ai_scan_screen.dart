import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/ai_scan_provider.dart';
import '../widgets/luxury_scanner_hud.dart';
import '../../product/widgets/product_card.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/product_grid_constants.dart';

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});

  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiScanProvider>().reset();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _onScanPressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    await context.read<AiScanProvider>().captureAndScan(_cameraController!);
  }

  Future<void> _onGalleryPressed() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    if (!mounted) return;
    await context.read<AiScanProvider>().scanImage(imagePath: picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AiScanProvider>(
        builder: (context, provider, child) {
          final hasResults = provider.matchedProducts != null &&
              provider.matchedProducts!.isNotEmpty;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Bottom Layer: Live Camera ──
              if (_cameraReady && _cameraController != null)
                CameraPreview(_cameraController!)
              else
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),

              // ── Middle Layer: Scanner HUD ──
              if (!hasResults)
                LuxuryScannerHUD(
                  isScanning: provider.isLoading,
                  onScanPressed: _onScanPressed,
                  onGalleryPressed: _onGalleryPressed,
                  onClose: () => Navigator.pop(context),
                ),

              // ── Error Toast ──
              if (provider.errorMessage != null && !hasResults)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 24,
                  right: 24,
                  child: _buildErrorToast(provider.errorMessage!),
                ),

              // ── Top Layer: Results Overlay ──
              if (hasResults)
                _buildResultsOverlay(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorToast(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The full-screen results overlay with a frosted header and product grid.
  Widget _buildResultsOverlay(BuildContext context, AiScanProvider provider) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Column(
        children: [
          // ── Frosted glass header ──
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => provider.reset(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 22, color: Color(0xFF333333)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visual Matches',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '${provider.matchedProducts!.length} similar pieces found',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scan Again button
                    GestureDetector(
                      onTap: () => provider.reset(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Scan Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

          // ── Product Grid ──
          Expanded(
            child: GridView.builder(
              padding: ProductGridConstants.gridPaddingWithBottom(context),
              gridDelegate: ProductGridConstants.gridDelegate,
              itemCount: provider.matchedProducts!.length,
              itemBuilder: (context, index) {
                final product = provider.matchedProducts![index];
                final score = provider.getScoreForProduct(product['id'] ?? '');
                final pct = (score * 100).toStringAsFixed(0);

                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      onTap: () => AppNavigation.toProductDetail(context, product: product),
                    ),
                    // Confidence badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
