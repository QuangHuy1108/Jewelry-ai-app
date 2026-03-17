import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart' as prov;
import 'shared/providers/cart_provider.dart';

// Nhúng các mảnh ghép bạn vừa tạo vào đây
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  // 1. Đảm bảo Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo kết nối Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase đã kết nối thành công!');
  } catch (e) {
    debugPrint('❌ Lỗi khởi tạo Firebase: $e');
  }

  // 3. Khởi chạy ứng dụng và bọc trong ProviderScope cho Riverpod
  runApp(
    // 2. LỚP BỌC 1: Trả lại ProviderScope cho Riverpod (để HomeScreen sống lại)
    ProviderScope(
      // 3. LỚP BỌC 2: Thêm Giỏ hàng của chúng ta vào
      child: prov.ChangeNotifierProvider(
        create: (context) => CartProvider(),
        child: const JewelryAiApp(), // Hoặc JewelryApp tùy vào tên class bên dưới của bạn
      ),
    ),
  );
}

class JewelryAiApp extends StatelessWidget {
  const JewelryAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jewelry AI App',
      debugShowCheckedModeBanner: false,

      // 4. Mặc chiếc "áo" Luxury Minimal mà bạn đã thiết kế
      theme: AppTheme.lightTheme,

      // 5. Giao việc chuyển trang cho GoRouter quản lý
      routerConfig: appRouter,
    );
  }
}