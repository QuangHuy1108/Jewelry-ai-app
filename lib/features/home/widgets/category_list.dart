import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../category/screens/category_screen.dart';
import '../../../core/theme/app_colors.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Catalog Collections",
                style: TextStyle(
                  fontSize: 21, // SF Pro tagline size
                  fontWeight: FontWeight.w600, 
                  color: AppColors.ink,
                  letterSpacing: 0.231,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Browse All",
                  style: TextStyle(
                    fontSize: 14, 
                    color: AppColors.primary, 
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.224,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44, // sleek button/chip standard navigation height
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProductService().getCategoriesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.ink));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No collections found", style: TextStyle(color: AppColors.inkMuted48)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final name = data['name'] ?? '';

                  return _CategoryChip(name: name);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String name;
  const _CategoryChip({required this.name});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryName: widget.name),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(9999), // full pill
            border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_outlined, size: 14, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(
                widget.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14, // SF Pro caption size
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.224,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}