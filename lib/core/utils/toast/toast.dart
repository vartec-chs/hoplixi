// Convenience methods with modern defaults
import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/toast/toast_item.dart';
import 'package:hoplixi/core/utils/toast/toast_manager.dart';

class Toast {
  static String success(
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    List<Widget>? actions,
    bool pauseOnHover = true,
  }) {
    return ToastManager().show(
      ToastConfig(
        message: message,
        type: ToastType.success,
        position: position,
        duration: duration,
        actions: actions,
        pauseOnHover: pauseOnHover,
      ),
    );
  }

  static String error(
    String message, {
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 4),
    List<Widget>? actions,
    bool pauseOnHover = true,
  }) {
    return ToastManager().show(
      ToastConfig(
        message: message,
        type: ToastType.error,
        position: position,
        duration: duration,
        actions: actions,
        pauseOnHover: pauseOnHover,
      ),
    );
  }

  static String warning(
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    List<Widget>? actions,
    bool pauseOnHover = true,
  }) {
    return ToastManager().show(
      ToastConfig(
        message: message,
        type: ToastType.warning,
        position: position,
        duration: duration,
        actions: actions,
        pauseOnHover: pauseOnHover,
      ),
    );
  }

  static String info(
    String message, {
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    List<Widget>? actions,
    bool pauseOnHover = true,
  }) {
    return ToastManager().show(
      ToastConfig(
        message: message,
        type: ToastType.info,
        position: position,
        duration: duration,
        actions: actions,
        pauseOnHover: pauseOnHover,
      ),
    );
  }

  static String custom({
    required String message,
    Widget? customWidget,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    List<Widget>? actions,
    bool showProgressBar = true,
    bool dismissible = true,
    bool pauseOnHover = true,
    bool pauseOnFocus = true,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return ToastManager().show(
      ToastConfig(
        message: message,
        type: ToastType.custom,
        customWidget: customWidget,
        position: position,
        duration: duration,
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon,
        actions: actions,
        showProgressBar: showProgressBar,
        dismissible: dismissible,
        pauseOnHover: pauseOnHover,
        pauseOnFocus: pauseOnFocus,
        onTap: onTap,
        onDismiss: onDismiss,
      ),
    );
  }

  static void dismiss(String id) {
    ToastManager().dismiss(id);
  }

  static void dismissAll() {
    ToastManager().dismissAll();
  }
}
