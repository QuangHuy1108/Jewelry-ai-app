import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponCard extends StatefulWidget {
  final String code;
  final String condition;
  final String discount;
  final bool isExpired;

  const CouponCard({
    super.key,
    required this.code,
    required this.condition,
    required this.discount,
    this.isExpired = false,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyCode() {
    if (widget.isExpired) return;
    
    _controller.forward().then((_) => _controller.reverse());
    Clipboard.setData(ClipboardData(text: widget.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code ${widget.code} Copied!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isExpired ? 0.6 : 1.0,
      child: CustomPaint(
        painter: TicketPainter(
          borderColor: const Color(0xFFE0E0E0),
          bgColor: Colors.white,
          borderRadius: 12,
          punchRadius: 10,
          punchPositionPercent: 0.7, // Position at 70% from top
        ),
        child: Column(
          children: [
            // Top Section (Info)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.confirmation_num_outlined, color: Colors.grey, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.code,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.condition,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.discount,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section (Action)
            InkWell(
              onTap: _copyCode,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      widget.isExpired ? 'EXPIRED' : 'COPY CODE',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketPainter extends CustomPainter {
  final Color borderColor;
  final Color bgColor;
  final double borderRadius;
  final double punchRadius;
  final double punchPositionPercent;

  TicketPainter({
    required this.borderColor,
    required this.bgColor,
    required this.borderRadius,
    required this.punchRadius,
    required this.punchPositionPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final punchY = size.height * punchPositionPercent;

    // Build the ticket path with cutouts
    path.moveTo(borderRadius, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(Offset(size.width, borderRadius), radius: Radius.circular(borderRadius));
    
    // Right side cut-out
    path.lineTo(size.width, punchY - punchRadius);
    path.arcToPoint(Offset(size.width, punchY + punchRadius), 
        radius: Radius.circular(punchRadius), clockwise: false);
    
    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(Offset(size.width - borderRadius, size.height), radius: Radius.circular(borderRadius));
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(Offset(0, size.height - borderRadius), radius: Radius.circular(borderRadius));
    
    // Left side cut-out
    path.lineTo(0, punchY + punchRadius);
    path.arcToPoint(Offset(0, punchY - punchRadius), 
        radius: Radius.circular(punchRadius), clockwise: false);
    
    path.lineTo(0, borderRadius);
    path.arcToPoint(Offset(borderRadius, 0), radius: Radius.circular(borderRadius));

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Draw dashed line between top and bottom sections
    final dashPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    double startX = punchRadius;
    const double dashWidth = 4;
    const double dashSpace = 4;
    while (startX < size.width - punchRadius) {
      canvas.drawLine(Offset(startX, punchY), Offset(startX + dashWidth, punchY), dashPaint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShimmerCouponCard extends StatefulWidget {
  const ShimmerCouponCard({super.key});

  @override
  State<ShimmerCouponCard> createState() => _ShimmerCouponCardState();
}

class _ShimmerCouponCardState extends State<ShimmerCouponCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _colorAnimation = ColorTween(
            begin: const Color(0xFFF5F5F5), end: const Color(0xFFEEEEEE))
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
          height: 140,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
