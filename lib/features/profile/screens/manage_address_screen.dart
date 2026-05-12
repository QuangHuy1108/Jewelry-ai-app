import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:jewelry_app/services/address_service.dart';

class ManageAddressScreen extends StatelessWidget {
  ManageAddressScreen({super.key});

  final AddressService _addressService = AddressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _addressService.getAddressesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No addresses found. Add a new one!', style: TextStyle(color: Color(0xFF999999))),
                          ),
                        ...docs.asMap().entries.map((entry) {
                          final data = entry.value.data();
                          final isLast = entry.key == docs.length - 1;
                          final type = data['type'] ?? 'Address';
                          final address = data['address'] ?? '';
                          return _buildAddressItem(type, address, showDivider: !isLast);
                        }),
                        if (docs.isNotEmpty) const SizedBox(height: 24),
                        _buildAddAddressButton(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Text(
            'Manage Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAddressItem(String title, String subtitle, {bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF777777), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE).withAlpha(128)),
      ],
    );
  }

  Widget _buildAddAddressButton(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: const Color(0xFFCCCCCC),
        strokeWidth: 1.5,
        gap: 4,
        dashWidth: 6,
        radius: 12,
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRouter.addAddress),
        child: Container(
          width: double.infinity,
          color: Colors.transparent, // Important for tap detection
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Color(0xFF999999), size: 18),
              SizedBox(width: 8),
              Text(
                'Add New Shipping Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF777777),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashWidth = 4.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();

    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
