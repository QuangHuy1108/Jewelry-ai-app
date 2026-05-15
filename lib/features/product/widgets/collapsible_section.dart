import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final String content;
  final bool initiallyExpanded;

  const CollapsibleSection({super.key, required this.title, required this.content, this.initiallyExpanded = false});

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title, 
                  style: const TextStyle(
                    fontSize: 17, // SF Pro body-strong token
                    fontWeight: FontWeight.w600, 
                    color: AppColors.ink,
                    letterSpacing: -0.374,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                  color: AppColors.inkMuted48,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.content,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: AppColors.inkMuted48, 
                      letterSpacing: -0.224,
                      height: 1.4,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: AppColors.inkMuted48, 
                      letterSpacing: -0.224,
                      height: 1.4,
                    ),
                  ),
                ),
        ),
        const Divider(height: 1, color: AppColors.hairline),
      ],
    );
  }
}
