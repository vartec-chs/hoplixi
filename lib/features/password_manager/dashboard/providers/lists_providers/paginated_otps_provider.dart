import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import '../filter_providers/otp_filter_provider.dart';
import '../filter_providers/filter_tabs_provider.dart';
import '../data_refresh_trigger_provider.dart';
import '../../models/filter_tab.dart';

/// Размер страницы для пагинации
const int kOtpsPageSize = 20;

/// Состояние пагинированного списка OTP
class PaginatedOtpsState {
  final List<CardOtpDto> otps;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final int totalCount;

  const PaginatedOtpsState({
    this.otps = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.totalCount = 0,
  });

  PaginatedOtpsState copyWith({
    List<CardOtpDto>? otps,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    int? totalCount,
  }) {
    return PaginatedOtpsState(
      otps: otps ?? this.otps,
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
    return 'PaginatedOtpsState('
        'otps: ${otps.length}, '
        'isLoading: $isLoading, '
        'isLoadingMore: $isLoadingMore, '
        'hasMore: $hasMore, '
        'error: $error, '
        'currentPage: $currentPage, '
        'totalCount: $totalCount)';
  }
}

/// Провайдер для пагинированного списка OTP
final paginatedOtpsProvider =
    AsyncNotifierProvider<PaginatedOtpsNotifier, PaginatedOtpsState>(
      () => PaginatedOtpsNotifier(),
    );

class PaginatedOtpsNotifier extends AsyncNotifier<PaginatedOtpsState> {
  @override
  Future<PaginatedOtpsState> build() async {
    logDebug('PaginatedOtpsNotifier: Инициализация');

    // Слушаем состояние базы данных
    ref.listen(isDatabaseOpenProvider, (previous, next) {
      if (previous != next) {
        if (next) {
          logDebug(
            'PaginatedOtpsNotifier: База данных открыта, загружаем данные',
          );
          // Задержка для обеспечения готовности всех провайдеров
          Future.delayed(const Duration(milliseconds: 300), () {
            if (ref.mounted) {
              ref.invalidateSelf();
            }
          });
        } else {
          logDebug(
            'PaginatedOtpsNotifier: База данных закрыта, очищаем данные',
          );
          // При закрытии базы данных очищаем данные
          if (ref.mounted) {
            state = AsyncValue.data(const PaginatedOtpsState());
          }
        }
      }
    });

    // Слушаем изменения фильтра OTP
    ref.listen(otpFilterProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedOtpsNotifier: Изменение фильтра OTP');
        _resetAndLoad();
      }
    });

