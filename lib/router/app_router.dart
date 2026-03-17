import 'package:go_router/go_router.dart';
import 'package:jewelry_app/features/shopping/cart_screen.dart';
import '../features/shopping/home_screen.dart';
import '../features/shopping/product_detail_screen.dart';
import '../shared/mock/mock_products.dart';
import '../features/shopping/camera_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/shopping/checkout_screen.dart';
import '../features/home/main_screen.dart';

// Đây là "Bản đồ" điều hướng của toàn bộ ứng dụng
final GoRouter appRouter = GoRouter(
  initialLocation: '/', // Khi mở app, trang đầu tiên hiện ra là '/'
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(), // Đổi HomeScreen thành MainScreen
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        // Lấy dữ liệu sản phẩm được truyền qua 'extra'
        final product = state.extra as ProductModel;
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
  ],
);