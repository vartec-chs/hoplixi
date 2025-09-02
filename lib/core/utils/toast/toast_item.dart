// Toast Position enum
import 'package:flutter/material.dart';
import 'dart:async';

enum ToastPosition {
  top,
  center,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

// Toast Type enum
enum ToastType { success, error, warning, info, custom }

// Toast Configuration
class ToastConfig {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final Widget? customWidget;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool showProgressBar;
  final bool dismissible;
  final bool pauseOnHover;
  final bool pauseOnFocus;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ToastConfig({
    required this.message,
    this.type = ToastType.info,
    this.position = ToastPosition.bottom,
    this.duration = const Duration(seconds: 3),
    this.customWidget,
    this.actions,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.showProgressBar = true,
    this.dismissible = true,
    this.pauseOnHover = true,
    this.pauseOnFocus = true,
    this.onTap,
    this.onDismiss,
  });
}

// Toast Item for queue management
class ToastItem {
  final String id;
  final ToastConfig config;
  final DateTime createdAt;
  OverlayEntry? overlayEntry;
  Timer? timer;
  AnimationController? animationController;
  AnimationController? progressController;
  bool isPaused = false;
  DateTime? pausedAt;
  Duration? remainingDuration;

  ToastItem({required this.id, required this.config, required this.createdAt}) {
    remainingDuration = config.duration;
  }

  void pauseTimer() {
    if (!isPaused && timer != null && timer!.isActive) {
      isPaused = true;
      pausedAt = DateTime.now();
      timer?.cancel();
      progressController?.stop();
    }
  }

  void resumeTimer(VoidCallback onTimeout) {
    if (isPaused && remainingDuration != null) {
      isPaused = false;
      if (pausedAt != null) {
        final elapsed = DateTime.now().difference(pausedAt!);
        remainingDuration = remainingDuration! - elapsed;
        if (remainingDuration!.isNegative) {
          remainingDuration = Duration.zero;
        }
      }

      if (remainingDuration! > Duration.zero) {
        timer = Timer(remainingDuration!, onTimeout);
        progressController?.forward();
      } else {
        onTimeout();
      }
      pausedAt = null;
    }
  }
}
