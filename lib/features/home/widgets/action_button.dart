import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.width = 150,
    this.description,
    this.height = 150,
    this.borderRadius = 12,
    this.isWidthFull = false,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;
  final String? description;
  final double borderRadius;
  final Widget? icon;
  final Color? backgroundColor;
  final double width;
  final double height;
  final bool isWidthFull;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWidthFull ? double.infinity : width,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero, // убирает лишние отступы
          backgroundColor: backgroundColor ?? Colors.transparent,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: borderColor ?? Colors.transparent),
          ),
        ),
        child: Center(
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [icon!, const SizedBox(width: 8), child],
                )
              : child,
        ), // текст/иконка по центру
      ),
    );
  }
}
