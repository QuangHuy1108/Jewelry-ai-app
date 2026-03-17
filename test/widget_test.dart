import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Đảm bảo import đúng file main.dart của bạn
import 'package:jewelry_app/main.dart';

void main() {
  testWidgets('Kiểm tra khởi chạy ứng dụng', (WidgetTester tester) async {
    // Chạy ứng dụng giả lập trong môi trường test
    await tester.pumpWidget(
      const ProviderScope(
        child: JewelryAiApp(),
      ),
    );

    // Chờ hệ thống vẽ xong giao diện
    await tester.pumpAndSettle();

    // Kiểm tra xem ứng dụng (JewelryAiApp) đã được hiển thị lên màn hình chưa
    expect(find.byType(JewelryAiApp), findsOneWidget);
  });
}