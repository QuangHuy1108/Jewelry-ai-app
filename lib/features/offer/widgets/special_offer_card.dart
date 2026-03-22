import 'package:flutter/material.dart';

class SpecialOfferCard extends StatefulWidget {
  final String tag;
  final String title;
  final String discount;
  final VoidCallback onOrderNow;

  const SpecialOfferCard({
    super.key,
    required this.tag,
    required this.title,
    required this.discount,
    required this.onOrderNow,
  });

  @override
  State<SpecialOfferCard> createState() => _SpecialOfferCardState();
}

class _SpecialOfferCardState extends State<SpecialOfferCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Scale: 0.97 when the banner or "Order Now" button is pressed
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onOrderNow();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          // Height: approx. 180px - 200px.
          height: 190, 
          width: double.infinity,
          // Internal Banner Padding: 20px
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF000000), // Black
                Color(0xFF666666), // Grey/Light Grey
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF), // White pill background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500, // medium
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: widget.onOrderNow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB0B0B0).withOpacity(0.8), // Light Grey/Translucent
                              borderRadius: BorderRadius.circular(20), // Small pill-shaped button
                            ),
                            child: const Text(
                              'Order Now',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flexible width constraint for discount number to handle 1, 2, or 3 digits
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.discount,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFFFFF),
                          height: 1.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Text(
                          '% OFF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerOfferCard extends StatefulWidget {
  const ShimmerOfferCard({super.key});

  @override
  State<ShimmerOfferCard> createState() => _ShimmerOfferCardState();
}

class _ShimmerOfferCardState extends State<ShimmerOfferCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _colorAnimation = ColorTween(
            begin: Colors.grey.shade300, end: Colors.grey.shade100)
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}
