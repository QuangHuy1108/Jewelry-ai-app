import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Determine if we show a clear button or a QR code scanner dummy icon
    final bool showClear = controller.text.isNotEmpty && !readOnly;

    return GestureDetector(
      onTap: onTap,
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
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: IgnorePointer(
                ignoring: readOnly,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  onChanged: (val) {
                    onChanged(val);
                    // trigger a rebuild in parent so the 'x' button toggles properly
                  },
                  onSubmitted: onSubmitted,
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
                onTap: onClear,
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              )
            else if (readOnly)
              const Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}