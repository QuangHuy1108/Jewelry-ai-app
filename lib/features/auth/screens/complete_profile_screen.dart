import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io'; // Thêm thư viện này để đọc File ảnh
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh
import 'package:country_picker/country_picker.dart'; // Thư viện chọn mã vùng có thanh tìm kiếm
import 'package:shared_preferences/shared_preferences.dart';
import '../../../router/app_router.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedCountryCode = "+1";
  String? _selectedGender;
  bool _isLoading = false;
  File? _imageFile; // Biến lưu trữ ảnh đại diện đã chọn

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOGIC: Xử lý chọn ảnh từ Camera hoặc Gallery
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Đóng BottomSheet trước
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Nén ảnh nhẹ bớt
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // Lưu file ảnh vào biến
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi chọn ảnh: $e");
    }
  }

  // LOGIC: Xử lý Submit Form
  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Tại đây bạn sẽ gọi API / Firebase để upload ảnh (_imageFile) và gửi dữ liệu lên
      // Giả lập thời gian gọi API mất 2 giây
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile completed successfully!"), backgroundColor: Colors.green),
        );

        // FEATURE: Only ask for notification permission for first-time users
        final prefs = await SharedPreferences.getInstance();
        bool isFirstTime = prefs.getBool('isFirstTimeUser') ?? true;

        if (isFirstTime) {
          await prefs.setBool('isFirstTimeUser', false);
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.enableNotification);
          }
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          }
        }
      }
    }
  }

  // Mở BottomSheet chọn ảnh
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => _pickImage(ImageSource.camera), // Gọi hàm chụp ảnh
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => _pickImage(ImageSource.gallery), // Gọi hàm mở thư viện
              ),
            ],
          ),
        );
      },
    );
  }

  // LOGIC: Dùng thư viện country_picker để hiển thị danh sách quốc gia có thanh tìm kiếm
  void _showCountryCodePicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}"; // Cập nhật mã vùng
        });
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ---
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
                        const SizedBox(height: 32),

                        // --- TITLES ---
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                "Complete Your Profile",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Don't worry, only you can see your personal\ndata. No one else will be able to see it.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- AVATAR SECTION (Cập nhật hiển thị ảnh thật) ---
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                  // Kiểm tra: Nếu có ảnh thì hiển thị ảnh, nếu không thì hiện icon mặc định
                                  image: _imageFile != null
                                      ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: _imageFile == null
                                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- FORM FIELDS ---
                        // 1. Name Input (Cập nhật chặn nhập số)
                        const Text("Name", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          // Regex chặn nhập số và ký tự đặc biệt, chỉ cho phép chữ cái (bao gồm tiếng Việt) và dấu cách
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ỹ\s]')),
                          ],
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          decoration: _inputDecoration(hintText: "Ex. John Doe"),
                        ),
                        const SizedBox(height: 24),

                        // 2. Phone Number Input (Cập nhật validate độ dài)
                        const Text("Phone Number", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _showCountryCodePicker,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      Text(_selectedCountryCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 24, color: Colors.grey.shade400),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    // Kiểm tra độ dài hợp lệ (ví dụ: 9 đến 11 số)
                                    if (value.length < 9 || value.length > 11) {
                                      return 'Phone number must be 9-11 digits';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    hintText: "Enter Phone Number",
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. Gender Dropdown
                        const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          decoration: _inputDecoration(hintText: "Select"),
                          items: _genders.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                          validator: (value) => value == null ? 'Please select your gender' : null,
                        ),

                        const Spacer(),
                        const SizedBox(height: 32),

                        // --- FOOTER BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              disabledBackgroundColor: Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                                : const Text(
                              "Complete Profile",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}
