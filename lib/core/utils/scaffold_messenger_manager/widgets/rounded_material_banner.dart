import 'package:flutter/material.dart';

/// Кастомный виджет для создания закругленного MaterialBanner
class RoundedMaterialBanner extends StatelessWidget {
  final Widget content;
  final Widget? leading;
  final List<Widget> actions;
  final Color? backgroundColor;
  final bool forceActionsBelow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final Color? dividerColor;
  final double? elevation;
  final BorderRadius borderRadius;
  final Color? borderColor;
  final double borderWidth;

  const RoundedMaterialBanner({
    super.key,
    required this.content,
    this.leading,
    required this.actions,
    this.backgroundColor,
    this.forceActionsBelow = false,
    this.margin,
    this.padding,
    this.surfaceTintColor,
    this.shadowColor,
    this.dividerColor,
    this.elevation,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerTheme = theme.bannerTheme;

    final effectiveBackgroundColor =
        backgroundColor ??
        bannerTheme.backgroundColor ??
        theme.colorScheme.surface;

    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    final effectiveMargin =
        margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: borderRadius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: shadowColor ?? Colors.black.withOpacity(0.15),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: effectivePadding,
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (forceActionsBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainContent(context),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMainContent(context)),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildActions(context),
          ],
        ],
      );
    }
  }

  Widget _buildMainContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: content),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (forceActionsBelow) {
      return Wrap(spacing: 8, runSpacing: 8, children: actions);
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: action,
              ),
            )
            .toList(),
      );
    }
  }
}
