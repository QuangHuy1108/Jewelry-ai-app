import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Assistant")),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text("Chat with AI")),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ask something...",
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      ),
    );
  }
}