import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';

/// Состояние фильтра с дополнительными полями для управления UI
@immutable
class FilterSectionState {
  /// Основной фильтр для паролей
  final PasswordFilter filter;

  /// Активная вкладка в TabBar
  final FilterTab activeTab;

  /// Поисковый запрос для мгновенной фильтрации
  final String searchQuery;

  /// Показывается ли индикатор активных фильтров
  final bool hasActiveFilters;

  const FilterSectionState({
    required this.filter,
    required this.activeTab,
    required this.searchQuery,
    required this.hasActiveFilters,
  });

  FilterSectionState copyWith({
    PasswordFilter? filter,
    FilterTab? activeTab,
    String? searchQuery,
    bool? hasActiveFilters,
  }) {
    return FilterSectionState(
      filter: filter ?? this.filter,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterSectionState &&
        other.filter == filter &&
        other.activeTab == activeTab &&
        other.searchQuery == searchQuery &&
        other.hasActiveFilters == hasActiveFilters;
  }

  @override
  int get hashCode {
    return Object.hash(filter, activeTab, searchQuery, hasActiveFilters);
  }
}

/// Тип фильтрации для быстрых вкладок
enum FilterTab {
  all('Все'),
  favorites('Избранные'),
  frequent('Часто используемые');

  const FilterTab(this.label);
  final String label;
}

/// Контроллер для управления состоянием фильтрации паролей
class FilterSectionController extends Notifier<FilterSectionState> {
  @override
  FilterSectionState build() {
    return FilterSectionState(
      filter: const PasswordFilter(),
      activeTab: FilterTab.all,
      searchQuery: '',
      hasActiveFilters: false,
    );
  }

  /// Обновляет поисковый запрос с мгновенным применением
  void updateSearchQuery(String query) {
    final normalizedQuery = query.trim();
    state = state.copyWith(
      searchQuery: normalizedQuery,
      filter: state.filter.copyWith(query: normalizedQuery),
      hasActiveFilters: _calculateHasActiveFilters(
        state.filter.copyWith(query: normalizedQuery),
        state.activeTab,
      ),
    );
  }

  /// Переключает активную вкладку в TabBar с мгновенным применением
  void switchTab(FilterTab tab) {
    final updatedFilter = _applyTabFilter(state.filter, tab);
    state = state.copyWith(
      activeTab: tab,
      filter: updatedFilter,
      hasActiveFilters: _calculateHasActiveFilters(updatedFilter, tab),
    );
  }

  /// Применяет новый фильтр (используется при подтверждении в модальном окне)
  void applyFilter(PasswordFilter newFilter) {
    final filterWithTab = _applyTabFilter(newFilter, state.activeTab);
    state = state.copyWith(
      filter: filterWithTab,
      hasActiveFilters: _calculateHasActiveFilters(
        filterWithTab,
        state.activeTab,
      ),
    );
  }

  /// Обновляет категории фильтра
  void updateCategories(List<String> categoryIds) {
    final updatedFilter = state.filter.copyWith(categoryIds: categoryIds);
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
    final updatedFilter = state.filter.copyWith(tagIds: tagIds);
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
    state = FilterSectionState(
      filter: PasswordFilter(query: state.searchQuery),
      activeTab: FilterTab.all,
      searchQuery: state.searchQuery,
      hasActiveFilters: state.searchQuery.isNotEmpty,
    );
  }

  /// Применяет фильтр в зависимости от активной вкладки
  PasswordFilter _applyTabFilter(PasswordFilter baseFilter, FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return baseFilter.copyWith(isFavorite: null, isFrequent: null);
      case FilterTab.favorites:
        return baseFilter.copyWith(isFavorite: true, isFrequent: null);
      case FilterTab.frequent:
        return baseFilter.copyWith(isFavorite: null, isFrequent: true);
    }
  }

  /// Вычисляет, есть ли активные фильтры
  bool _calculateHasActiveFilters(PasswordFilter filter, FilterTab tab) {
    // Проверяем базовые ограничения фильтра
    if (filter.hasActiveConstraints) return true;

    // Проверяем, выбрана ли не-дефолтная вкладка
    if (tab != FilterTab.all) return true;

    return false;
  }
}

/// Provider для контроллера фильтрации
final filterSectionControllerProvider =
    NotifierProvider<FilterSectionController, FilterSectionState>(
      () => FilterSectionController(),
    );

/// Computed provider для получения текущего фильтра
final currentPasswordFilterProvider = Provider<PasswordFilter>((ref) {
  return ref.watch(
    filterSectionControllerProvider.select((state) => state.filter),
  );
});

/// Computed provider для проверки активных фильтров
final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(
    filterSectionControllerProvider.select((state) => state.hasActiveFilters),
  );
});
