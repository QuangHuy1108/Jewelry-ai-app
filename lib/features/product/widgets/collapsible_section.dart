import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF999999)),
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
                  ),
                ),
        ),
        Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}
