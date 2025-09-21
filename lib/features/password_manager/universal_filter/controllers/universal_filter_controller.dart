import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/universal_filter/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/universal_filter/models/universal_filter.dart';

/// Универсальные вкладки фильтрации
enum UniversalFilterTab {
  all('Все', Icons.list),
  favorites('Избранные', Icons.star),
  frequent('Часто используемые', Icons.access_time),
  archived('Архив', Icons.archive);

  final String label;
  final IconData icon;
  const UniversalFilterTab(this.label, this.icon);

  /// Получить доступные вкладки для типа сущности
  static List<UniversalFilterTab> getAvailableTabsForEntity(
    UniversalEntityType entityType,
  ) {
    switch (entityType) {
      case UniversalEntityType.password:
        return [
          UniversalFilterTab.all,
          UniversalFilterTab.favorites,
          UniversalFilterTab.frequent,
          UniversalFilterTab.archived,
        ];
      case UniversalEntityType.note:
        return [
          UniversalFilterTab.all,
          UniversalFilterTab.favorites,
          UniversalFilterTab.archived,
        ];
      case UniversalEntityType.otp:
        return [
          UniversalFilterTab.all,
          UniversalFilterTab.favorites,
          UniversalFilterTab.archived,
        ];
      case UniversalEntityType.attachment:
        return [UniversalFilterTab.all, UniversalFilterTab.archived];
    }
  }
}

/// Состояние универсального фильтра
@immutable
class UniversalFilterState {
  /// Текущий универсальный фильтр
  final UniversalFilter filter;

  /// Активная вкладка
  final UniversalFilterTab activeTab;

  /// Доступные вкладки для текущего типа сущности
  final List<UniversalFilterTab> availableTabs;

  /// Поисковый запрос для мгновенной фильтрации
  final String searchQuery;

  /// Показывается ли индикатор активных фильтров
  final bool hasActiveFilters;

  const UniversalFilterState({
    required this.filter,
    required this.activeTab,
    required this.availableTabs,
    required this.searchQuery,
    required this.hasActiveFilters,
  });

