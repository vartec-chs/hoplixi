import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/auto_preferences/auto_preferences_manager.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/state.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Состояние главного экрана
class HomeState {
  final DatabaseEntry? recentDatabase;
  final bool isLoading;
  final String? error;
  final bool isAutoOpening;

  const HomeState({
    this.recentDatabase,
    this.isLoading = false,
    this.error,
    this.isAutoOpening = false,
  });

  /// Создание копии с измененными полями
  HomeState copyWith({
    DatabaseEntry? recentDatabase,
    bool? hasRecentDatabase,
    bool? isLoading,
    String? error,
    bool? clearError,
    bool? isAutoOpening,
  }) {
    return HomeState(
      recentDatabase: hasRecentDatabase == false
          ? null
          : (recentDatabase ?? this.recentDatabase),
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : (error ?? this.error),
      isAutoOpening: isAutoOpening ?? this.isAutoOpening,
    );
  }

  // Computed properties
  bool get hasRecentDatabase => recentDatabase != null;

  bool get canAutoOpen =>
      recentDatabase?.saveMasterPassword == true &&
      recentDatabase?.masterPassword?.isNotEmpty == true;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeState &&
        other.recentDatabase == recentDatabase &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isAutoOpening == isAutoOpening;
  }

  @override
  int get hashCode {
    return recentDatabase.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        isAutoOpening.hashCode;
  }
}

/// StateNotifier для управления состоянием главного экрана
class HomeController extends StateNotifier<HomeState> {
  final HoplixiStoreManager _storeManager;

  HomeController(this._storeManager) : super(const HomeState());

  // Геттеры для состояния
  DatabaseEntry? get recentDatabase => state.recentDatabase;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  bool get isAutoOpening => state.isAutoOpening;
  bool get hasRecentDatabase => state.hasRecentDatabase;
  bool get canAutoOpen => state.canAutoOpen;

  /// Инициализация контроллера
  Future<void> initialize() async {
    await _loadRecentDatabase();
  }

  Future<bool> get canAutoOpenAsync async {
    if (!hasRecentDatabase) return false;
    final manager = AutoPreferencesManager.instance;
    final autoOpenLastStorage = manager.getValue<bool>(
      'auto_open_last_storage',
    );
    if (autoOpenLastStorage != true) {
      return false;
    }
    return state.recentDatabase?.saveMasterPassword == true &&
        state.recentDatabase?.masterPassword?.isNotEmpty == true;
  }

  /// Загружает информацию о недавно открытой базе данных
  Future<void> _loadRecentDatabase() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      logDebug('Загрузка недавней базы данных', tag: 'HomeController');

      // Получаем самую недавно открытую базу данных из истории
      final history = await _storeManager.getDatabaseHistory();

