import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/global.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  static const toastificationStyle = ToastificationStyle.fillColored;

  static void success({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext!;
    final theme = Theme.of(contextToUse);

    // final textColor = theme.colorScheme.brightness == Brightness.dark
    //     ? Colors.black
    //     : Colors.black;

    final primaryColor = Colors.green.shade500;

    toastification.show(
      context: contextToUse,
      type: ToastificationType.success,
      style: toastificationStyle,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
      title: Text(title),
      description: description != null ? Text(description) : null,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.check),
      showIcon: true,
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1),
      // applyBlurEffect: true,
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      callbacks: callbacks ?? const ToastificationCallbacks(),
    );
  }

  static void error({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext!;
    final theme = Theme.of(contextToUse);

    final primaryColor = Colors.red.shade500;

    toastification.show(
      context: contextToUse,
      type: ToastificationType.error,
      style: toastificationStyle,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
      title: Text("$title"),
      description: description != null
          ? Text('(Нажмите для копирования) $description')
          : null,

      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.error),
      showIcon: true,
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,

      callbacks:
          callbacks ??
          ToastificationCallbacks(
            onTap: (value) =>
                Clipboard.setData(ClipboardData(text: description ?? '')).then(
                  (value) {
                    // ScaffoldMessenger.of(contextToUse).showSnackBar(
                    //   SnackBar(
                    //     content: Text('Ошибка скопирована в буфер обмена'),
                    //   ),
                    // );
                    ToastHelper.info(
                      context: contextToUse,
                      title: 'Скопировано',
                      description: 'Ошибка скопирована в буфер обмена',
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  },
                  onError: (error) {
                    // ScaffoldMessenger.of(contextToUse).showSnackBar(
                    //   SnackBar(content: Text('Ошибка копирования: $error')),
                    // );
                    ToastHelper.error(
                      context: contextToUse,
                      title: 'Ошибка',
                      description: 'Ошибка копирования: $error',
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  },
                ),
          ),
    );
  }

  static void warning({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext!;
    final theme = Theme.of(contextToUse);

    final primaryColor = Colors.orange.shade500;

    toastification.show(
      context: contextToUse,
      type: ToastificationType.warning,
      style: toastificationStyle,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
      title: Text(title),
      description: description != null ? Text(description) : null,

      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.warning),
      showIcon: true,
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      callbacks: callbacks ?? const ToastificationCallbacks(),
    );
  }

  static void info({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext!;
    final theme = Theme.of(contextToUse);

    final primaryColor = Colors.blue.shade500;

    toastification.show(
      context: contextToUse,
      type: ToastificationType.info,
      style: toastificationStyle,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
      title: Text(title),
      description: description != null ? Text(description) : null,

      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.info),
      showIcon: true,
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      callbacks: callbacks ?? const ToastificationCallbacks(),
    );
  }

  static void custom({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationType? type,
    ToastificationStyle? style,
    Icon? icon,
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    Alignment? alignment,
    bool? showIcon,
    bool? showProgressBar,
    ToastificationCallbacks? callbacks,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext!;
    final theme = Theme.of(contextToUse);

    toastification.show(
      context: contextToUse,
      type: type ?? ToastificationType.info,
      style: style ?? toastificationStyle,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
      title: Text(title),
      description: description != null ? Text(description) : null,
      alignment: alignment,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: icon ?? const Icon(Icons.notifications),
      showIcon: showIcon ?? true,
      primaryColor: primaryColor ?? theme.colorScheme.primary,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: showProgressBar ?? true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      callbacks: callbacks ?? const ToastificationCallbacks(),
    );
  }
}
