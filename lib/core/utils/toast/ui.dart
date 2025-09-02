import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/toast/toast_manager.dart';
import 'toast_item.dart';

class ToastWidget extends StatefulWidget {
  final ToastItem toast;
  final VoidCallback onDismiss;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const ToastWidget({
    super.key,
    required this.toast,
    required this.onDismiss,
    required this.onPause,
    required this.onResume,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    if (widget.toast.animationController == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.toast.animationController!,
      builder: (context, child) {
        return Positioned(
          top: _getTopPosition(context),
          left: _getLeftPosition(context),
          right: _getRightPosition(context),
          bottom: _getBottomPosition(context),
          child: Transform.translate(
            offset: _getAnimationOffset(),
            child: Transform.scale(
              scale: _getAnimationScale(),
              child: Opacity(
                opacity: widget.toast.animationController!.value,
                child: _buildToastContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToastContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: MouseRegion(
        onEnter: widget.toast.config.pauseOnHover ? _onHoverEnter : null,
        onExit: widget.toast.config.pauseOnHover ? _onHoverExit : null,
        child: Focus(
          onFocusChange: widget.toast.config.pauseOnFocus
              ? _onFocusChange
              : null,
          child: Material(
            elevation: 8,
            shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            color: _getBackgroundColor(context),
            child: InkWell(
              onTap: widget.toast.config.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: theme.colorScheme.onSurface.withOpacity(0.1),
              highlightColor: theme.colorScheme.onSurface.withOpacity(0.05),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                  minHeight: 72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toast content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.toast.config.customWidget ??
                              _buildDefaultContent(context),

                          // Progress bar inside content
                          if (widget.toast.config.showProgressBar &&
                              widget.toast.progressController != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: AnimatedBuilder(
                                  animation: widget.toast.progressController!,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: widget
                                          .toast
                                          .progressController!
                                          .value,
                                      backgroundColor:
                                          _getProgressBackgroundColor(context),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getProgressColor(context),
                                      ),
                                      minHeight: 4,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon with modern styling
        if (widget.toast.config.icon != null ||
            widget.toast.config.type != ToastType.custom)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.toast.config.icon ?? _getDefaultIcon(),
              color: _getIconColor(context),
              size: 20,
            ),
          ),

        // Message and actions
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message with modern typography
              Text(
                widget.toast.config.message,
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ) ??
                    TextStyle(
                      color: _getTextColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Actions with modern styling
              if (widget.toast.config.actions != null &&
                  widget.toast.config.actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    children: widget.toast.config.actions!,
                  ),
                ),
            ],
          ),
        ),

        // Modern close button
        if (widget.toast.config.dismissible)
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onDismiss,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: _getTextColor(context).withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Hover and focus handlers
  void _onHoverEnter(PointerEvent event) {
    setState(() => _isHovered = true);
    widget.onPause();
  }

  void _onHoverExit(PointerEvent event) {
    setState(() => _isHovered = false);
    if (!_isFocused) {
      widget.onResume();
    }
  }

  void _onFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    if (focused) {
      widget.onPause();
    } else if (!_isHovered) {
      widget.onResume();
    }
  }

  // Position calculations (same as before)
  double? _getTopPosition(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final index = _getToastIndex();

    switch (widget.toast.config.position) {
      case ToastPosition.top:
      case ToastPosition.topLeft:
      case ToastPosition.topRight:
        return padding.top + 24 + index * 96.0;
      case ToastPosition.center:
        return (MediaQuery.of(context).size.height - 100) / 2 +
            (index - 1) * 96.0;
      default:
        return null;
    }
  }

  double? _getBottomPosition(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final index = _getToastIndex();

    switch (widget.toast.config.position) {
      case ToastPosition.bottom:
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomRight:
        return padding.bottom + 24 + index * 96.0;
      default:
        return null;
    }
  }

  double? _getLeftPosition(BuildContext context) {
    switch (widget.toast.config.position) {
      case ToastPosition.topLeft:
      case ToastPosition.bottomLeft:
        return 0;
      case ToastPosition.center:
      case ToastPosition.top:
      case ToastPosition.bottom:
        return 0;
      default:
        return null;
    }
  }

  double? _getRightPosition(BuildContext context) {
    switch (widget.toast.config.position) {
      case ToastPosition.topRight:
      case ToastPosition.bottomRight:
        return 0;
      case ToastPosition.center:
      case ToastPosition.top:
      case ToastPosition.bottom:
        return 0;
      default:
        return null;
    }
  }

  // Animation calculations with modern curves
  Offset _getAnimationOffset() {
    final value = Curves.easeOutCubic.transform(
      widget.toast.animationController!.value,
    );
    switch (widget.toast.config.position) {
      case ToastPosition.top:
      case ToastPosition.topLeft:
      case ToastPosition.topRight:
        return Offset(0, -30 * (1 - value));
      case ToastPosition.bottom:
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomRight:
        return Offset(0, 30 * (1 - value));
      case ToastPosition.center:
        return Offset(0, 0);
    }
  }

  double _getAnimationScale() {
    final value = Curves.easeOutBack.transform(
      widget.toast.animationController!.value,
    );
    return 0.85 + (0.15 * value);
  }

  // Modern color system using theme
  Color _getBackgroundColor(BuildContext context) {
    if (widget.toast.config.backgroundColor != null) {
      return widget.toast.config.backgroundColor!;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    switch (widget.toast.config.type) {
      case ToastType.success:
        return isDark ? Colors.green.shade700 : Colors.green.shade500;
      case ToastType.error:
        return isDark ? Colors.red.shade700 : Colors.red.shade500;
      case ToastType.warning:
        return isDark ? Colors.orange.shade700 : Colors.orange.shade500;
      case ToastType.info:
        return isDark ? Colors.blue.shade700 : Colors.blue.shade500;
      case ToastType.custom:
        return colorScheme.surface;
    }
  }

  Color _getTextColor(BuildContext context) {
    if (widget.toast.config.textColor != null) {
      return widget.toast.config.textColor!;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (widget.toast.config.type) {
      case ToastType.success:
      case ToastType.error:
      case ToastType.warning:
      case ToastType.info:
        return Colors.white;
      case ToastType.custom:
        return colorScheme.onSurface;
    }
  }

  Color _getIconColor(BuildContext context) {
    return _getTextColor(context);
  }

  Color _getIconBackgroundColor(BuildContext context) {
    return Colors.white.withOpacity(0.2);
  }

  Color _getProgressColor(BuildContext context) {
    return Colors.white;
  }

  Color _getProgressBackgroundColor(BuildContext context) {
    return Colors.white.withOpacity(0.3);
  }

  IconData _getDefaultIcon() {
    switch (widget.toast.config.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
      case ToastType.custom:
        return Icons.message_rounded;
    }
  }

  int _getToastIndex() {
    final manager = ToastManager();
    return manager.getDisplayedToastIndex(widget.toast);
  }
}
