import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OfferBanner extends StatefulWidget {
  const OfferBanner({super.key});

  @override
  State<OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<OfferBanner> {
  int activeIndex = 0;

  final images = [
    "https://i.imgur.com/8Km9tLL.jpg",
    "https://i.imgur.com/5tj6S7Ol.jpg",
    "https://i.imgur.com/3ZQ3Z3Zl.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: images.length,
          options: CarouselOptions(
            height: 170,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() => activeIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return buildBanner(images[index]);
          },
        ),

        const SizedBox(height: 8),

        AnimatedSmoothIndicator(
          activeIndex: activeIndex,
          count: images.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: Colors.black,
          ),
        )
      ],
    );
  }

  Widget buildBanner(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          // 🔥 GRADIENT CHUẨN UI
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Limited time!",
                style: TextStyle(color: Colors.white)),
            SizedBox(height: 5),
            Text("Get Special Offer",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Spacer(),
            Text("Up to 40%",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}