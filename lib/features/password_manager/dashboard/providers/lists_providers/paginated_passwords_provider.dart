import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import '../filter_providers/password_filter_provider.dart';
import '../filter_providers/filter_tabs_provider.dart';
import '../data_refresh_trigger_provider.dart';
import '../../models/filter_tab.dart';

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
    AsyncNotifierProvider<PaginatedPasswordsNotifier, PaginatedPasswordsState>(
      () => PaginatedPasswordsNotifier(),
    );

class PaginatedPasswordsNotifier
    extends AsyncNotifier<PaginatedPasswordsState> {
  @override
  Future<PaginatedPasswordsState> build() async {
    logDebug('PaginatedPasswordsNotifier: Инициализация');

    // Слушаем состояние базы данных
    ref.listen(isDatabaseOpenProvider, (previous, next) {
      if (previous != next) {
        if (next) {
          logDebug(
            'PaginatedPasswordsNotifier: База данных открыта, перезагружаем данные',
          );
          // Задержка для обеспечения готовности всех провайдеров
          Future.delayed(const Duration(milliseconds: 300), () {
            if (ref.mounted) {
              _resetAndLoad();
            }
          });
        } else {
          logDebug(
            'PaginatedPasswordsNotifier: База данных закрыта, очищаем данные',
          );
          // При закрытии базы данных очищаем данные
          if (ref.mounted) {
            state = const AsyncValue.data(PaginatedPasswordsState());
          }
        }
      }
    });

    // Слушаем изменения фильтра паролей
    ref.listen(passwordFilterProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedPasswordsNotifier: Изменение фильтра паролей');
        _resetAndLoad();
      }
    });

    // Слушаем изменения вкладок фильтров
    ref.listen(filterTabsControllerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedPasswordsNotifier: Изменение вкладки фильтра');
        _resetAndLoad();
      }
    });

    // Слушаем триггер обновления данных
    ref.listen(dataRefreshTriggerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedPasswordsNotifier: Триггер обновления данных');
        _resetAndLoad();
      }
    });

    return _loadInitialData();
  }

  /// Загружает начальные данные
  Future<PaginatedPasswordsState> _loadInitialData() async {
    try {
      logDebug('PaginatedPasswordsNotifier: Загрузка начальных данных', tag: 'PaginatedPasswordsNotifier');

      // Проверяем, что база данных открыта
      final isDatabaseOpen = ref.read(isDatabaseOpenProvider);
      if (!isDatabaseOpen) {
        logDebug(
          'PaginatedPasswordsNotifier: База данных не открыта, возвращаем пустое состояние',
        );
        return const PaginatedPasswordsState();
      }

      // Проверяем доступность DAO
      try {
        final dao = ref.read(passwordFilterDaoProvider);
        logDebug('PaginatedPasswordsNotifier: DAO получен успешно');

        // Проверяем доступность базы данных через DAO
        final testCount = await dao.countFilteredPasswords(
          PasswordFilter.create().copyWith(
            base: BaseFilter.create().copyWith(limit: 1, offset: 0),
          ),
        );
        logDebug(
          'PaginatedPasswordsNotifier: Тестовый запрос к БД выполнен, результат: $testCount',
        );
      } catch (e, s) {
        logError(
          'PaginatedPasswordsNotifier: Ошибка доступа к DAO или БД',
          error: e,
          stackTrace: s,
        );
        return PaginatedPasswordsState(
          error: 'Ошибка доступа к базе данных: ${e.toString()}',
          isLoading: false,
        );
      }

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
        !currentState.hasMore ||
        !ref.read(isDatabaseOpenProvider)) {
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
    if (!ref.read(isDatabaseOpenProvider)) {
      logDebug(
        'PaginatedPasswordsNotifier: База данных не открыта, пропускаем обновление',
      );
      return;
    }

    logDebug('PaginatedPasswordsNotifier: Обновление данных');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitialData);
  }

  /// Переключение избранного состояния пароля с оптимистичным обновлением UI
  Future<void> toggleFavorite(String passwordId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

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

      // Проверяем текущую вкладку фильтра
      final currentTab = ref.read(filterTabsControllerProvider);

      // Если текущая вкладка - "Избранные" и мы убираем из избранных,
      // удаляем пароль из списка
      if (currentTab == FilterTab.favorites && !newFavoriteState) {
        logDebug(
          'PaginatedPasswordsNotifier: Удаление пароля $passwordId из списка избранных',
        );

        final updatedPasswords = [...currentState.passwords];
        updatedPasswords.removeAt(passwordIndex);

        state = AsyncValue.data(
          currentState.copyWith(
            passwords: updatedPasswords,
            totalCount: currentState.totalCount - 1,
          ),
        );

        // Обновляем в базе данных
        final service = ref.read(passwordsServiceProvider);
        final result = await service.updatePassword(
          UpdatePasswordDto(id: passwordId, isFavorite: newFavoriteState),
        );

        if (!result.success) {
          // Откатываем изменения при ошибке - возвращаем пароль в список
          updatedPasswords.insert(passwordIndex, password);
          state = AsyncValue.data(
            currentState.copyWith(
              passwords: updatedPasswords,
              totalCount: currentState.totalCount,
            ),
          );
          logError(
            'PaginatedPasswordsNotifier: Ошибка при обновлении избранного: ${result.message}',
          );
        } else {
          logDebug(
            'PaginatedPasswordsNotifier: Избранное успешно обновлено для пароля $passwordId',
          );
        }
      } else {
        // Стандартное поведение - обновляем состояние пароля
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

  /// Удаление пароля с оптимистичным обновлением UI
  Future<void> deletePassword(String passwordId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим пароль в текущем списке
      final passwordIndex = currentState.passwords.indexWhere(
        (p) => p.id == passwordId,
      );
      if (passwordIndex == -1) return;

      final password = currentState.passwords[passwordIndex];

      logDebug('PaginatedPasswordsNotifier: Удаление пароля $passwordId');

      // Оптимистично удаляем пароль из UI
      final updatedPasswords = [...currentState.passwords];
      updatedPasswords.removeAt(passwordIndex);

      state = AsyncValue.data(
        currentState.copyWith(
          passwords: updatedPasswords,
          totalCount: currentState.totalCount - 1,
        ),
      );

      // Удаляем пароль из базы данных
      final service = ref.read(passwordsServiceProvider);
      final result = await service.deletePassword(passwordId);

      if (!result.success) {
        // Откатываем изменения при ошибке - возвращаем пароль в список
        updatedPasswords.insert(passwordIndex, password);
        state = AsyncValue.data(
          currentState.copyWith(
            passwords: updatedPasswords,
            totalCount: currentState.totalCount,
          ),
        );
        logError(
          'PaginatedPasswordsNotifier: Ошибка при удалении пароля: ${result.message}',
        );
      } else {
        logDebug(
          'PaginatedPasswordsNotifier: Пароль $passwordId успешно удален',
        );
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedPasswordsNotifier: Ошибка при удалении пароля',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Сбрасывает состояние и загружает данные заново
  void _resetAndLoad() {
    if (!ref.read(isDatabaseOpenProvider)) {
      logDebug(
        'PaginatedPasswordsNotifier: База данных не открыта, пропускаем сброс и загрузку',
      );
      return;
    }

    logDebug('PaginatedPasswordsNotifier: Сброс и перезагрузка');
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  /// Строит текущий фильтр с учетом пагинации
  PasswordFilter _buildCurrentFilter({int page = 1}) {
    final passwordFilter = ref.read(passwordFilterProvider);
    final currentTab = ref.read(filterTabsControllerProvider);

    logDebug(
      'PaginatedPasswordsNotifier: Построение фильтра для страницы $page, вкладка: $currentTab',
    );

    // Применяем фильтр текущей вкладки к базовому фильтру
    final tabFilter = _getTabFilter(currentTab);
    final baseFilter = passwordFilter.base.copyWith(
      isFavorite: tabFilter,
      limit: kPasswordsPageSize,
      offset: (page - 1) * kPasswordsPageSize,
    );

    final finalFilter = passwordFilter.copyWith(base: baseFilter);

    logDebug(
      'PaginatedPasswordsNotifier: Фильтр построен - '
      'isFavorite: ${baseFilter.isFavorite}, '
      'isArchived: ${baseFilter.isArchived}, '
      'limit: ${baseFilter.limit}, '
      'offset: ${baseFilter.offset}, '
      'searchQuery: ${baseFilter.query}',
    );

    return finalFilter;
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
