import 'package:flutter/material.dart';

class SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelect;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No suggestions found.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: suggestions.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _AnimatedOpacityItem(
          onTap: () => onSelect(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedOpacityItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedOpacityItem({required this.child, required this.onTap});

  @override
  State<_AnimatedOpacityItem> createState() => _AnimatedOpacityItemState();
}

class _AnimatedOpacityItemState extends State<_AnimatedOpacityItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}
