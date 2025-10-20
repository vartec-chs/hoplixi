import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/app_close_provider.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';

/// Провайдер для управления жизненным циклом приложения
final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleStateData>(
      AppLifecycleNotifier.new,
    );

// time
final appInactivityTimeoutProvider = Provider<int>((ref) {
  final state = ref.watch(appLifecycleProvider);
  return state.remainingTime;
});

/// Состояние жизненного цикла приложения (переименовываем чтобы не конфликтовать с Flutter AppLifecycleState)
class AppLifecycleStateData {
  const AppLifecycleStateData({
    this.isActive = true,
    this.timerActive = false,
    this.remainingTime = 0,
    this.dataCleared = false,
    this.databaseLocked = false,
  });

  final bool isActive;
  final bool timerActive;
  final int remainingTime; // в секундах
  final bool
  dataCleared; // флаг того, что данные были очищены (полное закрытие)
  final bool
  databaseLocked; // флаг того, что БД заблокирована (но не закрыта полностью)

  AppLifecycleStateData copyWith({
    bool? isActive,
    bool? timerActive,
    int? remainingTime,
    bool? dataCleared,
    bool? databaseLocked,
  }) {
    return AppLifecycleStateData(
      isActive: isActive ?? this.isActive,
      timerActive: timerActive ?? this.timerActive,
      remainingTime: remainingTime ?? this.remainingTime,
      dataCleared: dataCleared ?? this.dataCleared,
      databaseLocked: databaseLocked ?? this.databaseLocked,
    );
  }
}

/// Нотификатор для управления жизненным циклом приложения
class AppLifecycleNotifier extends Notifier<AppLifecycleStateData> {
  Timer? _inactivityTimer;
  Timer? _countdownTimer;

  static const int _inactivityTimeoutSeconds = 5; // 2 минуты

  @override
  AppLifecycleStateData build() {
    // Автоматическая очистка ресурсов при уничтожении провайдера
    ref.onDispose(() {
      logInfo(
        'Автоматическая очистка ресурсов AppLifecycleNotifier',
        tag: 'AppLifecycleNotifier',
      );
      _stopInactivityTimer();
    });

    return const AppLifecycleStateData();
  }

  Future<void> onDetach() async {
    await _onDetached();
  }

  Future<void> onHide() async {
    await _onHidden();
  }

  Future<void> onInactive() async {
    await _onInactive();
  }

  Future<void> onPause() async {
    await _onPaused();
  }

  Future<void> onRestart() async {
    await _onRestarted();
  }

  Future<void> onResume() async {
    await _onResumed();
  }

  Future<void> onShow() async {
    await _onShown();
  }

