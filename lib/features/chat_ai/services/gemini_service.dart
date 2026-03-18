class GeminiService {
  Future<String> askAI(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    return "AI response for: $prompt";
  }
}