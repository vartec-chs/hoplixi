import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/global_key.dart';

/// Состояние навигации OAuth2
class OAuth2NavigationState {
  final String? savedPath;
  final bool isAuthInProgress;

  const OAuth2NavigationState({this.savedPath, this.isAuthInProgress = false});

  OAuth2NavigationState copyWith({String? savedPath, bool? isAuthInProgress}) {
    return OAuth2NavigationState(
      savedPath: savedPath ?? this.savedPath,
      isAuthInProgress: isAuthInProgress ?? this.isAuthInProgress,
    );
  }
}

/// Notifier для управления навигацией во время OAuth2 авторизации
class OAuth2NavigationNotifier
    extends AsyncNotifier<OAuth2NavigationState> {
  static const String _tag = 'OAuth2NavigationNotifier';

  @override
  Future<OAuth2NavigationState> build() async {
    logInfo('Инициализация OAuth2NavigationNotifier', tag: _tag);
    return const OAuth2NavigationState();
  }

  /// Сохраняет текущий путь перед началом авторизации
  Future<void> saveCurrentPath() async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        logError('Не удалось получить context для сохранения пути', tag: _tag);
        return;
      }

      final currentPath = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.fullPath;

      logInfo(
        'Сохранение пути перед авторизацией',
        tag: _tag,
        data: {'path': currentPath},
      );

      state = AsyncData(
        OAuth2NavigationState(savedPath: currentPath, isAuthInProgress: true),
      );
    } catch (e, stack) {
      logError(
        'Ошибка при сохранении пути',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      state = AsyncError(e, stack);
    }
  }

  /// Возвращает на сохранённый путь после успешной авторизации
  Future<void> restorePathOnSuccess() async {
    try {
      final currentState = state.value;
      if (currentState == null) {
        logWarning('Состояние не инициализировано', tag: _tag);
        return;
      }

      final savedPath = currentState.savedPath;

      logInfo(
        'Успешная авторизация, возврат на сохранённый путь',
        tag: _tag,
        data: {'savedPath': savedPath},
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          GoRouter.of(context).go(savedPath);
        }
      }

      // Сброс состояния
      state = const AsyncData(OAuth2NavigationState());
    } catch (e, stack) {
      logError(
        'Ошибка при восстановлении пути после успеха',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      state = AsyncError(e, stack);
    }
  }

  /// Возвращает на сохранённый путь после ошибки авторизации
  Future<void> restorePathOnError() async {
    try {
      final currentState = state.value;
      if (currentState == null) {
        logWarning('Состояние не инициализировано', tag: _tag);
        return;
      }

      final savedPath = currentState.savedPath;

      logInfo(
        'Ошибка авторизации, возврат на сохранённый путь',
        tag: _tag,
        data: {'savedPath': savedPath},
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          GoRouter.of(context).go(savedPath);
        }
      }

      // Сброс состояния
      state = const AsyncData(OAuth2NavigationState());
    } catch (e, stack) {
      logError(
        'Ошибка при восстановлении пути после ошибки',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      state = AsyncError(e, stack);
    }
  }

  /// Возвращает на сохранённый путь или дефолтный
  Future<void> restorePathOrDefault({String? defaultPath}) async {
    try {
      final currentState = state.value;
      if (currentState == null) {
        logWarning('Состояние не инициализировано', tag: _tag);
        return;
      }

      final savedPath = currentState.savedPath;
      final targetPath = savedPath ?? defaultPath ?? AppRoutes.dashboard;

      logInfo(
        'Возврат на путь',
        tag: _tag,
        data: {
          'savedPath': savedPath,
          'defaultPath': defaultPath,
          'targetPath': targetPath,
        },
      );

      final context = navigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).go(targetPath);
      }

      // Сброс состояния
      state = const AsyncData(OAuth2NavigationState());
    } catch (e, stack) {
      logError(
        'Ошибка при восстановлении пути',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      state = AsyncError(e, stack);
    }
  }

  /// Принудительный сброс состояния
  Future<void> reset() async {
    logInfo('Принудительный сброс состояния навигации', tag: _tag);
    state = const AsyncData(OAuth2NavigationState());
  }

  /// Проверка, идёт ли авторизация
  bool get isAuthInProgress => state.value?.isAuthInProgress ?? false;

  /// Получение сохранённого пути
  String? get savedPath => state.value?.savedPath;
}

/// Провайдер для управления навигацией OAuth2
final oauth2NavigationProvider =
    AsyncNotifierProvider<
      OAuth2NavigationNotifier,
      OAuth2NavigationState
    >(OAuth2NavigationNotifier.new);
