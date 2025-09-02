import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme_old/theme_provider.dart';
import 'package:hoplixi/core/utils/toast/ui.dart';
import 'package:hoplixi/global.dart';

import 'toast_item.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class ToastManager {
  static final ToastManager _instance = ToastManager._internal();
  factory ToastManager() => _instance;
  ToastManager._internal();

  final List<ToastItem> _toastQueue = [];
  final List<ToastItem> _displayedToasts = [];
  final int _maxDisplayedToasts = 3;
  bool _isInitialized = false;

  // Queue for toasts shown before initialization
  final List<ToastConfig> _preInitQueue = [];

  // Initialize after MaterialApp is ready
  void initialize() {
    if (_isInitialized) return;

    // Use a more robust approach to ensure overlay is available
    Future.delayed(Duration.zero, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double check that context and overlay are available
        final context = navigatorKey.currentContext;
        if (context != null && navigatorKey.currentState?.overlay != null) {
          _isInitialized = true;

          // Process pre-init queue
          for (final config in _preInitQueue) {
            _showToastInternal(config);
          }
          _preInitQueue.clear();

          _processQueue();
        } else {
          // Retry initialization after a delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _isInitialized = false;
            initialize();
          });
        }
      });
    });
  }

  // Internal method to show toast without checking initialization
  String _showToastInternal(ToastConfig config) {
    final id = _generateId();
    final toastItem = ToastItem(
      id: id,
      config: config,
      createdAt: DateTime.now(),
    );

    _toastQueue.add(toastItem);
    if (_isInitialized) {
      _processQueue();
    }

    return id;
  }

  // Show toast
  String show(ToastConfig config) {
    // If not initialized yet, add to pre-init queue
    if (!_isInitialized) {
      _preInitQueue.add(config);
      return 'pre_init_${_preInitQueue.length}';
    }

    return _showToastInternal(config);
  }

  // Dismiss specific toast
  void dismiss(String id) {
    final toast = _findToast(id);
    if (toast != null) {
      _removeToast(toast);
    }
  }

  // Dismiss all toasts
  void dismissAll() {
    final toastsToRemove = List<ToastItem>.from(_displayedToasts);
    for (final toast in toastsToRemove) {
      _removeToast(toast);
    }
    _toastQueue.clear();
    _preInitQueue.clear();
  }

  // Process queue
  void _processQueue() {
    if (!_isInitialized) return;

    while (_displayedToasts.length < _maxDisplayedToasts &&
        _toastQueue.isNotEmpty) {
      final toast = _toastQueue.removeAt(0);
      _showToast(toast);
    }
  }

  // Show individual toast
  void _showToast(ToastItem toast) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // If context is not available, add back to queue and retry
      _toastQueue.insert(0, toast);
      _displayedToasts.remove(toast);
      Future.delayed(const Duration(milliseconds: 100), () {
        _processQueue();
      });
      return;
    }

    final overlay = navigatorKey.currentState?.overlay;
    logDebug('Showing toast: ${overlay.toString()}');
    if (overlay == null) {
      // If overlay is not available, add back to queue and retry
      _toastQueue.insert(0, toast);
      _displayedToasts.remove(toast);
      Future.delayed(const Duration(milliseconds: 100), () {
        _processQueue();
      });
      return;
    }

    // Create animation controllers
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: overlay,
    );

    final progressController = AnimationController(
      duration: toast.config.duration,
      vsync: overlay,
    );

    toast.animationController = animationController;
    toast.progressController = progressController;

    // Create overlay entry
    toast.overlayEntry = OverlayEntry(
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Listen to theme changes to rebuild toast
          ref.watch(themeProvider);

          return ToastWidget(
            toast: toast,
            onDismiss: () => _removeToast(toast),
            onPause: () => toast.pauseTimer(),
            onResume: () => toast.resumeTimer(() => _removeToast(toast)),
          );
        },
      ),
    );

    // Add to displayed list and overlay
    _displayedToasts.add(toast);
    overlay.insert(toast.overlayEntry!);

    // Start animations
    animationController.forward();
    if (toast.config.showProgressBar) {
      progressController.forward();
    }

    // Set up auto-dismiss timer
    toast.timer = Timer(toast.config.duration, () {
      _removeToast(toast);
    });
  }

  // Remove toast
  void _removeToast(ToastItem toast) {
    if (!_displayedToasts.contains(toast)) return;

    // Cancel timer
    toast.timer?.cancel();

    // Animate out
    toast.animationController?.reverse().then((_) {
      // Remove from overlay and lists
      toast.overlayEntry?.remove();
      _displayedToasts.remove(toast);
      _toastQueue.remove(toast);

      // Dispose controllers
      toast.animationController?.dispose();
      toast.progressController?.dispose();

      // Call onDismiss callback
      toast.config.onDismiss?.call();

      // Process next in queue
      _processQueue();
    });
  }

  // Find toast by id
  ToastItem? _findToast(String id) {
    for (final toast in _displayedToasts) {
      if (toast.id == id) return toast;
    }
    for (final toast in _toastQueue) {
      if (toast.id == id) return toast;
    }
    return null;
  }

  // Get toast index for positioning
  int getDisplayedToastIndex(ToastItem toast) {
    return _displayedToasts.indexOf(toast);
  }

  // Generate unique id
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }
}
