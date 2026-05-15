import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidNotificationOverlay extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const LiquidNotificationOverlay({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
    required this.onDismiss,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String body,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => LiquidNotificationOverlay(
        title: title,
        body: body,
        imageUrl: imageUrl,
        onTap: () {
          onTap();
          overlayEntry.remove();
        },
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<LiquidNotificationOverlay> createState() =>
      _LiquidNotificationOverlayState();
}

class _LiquidNotificationOverlayState extends State<LiquidNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Total "In" duration: Slide (450ms) + Settle (200ms) = 650ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Slide in: 450ms of 650ms total (approx 69%)
    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1.2),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.69, curve: Curves.easeOut),
          ),
        );

    // Scale settle: 200ms at the end (approx 31%)
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.9,
              end: 1.04,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.04,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.69, 1.0),
          ),
        );

    // Blur fade: 300ms of 650ms total (approx 46%)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeIn),
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    // Dismiss: 250ms
    _controller.duration = const Duration(milliseconds: 250);
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -10) {
                  _dismiss();
                }
              },
              child: AnimatedBuilder(
                animation: _blurAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value,
                      ),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7), // Glass morph
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (widget.imageUrl != null &&
                          widget.imageUrl!.isNotEmpty)
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF333333),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A).withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
