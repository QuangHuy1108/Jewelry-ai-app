import 'package:flutter/material.dart';

class LuxuryToast {
  static void show(BuildContext context, {required String message, IconData? icon}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _LuxuryToastWidget(message: message, icon: icon),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 2 seconds + animation time
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _LuxuryToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;

  const _LuxuryToastWidget({required this.message, this.icon});

  @override
  State<_LuxuryToastWidget> createState() => _LuxuryToastWidgetState();
}

class _LuxuryToastWidgetState extends State<_LuxuryToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 50.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _widthAnimation = Tween<double>(begin: 80.0, end: 320.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _controller.forward();

    // Trigger reverse animation before the overlay is forcefully removed
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) {
        _controller.reverse();
      }
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
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Center(
                  child: Container(
                    width: _widthAnimation.value,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222), // Dark luxury color
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
