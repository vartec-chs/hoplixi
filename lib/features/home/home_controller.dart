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
  final int selectedBottomNavIndex;
  final List<HomeWidgetData> widgets;

  const HomeState({
    this.recentDatabase,
    this.isLoading = false,
    this.error,
    this.isAutoOpening = false,
    this.selectedBottomNavIndex = 0,
    this.widgets = const [],
  });

  /// Создание копии с измененными полями
  HomeState copyWith({
    DatabaseEntry? recentDatabase,
    bool? hasRecentDatabase,
    bool? isLoading,
    String? error,
    bool? clearError,
    bool? isAutoOpening,
    int? selectedBottomNavIndex,
    List<HomeWidgetData>? widgets,
  }) {
    return HomeState(
      recentDatabase: hasRecentDatabase == false
          ? null
          : (recentDatabase ?? this.recentDatabase),
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : (error ?? this.error),
      isAutoOpening: isAutoOpening ?? this.isAutoOpening,
      selectedBottomNavIndex:
          selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      widgets: widgets ?? this.widgets,
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
        other.isAutoOpening == isAutoOpening &&
        other.selectedBottomNavIndex == selectedBottomNavIndex &&
        other.widgets.length == widgets.length;
  }

  @override
  int get hashCode {
    return recentDatabase.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        isAutoOpening.hashCode ^
        selectedBottomNavIndex.hashCode ^
        widgets.length.hashCode;
  }
}

/// Данные для виджета на главном экране
class HomeWidgetData {
  final String id;
  final String title;
  final HomeWidgetType type;
  final Map<String, dynamic> data;
  final bool isVisible;
  final int order;

  const HomeWidgetData({
    required this.id,
    required this.title,
    required this.type,
    this.data = const {},
    this.isVisible = true,
    this.order = 0,
  });

  HomeWidgetData copyWith({
    String? id,
    String? title,
    HomeWidgetType? type,
    Map<String, dynamic>? data,
    bool? isVisible,
    int? order,
  }) {
    return HomeWidgetData(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      data: data ?? this.data,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }
}

/// Типы виджетов на главном экране
enum HomeWidgetType {
  recentDatabase,
  quickActions,
  statistics,
  shortcuts,
  notifications,
  customWidget,
}

/// Современный контроллер главного экрана с использованием Riverpod 3.0 Notifier API
class HomeController extends Notifier<HomeState> {
  HoplixiStoreManager get _storeManager =>
      ref.read(hoplixiStoreManagerProvider);

  @override
  HomeState build() {
    // Инициализация состояния с виджетами по умолчанию
    final initialWidgets = [
      const HomeWidgetData(
        id: 'recent_database',
        title: 'Недавние базы данных',
        type: HomeWidgetType.recentDatabase,
        order: 0,
      ),
      const HomeWidgetData(
        id: 'quick_actions',
        title: 'Быстрые действия',
        type: HomeWidgetType.quickActions,
        order: 1,
      ),
      const HomeWidgetData(
        id: 'statistics',
        title: 'Статистика',
        type: HomeWidgetType.statistics,
        order: 2,
        isVisible: false, // По умолчанию скрыт
      ),
    ];

    // Загружаем данные асинхронно
    _loadInitialData();

    return HomeState(widgets: initialWidgets);
  }

  // Геттеры для состояния
  DatabaseEntry? get recentDatabase => state.recentDatabase;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  bool get isAutoOpening => state.isAutoOpening;
  bool get hasRecentDatabase => state.hasRecentDatabase;
  bool get canAutoOpen => state.canAutoOpen;
  int get selectedBottomNavIndex => state.selectedBottomNavIndex;
  List<HomeWidgetData> get widgets =>
      state.widgets.where((w) => w.isVisible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// Проверяет возможность автоматического открытия с учетом настроек
  Future<bool> get canAutoOpenWithSettings async {
    if (!hasRecentDatabase) return false;
    final manager = AutoPreferencesManager.instance;
    final autoOpenLastStorage = manager.getValue<bool>(
      'auto_open_last_storage',
    );
    if (autoOpenLastStorage != true) return false;

    return state.recentDatabase?.saveMasterPassword == true &&
        state.recentDatabase?.masterPassword?.isNotEmpty == true;
  }

  /// Загружает информацию о недавно открытой базе данных
  Future<void> _loadInitialData() async {
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

  /// Устанавливает выбранный индекс нижней навигации
  void setBottomNavIndex(int index) {
    state = state.copyWith(selectedBottomNavIndex: index);
  }

  /// Добавляет новый виджет на главный экран
  void addWidget(HomeWidgetData widget) {
    final updatedWidgets = List<HomeWidgetData>.from(state.widgets);
    updatedWidgets.add(widget);
    state = state.copyWith(widgets: updatedWidgets);
  }

  /// Удаляет виджет с главного экрана
  void removeWidget(String widgetId) {
    final updatedWidgets = state.widgets
        .where((w) => w.id != widgetId)
        .toList();
    state = state.copyWith(widgets: updatedWidgets);
  }

  /// Переключает видимость виджета
  void toggleWidgetVisibility(String widgetId) {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == widgetId) {
        return w.copyWith(isVisible: !w.isVisible);
      }
      return w;
    }).toList();
    state = state.copyWith(widgets: updatedWidgets);
  }

  /// Обновляет порядок виджетов
  void reorderWidgets(List<HomeWidgetData> newOrder) {
    final updatedWidgets = newOrder.map((widget) {
      final index = newOrder.indexOf(widget);
      return widget.copyWith(order: index);
    }).toList();
    state = state.copyWith(widgets: updatedWidgets);
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
        saveMasterPassword: false,
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с введенным паролем',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

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
        saveMasterPassword: true,
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с сохранением пароля',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

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
        await _loadInitialData();
        return;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          logError(
            'Не удалось загрузить историю БД после $maxRetries попыток',
            error: e,
            tag: 'HomeController',
          );
          state = state.copyWith(hasRecentDatabase: false);
          return;
        }
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
// ПРОВАЙДЕРЫ RIVERPOD 3.0
// =============================================================================

/// Провайдер для HomeController с использованием Notifier API
final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
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
final canAutoOpenWithSettingsProvider = FutureProvider<bool>((ref) async {
  final homeController = ref.read(homeControllerProvider.notifier);
  return await homeController.canAutoOpenWithSettings;
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

/// Провайдер для выбранного индекса нижней навигации
final selectedBottomNavIndexProvider = Provider<int>((ref) {
  final homeState = ref.watch(homeControllerProvider);
  return homeState.selectedBottomNavIndex;
});

/// Провайдер для видимых виджетов главного экрана
final homeWidgetsProvider = Provider<List<HomeWidgetData>>((ref) {
  final homeController = ref.read(homeControllerProvider.notifier);
  return homeController.widgets;
});

/// Провайдер для конкретного типа виджета
final homeWidgetByTypeProvider =
    Provider.family<HomeWidgetData?, HomeWidgetType>((ref, type) {
      final widgets = ref.watch(homeWidgetsProvider);
      return widgets.cast<HomeWidgetData?>().firstWhere(
        (widget) => widget?.type == type,
        orElse: () => null,
      );
    });