  UniversalFilterState copyWith({
    UniversalFilter? filter,
    UniversalFilterTab? activeTab,
    List<UniversalFilterTab>? availableTabs,
    String? searchQuery,
    bool? hasActiveFilters,
  }) {
    return UniversalFilterState(
      filter: filter ?? this.filter,
      activeTab: activeTab ?? this.activeTab,
      availableTabs: availableTabs ?? this.availableTabs,
      searchQuery: searchQuery ?? this.searchQuery,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniversalFilterState &&
        other.filter == filter &&
        other.activeTab == activeTab &&
        _listEquals(other.availableTabs, availableTabs) &&
        other.searchQuery == searchQuery &&
        other.hasActiveFilters == hasActiveFilters;
  }

  @override
  int get hashCode {
    return Object.hash(
      filter,
      activeTab,
      availableTabs,
      searchQuery,
      hasActiveFilters,
    );
  }

  bool _listEquals(List<UniversalFilterTab> a, List<UniversalFilterTab> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Контроллер для управления универсальной фильтрацией
class UniversalFilterController extends Notifier<UniversalFilterState> {
  @override
  UniversalFilterState build() {
    // Инициализируем с типом сущности по умолчанию
    final entityType = ref.watch(currentEntityTypeProvider);
    final availableTabs = UniversalFilterTab.getAvailableTabsForEntity(
      entityType,
    );

    return UniversalFilterState(
      filter: UniversalFilter.empty(entityType),
      activeTab: UniversalFilterTab.all,
      availableTabs: availableTabs,
      searchQuery: '',
      hasActiveFilters: false,
    );
  }

  /// Обновляет поисковый запрос с мгновенным применением
  void updateSearchQuery(String query) {
    final normalizedQuery = query.trim();
    logDebug('Обновление поискового запроса', data: {'query': normalizedQuery});

    final updatedFilter = state.filter.updateSearchQuery(normalizedQuery);

    state = state.copyWith(
      searchQuery: normalizedQuery,
      filter: updatedFilter,
      hasActiveFilters: _calculateHasActiveFilters(
        updatedFilter,
        state.activeTab,
      ),
    );

    logDebug(
      'Фильтр после обновления запроса',
      data: {'entityType': state.filter.entityType.id},
    );
  }

  /// Переключает активную вкладку с мгновенным применением
  void switchTab(UniversalFilterTab tab) {
    if (!state.availableTabs.contains(tab)) {
      logWarning(
        'Попытка переключиться на недоступную вкладку',
        data: {
          'requestedTab': tab.label,
          'availableTabs': state.availableTabs.map((t) => t.label).toList(),
        },
      );
      return;
    }

    logDebug('Переключение вкладки', data: {'tab': tab.label});

    final updatedFilter = _applyTabFilter(state.filter, tab);
    state = state.copyWith(
      activeTab: tab,
      filter: updatedFilter,
      hasActiveFilters: _calculateHasActiveFilters(updatedFilter, tab),
    );

    logDebug(
      'Фильтр после переключения вкладки',
      data: {'entityType': updatedFilter.entityType.id},
    );
  }

  /// Применяет новый фильтр (используется при подтверждении в модальном окне)
  void applyFilter(UniversalFilter newFilter) {
    final filterWithTab = _applyTabFilter(newFilter, state.activeTab);
    state = state.copyWith(
      filter: filterWithTab,
      hasActiveFilters: _calculateHasActiveFilters(
        filterWithTab,
        state.activeTab,
      ),
    );

    logInfo(
      'Применен новый фильтр',
      data: {
        'entityType': filterWithTab.entityType.id,
        'hasConstraints': filterWithTab.hasActiveConstraints,
      },
    );
  }

  /// Обновляет категории фильтра
  void updateCategories(List<String> categoryIds) {
    final updatedFilter = state.filter.updateCategories(categoryIds);
    state = state.copyWith(
      filter: updatedFilter,
      hasActiveFilters: _calculateHasActiveFilters(
        updatedFilter,
        state.activeTab,
      ),
    );
  }

  /// Обновляет теги фильтра
  void updateTags(List<String> tagIds) {
    final updatedFilter = state.filter.updateTags(tagIds);
    state = state.copyWith(
      filter: updatedFilter,
      hasActiveFilters: _calculateHasActiveFilters(
        updatedFilter,
        state.activeTab,
      ),
    );
  }

  /// Сбрасывает все фильтры к начальному состоянию
  void resetFilters() {
    logInfo('Сброс фильтров');

    final resetFilter = state.filter.reset();
    state = state.copyWith(
      filter: resetFilter,
      activeTab: UniversalFilterTab.all,
      hasActiveFilters: state.searchQuery.isNotEmpty,
    );
  }

  /// Обновляет тип сущности и соответствующие вкладки
  void updateEntityType(UniversalEntityType newEntityType) {
    logInfo(
      'Обновление типа сущности',
      data: {
        'oldType': state.filter.entityType.id,
        'newType': newEntityType.id,
      },
    );

    final availableTabs = UniversalFilterTab.getAvailableTabsForEntity(
      newEntityType,
    );
    final newActiveTab = availableTabs.contains(state.activeTab)
        ? state.activeTab
        : UniversalFilterTab.all;

    final newFilter = UniversalFilter.empty(
      newEntityType,
    ).updateSearchQuery(state.searchQuery);

    final filterWithTab = _applyTabFilter(newFilter, newActiveTab);

    state = state.copyWith(
      filter: filterWithTab,
      activeTab: newActiveTab,
      availableTabs: availableTabs,
      hasActiveFilters: _calculateHasActiveFilters(filterWithTab, newActiveTab),
    );
  }

  /// Применяет фильтр в зависимости от активной вкладки
  UniversalFilter _applyTabFilter(
    UniversalFilter baseFilter,
    UniversalFilterTab tab,
  ) {
    switch (tab) {
      case UniversalFilterTab.all:
        return _clearTabSpecificFilters(baseFilter);
      case UniversalFilterTab.favorites:
        return _applyFavoriteFilter(baseFilter, true);
      case UniversalFilterTab.frequent:
        return _applyFrequentFilter(baseFilter, true);
      case UniversalFilterTab.archived:
        return _applyArchivedFilter(baseFilter, true);
    }
  }

  /// Очищает специфичные для вкладок фильтры
  UniversalFilter _clearTabSpecificFilters(UniversalFilter filter) {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        return filter.copyWith(
          passwordFilter: filter.passwordFilter?.copyWith(
            isFavorite: null,
            isFrequent: null,
            isArchived: null,
          ),
        );
      default:
        // Для других типов используем BaseFilter
        final baseFilter = _getBaseFilter(filter);
        return _updateBaseFilter(
          filter,
          baseFilter?.copyWith(isFavorite: null, isArchived: null),
        );
    }
  }

  /// Применяет фильтр избранного
  UniversalFilter _applyFavoriteFilter(
    UniversalFilter filter,
    bool isFavorite,
  ) {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        return filter.copyWith(
          passwordFilter: filter.passwordFilter?.copyWith(
            isFavorite: isFavorite,
            isArchived: null,
          ),
        );
      default:
        final baseFilter = _getBaseFilter(filter);
        return _updateBaseFilter(
          filter,
          baseFilter?.copyWith(isFavorite: isFavorite, isArchived: null),
        );
    }
  }

  /// Применяет фильтр частых (только для паролей)
  UniversalFilter _applyFrequentFilter(
    UniversalFilter filter,
    bool isFrequent,
  ) {
    if (filter.entityType == UniversalEntityType.password) {
      return filter.copyWith(
        passwordFilter: filter.passwordFilter?.copyWith(
          isFrequent: isFrequent,
          isFavorite: null,
          isArchived: null,
        ),
      );
    }
    return filter;
  }

  /// Применяет фильтр архивных
  UniversalFilter _applyArchivedFilter(
    UniversalFilter filter,
    bool isArchived,
  ) {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        return filter.copyWith(
          passwordFilter: filter.passwordFilter?.copyWith(
            isArchived: isArchived,
            isFavorite: null,
          ),
        );
      default:
        final baseFilter = _getBaseFilter(filter);
        return _updateBaseFilter(
          filter,
          baseFilter?.copyWith(isArchived: isArchived, isFavorite: null),
        );
    }
  }

