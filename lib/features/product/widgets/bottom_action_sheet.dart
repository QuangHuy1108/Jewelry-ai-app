import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../shared/widgets/cart_badge_icon.dart';
import '../../chat/screens/seller_chat_screen.dart';
import '../../../router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class BottomActionSheet extends StatelessWidget {
  final Map<String, dynamic> product;

  const BottomActionSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<WishlistProvider, bool>((w) => w.isInWishlist(product['id']));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : const Color(0xFF333333),
            label: 'Wishlist',
            onTap: () => context.read<WishlistProvider>().toggleWishlist(product),
          ),
          _buildActionItem(
            icon: Icons.ios_share,
            label: 'Share',
            onTap: () {
              Share.share('Check out this luxurious ${product['name']}!');
            },
          ),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('sellers').doc(product['sellerId']).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
              final sellerData = snapshot.data!.data() as Map<String, dynamic>?;
              final sellerUserId = sellerData?['userId'] as String?;
              
              // Task 1: Hide button if the logged-in user is the seller of the product
              if (FirebaseAuth.instance.currentUser?.uid == sellerUserId) {
                return const SizedBox.shrink();
              }
              
              return _buildActionItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                onTap: () {
                  // Task 2: Pass sellerUserId instead of product['sellerId']
                  Navigator.pushNamed(
                    context, 
                    AppRouter.chatDetail,
                    arguments: {
                      'sellerId': sellerUserId ?? product['sellerId'],
                      'sellerName': sellerData?['name'] ?? 'Support',
                      'sellerAvatar': sellerData?['avatar'] ?? '',
                      'productContext': product,
                    }
                  );
                },
              );
            },
          ),
          _buildActionItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Cart',
            isCart: true,
            onTap: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap, 
    Color color = const Color(0xFF333333),
    bool isCart = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isCart ? CartIconWithBadge(iconData: icon, iconColor: color, size: 24) : Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
