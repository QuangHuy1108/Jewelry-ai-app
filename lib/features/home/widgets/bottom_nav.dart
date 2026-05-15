import 'package:flutter/material.dart';
import '../../../shared/widgets/cart_badge_icon.dart';
import '../../../core/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    int selectedIndex = 0;
    if (currentRoute == '/') {
      selectedIndex = 0;
    } else if (currentRoute == '/wishlist') {
      selectedIndex = 1;
    } else if (currentRoute == '/cart') {
      selectedIndex = 2;
    } else if (currentRoute == '/chat-list') {
      selectedIndex = 3;
    } else if (currentRoute == '/user-profile') {
      selectedIndex = 4;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasParchment, // off-white parchment token for footer/navigation chrome
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        backgroundColor: Colors.transparent,
        elevation: 0, // strict flat layout
        selectedItemColor: AppColors.primary, // pure Action Blue interaction state
        unselectedItemColor: AppColors.inkMuted48,
        selectedLabelStyle: const TextStyle(
          fontSize: 12, // SF Pro nav-link token size
          fontWeight: FontWeight.w600,
          letterSpacing: -0.12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.12,
        ),
        onTap: (index) {
          if (index == selectedIndex) return;
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.pushNamed(context, '/wishlist');
              break;
            case 2:
              Navigator.pushNamed(context, '/cart');
              break;
            case 3:
              Navigator.pushNamed(context, '/chat-list');
              break;
            case 4:
              Navigator.pushNamed(context, '/user-profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: "Wishlist"),
          BottomNavigationBarItem(
              icon: CartIconWithBadge(iconData: Icons.shopping_bag_outlined),
              activeIcon: CartIconWithBadge(iconData: Icons.shopping_bag, iconColor: AppColors.primary),
              label: "Bag"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}