  /// Получает BaseFilter для текущего типа сущности
  dynamic _getBaseFilter(UniversalFilter filter) {
    switch (filter.entityType) {
      case UniversalEntityType.note:
        return filter.notesFilter?.base;
      case UniversalEntityType.otp:
        return filter.otpFilter?.base;
      case UniversalEntityType.attachment:
        return filter.attachmentsFilter?.base;
      default:
        return null;
    }
  }

  /// Обновляет BaseFilter для текущего типа сущности
  UniversalFilter _updateBaseFilter(
    UniversalFilter filter,
    dynamic newBaseFilter,
  ) {
    if (newBaseFilter == null) return filter;

    switch (filter.entityType) {
      case UniversalEntityType.note:
        return filter.copyWith(
          notesFilter: filter.notesFilter?.copyWith(base: newBaseFilter),
        );
      case UniversalEntityType.otp:
        return filter.copyWith(
          otpFilter: filter.otpFilter?.copyWith(base: newBaseFilter),
        );
      case UniversalEntityType.attachment:
        return filter.copyWith(
          attachmentsFilter: filter.attachmentsFilter?.copyWith(
            base: newBaseFilter,
          ),
        );
      default:
        return filter;
    }
  }

  /// Вычисляет, есть ли активные фильтры
  bool _calculateHasActiveFilters(
    UniversalFilter filter,
    UniversalFilterTab tab,
  ) {
    // Проверяем базовые ограничения фильтра
    if (filter.hasActiveConstraints) return true;

    // Проверяем, выбрана ли не-дефолтная вкладка
    if (tab != UniversalFilterTab.all) return true;

    return false;
  }
}

/// Провайдер для контроллера универсальной фильтрации
final universalFilterControllerProvider =
    NotifierProvider<UniversalFilterController, UniversalFilterState>(
      () => UniversalFilterController(),
    );

/// Computed провайдер для получения текущего фильтра
final currentUniversalFilterProvider = Provider<UniversalFilter>((ref) {
  return ref.watch(
    universalFilterControllerProvider.select((state) => state.filter),
  );
});

/// Computed провайдер для получения активного специфичного фильтра
final currentActiveFilterProvider = Provider<dynamic>((ref) {
  final universalFilter = ref.watch(currentUniversalFilterProvider);
  return universalFilter.activeFilter;
});

/// Computed провайдер для проверки активных фильтров
final hasActiveUniversalFiltersProvider = Provider<bool>((ref) {
  return ref.watch(
    universalFilterControllerProvider.select((state) => state.hasActiveFilters),
  );
});

/// Computed провайдер для доступных вкладок
final availableFilterTabsProvider = Provider<List<UniversalFilterTab>>((ref) {
  return ref.watch(
    universalFilterControllerProvider.select((state) => state.availableTabs),
  );
});

/// Computed провайдер для текущей активной вкладки
final currentFilterTabProvider = Provider<UniversalFilterTab>((ref) {
  return ref.watch(
    universalFilterControllerProvider.select((state) => state.activeTab),
  );
});

/// Автоматическое обновление фильтра при изменении типа сущности
final _entityTypeListenerProvider = Provider<void>((ref) {
  final entityType = ref.watch(currentEntityTypeProvider);
  final controller = ref.read(universalFilterControllerProvider.notifier);

  // Обновляем фильтр при изменении типа сущности
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.updateEntityType(entityType);
  });
});
