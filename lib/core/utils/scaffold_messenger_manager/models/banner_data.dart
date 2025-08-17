import 'package:flutter/material.dart';

enum BannerType { error, warning, info, success }

class BannerData {
  final String message;
  final BannerType type;
  final Widget? leading;
  final List<Widget>? actions;
  final bool forceActionsBelow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final Color? dividerColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool useRoundedCorners;

  const BannerData({
    required this.message,
    required this.type,
    this.leading,
    this.actions,
    this.forceActionsBelow = false,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.dividerColor,
    this.elevation,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.useRoundedCorners = true,
  });

  BannerData copyWith({
    String? message,
    BannerType? type,
    Widget? leading,
    List<Widget>? actions,
    bool? forceActionsBelow,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? surfaceTintColor,
    Color? shadowColor,
    Color? dividerColor,
    double? elevation,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    bool? useRoundedCorners,
  }) {
    return BannerData(
      message: message ?? this.message,
      type: type ?? this.type,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      forceActionsBelow: forceActionsBelow ?? this.forceActionsBelow,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shadowColor: shadowColor ?? this.shadowColor,
      dividerColor: dividerColor ?? this.dividerColor,
      elevation: elevation ?? this.elevation,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      useRoundedCorners: useRoundedCorners ?? this.useRoundedCorners,
    );
  }
}
