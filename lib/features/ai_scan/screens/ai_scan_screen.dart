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

  Future<void> _onScanPressed(String mode) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    await context.read<AiScanProvider>().captureAndScan(_cameraController!, mode);
  }

  Future<void> _onGalleryPressed(String mode) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    if (!mounted) return;
    await context.read<AiScanProvider>().scanImage(imagePath: picked.path, mode: mode);
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

  /// The full-screen results overlay with a frosted header, mode-specific analysis cards, and product grid.
  Widget _buildResultsOverlay(BuildContext context, AiScanProvider provider) {
    final mode = provider.currentMode;
    final hasMaterial = provider.materialAnalysis != null;
    final hasStyle = provider.styleRecommendation != null;

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
                          Text(
                            mode == 'material'
                                ? 'Material Analysis'
                                : mode == 'style'
                                    ? 'Style Advisor'
                                    : 'Visual Matches',
                            style: const TextStyle(
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

          // ── Scrollable Body with Mode Cards & Product Grid ──
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Material Analysis Card (if applicable)
                if (hasMaterial)
                  SliverToBoxAdapter(
                    child: _buildMaterialAnalysisCard(provider.materialAnalysis!),
                  ),

                // 2. Style Recommendation Card (if applicable)
                if (hasStyle)
                  SliverToBoxAdapter(
                    child: _buildStyleRecommendationCard(provider.styleRecommendation!),
                  ),

                // Section Title for product matches
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                    child: Text(
                      'Matching Boutique Pieces',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // 3. Grid of Hydrated Products
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: ProductGridConstants.gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                      childCount: provider.matchedProducts!.length,
                    ),
                  ),
                ),

                // Spacer at bottom
                const SliverToBoxAdapter(
                  child: SizedBox(height: 48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a stunning silver-themed card for material estimation results.
  Widget _buildMaterialAnalysisCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.query_stats, color: Color(0xFF7F8C8D), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Material & Accents Estimation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisRow('Estimated Base', data['base_material'] ?? 'Unknown'),
          _buildAnalysisRow('Estimated Purity', data['purity'] ?? 'Unknown'),
          _buildAnalysisRow('Outer Finishing', data['finishing'] ?? 'Unknown'),
          _buildAnalysisRow('Accent Stones', data['accent_stones'] ?? 'None detected'),
          _buildAnalysisRow('Surface Texture', data['texture'] ?? 'Smooth'),
          _buildAnalysisRow('Match Purity', data['confidence_score'] ?? '0%'),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF2F2F2)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.grey, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['disclaimer'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a beautiful rose-gold-themed style recommender card.
  Widget _buildStyleRecommendationCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2E6E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB76E79).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFB76E79), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'ZINK Stylist Recommendation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A3437),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildStyleDetailSection('Aesthetic Match', data['aesthetic_profile']),
          _buildStyleDetailSection('Vibe Profile', data['vibe_accent']),
          _buildStyleDetailSection('Recommended Outfit Colors', data['outfit_tone']),
          _buildStyleDetailSection('Stylist Layering & Pairing Tips', data['pairing_suggestions']),
          _buildStyleDetailSection('Perfect Occasions', data['occasion_match']),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleDetailSection(String title, String? content) {
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB76E79),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
