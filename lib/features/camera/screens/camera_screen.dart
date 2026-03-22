import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../product/screens/product_detail_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isSearching = true;

  late AnimationController _scannerLineController;
  late Animation<double> _scannerLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initScannerAnimation();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _initScannerAnimation() {
    _scannerLineController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scannerLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scannerLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scannerLineController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller == null || !_isCameraInitialized) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showResult();
    }
  }

  void _showResult() {
    setState(() => _isSearching = false);
  }

  void _capture() {
    // Simulate Vision API processing
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _showResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎥 Camera Preview
          if (_isCameraInitialized && _controller != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            Container(color: Colors.grey.shade900),

          // 🔳 Semi-transparent Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 🔳 Scanner Frame and Line
          if (_isSearching) _buildScannerOverlay(),

          // ⬅️ Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _buildCircularButton(
              icon: Icons.close,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // 🛠️ Footer / Result
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isSearching ? _buildFooterTools() : _buildResultCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(280, 280),
            painter: ScannerFramePainter(),
          ),
          AnimatedBuilder(
            animation: _scannerLineAnimation,
            builder: (context, child) {
              return Positioned(
                top: 280 * _scannerLineAnimation.value,
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionIcon(Icons.photo_library_outlined, _pickFromGallery),
          _buildShutterButton(),
          _buildActionIcon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off_outlined, _toggleFlash),
        ],
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _capture,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget _buildResultCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "https://i.postimg.cc/pL94mBxp/h10.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Gold Necklace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Necklace',
                      style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$960.00',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductDetailScreen()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFF808080)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double radius = 10; // Outter corner radius

    // Top-left
    canvas.drawLine(Offset(0, radius), const Offset(0, 40), paint);
    canvas.drawLine(Offset(radius, 0), const Offset(40, 0), paint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        3.14,
        1.57,
        false,
        paint);

    // Top-right
    canvas.drawLine(Offset(size.width, radius), Offset(size.width, 40), paint);
    canvas.drawLine(Offset(size.width - radius, 0), Offset(size.width - 40, 0), paint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width - radius, radius), radius: radius),
        4.71,
        1.57,
        false,
        paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - radius), Offset(0, size.height - 40), paint);
    canvas.drawLine(Offset(radius, size.height), Offset(40, size.height), paint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, size.height - radius), radius: radius),
        1.57,
        1.57,
        false,
        paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width, size.height - radius), Offset(size.width, size.height - 40), paint);
    canvas.drawLine(
        Offset(size.width - radius, size.height), Offset(size.width - 40, size.height), paint);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width - radius, size.height - radius), radius: radius),
        0,
        1.57,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}