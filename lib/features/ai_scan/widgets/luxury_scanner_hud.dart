import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium HUD overlay for the AI jewelry scanner camera.
/// Renders a frosted-glass scan frame with gold corner accents,
/// animated shimmer scan line, and a capture button.
class LuxuryScannerHUD extends StatefulWidget {
  final bool isScanning;
  final VoidCallback onScanPressed;
  final VoidCallback onClose;
  final VoidCallback? onGalleryPressed;

  const LuxuryScannerHUD({
    super.key,
    required this.isScanning,
    required this.onScanPressed,
    required this.onClose,
    this.onGalleryPressed,
  });

  @override
  State<LuxuryScannerHUD> createState() => _LuxuryScannerHUDState();
}

class _LuxuryScannerHUDState extends State<LuxuryScannerHUD>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLinePosition;

  late AnimationController _glowController;
  late Animation<double> _glowOpacity;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Scan line: sweeps top-to-bottom within frame bounds (0.0 → 1.0)
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _scanLinePosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Glow pulse on the frame border while scanning
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Subtle pulse on the capture button when idle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    if (widget.isScanning) {
      _startScanAnimations();
    }
  }

  void _startScanAnimations() {
    _scanLineController.repeat();
    _glowController.repeat(reverse: true);
    _pulseController.stop();
  }

  void _stopScanAnimations() {
    _scanLineController.stop();
    _scanLineController.reset();
    _glowController.stop();
    _glowController.reset();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LuxuryScannerHUD oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _startScanAnimations();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _stopScanAnimations();
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  static const _gold = Color(0xFFD4AF37);
  static const _goldLight = Color(0xFFE8D48B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameWidth = size.width * 0.72;
    final frameHeight = frameWidth; // Square frame
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2 - 40; // Shift up slightly

    return Stack(
      children: [
        // Layer 1: Dark overlay with transparent cutout
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _ScannerOverlayPainter(
            frameRect: Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
          ),
        ),

        // Layer 2: Frosted glass border + glow edges
        Positioned(
          left: frameLeft - 2,
          top: frameTop - 2,
          width: frameWidth + 4,
          height: frameHeight + 4,
          child: AnimatedBuilder(
            animation: _glowOpacity,
            builder: (context, child) {
              final glowAlpha = widget.isScanning ? _glowOpacity.value : 0.2;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: glowAlpha * 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _gold.withValues(alpha: glowAlpha * 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Layer 3: Gold corner accents
        _buildCornerAccent(frameLeft, frameTop, topLeft: true),
        _buildCornerAccent(frameLeft + frameWidth, frameTop, topRight: true),
        _buildCornerAccent(frameLeft, frameTop + frameHeight, bottomLeft: true),
        _buildCornerAccent(frameLeft + frameWidth, frameTop + frameHeight, bottomRight: true),

        // Layer 4: Shimmer scan line
        if (widget.isScanning)
          AnimatedBuilder(
            animation: _scanLinePosition,
            builder: (context, child) {
              final lineY = frameTop + (frameHeight * _scanLinePosition.value);
              return Positioned(
                top: lineY,
                left: frameLeft + 12,
                width: frameWidth - 24,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        _goldLight,
                        _gold,
                        _goldLight,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Layer 5: Close button (top-left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: GestureDetector(
            onTap: widget.onClose,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ),

        // Layer 6: "ZINK AI" badge (top-right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _gold, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ZINK AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 7: Status text below frame
        Positioned(
          top: frameTop + frameHeight + 24,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: widget.isScanning
                  ? const Text(
                      'Analyzing jewelry profile...',
                      key: ValueKey('scanning'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    )
                  : const Text(
                      'Position jewelry within the frame',
                      key: ValueKey('idle'),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
            ),
          ),
        ),

        // Layer 8: Bottom action bar (Gallery + Capture + placeholder for symmetry)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 48,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery button (left)
              if (widget.onGalleryPressed != null)
                GestureDetector(
                  onTap: widget.isScanning ? null : widget.onGalleryPressed,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),

              const SizedBox(width: 32),

              // Capture button (center)
              GestureDetector(
                onTap: widget.isScanning ? null : widget.onScanPressed,
                child: AnimatedBuilder(
                  animation: _pulseScale,
                  builder: (context, child) {
                    final scale = widget.isScanning ? 1.0 : _pulseScale.value;
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isScanning ? Colors.white38 : _gold,
                            width: 4,
                          ),
                          boxShadow: widget.isScanning
                              ? []
                              : [
                                  BoxShadow(
                                    color: _gold.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isScanning ? Colors.white38 : Colors.white,
                            ),
                            child: widget.isScanning
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      color: _gold,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Color(0xFF333333), size: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 32),

              // Symmetry placeholder (right)
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a single gold L-shaped corner accent.
  Widget _buildCornerAccent(double x, double y, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    const length = 28.0;
    const stroke = 3.0;
    const offset = 2.0; // Aligns with the border

    double left = x;
    double top = y;

    if (topRight || bottomRight) left -= length;
    if (bottomLeft || bottomRight) top -= length;
    if (topLeft) { left -= offset; top -= offset; }
    if (topRight) { left += offset; top -= offset; }
    if (bottomLeft) { left -= offset; top += offset; }
    if (bottomRight) { left += offset; top += offset; }

    return Positioned(
      left: left,
      top: top,
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: _gold,
          strokeWidth: stroke,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────

/// Draws the dark overlay with a rounded-rect cutout in the center.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect frameRect;

  _ScannerOverlayPainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutoutRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(28));

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) =>
      oldDelegate.frameRect != frameRect;
}

/// Draws an L-shaped gold corner bracket.
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height * 0.5);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.5, 0);
    } else if (topRight) {
      path.moveTo(size.width * 0.5, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height * 0.5);
    } else if (bottomLeft) {
      path.moveTo(0, size.height * 0.5);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.5, size.height);
    } else if (bottomRight) {
      path.moveTo(size.width * 0.5, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height * 0.5);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