  Future<AppExitResponse> onExitRequested() async {
    logInfo('Запрос на выход из приложения', tag: 'AppLifecycleNotifier');
    final result = await ref.read(appCloseProvider.notifier).handleAppClose();
    return result ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  /// Приложение стало активным
  Future<void> _onResumed() async {
    logInfo('Приложение возобновлено', tag: 'AppLifecycleNotifier');
    _stopInactivityTimer();
    state = state.copyWith(isActive: true);
  }

  /// Приложение показано
  Future<void> _onShown() async {
    logInfo('Приложение показано', tag: 'AppLifecycleNotifier');
    _stopInactivityTimer();
    state = state.copyWith(isActive: true);
  }

  /// Приложение перезапущено
  Future<void> _onRestarted() async {
    logInfo('Приложение перезапущено', tag: 'AppLifecycleNotifier');
    _stopInactivityTimer();
    state = state.copyWith(isActive: true);
  }

  /// Приложение приостановлено
  Future<void> _onPaused() async {
    logInfo('Приложение приостановлено', tag: 'AppLifecycleNotifier');
    final context = navigatorKey.currentContext;
    if (context != null &&
        GoRouter.of(context).state.path!.contains('dashboard')) {
      _startInactivityTimer();
    }
    state = state.copyWith(isActive: false);
  }

  /// Приложение неактивно
  Future<void> _onInactive() async {
    logInfo('Приложение неактивно', tag: 'AppLifecycleNotifier');
    final context = navigatorKey.currentContext;

    if (context != null &&
        GoRouter.of(context).state.path!.contains('dashboard')) {
      logInfo(
        'App is inactive and in protected route, starting inactivity timer',
        tag: 'AppLifecycleNotifier',
      );
      _startInactivityTimer();
    }
    state = state.copyWith(isActive: false);
  }

  /// Приложение скрыто
  Future<void> _onHidden() async {
    logInfo('Приложение скрыто', tag: 'AppLifecycleNotifier');
    final context = navigatorKey.currentContext;
    if (context != null &&
        GoRouter.of(context).state.path!.contains('dashboard')) {
      _startInactivityTimer();
    }
    state = state.copyWith(isActive: false);
  }

  /// Приложение отсоединено
  Future<void> _onDetached() async {
    logInfo('Приложение отсоединено', tag: 'AppLifecycleNotifier');
    _stopInactivityTimer();
    state = state.copyWith(
      isActive: false,
      timerActive: false,
      remainingTime: 0,
      dataCleared: true, // Устанавливаем флаг очистки данных
    );
  }

  /// Запускает таймер неактивности на 1 минуту
  void _startInactivityTimer() {
    _stopInactivityTimer(); // Останавливаем предыдущий таймер, если он был

    // final currentPath = ref.read(goRouterPathProvider);
    logInfo(
      'Запуск таймера неактивности на $_inactivityTimeoutSeconds секунд',
      tag: 'AppLifecycleNotifier',
      // data: {'currentPath': currentPath},
    );

    // Обновляем состояние - таймер активен
    state = state.copyWith(
      timerActive: true,
      remainingTime: _inactivityTimeoutSeconds,
    );

    // Таймер обратного отсчета (обновляется каждую секунду)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemainingTime = state.remainingTime - 1;

      if (newRemainingTime <= 0) {
        timer.cancel();
        state = state.copyWith(timerActive: false, remainingTime: 0);
      } else {
        state = state.copyWith(remainingTime: newRemainingTime);
      }
    });

