import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../models/ai_result_model.dart';

class AiScanProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AiResultModel? _result;
  AiResultModel? get result => _result;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        _result = null;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Failed to access camera/gallery: $e";
      notifyListeners();
    }
  }

  void reset() {
    _selectedImage = null;
    _result = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> scanImage() async {
    if (_selectedImage == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload to Firebase Storage
      final fileName = 'ai_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('ai_scans').child(fileName);
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      // 2. Call Cloud Function via HTTP
      // Note: Assuming a standardized deployment structure. In real deployment,
      // this URL would dynamically point to the registered regional gateway.
      final url = Uri.parse('https://us-central1-glowup-jewelry-ai.cloudfunctions.net/aiScan');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageUrl': downloadUrl}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _result = AiResultModel.fromJson(data);
      } else {
        _errorMessage = "AI Analysis failed (HTTP ${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      _errorMessage = "Failed to process image: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