      if (history.isNotEmpty) {
        final recentDatabase = history.first;
        state = state.copyWith(
          recentDatabase: recentDatabase,
          isLoading: false,
        );

        logDebug(
          'Найдена недавняя БД: ${recentDatabase.name}',
          tag: 'HomeController',
          data: {
            'path': recentDatabase.path,
            'hasSavedPassword': recentDatabase.saveMasterPassword,
          },
        );
      } else {
        state = state.copyWith(hasRecentDatabase: false, isLoading: false);
        logDebug('Недавние базы данных не найдены', tag: 'HomeController');
      }
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки недавней базы данных: ${e.toString()}',
      );

      logError(
        'Ошибка загрузки недавней базы данных',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
      );
    }
  }

  /// Автоматическое открытие базы данных (если пароль сохранен)
  Future<DatabaseState?> autoOpenRecentDatabase() async {
    if (!canAutoOpen) {
      logWarning(
        'Автоматическое открытие недоступно',
        tag: 'HomeController',
        data: {
          'hasRecentDb': hasRecentDatabase,
          'hasSavedPassword': state.recentDatabase?.saveMasterPassword ?? false,
        },
      );
      return null;
    }

    try {
      state = state.copyWith(isAutoOpening: true, clearError: true);

      logInfo(
        'Автоматическое открытие БД: ${state.recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': state.recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: state.recentDatabase!.path,
        masterPassword: state.recentDatabase!.masterPassword!,
        saveMasterPassword: true,
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД автоматически открыта успешно',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка автоматического открытия: ${e.toString()}';
      state = state.copyWith(isAutoOpening: false, error: errorMessage);

      logError(
        'Ошибка автоматического открытия БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': state.recentDatabase?.path},
      );

      return null;
    } finally {
      state = state.copyWith(isAutoOpening: false);
    }
  }

  /// Открытие базы данных с введенным паролем
  Future<DatabaseState?> openRecentDatabaseWithPassword(String password) async {
    if (!hasRecentDatabase) {
      state = state.copyWith(error: 'Недавняя база данных не найдена');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      logInfo(
        'Открытие БД с паролем: ${state.recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': state.recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: state.recentDatabase!.path,
        masterPassword: password,
        saveMasterPassword: false, // Не сохраняем пароль по умолчанию
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с введенным паролем',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка открытия: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: errorMessage);

      logError(
        'Ошибка открытия БД с паролем',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': state.recentDatabase?.path},
      );

      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Открытие базы данных с сохранением пароля
  Future<DatabaseState?> openRecentDatabaseWithPasswordAndSave(
    String password,
  ) async {
    if (!hasRecentDatabase) {
      state = state.copyWith(error: 'Недавняя база данных не найдена');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      logInfo(
        'Открытие БД с сохранением пароля: ${state.recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': state.recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: state.recentDatabase!.path,
        masterPassword: password,
        saveMasterPassword: true, // Сохраняем пароль
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с сохранением пароля',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка открытия: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: errorMessage);

      logError(
        'Ошибка открытия БД с сохранением пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': state.recentDatabase?.path},
      );

      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Удаляет недавнюю базу данных из истории
  Future<void> removeRecentDatabase() async {
    if (!hasRecentDatabase) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _storeManager.removeDatabaseHistoryEntry(
        state.recentDatabase!.path,
      );

      logInfo(
        'БД удалена из истории: ${state.recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': state.recentDatabase!.path},
      );

      // Перезагружаем список
      await _safeReloadHistory();
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка удаления из истории: ${e.toString()}',
      );

      logError(
        'Ошибка удаления БД из истории',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Получает статистику истории
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      return await _storeManager.getDatabaseHistoryStats();
    } catch (e) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        tag: 'HomeController',
      );
      return {
        'totalEntries': 0,
        'entriesWithSavedPasswords': 0,
        'oldestEntry': null,
        'newestEntry': null,
      };
    }
  }

  /// Безопасная перезагрузка истории БД с повторными попытками
  Future<void> _safeReloadHistory({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _loadRecentDatabase();
        return; // Успешно загружено
      } catch (e) {
        if (attempt == maxRetries - 1) {
          // Последняя попытка не удалась
          logError(
            'Не удалось загрузить историю БД после $maxRetries попыток',
            error: e,
            tag: 'HomeController',
          );
          state = state.copyWith(hasRecentDatabase: false);
          return;
        }

        // Ждем перед следующей попыткой
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Установка ошибки
  void setError(String error) {
    state = state.copyWith(error: error);
  }
}

// =============================================================================
// ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для HomeController
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    final storeManager = ref.read(hoplixiStoreManagerProvider);

    return HomeController(storeManager);
  },
);

/// Провайдер для недавней базы данных
final recentDatabaseProvider = Provider<DatabaseEntry?>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.recentDatabase;
});

/// Провайдер для проверки наличия недавней базы данных
final hasRecentDatabaseProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.hasRecentDatabase;
});

/// Провайдер для проверки возможности автоматического открытия
final canAutoOpenProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.canAutoOpen;
});

/// Асинхронный провайдер для проверки возможности автоматического открытия с настройками
final canAutoOpenAsyncProvider = FutureProvider<bool>((ref) async {
  final homeController = ref.read(homeControllerProvider.notifier);
  return await homeController.canAutoOpenAsync;
});

/// Провайдер для статистики истории
final historyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final homeController = ref.read(homeControllerProvider.notifier);
  return await homeController.getHistoryStats();
});

/// Провайдер для состояния загрузки главного экрана
final homeLoadingProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.isLoading;
});

/// Провайдер для ошибки главного экрана
final homeErrorProvider = Provider<String?>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.error;
});

/// Провайдер для состояния автоматического открытия
final homeAutoOpeningProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.isAutoOpening;
});
