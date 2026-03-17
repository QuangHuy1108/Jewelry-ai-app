import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:go_router/go_router.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  ObjectDetector? _objectDetector;
  bool _isInitialized = false;
  String _detectedLabel = "Đang quét...";

  @override
  void initState() {
    super.initState();
    _initializeCameraAndAI();
  }

  Future<void> _initializeCameraAndAI() async {
    // 1. Khởi tạo "Bộ não" AI
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream, // Quét liên tục theo dòng hình ảnh
      classifyObjects: true,      // Phân loại vật thể (Nhẫn, vòng, v.v.)
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);

    // 2. Khởi tạo Camera
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    // 3. Bắt đầu truyền hình ảnh cho AI
    _controller!.startImageStream((CameraImage image) {
      _processImage(image);
    });

    if (!mounted) return;
    setState(() { _isInitialized = true; });
  }

  // Hàm quan trọng: AI sẽ phân tích hình ảnh ở đây
  Future<void> _processImage(CameraImage image) async {
    // Để cho nhẹ máy, cứ mỗi 1 giây ta mới quét 1 lần (hoặc xử lý logic ở đây)
    // Tạm thời ta sẽ bắt đầu logic nhận diện
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final objects = await _objectDetector!.processImage(inputImage);

      if (objects.isNotEmpty && objects.first.labels.isNotEmpty) {
        final label = objects.first.labels.first.text.toLowerCase();

        setState(() {
          // Logic nhận diện thông minh:
          if (label.contains('ring') || label.contains('jewelry')) {
            _detectedLabel = "✨ Đã tìm thấy: Nhẫn Kim Cương 18K";
          } else if (label.contains('necklace') || label.contains('pendant')) {
            _detectedLabel = "✨ Đã tìm thấy: Dây Chuyền Vàng Hồng";
          } else {
            _detectedLabel = "Đang quét tìm trang sức...";
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi AI: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Hiển thị khung hình Camera
          if (_isInitialized)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),

          // 2. Nút quay lại
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),

          // 3. Khung ngắm AI (Thiết kế Luxury)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 4. Nút bấm Quét AI
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    "Đưa trang sức vào khung hình để nhận diện",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Tạm thời hiện thông báo, bước sau ta sẽ gắn AI vào đây
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("AI đang phân tích...")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}