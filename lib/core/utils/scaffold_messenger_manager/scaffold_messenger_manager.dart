import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'models/snack_bar_data.dart';
import 'models/snack_bar_type.dart';
import 'models/snack_bar_animation_config.dart';
import 'models/banner_data.dart';
import 'queue/snack_bar_queue_manager.dart';
import 'builders/snack_bar_builder.dart';
import 'builders/banner_builder.dart';
import 'themes/default_snack_bar_theme_provider.dart';
import 'themes/default_banner_theme_provider.dart';

/// Синглтон менеджер для управления SnackBar и MaterialBanner
/// через глобальный ключ с поддержкой очереди и современного UI
class ScaffoldMessengerManager {
  static final ScaffoldMessengerManager _instance =
      ScaffoldMessengerManager._internal();
  static ScaffoldMessengerManager get instance => _instance;

  ScaffoldMessengerManager._internal();

  // Глобальный ключ для доступа к ScaffoldMessenger
  static final GlobalKey<ScaffoldMessengerState> _globalKey =
      GlobalKey<ScaffoldMessengerState>();
  // GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<ScaffoldMessengerState> get globalKey => _globalKey;

  // Зависимости (можно заменить для тестирования)
  SnackBarQueueManager _queueManager = DefaultSnackBarQueueManager();
  SnackBarBuilder _snackBarBuilder = ModernSnackBarBuilder(
    themeProvider: DefaultSnackBarThemeProvider(),
  );
  BannerBuilder _bannerBuilder = ModernBannerBuilder(
    themeProvider: DefaultBannerThemeProvider(),
  );

  bool _isProcessingQueue = false;
  SnackBarAnimationConfig _defaultAnimationConfig =
      const SnackBarAnimationConfig();

  static bool _isInitializedApp = false;

  static void initializeApp() {
    if (!_isInitializedApp) {
      _isInitializedApp = true;

      // Уведомляем менеджер очереди о том, что приложение инициализировано
      instance._queueManager.setInitialized(true);

      // Обрабатываем отложенные сообщения
      instance._processPendingMessages();
    }
  }

  /// Настройка зависимостей (для тестирования или кастомизации)
  void configure({
    SnackBarQueueManager? queueManager,
    SnackBarBuilder? snackBarBuilder,
    BannerBuilder? bannerBuilder,
    SnackBarAnimationConfig? defaultAnimationConfig,
  }) {
    if (queueManager != null) _queueManager = queueManager;
    if (snackBarBuilder != null) _snackBarBuilder = snackBarBuilder;
    if (bannerBuilder != null) _bannerBuilder = bannerBuilder;
    if (defaultAnimationConfig != null)
      _defaultAnimationConfig = defaultAnimationConfig;
  }

  /// Получение текущего контекста
  BuildContext? get _context {
    return _globalKey.currentContext;
  }

  /// Получение ScaffoldMessengerState
  ScaffoldMessengerState? get _scaffoldMessenger {
    return _globalKey.currentState;
  }

  // ==================== SNACKBAR METHODS ====================