    // Слушаем изменения вкладок фильтров
    ref.listen(filterTabsControllerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedOtpsNotifier: Изменение вкладки фильтра');
        _resetAndLoad();
      }
    });

    // Слушаем триггер обновления данных
    ref.listen(dataRefreshTriggerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedOtpsNotifier: Триггер обновления данных');
        _resetAndLoad();
      }
    });

    return _loadInitialData();
  }

  /// Загружает начальные данные
  Future<PaginatedOtpsState> _loadInitialData() async {
    try {
      logDebug(
        'PaginatedOtpsNotifier: Загрузка начальных данных',
        tag: 'PaginatedOtpsNotifier',
      );

      // Проверяем, что база данных открыта
      final isDatabaseOpen = ref.read(isDatabaseOpenProvider);
      if (!isDatabaseOpen) {
        logDebug(
          'PaginatedOtpsNotifier: База данных не открыта, возвращаем пустое состояние',
        );
        return const PaginatedOtpsState();
      }

      // Проверяем доступность DAO
      try {
        final dao = ref.read(otpFilterDaoProvider);
        logDebug('PaginatedOtpsNotifier: DAO получен успешно');

        // Проверяем доступность базы данных через DAO
        final testCount = await dao.countFilteredOtps(
          OtpFilter.create().copyWith(
            base: BaseFilter.create().copyWith(limit: 1, offset: 0),
          ),
        );
        logDebug(
          'PaginatedOtpsNotifier: Тестовый запрос к БД выполнен, результат: $testCount',
        );
      } catch (e, s) {
        logError(
          'PaginatedOtpsNotifier: Ошибка доступа к DAO',
          error: e,
          stackTrace: s,
        );
        return PaginatedOtpsState(
          error: 'Ошибка доступа к базе данных',
          isLoading: false,
        );
      }

      final filter = _buildCurrentFilter();
      final dao = ref.read(otpFilterDaoProvider);

      // Загружаем первую страницу
      final otps = await dao.getFilteredOtps(filter);
      final totalCount = await dao.countFilteredOtps(filter);

      logDebug(
        'PaginatedOtpsNotifier: Загружено ${otps.length} OTP, всего: $totalCount',
      );

      return PaginatedOtpsState(
        otps: otps,
        isLoading: false,
        hasMore: otps.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e, s) {
      logError(
        'PaginatedOtpsNotifier: Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
      return PaginatedOtpsState(
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
      logDebug('PaginatedOtpsNotifier: Загрузка следующей страницы');

      // Устанавливаем состояние загрузки
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final filter = _buildCurrentFilter(page: currentState.currentPage + 1);
      final dao = ref.read(otpFilterDaoProvider);

      final newOtps = await dao.getFilteredOtps(filter);

      logDebug(
        'PaginatedOtpsNotifier: Загружено дополнительно ${newOtps.length} OTP',
      );

      final allOtps = [...currentState.otps, ...newOtps];
      final hasMore =
          newOtps.length >= kOtpsPageSize &&
          allOtps.length < currentState.totalCount;

      state = AsyncValue.data(
        currentState.copyWith(
          otps: allOtps,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: currentState.currentPage + 1,
        ),
      );
    } catch (e, s) {
      logError(
        'PaginatedOtpsNotifier: Ошибка загрузки дополнительных данных',
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
        'PaginatedOtpsNotifier: База данных не открыта, пропускаем обновление',
      );
      return;
    }

    logDebug('PaginatedOtpsNotifier: Обновление данных');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitialData);
  }

  /// Переключение избранного состояния OTP с оптимистичным обновлением UI
  Future<void> toggleFavorite(String otpId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим OTP в текущем списке
      final otpIndex = currentState.otps.indexWhere((o) => o.id == otpId);
      if (otpIndex == -1) return;

      final otp = currentState.otps[otpIndex];
      final newFavoriteState = !otp.isFavorite;

      logDebug(
        'PaginatedOtpsNotifier: Переключение избранного для OTP $otpId: ${otp.isFavorite} -> $newFavoriteState',
      );

      // Проверяем текущую вкладку фильтра
      final currentTab = ref.read(filterTabsControllerProvider);

      // Если текущая вкладка - "Избранные" и мы убираем из избранных,
      // удаляем OTP из списка
      if (currentTab == FilterTab.favorites && !newFavoriteState) {
        logDebug('PaginatedOtpsNotifier: Удаление OTP из списка избранных');

        final updatedOtps = [...currentState.otps];
        updatedOtps.removeAt(otpIndex);

        state = AsyncValue.data(
          currentState.copyWith(
            otps: updatedOtps,
            totalCount: currentState.totalCount - 1,
          ),
        );

        // Обновляем в базе данных
        final service = ref.read(totpServiceProvider);
        final result = await service.toggleFavorite(otpId);

        if (!result.success) {
          // Откатываем изменения при ошибке
          updatedOtps.insert(otpIndex, otp);
          state = AsyncValue.data(
            currentState.copyWith(
              otps: updatedOtps,
              totalCount: currentState.totalCount,
            ),
          );
          logError(
            'PaginatedOtpsNotifier: Ошибка переключения избранного',
            error: result.message,
          );
        } else {
          logDebug('PaginatedOtpsNotifier: Избранное переключено успешно');
        }
      } else {
        // Стандартное поведение - обновляем состояние OTP
        final updatedOtps = [...currentState.otps];
        updatedOtps[otpIndex] = otp.copyWith(isFavorite: newFavoriteState);

        state = AsyncValue.data(currentState.copyWith(otps: updatedOtps));

        // Обновляем в базе данных
        final service = ref.read(totpServiceProvider);
        final result = await service.toggleFavorite(otpId);

        if (!result.success) {
          // Откатываем изменения при ошибке
          updatedOtps[otpIndex] = otp;
          state = AsyncValue.data(currentState.copyWith(otps: updatedOtps));
          logError(
            'PaginatedOtpsNotifier: Ошибка переключения избранного',
            error: result.message,
          );
        } else {
          logDebug('PaginatedOtpsNotifier: Избранное переключено успешно');
        }
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedOtpsNotifier: Ошибка при переключении избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Удаление OTP с оптимистичным обновлением UI
  Future<void> deleteOtp(String otpId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим OTP в текущем списке
      final otpIndex = currentState.otps.indexWhere((o) => o.id == otpId);
      if (otpIndex == -1) return;

      final otp = currentState.otps[otpIndex];

      logDebug('PaginatedOtpsNotifier: Удаление OTP $otpId');

      // Оптимистично удаляем OTP из UI
      final updatedOtps = [...currentState.otps];
      updatedOtps.removeAt(otpIndex);

      state = AsyncValue.data(
        currentState.copyWith(
          otps: updatedOtps,
          totalCount: currentState.totalCount - 1,
        ),
      );

      // Удаляем OTP из базы данных
      final service = ref.read(totpServiceProvider);
      final result = await service.deleteTotp(otpId);

      if (!result.success) {
        // Откатываем изменения при ошибке - возвращаем OTP в список
        updatedOtps.insert(otpIndex, otp);
        state = AsyncValue.data(
          currentState.copyWith(
            otps: updatedOtps,
            totalCount: currentState.totalCount,
          ),
        );
        logError(
          'PaginatedOtpsNotifier: Ошибка при удалении OTP',
          error: result.message,
        );
      } else {
        logDebug('PaginatedOtpsNotifier: OTP удален успешно');
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedOtpsNotifier: Ошибка при удалении OTP',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Сбрасывает состояние и загружает данные заново
  void _resetAndLoad() {
    if (!ref.read(isDatabaseOpenProvider)) {
      logDebug(
        'PaginatedOtpsNotifier: База данных не открыта, пропускаем сброс и загрузку',
      );
      return;
    }

    logDebug('PaginatedOtpsNotifier: Сброс и перезагрузка');
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  /// Строит текущий фильтр с учетом пагинации
  OtpFilter _buildCurrentFilter({int page = 1}) {
    final otpFilter = ref.read(otpFilterProvider);
    final currentTab = ref.read(filterTabsControllerProvider);

    logDebug(
      'PaginatedOtpsNotifier: Построение фильтра для страницы $page, вкладка: $currentTab',
    );

    // Применяем фильтр текущей вкладки к базовому фильтру
    final tabFilter = _getTabFilter(currentTab);
    final baseFilter = otpFilter.base.copyWith(
      isFavorite: tabFilter,
      limit: kOtpsPageSize,
      offset: (page - 1) * kOtpsPageSize,
    );

    final finalFilter = otpFilter.copyWith(base: baseFilter);

    logDebug(
      'PaginatedOtpsNotifier: Фильтр построен - '
      'isFavorite: ${baseFilter.isFavorite}, '
      'limit: ${baseFilter.limit}, '
      'offset: ${baseFilter.offset}, '
      'searchQuery: ${baseFilter.query}',
    );

    return finalFilter;
  }

  /// Получает текущее количество OTP
  int get currentCount => state.value?.otps.length ?? 0;

  /// Проверяет, есть ли еще данные для загрузки
  bool get hasMore => state.value?.hasMore ?? false;

  /// Проверяет, идет ли загрузка дополнительных данных
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;

  /// Получает список OTP
  List<CardOtpDto> get otps => state.value?.otps ?? [];

  /// Получает общее количество OTP
  int get totalCount => state.value?.totalCount ?? 0;

  /// Получает фильтр для вкладки
  bool? _getTabFilter(FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return null;
      case FilterTab.favorites:
        return true;
      case FilterTab.frequent:
        return null; // Будет обрабатываться через isFrequent в OtpFilter
      case FilterTab.archived:
        return null; // Будет обрабатываться через isArchived в BaseFilter
    }
  }
}
