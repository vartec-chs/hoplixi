import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

/// Состояние главного экрана (только UI состояние)
class HomeState {
  final DatabaseEntry? recentDatabase;
  final bool isLoading;
  final String? error;

  const HomeState({this.recentDatabase, this.isLoading = false, this.error});

  HomeState copyWith({
    DatabaseEntry? recentDatabase,
    bool? hasRecentDatabase,
    bool? isLoading,
    String? error,
    bool? clearError,
  }) {
    return HomeState(
      recentDatabase: hasRecentDatabase == false
          ? null
          : (recentDatabase ?? this.recentDatabase),
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : (error ?? this.error),
    );
  }
}

/// Данные для виджета на главном экране
class HomeWidgetData {
  final String id;
  final String title;
  final HomeWidgetType type;
  final bool isVisible;

  const HomeWidgetData({
    required this.id,
    required this.title,
    required this.type,
    this.isVisible = true,
  });
}

/// Типы виджетов на главном экране
enum HomeWidgetType { recentDatabase }

/// Упрощенный контроллер главного экрана - только управление UI
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(() => _loadRecentDatabase());
    return const HomeState();
  }

  Future<void> _loadRecentDatabase() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      logDebug('Загрузка недавней базы данных', tag: 'HomeController');

      final storeManager = await ref.read(hoplixiStoreManagerProvider.future);
      final history = await storeManager.getDatabaseHistory();

      if (history.isNotEmpty) {
        final recentDatabase = history.first;
        state = state.copyWith(
          recentDatabase: recentDatabase,
          isLoading: false,
        );
        logDebug(
          'Недавняя БД загружена: ${recentDatabase.name}',
          tag: 'HomeController',
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

  Future<void> removeRecentDatabase() async {
    if (state.recentDatabase == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final storeManager = await ref.read(hoplixiStoreManagerProvider.future);
      await storeManager.removeDatabaseHistoryEntry(state.recentDatabase!.path);
      logInfo(
        'Недавняя БД удалена из истории: ${state.recentDatabase!.name}',
        tag: 'HomeController',
      );
      await _loadRecentDatabase();
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка удаления из истории: ${e.toString()}',
      );
      logError(
        'Ошибка удаления из истории',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> reloadHistory() async {
    await _loadRecentDatabase();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

final recentDatabaseProvider = Provider<DatabaseEntry?>((ref) {
  return ref.watch(
    homeControllerProvider.select((state) => state.recentDatabase),
  );
});

final homeWidgetsProvider = Provider<List<HomeWidgetData>>((ref) {
  final hasRecent = ref.watch(recentDatabaseProvider) != null;

  return [
    if (hasRecent)
      const HomeWidgetData(
        id: 'recent_database',
        title: 'Недавние базы данных',
        type: HomeWidgetType.recentDatabase,
      ),
  ];
});