    // Основной таймер для блокировки базы данных
    _inactivityTimer = Timer(Duration(seconds: _inactivityTimeoutSeconds), () {
      logInfo(
        'Таймер неактивности истек, блокируем базу данных',
        tag: 'AppLifecycleNotifier',
      );
      _lockDatabase();
    });
  }

  /// Останавливает таймер неактивности
  void _stopInactivityTimer() {
    if (_inactivityTimer?.isActive == true) {
      logInfo('Остановка таймера неактивности', tag: 'AppLifecycleNotifier');
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
    }

    if (_countdownTimer?.isActive == true) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }

    // Обновляем состояние - таймер неактивен
    state = state.copyWith(
      timerActive: false,
      remainingTime: 0,
      dataCleared: false,
      isActive: true,
    );
  }

  /// Принудительно запускает таймер (для тестирования)
  void startTimer() {
    logInfo('Принудительный запуск таймера', tag: 'AppLifecycleNotifier');
    _startInactivityTimer();
  }

  /// Принудительно останавливает таймер
  void stopTimer() {
    logInfo('Принудительная остановка таймера', tag: 'AppLifecycleNotifier');
    _stopInactivityTimer();
  }

  /// Блокирует базу данных вместо полного закрытия
  Future<void> _lockDatabase() async {
    try {
      logInfo('Начинаем блокировку базы данных', tag: 'AppLifecycleNotifier');

      // Останавливаем таймер
      _stopInactivityTimer();

      try {
        await ref.read(clearAllProvider.notifier).clearAll();
        // Блокируем базу данных (сохраняем path и name, закрываем соединение)
        await ref.read(hoplixiStoreProvider.notifier).lockDatabase();

        // Обновляем состояние - помечаем что БД заблокирована (НЕ используем dataCleared)
        state = state.copyWith(
          databaseLocked: true,
          timerActive: false,
          dataCleared: false,
        );

        logInfo(
          'База данных успешно заблокирована',
          tag: 'AppLifecycleNotifier',
        );
      } catch (e) {
        logError(
          'Ошибка при блокировке базы данных',
          error: e,
          tag: 'AppLifecycleNotifier',
        );
      }
    } catch (e, s) {
      logError(
        'Критическая ошибка в _lockDatabase',
        error: e,
        stackTrace: s,
        tag: 'AppLifecycleNotifier',
      );
    }
  }

  /// Очищает все данные приложения
  Future<void> _clearAllData() async {
    try {
      logInfo('Начинаем очистку всех данных', tag: 'AppLifecycleNotifier');

      // Останавливаем таймер
      _stopInactivityTimer();

      try {
        // final dbState = ref.read(hoplixiStoreProvider);

        // Очищаем провайдеры
        await ref.read(clearAllProvider.notifier).clearAll();

        // Закрываем базу данных
        await ref.read(hoplixiStoreProvider.notifier).closeDatabase();

        // Обновляем состояние - помечаем что данные очищены
        state = state.copyWith(
          isActive: false,
          timerActive: false,
          remainingTime: 0,
          dataCleared: true, // Устанавливаем флаг очистки данных
        );
      } catch (e, st) {
        logError(
          'Ошибка при обращении к провайдерам во время очистки',
          error: e,
          stackTrace: st,
          tag: 'AppLifecycleNotifier',
        );
        // Все равно устанавливаем флаг очистки данных
        state = state.copyWith(
          isActive: false,
          timerActive: false,
          remainingTime: 0,
          dataCleared: true,
        );
      }
    } catch (e, st) {
      logError(
        'Ошибка при очистке данных',
        error: e,
        stackTrace: st,
        tag: 'AppLifecycleNotifier',
      );
    }
  }

  // Принудительная очистка данных (для внешнего вызова)
  Future<void> clearAll() async {
    logInfo('Принудительная очистка всех данных', tag: 'AppLifecycleNotifier');
    await _clearAllData();
  }

  /// Сбрасывает флаг очистки данных (вызывается после перенаправления)
  void resetDataClearedFlag() {
    logInfo('Сброс флага очистки данных', tag: 'AppLifecycleNotifier');
    state = state.copyWith(dataCleared: false);
  }

  /// Сбрасывает флаг блокировки БД (вызывается после разблокировки)
  void resetDatabaseLockedFlag() {
    logInfo('Сброс флага блокировки БД', tag: 'AppLifecycleNotifier');
    state = state.copyWith(databaseLocked: false);
  }

  /// Освобождение ресурсов при уничтожении провайдера
  void cleanup() {
    logInfo(
      'Освобождение ресурсов AppLifecycleNotifier',
      tag: 'AppLifecycleNotifier',
    );
    _stopInactivityTimer();
  }
}

/// Провайдер для получения оставшегося времени в удобочитаемом формате
final remainingTimeFormattedProvider = Provider<String>((ref) {
  final lifecycleState = ref.watch(appLifecycleProvider);

  if (!lifecycleState.timerActive) {
    return '';
  }

  final remainingSeconds = lifecycleState.remainingTime;
  final minutes = remainingSeconds ~/ 60;
  final seconds = remainingSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});

/// Провайдер для проверки активности таймера
final isTimerActiveProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider.select((state) => state.timerActive));
});

/// Провайдер для проверки активности приложения
final isAppActiveProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider.select((state) => state.isActive));
});

/// Провайдер для отслеживания состояния очистки данных (для router'а)
final dataClearedProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider.select((state) => state.dataCleared));
});

/// Провайдер для отслеживания блокировки БД (для router'а)
final databaseLockedProvider = Provider<bool>((ref) {
  return ref.watch(
    appLifecycleProvider.select((state) => state.databaseLocked),
  );
});

/// Провайдер для проверки нахождения в защищённом маршруте
// final isInProtectedRouteTimerProvider = Provider<bool>((ref) {
//   final isInProtectedRoute = ref.watch(isInProtectedRouteProvider);
//   final isTimerActive = ref.watch(isTimerActiveProvider);
//   return isInProtectedRoute && isTimerActive;
// });
