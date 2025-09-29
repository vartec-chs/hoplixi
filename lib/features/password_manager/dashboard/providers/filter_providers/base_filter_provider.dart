import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Провайдер для управления базовым фильтром
final baseFilterProvider = NotifierProvider<BaseFilterNotifier, BaseFilter>(
  () => BaseFilterNotifier(),
);

class BaseFilterNotifier extends Notifier<BaseFilter> {
  @override
  BaseFilter build() {
    logDebug('BaseFilterNotifier: Инициализация базового фильтра');
    return const BaseFilter();
  }

  /// Обновляет поисковый запрос
  void updateQuery(String query) {
    logDebug('BaseFilterNotifier: Обновление запроса: $query');
    state = state.copyWith(query: query.trim());
  }

  /// Обновляет список категорий
  void updateCategoryIds(List<String> categoryIds) {
    logDebug('BaseFilterNotifier: Обновление категорий: ${categoryIds.length}');
    final normalized = categoryIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    state = state.copyWith(categoryIds: normalized);
  }

  /// Добавляет категорию к фильтру
  void addCategoryId(String categoryId) {
    if (categoryId.trim().isEmpty) return;

    final currentCategories = List<String>.from(state.categoryIds);
    if (!currentCategories.contains(categoryId)) {
      currentCategories.add(categoryId);
      logDebug('BaseFilterNotifier: Добавлена категория: $categoryId');
      state = state.copyWith(categoryIds: currentCategories);
    }
  }

  /// Удаляет категорию из фильтра
  void removeCategoryId(String categoryId) {
    final currentCategories = List<String>.from(state.categoryIds);
    if (currentCategories.remove(categoryId)) {
      logDebug('BaseFilterNotifier: Удалена категория: $categoryId');
      state = state.copyWith(categoryIds: currentCategories);
    }
  }

  /// Обновляет список тегов
  void updateTagIds(List<String> tagIds) {
    logDebug('BaseFilterNotifier: Обновление тегов: ${tagIds.length}');
    final normalized = tagIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    state = state.copyWith(tagIds: normalized);
  }

  /// Добавляет тег к фильтру
  void addTagId(String tagId) {
    if (tagId.trim().isEmpty) return;

    final currentTags = List<String>.from(state.tagIds);
    if (!currentTags.contains(tagId)) {
      currentTags.add(tagId);
      logDebug('BaseFilterNotifier: Добавлен тег: $tagId');
      state = state.copyWith(tagIds: currentTags);
    }
  }

  /// Удаляет тег из фильтра
  void removeTagId(String tagId) {
    final currentTags = List<String>.from(state.tagIds);
    if (currentTags.remove(tagId)) {
      logDebug('BaseFilterNotifier: Удален тег: $tagId');
      state = state.copyWith(tagIds: currentTags);
    }
  }

  /// Обновляет фильтр избранного
  void updateFavorite(bool? isFavorite) {
    logDebug('BaseFilterNotifier: Обновление фильтра избранного: $isFavorite');
    state = state.copyWith(isFavorite: isFavorite);
  }

  /// Обновляет фильтр архивных элементов
  void updateArchived(bool? isArchived) {
    logDebug('BaseFilterNotifier: Обновление фильтра архивных: $isArchived');
    state = state.copyWith(isArchived: isArchived);
  }

  /// Обновляет фильтр наличия заметок
  void updateHasNotes(bool? hasNotes) {
    logDebug('BaseFilterNotifier: Обновление фильтра заметок: $hasNotes');
    state = state.copyWith(hasNotes: hasNotes);
  }

  /// Обновляет диапазон дат создания
  void updateCreatedDateRange(DateTime? after, DateTime? before) {
    logDebug(
      'BaseFilterNotifier: Обновление диапазона дат создания: $after - $before',
    );
    state = state.copyWith(createdAfter: after, createdBefore: before);
  }

  /// Обновляет диапазон дат изменения
  void updateModifiedDateRange(DateTime? after, DateTime? before) {
    logDebug(
      'BaseFilterNotifier: Обновление диапазона дат изменения: $after - $before',
    );
    state = state.copyWith(modifiedAfter: after, modifiedBefore: before);
  }

  /// Обновляет диапазон дат последнего доступа
  void updateLastAccessedDateRange(DateTime? after, DateTime? before) {
    logDebug(
      'BaseFilterNotifier: Обновление диапазона дат доступа: $after - $before',
    );
    state = state.copyWith(
      lastAccessedAfter: after,
      lastAccessedBefore: before,
    );
  }

  /// Обновляет направление сортировки
  void updateSortDirection(SortDirection direction) {
    logDebug(
      'BaseFilterNotifier: Обновление направления сортировки: $direction',
    );
    state = state.copyWith(sortDirection: direction);
  }

  /// Обновляет лимит и смещение для пагинации
  void updatePagination({int? limit, int? offset}) {
    logDebug(
      'BaseFilterNotifier: Обновление пагинации: limit=$limit, offset=$offset',
    );
    state = state.copyWith(limit: limit, offset: offset);
  }

  /// Сбрасывает фильтр к начальному состоянию
  void reset() {
    logDebug('BaseFilterNotifier: Сброс фильтра');
    state = const BaseFilter();
  }

  /// Применяет новый фильтр
  void applyFilter(BaseFilter filter) {
    logDebug('BaseFilterNotifier: Применение нового фильтра');
    state = filter;
  }

  /// Проверяет, есть ли активные ограничения
  bool get hasActiveConstraints => state.hasActiveConstraints;
}
