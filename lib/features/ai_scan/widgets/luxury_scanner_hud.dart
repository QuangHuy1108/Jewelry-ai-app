import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium HUD overlay for the AI jewelry scanner camera.
/// Renders a frosted-glass scan frame with gold corner accents,
/// animated shimmer scan line, and a capture button.
class LuxuryScannerHUD extends StatefulWidget {
  final bool isScanning;
  final Function(String mode) onScanPressed;
  final VoidCallback onClose;
  final Function(String mode)? onGalleryPressed;

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

  // Track the selected scan mode:
  // - 'visual' (Visual Search - most important, default)
  // - 'material' (Material Analysis)
  // - 'style' (Style & Fashion Recommendation)
  String _selectedMode = 'visual';

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

  // Dynamic Theme Colors based on mode
  Color get _currentThemeColor {
    switch (_selectedMode) {
      case 'material':
        return const Color(0xFFC0C0C0); // Premium Silver
      case 'style':
        return const Color(0xFFB76E79); // Rose Gold
      case 'visual':
      default:
        return const Color(0xFFD4AF37); // Classic Gold
    }
  }

  Color get _currentThemeLightColor {
    switch (_selectedMode) {
      case 'material':
        return const Color(0xFFE5E4E2);
      case 'style':
        return const Color(0xFFE8C3C9);
      case 'visual':
      default:
        return const Color(0xFFE8D48B);
    }
  }

  String get _modeTitleText {
    switch (_selectedMode) {
      case 'material':
        return 'MATERIAL ANALYSIS';
      case 'style':
        return 'STYLE ADVISOR';
      case 'visual':
      default:
        return 'ZINK AI FINDER';
    }
  }

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
                      color: _currentThemeColor.withValues(alpha: glowAlpha * 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _currentThemeColor.withValues(alpha: glowAlpha * 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Layer 3: Dynamic Corner Accents
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
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _currentThemeLightColor,
                        _currentThemeColor,
                        _currentThemeLightColor,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _currentThemeColor.withValues(alpha: 0.6),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _currentThemeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _currentThemeColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _modeTitleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
                  ? Text(
                      _selectedMode == 'material'
                          ? 'Analyzing structural materials...'
                          : _selectedMode == 'style'
                              ? 'Analyzing style & matching outfits...'
                              : 'Searching global jewelry index...',
                      key: ValueKey('scanning_$_selectedMode'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    )
                  : Text(
                      _selectedMode == 'material'
                          ? 'Position piece for detailed metal & stone scan'
                          : _selectedMode == 'style'
                              ? 'Capture fashion profile for recommendations'
                              : 'Align jewelry to discover exact match',
                      key: ValueKey('idle_$_selectedMode'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
            ),
          ),
        ),

        // Mode Selector: Horizontal sliding picker right above the bottom action bar
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 144,
          left: 0,
          right: 0,
          child: Center(
            child: _buildModeSelector(),
          ),
        ),

        // Layer 8: Bottom action bar (Gallery + Capture + Symmetry spacing)
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
                  onTap: widget.isScanning
                      ? null
                      : () => widget.onGalleryPressed!(_selectedMode),
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
                onTap: widget.isScanning
                    ? null
                    : () => widget.onScanPressed(_selectedMode),
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
                            color: widget.isScanning
                                ? Colors.white38
                                : _currentThemeColor,
                            width: 4,
                          ),
                          boxShadow: widget.isScanning
                              ? []
                              : [
                                  BoxShadow(
                                    color: _currentThemeColor.withValues(alpha: 0.3),
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
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      color: _currentThemeColor,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Icon(
                                    _selectedMode == 'material'
                                        ? Icons.query_stats
                                        : _selectedMode == 'style'
                                            ? Icons.style
                                            : Icons.camera_alt,
                                    color: const Color(0xFF333333),
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 32),

              // Symmetry placeholder
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal Apple-style sliding mode picker
  Widget _buildModeSelector() {
    final modes = [
      {'id': 'visual', 'label': 'VISUAL'},
      {'id': 'material', 'label': 'MATERIAL'},
      {'id': 'style', 'label': 'STYLE'},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: modes.map((m) {
              final isSelected = _selectedMode == m['id'];
              return GestureDetector(
                onTap: widget.isScanning
                    ? null
                    : () {
                        setState(() {
                          _selectedMode = m['id']!;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _currentThemeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _currentThemeColor : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    m['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Builds a single L-shaped corner accent with dynamically changing theme colors.
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
          color: _currentThemeColor,
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

/// Draws an L-shaped dynamic theme corner bracket.
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
  bool shouldRepaint(_CornerPainter oldDelegate) => true;
}