  /// Показать SnackBar с автоматической обработкой очереди
  void showSnackBar(SnackBarData data) {
    _queueManager.enqueue(data);

    // Обрабатываем очередь только если приложение инициализировано
    if (_isInitializedApp) {
      // Если мы находимся в процессе build, отложим выполнение
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _processQueue();
        });
      } else {
        _processQueue();
      }
    }
    // Если приложение не инициализировано, сообщения останутся в pending очереди
    // и будут обработаны после вызова initializeApp()
  }

  /// Показать SnackBar с ошибкой
  void showError(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCopyButton = true,
    VoidCallback? onCopyPressed,
    SnackBarAnimationConfig? animationConfig,
    bool enableBlur = false,
    bool showProgressBar = true,
  }) {
    showSnackBar(
      SnackBarData(
        message: message,
        type: SnackBarType.error,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        showCopyButton: showCopyButton,
        onCopyPressed: onCopyPressed,
        animationConfig: animationConfig ?? _defaultAnimationConfig,
        enableBlur: enableBlur,
        showProgressBar: showProgressBar,
      ),
    );
  }

  /// Показать SnackBar с предупреждением
  void showWarning(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCopyButton = false,
    SnackBarAnimationConfig? animationConfig,
    bool enableBlur = false,
    bool showProgressBar = true,
  }) {
    showSnackBar(
      SnackBarData(
        message: message,
        type: SnackBarType.warning,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        showCopyButton: showCopyButton,
        animationConfig: animationConfig ?? _defaultAnimationConfig,
        enableBlur: enableBlur,
        showProgressBar: showProgressBar,
      ),
    );
  }

  /// Показать SnackBar с информацией
  void showInfo(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarAnimationConfig? animationConfig,
    bool enableBlur = false,
    bool showProgressBar = true,
  }) {
    showSnackBar(
      SnackBarData(
        message: message,
        type: SnackBarType.info,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        animationConfig: animationConfig ?? _defaultAnimationConfig,
        enableBlur: enableBlur,
        showProgressBar: showProgressBar,
      ),
    );
  }

  /// Показать SnackBar с успехом
  void showSuccess(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarAnimationConfig? animationConfig,
    bool enableBlur = false,
    bool showProgressBar = true,
  }) {
    showSnackBar(
      SnackBarData(
        message: message,
        type: SnackBarType.success,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        animationConfig: animationConfig ?? _defaultAnimationConfig,
        enableBlur: enableBlur,
        showProgressBar: showProgressBar,
      ),
    );
  }

  /// Обработка очереди SnackBar
  void _processQueue() {
    if (_isProcessingQueue ||
        _queueManager.isEmpty ||
        _scaffoldMessenger == null ||
        _context == null) {
      return;
    }

    // Если мы находимся в процессе build, отложим выполнение
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _processQueue();
      });
      return;
    }

    _isProcessingQueue = true;
    final data = _queueManager.dequeue();

    if (data != null) {
      final snackBar = _snackBarBuilder.build(_context!, data);

      _scaffoldMessenger!.showSnackBar(snackBar).closed.then((_) {
        _isProcessingQueue = false;
        // Обработать следующий элемент в очереди
        if (_queueManager.isNotEmpty) {
          _processQueue();
        }
      });
    } else {
      _isProcessingQueue = false;
    }
  }

  /// Обработка отложенных сообщений после инициализации приложения
  void _processPendingMessages() {
    if (_queueManager.isNotEmpty) {
      _processQueue();
    }
  }

  /// Скрыть текущий SnackBar
  void hideCurrentSnackBar() {
    _scaffoldMessenger?.hideCurrentSnackBar();
  }

  /// Удалить все SnackBar
  void removeCurrentSnackBar() {
    _scaffoldMessenger?.removeCurrentSnackBar();
  }

  /// Очистить очередь SnackBar
  void clearSnackBarQueue() {
    _queueManager.clear();
  }

  // ==================== BANNER METHODS ====================

  /// Показать MaterialBanner
  void showBanner(BannerData data) {
    if (_scaffoldMessenger == null || _context == null) return;

    // Если мы находимся в процессе build, отложим выполнение
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showBannerInternal(data);
      });
    } else {
      _showBannerInternal(data);
    }
  }

  /// Внутренний метод для показа Banner
  void _showBannerInternal(BannerData data) {
    if (_scaffoldMessenger == null || _context == null) return;

    final banner = _bannerBuilder.build(_context!, data);
    _scaffoldMessenger!.showMaterialBanner(banner);
  }

  /// Показать MaterialBanner с ошибкой
  void showErrorBanner(
    String message, {
    List<Widget>? actions,
    bool forceActionsBelow = false,
  }) {
    showBanner(
      BannerData(
        message: message,
        type: BannerType.error,
        actions: actions,
        forceActionsBelow: forceActionsBelow,
      ),
    );
  }

  /// Показать MaterialBanner с предупреждением
  void showWarningBanner(
    String message, {
    List<Widget>? actions,
    bool forceActionsBelow = false,
  }) {
    showBanner(
      BannerData(
        message: message,
        type: BannerType.warning,
        actions: actions,
        forceActionsBelow: forceActionsBelow,
      ),
    );
  }

  /// Показать MaterialBanner с информацией
  void showInfoBanner(
    String message, {
    List<Widget>? actions,
    bool forceActionsBelow = false,
  }) {
    showBanner(
      BannerData(
        message: message,
        type: BannerType.info,
        actions: actions,
        forceActionsBelow: forceActionsBelow,
      ),
    );
  }

  /// Показать MaterialBanner с успехом
  void showSuccessBanner(
    String message, {
    List<Widget>? actions,
    bool forceActionsBelow = false,
  }) {
    showBanner(
      BannerData(
        message: message,
        type: BannerType.success,
        actions: actions,
        forceActionsBelow: forceActionsBelow,
      ),
    );
  }

  /// Скрыть текущий MaterialBanner
  void hideCurrentBanner() {
    _scaffoldMessenger?.hideCurrentMaterialBanner();
  }

  /// Удалить текущий MaterialBanner
  void removeCurrentBanner() {
    _scaffoldMessenger?.removeCurrentMaterialBanner();
  }

  // ==================== UTILITY METHODS ====================

  /// Проверить наличие активного SnackBar
  bool get hasActiveSnackBar {
    return _scaffoldMessenger?.mounted == true;
  }

  /// Проверить наличие активного MaterialBanner
  bool get hasActiveBanner {
    return _scaffoldMessenger?.mounted == true;
  }

  /// Получить количество SnackBar в очереди
  int get queueLength => _queueManager.length;

  /// Проверить пустая ли очередь
  bool get isQueueEmpty => _queueManager.isEmpty;

  /// Проверить инициализировано ли приложение
  bool get isAppInitialized => _isInitializedApp;

  /// Получить количество отложенных сообщений (если очередь поддерживает эту функцию)
  int get pendingMessagesCount {
    if (_queueManager is DefaultSnackBarQueueManager) {
      return (_queueManager as DefaultSnackBarQueueManager).pendingLength;
    }
    return 0;
  }

  /// Проверить есть ли отложенные сообщения
  bool get hasPendingMessages {
    if (_queueManager is DefaultSnackBarQueueManager) {
      return (_queueManager as DefaultSnackBarQueueManager).hasPendingMessages;
    }
    return false;
  }

  /// Получить общее количество сообщений (в очереди + отложенные)
  int get totalMessagesCount {
    if (_queueManager is DefaultSnackBarQueueManager) {
      return (_queueManager as DefaultSnackBarQueueManager).totalLength;
    }
    return queueLength;
  }

  // ==================== ANIMATION CONFIGURATION ====================

  /// Настроить анимации для SnackBar
  void setDefaultAnimationConfig(SnackBarAnimationConfig config) {
    _defaultAnimationConfig = config;
  }

  /// Получить текущую конфигурацию анимаций
  SnackBarAnimationConfig get defaultAnimationConfig => _defaultAnimationConfig;

  /// Отключить все анимации
  void disableAnimations() {
    _defaultAnimationConfig = SnackBarAnimationConfig.disabled;
  }

  /// Включить анимации с настройками по умолчанию
  void enableAnimations() {
    _defaultAnimationConfig = const SnackBarAnimationConfig();
  }

  /// Установить быстрые анимации
  void setFastAnimations() {
    _defaultAnimationConfig = SnackBarAnimationConfig.fast;
  }

  /// Установить медленные анимации
  void setSlowAnimations() {
    _defaultAnimationConfig = SnackBarAnimationConfig.slow;
  }

  /// Установить анимации с bounce эффектом
  void setBounceAnimations() {
    _defaultAnimationConfig = SnackBarAnimationConfig.bouncy;
  }
}
