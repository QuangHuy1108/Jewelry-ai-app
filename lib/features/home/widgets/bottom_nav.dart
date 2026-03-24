import 'package:flutter/material.dart';
import '../../../shared/widgets/cart_badge_icon.dart';

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
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      selectedItemColor: const Color(0xFF333333),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == selectedIndex) return;
        switch (index) {
          case 0:
            // Pop back to Home (root of the stack)
            Navigator.popUntil(context, (route) => route.isFirst);
            break;
          case 1:
            Navigator.pushNamed(context, '/wishlist');
            break;
          case 2:
            Navigator.pushNamed(context, '/cart');
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: "Wishlist"),
        const BottomNavigationBarItem(
            icon: CartIconWithBadge(iconData: Icons.shopping_bag_outlined, iconColor: Colors.grey),
            activeIcon: CartIconWithBadge(iconData: Icons.shopping_bag, iconColor: Color(0xFF333333)),
            label: "Cart"),
        const BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: "Chat"),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}