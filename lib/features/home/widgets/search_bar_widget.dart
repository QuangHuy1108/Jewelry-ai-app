import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onTap;
  final bool readOnly;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  DateTime? _lastSubmitTime;

  void _handleSearch() {
    if (widget.readOnly) {
      if (widget.onTap != null) widget.onTap!();
      return;
    }

    final now = DateTime.now();
    if (_lastSubmitTime != null && now.difference(_lastSubmitTime!).inMilliseconds < 500) {
      return; // prevent duplicate requests
    }
    _lastSubmitTime = now;

    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmitted(text);
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a keyword"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we show a clear button or a QR code scanner dummy icon
    final bool showClear = widget.controller.text.isNotEmpty && !widget.readOnly;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _handleSearch,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: IgnorePointer(
                ignoring: widget.readOnly,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  readOnly: widget.readOnly,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => _handleSearch(),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: "Search..",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            if (showClear)
              GestureDetector(
                onTap: widget.onClear,
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              )
            else if (widget.readOnly)
              const Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}