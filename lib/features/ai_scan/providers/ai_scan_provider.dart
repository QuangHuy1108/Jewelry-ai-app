import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiScanProvider extends ChangeNotifier {
  // TODO: Move to environment config / .env for production
  // For Android emulator → host machine, use 10.0.2.2
  // For physical device on same WiFi, use the machine's LAN IP
  static const String _apiBaseUrl = 'http://10.0.2.2:8000';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Raw match data from the Python API: [{product_id, score}, ...]
  List<Map<String, dynamic>>? _rawMatches;
  List<Map<String, dynamic>>? get rawMatches => _rawMatches;

  /// Ordered product IDs returned by the AI (highest confidence first)
  List<String>? _resultIds;
  List<String>? get resultIds => _resultIds;

  /// Fully hydrated product documents from Firestore, ordered by AI confidence
  List<Map<String, dynamic>>? _matchedProducts;
  List<Map<String, dynamic>>? get matchedProducts => _matchedProducts;

  void reset() {
    _resultIds = null;
    _rawMatches = null;
    _matchedProducts = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Captures a photo from the live camera and sends it to the Python API.
  Future<void> captureAndScan(CameraController cameraController) async {
    if (!cameraController.value.isInitialized) return;
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _resultIds = null;
    _rawMatches = null;
    _matchedProducts = null;
    notifyListeners();

    try {
      // 1. Capture image from camera
      final XFile image = await cameraController.takePicture();
      
      // 2. Send to Python API
      await _sendToVisualSearch(image.path);

      // 3. Hydrate product data from Firestore
      if (_resultIds != null && _resultIds!.isNotEmpty) {
        await _hydrateProducts();
      }
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      debugPrint('AiScanProvider.captureAndScan Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Also supports scanning from a file path (e.g. gallery pick)
  Future<void> scanImage({required String imagePath}) async {
    _isLoading = true;
    _errorMessage = null;
    _resultIds = null;
    _rawMatches = null;
    _matchedProducts = null;
    notifyListeners();

    try {
      await _sendToVisualSearch(imagePath);

      if (_resultIds != null && _resultIds!.isNotEmpty) {
        await _hydrateProducts();
      }
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      debugPrint('AiScanProvider.scanImage Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends image as multipart/form-data to the Python FastAPI endpoint.
  Future<void> _sendToVisualSearch(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found at $imagePath');
    }

    final uri = Uri.parse('$_apiBaseUrl/api/v1/visual-search');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final matches = (body['matches'] as List<dynamic>?)
          ?.map((m) => Map<String, dynamic>.from(m as Map))
          .toList() ?? [];

      _rawMatches = matches;
      _resultIds = matches.map((m) => m['product_id'].toString()).toList();

      debugPrint('Visual Search: ${_resultIds!.length} matches '
          '(inference: ${body['inference_time_ms']}ms, '
          'vector dim: ${body['vector_dimension']})');
    } else {
      throw Exception('AI server returned status ${response.statusCode}: ${response.body}');
    }
  }

  /// Fetches full product documents from Firestore and orders them
  /// by the AI confidence score (highest first).
  Future<void> _hydrateProducts() async {
    if (_resultIds == null || _resultIds!.isEmpty) return;

    // Firestore 'whereIn' supports max 30 items
    final idsToQuery = _resultIds!.take(10).toList();

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where(FieldPath.documentId, whereIn: idsToQuery)
        .get();

    // Build a lookup map
    final docsById = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      docsById[doc.id] = data;
    }

    // Re-order by AI confidence score (preserving the API's ranking)
    _matchedProducts = [];
    for (final id in _resultIds!) {
      if (docsById.containsKey(id)) {
        _matchedProducts!.add(docsById[id]!);
      }
    }

    debugPrint('Hydrated ${_matchedProducts!.length} products from Firestore');
  }

  /// Get the confidence score for a specific product ID.
  double getScoreForProduct(String productId) {
    if (_rawMatches == null) return 0.0;
    final match = _rawMatches!.where((m) => m['product_id'].toString() == productId).toList();
    if (match.isEmpty) return 0.0;
    return (match.first['score'] as num?)?.toDouble() ?? 0.0;
  }
}
