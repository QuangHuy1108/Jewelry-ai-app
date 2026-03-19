import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Thư viện lấy tọa độ GPS
import 'package:geocoding/geocoding.dart'; // Thư viện dịch tọa độ sang địa chỉ Text
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện lưu trạng thái
import '../../../router/app_router.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({Key? key}) : super(key: key);

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _bounceController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _dropBounceAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controller cho hiệu ứng Fade In tổng thể
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    // 2. Controller cho hiệu ứng Drop & Bounce của Icon
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _dropBounceAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    _entranceController.forward().then((_) {
      _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // LOGIC: Xin quyền GPS, lấy tọa độ và dịch sang tên đường
  Future<void> _handleAllowLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra xem dịch vụ định vị của máy đã bật chưa
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật Dịch vụ định vị (GPS) trên thiết bị.')),
        );
      }
      return;
    }

    // 2. Kiểm tra và xin quyền
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã từ chối quyền truy cập vị trí.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn. Hãy vào Cài đặt để mở lại.')),
        );
      }
      return;
    }

    // 3. Đã có quyền -> Tiến hành lấy vị trí
    try {
      // Hiện vòng xoay loading vì việc tìm GPS có thể mất 1-3 giây
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      // Lấy tọa độ Kinh độ / Vĩ độ chính xác cao
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 4. Dịch tọa độ sang tên Thành phố / Đường (Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = "Unknown Location";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Tạo chuỗi địa chỉ (vd: Quận 1, Hồ Chí Minh)
        address = "${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }

      // 5. Lưu trạng thái và địa chỉ vào bộ nhớ máy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationGranted', true);
      await prefs.setString('userLocation', address);

      // Tắt vòng xoay loading
      if (mounted) Navigator.pop(context);

      // 6. Chuyển thẳng về Trang chủ
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }

    } catch (e) {
      if (mounted) Navigator.pop(context); // Tắt loading nếu lỗi
      debugPrint("Lỗi khi lấy vị trí: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy vị trí hiện tại. Vui lòng thử lại sau.')),
        );
      }
    }
  }

  // LOGIC: Xử lý khi người dùng chọn Nhập thủ công
  void _handleEnterManually() {
    // Điều hướng sang màn hình nhập địa chỉ thủ công
    // Lưu ý: Đảm bảo bạn đã khai báo route này trong AppRouter
    // Navigator.pushNamed(context, AppRouter.enterLocation);

    // Tạm thời hiển thị thông báo nếu bạn chưa tạo màn hình này:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng nhập thủ công đang được phát triển.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _dropBounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 50,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  "What is Your Location?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "To Find Nearby Jewelry Store.", // Đã đổi thành Jewelry Store
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleAllowLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      "Allow Location Access",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _handleEnterManually,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      "Enter Location Manually",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}