import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  // Thay chuỗi này bằng API Key bạn lấy từ Google AI Studio
  static const String _apiKey = 'AIzaSyAS1-79ZnuxC-2sNd0ridUT48gKVh-S6Xw';

  // Biến lưu trữ model AI
  late final GenerativeModel _model;

  // Hàm khởi tạo service
  GeminiChatService() {
    // Chúng ta sử dụng 'gemini-1.5-flash' vì nó rất nhanh và tối ưu cho Chatbot
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Hàm gửi tin nhắn của người dùng và nhận câu trả lời từ AI
  Future<String> getAIResponse(String userMessage) async {
    try {
      // Đóng gói tin nhắn thành định dạng Content mà thư viện yêu cầu
      final content = [Content.text(userMessage)];

      // Gửi yêu cầu lên Gemini API
      final response = await _model.generateContent(content);

      // Trả về câu trả lời. Nếu response.text bị null, trả về chuỗi mặc định.
      return response.text ?? 'Xin lỗi, tôi chưa hiểu ý bạn.';

    } catch (e) {
      // In lỗi ra console để lập trình viên (chúng ta) dễ theo dõi
      print('Lỗi kết nối Gemini: $e');

      // Trả về thông báo lỗi thân thiện cho người dùng trên màn hình
      return 'Hệ thống AI đang bảo trì hoặc gặp lỗi kết nối. Vui lòng thử lại sau!';
    }
  }
}