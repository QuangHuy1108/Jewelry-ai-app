import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
      LuxuryToast.show(context, message: "Please enter a keyword");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showClear = widget.controller.text.isNotEmpty && !widget.readOnly;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44, // exact search-input height token
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(9999), // rounded.pill
          border: Border.all(color: AppColors.hairline, width: 1), // theme hairline token standard
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            GestureDetector(
              onTap: _handleSearch,
              child: const Icon(Icons.search, color: AppColors.inkMuted48, size: 16),
            ),
            const SizedBox(width: 8),
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
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17, // SF Pro body size
                    letterSpacing: -0.374,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Search catalog...",
                    hintStyle: TextStyle(color: AppColors.inkMuted48, fontSize: 17, letterSpacing: -0.374),
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
                child: const Icon(Icons.close, color: AppColors.inkMuted48, size: 16),
              )
            else if (widget.readOnly)
              const Icon(Icons.qr_code_scanner, color: AppColors.inkMuted48, size: 16),
          ],
        ),
      ),
    );
  }
}