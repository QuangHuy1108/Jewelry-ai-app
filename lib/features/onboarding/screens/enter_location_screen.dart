import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart'; // Thư viện lấy tọa độ GPS
import 'package:geocoding/geocoding.dart'; // Thư viện dịch tọa độ sang địa chỉ Text
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện lưu trạng thái
import '../../../router/app_router.dart'; // Sử dụng AppRouter chuẩn của dự án

class EnterLocationScreen extends StatefulWidget {
  const EnterLocationScreen({Key? key}) : super(key: key);

  @override
  State<EnterLocationScreen> createState() => _EnterLocationScreenState();
}

class _EnterLocationScreenState extends State<EnterLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Tự động focus vào ô tìm kiếm và bật bàn phím ngay khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // Lắng nghe sự thay đổi của text để hiện/ẩn nút 'x'
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // LOGIC 1: Debounce - Chống gửi API liên tục
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  // LOGIC 2: Tìm kiếm tự động (Auto-complete)
  Future<void> _performSearch(String query) async {
    // Giả lập độ trễ mạng khi gọi API thật (vd: Google Places)
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _searchResults = [
        {
          "name": "Golden Avenue",
          "address": "8502 Preston Rd. Inglewood, Maine 98380"
        },
        {
          "name": "Golden Gate Bridge",
          "address": "San Francisco, CA 94129, United States"
        },
        {
          "name": "Golden Jewelry Store",
          "address": "123 Diamond Street, New York, NY 10001"
        },
      ];
    });
  }

  // LOGIC 3: Lấy phần cứng GPS (Use my current location)
  Future<void> _useCurrentLocation() async {
    _searchFocusNode.unfocus(); // Ẩn bàn phím

    setState(() {
      _isLoading = true; // Hiện loading góc phải màn hình
    });

    try {
      // 1. Kiểm tra quyền và dịch vụ GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Vui lòng bật Dịch vụ định vị (GPS).');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Bạn đã từ chối quyền vị trí.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị từ chối vĩnh viễn.');
      }

      // 2. Lấy tọa độ và dịch sang tên đường
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      String address = "Vị trí của bạn";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address = "${place.street ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }

      // 3. Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationGranted', true);
      await prefs.setString('userLocation', address);

      // 4. Chuyển về trang chủ bằng AppRouter
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // LOGIC 4: Chọn kết quả và lưu trạng thái
  Future<void> _selectLocation(Map<String, String> location) async {
    _searchFocusNode.unfocus(); // Ẩn bàn phím

    // Lưu vị trí được chọn vào bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationGranted', true);
    await prefs.setString('userLocation', location["address"] ?? location["name"] ?? "");

    // Chuyển hướng về trang chủ bằng AppRouter
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Enter Your Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // --- SEARCH BAR (Có tính năng Clear Text) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Search location...",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        ),
                        child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged("");
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- USE MY CURRENT LOCATION ---
            InkWell(
              onTap: _useCurrentLocation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: Colors.black87, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Use my current location",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // --- SEARCH RESULTS AREA ---
            if (_searchController.text.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                child: Row(
                  children: [
                    const Text(
                      "SEARCH RESULT",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return InkWell(
                      onTap: () => _selectLocation(result),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.grey, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result["name"]!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result["address"]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Spacer(),
            ]
          ],
        ),
      ),
    );
  }
}