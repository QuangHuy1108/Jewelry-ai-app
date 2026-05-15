import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ButtonVariant { primaryPill, secondaryPill, darkUtility }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final EdgeInsetsGeometry? customPadding;
  final bool isExpanded;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primaryPill,
    this.customPadding,
    this.isExpanded = false,
    this.isDisabled = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled) _scaleController.forward();
  }
  void _onTapUp(TapUpDetails details) {
    if (!widget.isDisabled) _scaleController.reverse();
  }
  void _onTapCancel() {
    if (!widget.isDisabled) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderRadius borderRadius;
    EdgeInsetsGeometry padding;
    double fontSize;
    FontWeight fontWeight;
    Border? border;

    switch (widget.variant) {
      case ButtonVariant.secondaryPill:
        bgColor = Colors.transparent;
        textColor = widget.isDisabled ? AppColors.inkMuted48 : AppColors.primary;
        borderRadius = BorderRadius.circular(9999);
        padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 22);
        fontSize = 17;
        fontWeight = FontWeight.w400;
        border = Border.all(color: widget.isDisabled ? AppColors.hairline : AppColors.primary, width: 1);
        break;

      case ButtonVariant.darkUtility:
        bgColor = widget.isDisabled ? AppColors.canvasParchment : AppColors.ink;
        textColor = widget.isDisabled ? AppColors.inkMuted48 : AppColors.bodyOnDark;
        borderRadius = BorderRadius.circular(8); // rounded.sm
        padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 15);
        fontSize = 14;
        fontWeight = FontWeight.w400;
        break;

      case ButtonVariant.primaryPill:
      default:
        bgColor = widget.isDisabled ? AppColors.canvasParchment : AppColors.primary;
        textColor = widget.isDisabled ? AppColors.inkMuted48 : AppColors.bodyOnDark;
        borderRadius = BorderRadius.circular(9999); // rounded.pill
        padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 22);
        fontSize = 17;
        fontWeight = FontWeight.w400;
        break;
    }

    final effectivePadding = widget.customPadding ?? padding;

    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: border,
      ),
      alignment: widget.isExpanded ? Alignment.center : null,
      child: Text(
        widget.text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: fontSize >= 17 ? -0.374 : -0.224,
          height: 1.0,
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isDisabled ? null : widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.isExpanded ? SizedBox(width: double.infinity, child: buttonContent) : buttonContent,
      ),
    );
  }
}