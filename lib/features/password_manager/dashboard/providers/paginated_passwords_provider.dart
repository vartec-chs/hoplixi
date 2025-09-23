import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'password_filter_provider.dart';
import 'filter_tabs_provider.dart';
import 'data_refresh_trigger_provider.dart';
import '../models/filter_tab.dart';

/// Размер страницы для пагинации
const int kPasswordsPageSize = 20;

/// Состояние пагинированного списка паролей
class PaginatedPasswordsState {
  final List<CardPasswordDto> passwords;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final int totalCount;

  const PaginatedPasswordsState({
    this.passwords = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.totalCount = 0,
  });

  PaginatedPasswordsState copyWith({
    List<CardPasswordDto>? passwords,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    int? totalCount,
  }) {
    return PaginatedPasswordsState(
      passwords: passwords ?? this.passwords,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  String toString() {
    return 'PaginatedPasswordsState('
        'passwords: ${passwords.length}, '
        'isLoading: $isLoading, '
        'isLoadingMore: $isLoadingMore, '
        'hasMore: $hasMore, '
        'error: $error, '
        'currentPage: $currentPage, '
        'totalCount: $totalCount)';
  }
}

/// Провайдер для пагинированного списка паролей
final paginatedPasswordsProvider =
    AsyncNotifierProvider.autoDispose<
      PaginatedPasswordsNotifier,
      PaginatedPasswordsState
    >(() => PaginatedPasswordsNotifier());

class PaginatedPasswordsNotifier
    extends AsyncNotifier<PaginatedPasswordsState> {
  @override
  Future<PaginatedPasswordsState> build() async {
    logDebug('PaginatedPasswordsNotifier: Инициализация');

    // Слушаем изменения фильтра паролей
    ref.listen(passwordFilterProvider, (previous, next) {
      if (previous != next) {
        logDebug('PaginatedPasswordsNotifier: Изменение фильтра паролей');
        _resetAndLoad();
      }
    });

    // Слушаем изменения вкладок фильтров
    ref.listen(filterTabsControllerProvider, (previous, next) {
      if (previous != next) {
        logDebug('PaginatedPasswordsNotifier: Изменение вкладки фильтра');
        _resetAndLoad();
      }
    });

    // Слушаем триггер обновления данных
    ref.listen(dataRefreshTriggerProvider, (previous, next) {
      if (previous != next) {
        logDebug('PaginatedPasswordsNotifier: Триггер обновления данных');
        _resetAndLoad();
      }
    });

    return _loadInitialData();
  }

  /// Загружает начальные данные
  Future<PaginatedPasswordsState> _loadInitialData() async {
    try {
      logDebug('PaginatedPasswordsNotifier: Загрузка начальных данных');

      final filter = _buildCurrentFilter();
      final dao = ref.read(passwordFilterDaoProvider);

      // Загружаем первую страницу
      final passwords = await dao.getFilteredPasswords(filter);
      final totalCount = await dao.countFilteredPasswords(filter);

      logDebug(
        'PaginatedPasswordsNotifier: Загружено ${passwords.length} паролей, всего: $totalCount',
      );

      return PaginatedPasswordsState(
        passwords: passwords,
        isLoading: false,
        hasMore:
            passwords.length >= kPasswordsPageSize &&
            passwords.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e, s) {
      logError(
        'PaginatedPasswordsNotifier: Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
      return PaginatedPasswordsState(
        error: 'Ошибка загрузки данных: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Загружает следующую страницу данных
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    try {
      logDebug('PaginatedPasswordsNotifier: Загрузка следующей страницы');

      // Устанавливаем состояние загрузки
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final filter = _buildCurrentFilter(page: currentState.currentPage + 1);
      final dao = ref.read(passwordFilterDaoProvider);

      final newPasswords = await dao.getFilteredPasswords(filter);

      logDebug(
        'PaginatedPasswordsNotifier: Загружено дополнительно ${newPasswords.length} паролей',
      );

      final allPasswords = [...currentState.passwords, ...newPasswords];
      final hasMore =
          newPasswords.length >= kPasswordsPageSize &&
          allPasswords.length < currentState.totalCount;

      state = AsyncValue.data(
        currentState.copyWith(
          passwords: allPasswords,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: currentState.currentPage + 1,
        ),
      );
    } catch (e, s) {
      logError(
        'PaginatedPasswordsNotifier: Ошибка загрузки дополнительных данных',
        error: e,
        stackTrace: s,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          error: 'Ошибка загрузки дополнительных данных: ${e.toString()}',
        ),
      );
    }
  }

  /// Обновляет данные (pull-to-refresh)
  Future<void> refresh() async {
    logDebug('PaginatedPasswordsNotifier: Обновление данных');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitialData);
  }

  /// Переключение избранного состояния пароля с оптимистичным обновлением UI
  Future<void> toggleFavorite(String passwordId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Находим пароль в текущем списке
      final passwordIndex = currentState.passwords.indexWhere(
        (p) => p.id == passwordId,
      );
      if (passwordIndex == -1) return;

      final password = currentState.passwords[passwordIndex];
      final newFavoriteState = !password.isFavorite;

      logDebug(
        'PaginatedPasswordsNotifier: Переключение избранного для пароля $passwordId: ${password.isFavorite} -> $newFavoriteState',
      );

      // Оптимистично обновляем UI
      final updatedPasswords = [...currentState.passwords];
      updatedPasswords[passwordIndex] = password.copyWith(
        isFavorite: newFavoriteState,
      );

      state = AsyncValue.data(
        currentState.copyWith(passwords: updatedPasswords),
      );

      // Обновляем в базе данных
      final service = ref.read(passwordsServiceProvider);
      final result = await service.updatePassword(
        UpdatePasswordDto(id: passwordId, isFavorite: newFavoriteState),
      );

      if (!result.success) {
        // Откатываем изменения при ошибке
        updatedPasswords[passwordIndex] = password;
        state = AsyncValue.data(
          currentState.copyWith(passwords: updatedPasswords),
        );
        logError(
          'PaginatedPasswordsNotifier: Ошибка при обновлении избранного: ${result.message}',
        );
      } else {
        logDebug(
          'PaginatedPasswordsNotifier: Избранное успешно обновлено для пароля $passwordId',
        );
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedPasswordsNotifier: Ошибка при переключении избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Сбрасывает состояние и загружает данные заново
  void _resetAndLoad() {
    logDebug('PaginatedPasswordsNotifier: Сброс и перезагрузка');
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  /// Строит текущий фильтр с учетом пагинации
  PasswordFilter _buildCurrentFilter({int page = 1}) {
    final passwordFilter = ref.read(passwordFilterProvider);
    final currentTab = ref.read(filterTabsControllerProvider);

    // Применяем фильтр текущей вкладки к базовому фильтру
    final baseFilter = passwordFilter.base.copyWith(
      isFavorite: _getTabFilter(currentTab),
      limit: kPasswordsPageSize,
      offset: (page - 1) * kPasswordsPageSize,
    );

    return passwordFilter.copyWith(base: baseFilter);
  }

  /// Получает текущее количество паролей
  int get currentCount => state.value?.passwords.length ?? 0;

  /// Проверяет, есть ли еще данные для загрузки
  bool get hasMore => state.value?.hasMore ?? false;

  /// Проверяет, идет ли загрузка дополнительных данных
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;

  /// Получает список паролей
  List<CardPasswordDto> get passwords => state.value?.passwords ?? [];

  /// Получает общее количество паролей
  int get totalCount => state.value?.totalCount ?? 0;

  /// Получает фильтр для вкладки
  bool? _getTabFilter(FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return null;
      case FilterTab.favorites:
        return true;
      case FilterTab.frequent:
        return null; // Будет обрабатываться через isFrequent в PasswordFilter
      case FilterTab.archived:
        return null; // Будет обрабатываться через isArchived в BaseFilter
    }
  }
}
