import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';

/// Legacy Seller-initiated chat screen. Now wired to the real ChatProvider.
class SellerChatScreen extends StatefulWidget {
  final Map<String, dynamic> initialProduct;
  final String sellerName;
  final String sellerAvatar;

  const SellerChatScreen({
    super.key,
    required this.initialProduct,
    required this.sellerName,
    required this.sellerAvatar,
  });

  @override
  State<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(_msgController.text.trim());
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.sellerAvatar.isNotEmpty ? NetworkImage(widget.sellerAvatar) : null,
            radius: 18,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sellerName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Online', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final messages = provider.activeMessages;
        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == provider.currentUserId;
            return _buildMessageBubble(msg, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF333333) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF333333)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
