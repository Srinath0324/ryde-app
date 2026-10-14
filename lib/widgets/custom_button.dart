import 'package:flutter/material.dart';

enum ButtonBgVariant { primary, secondary, danger, success, outline , white}
enum ButtonTextVariant { primary, secondary, danger, success, defaultText }

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final ButtonBgVariant bgVariant;
  final ButtonTextVariant textVariant;
  final Widget? iconLeft;
  final Widget? iconRight;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.bgVariant = ButtonBgVariant.primary,
    this.textVariant = ButtonTextVariant.defaultText,
    this.iconLeft,
    this.iconRight,
    this.padding,
  });

  Color _getBgColor() {
    switch (bgVariant) {
      case ButtonBgVariant.secondary:
        return Colors.grey;
      case ButtonBgVariant.danger:
        return Colors.red;
      case ButtonBgVariant.success:
        return Colors.green;
      case ButtonBgVariant.outline:
        return Colors.transparent;
      case ButtonBgVariant.white:
        return Colors.white;
      default:
        return const Color(0xFF0091FF); // default
    }
  }

  Color _getTextColor() {
    switch (textVariant) {
      case ButtonTextVariant.primary:
        return Colors.black;
      case ButtonTextVariant.secondary:
        return Colors.grey.shade100;
      case ButtonTextVariant.danger:
        return Colors.red.shade100;
      case ButtonTextVariant.success:
        return Colors.green.shade100;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(100),
        border: bgVariant == ButtonBgVariant.outline
            ? Border.all(color: Colors.grey.shade300, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconLeft != null) iconLeft!,
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextColor(),
              ),
            ),
            if (iconRight != null) iconRight!,
          ],
        ),
      ),
    );
  }
}
