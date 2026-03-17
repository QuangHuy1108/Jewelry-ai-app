import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'text': 'Xin chào! Tôi là trợ lý AI chuyên về trang sức cao cấp. Tôi có thể giúp gì cho bạn?'}
  ];

  bool _isLoading = false;

  // --- PHẦN KẾT NỐI GEMINI ---
  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // 1. Khởi tạo mô hình Gemini
    _model = GenerativeModel(
      // Thêm "-latest" vào sau tên model
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyAS1-79ZnuxC-2sNd0ridUT48gKVh-S6Xw',
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.7,
      ),
    );
    // 2. Bắt đầu phiên hội thoại với "vai diễn" chuyên gia
    _chat = _model.startChat(history: [
      Content.text("Bạn là một chuyên gia tư vấn trang sức cao cấp. Hãy trả lời ngắn gọn, lịch sự và sang trọng. Bạn am hiểu về vàng, kim cương, đá quý và phong thủy."),
    ]);
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userMessage});
      _isLoading = true; // Hiện hiệu ứng đang suy nghĩ
    });
    _controller.clear();

    try {
      // 3. Gửi tin nhắn lên Gemini
      final response = await _chat.sendMessage(Content.text(userMessage));

      setState(() {
        _messages.add({'role': 'bot', 'text': response.text ?? 'Xin lỗi, tôi gặp chút trục trặc.'});
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi thật sự đây nè: $e");

      setState(() {
        _messages.add({'role': 'bot', 'text': 'Lỗi kết nối: Bạn hãy kiểm tra lại API Key nhé!'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TRỢ LÝ TRANG SỨC AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return _buildChatBubble(isUser, _messages[index]['text']!);
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Trợ lý đang soạn câu trả lời...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // Giao diện ô nhập tin nhắn
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(hintText: 'Hỏi về phong thủy, phối đồ...', border: InputBorder.none),
            ),
          ),
          IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Color(0xFFD4AF37))),
        ],
      ),
    );
  }

  // Giao diện bong bóng chat
  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1A1A1A) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black)),
      ),
    );
  }
}