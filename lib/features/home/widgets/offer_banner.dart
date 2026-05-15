import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../offer/screens/special_offers_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class OfferBanner extends StatefulWidget {
  const OfferBanner({super.key});

  @override
  State<OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<OfferBanner> {
  final ValueNotifier<int> _activeIndexNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _activeIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ProductService().getBannersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220, 
            child: Center(child: CircularProgressIndicator(color: AppColors.ink))
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final banners = docs.map((d) => d.data()).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Special Campaigns",
                    style: TextStyle(
                      fontSize: 21, // SF Pro tagline size
                      fontWeight: FontWeight.w600, 
                      color: AppColors.ink,
                      letterSpacing: 0.231,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SpecialOffersScreen()),
                      );
                    },
                    child: const Text(
                      "See All",
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
            CarouselSlider.builder(
              itemCount: banners.length,
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.92,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  _activeIndexNotifier.value = index;
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return buildBanner(banners[index]);
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: _activeIndexNotifier,
              builder: (context, activeIndex, child) {
                return AnimatedSmoothIndicator(
                  activeIndex: activeIndex,
                  count: banners.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 5,
                    dotWidth: 5,
                    activeDotColor: AppColors.ink,
                    dotColor: AppColors.bodyMuted,
                  ),
                );
              },
            )
          ],
        );
      },
    );
  }

  Widget buildBanner(Map<String, dynamic> banner) {
    final String imageUrl = banner['image'] ?? '';
    final String title = banner['title'] ?? 'Special Offer';
    final String subtitle = banner['subtitle'] ?? '';
    final String label = banner['label'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18), // rounded.lg matching utility cards
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24), // spacing.lg matching utility cards
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              AppColors.surfaceBlack.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.canvas.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  label.toUpperCase(), 
                  style: const TextStyle(
                    color: AppColors.bodyOnDark, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.bodyOnDark, 
                fontSize: 28, // SF Pro lead
                fontWeight: FontWeight.w600,
                letterSpacing: 0.196,
                height: 1.14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.bodyMuted, 
                      fontSize: 17, // body strong
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.374,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: "Order Now",
                  variant: ButtonVariant.primaryPill,
                  customPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SpecialOffersScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
