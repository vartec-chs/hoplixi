import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/repository/tags_service.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Состояние управления тегами
class TagsManagementState {
  final List<Tag> tags;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final String searchQuery;
  final TagType? filterType;
  final String sortBy;
  final bool isAscending;
  final bool hasMore;

  const TagsManagementState({
    this.tags = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.searchQuery = '',
    this.filterType,
    this.sortBy = 'name',
    this.isAscending = true,
    this.hasMore = false,
  });

  TagsManagementState copyWith({
    List<Tag>? tags,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    String? searchQuery,
    TagType? filterType,
    String? sortBy,
    bool? isAscending,
    bool? hasMore,
    bool clearError = false,
    bool clearFilterType = false,
  }) {
    return TagsManagementState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Провайдер сервиса тегов

/// Контроллер управления тегами
class TagsManagementNotifier extends Notifier<TagsManagementState> {
  late TagsService _tagsService;

  @override
  TagsManagementState build() {
    _tagsService = ref.read(tagsServiceProvider);
    // Не вызываем loadTags в build - это приведет к "Build scheduled during frame"
    // Вместо этого инициализируем загрузку через Future.microtask
    Future.microtask(() => loadTags());
    return const TagsManagementState();
  }

  /// Загрузка тегов с учетом текущих фильтров
  Future<void> loadTags({bool append = false}) async {
    if (state.isLoading && !append) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final page = append ? state.currentPage + 1 : 1;

      final result = await _tagsService.getTagsPaginated(
        page: page,
        pageSize: state.pageSize,
        orderBy: state.sortBy,
        ascending: state.isAscending,
        type: state.filterType,
        searchTerm: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      final newTags = append ? [...state.tags, ...result.tags] : result.tags;

      state = state.copyWith(
        tags: newTags,
        isLoading: false,
        currentPage: page,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки тегов: ${e.toString()}',
      );
    }
  }

  /// Поиск тегов
  Future<void> searchTags(String query) async {
    if (query == state.searchQuery) return;

    state = state.copyWith(searchQuery: query, currentPage: 1, tags: []);

    await loadTags();
  }

  /// Фильтрация по типу
  Future<void> filterByType(TagType? type) async {
    if (type == state.filterType) return;

    state = state.copyWith(
      filterType: type,
      currentPage: 1,
      tags: [],
      clearFilterType: type == null,
    );

    await loadTags();
  }

  /// Сортировка
  Future<void> sort(String sortBy, {bool? ascending}) async {
    final isAsc =
        ascending ?? (sortBy == state.sortBy ? !state.isAscending : true);

    if (sortBy == state.sortBy && isAsc == state.isAscending) return;

    state = state.copyWith(
      sortBy: sortBy,
      isAscending: isAsc,
      currentPage: 1,
      tags: [],
    );

    await loadTags();
  }

  /// Загрузка следующей страницы
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadTags(append: true);
  }

  /// Обновление списка
  Future<void> refresh() async {
    state = state.copyWith(currentPage: 1, tags: []);
    await loadTags();
  }

  /// Создание тега
  Future<bool> createTag({
    required String name,
    String? color,
    required TagType type,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      final result = await _tagsService.createTag(
        name: name,
        color: color,
        type: type,
      );

      if (result.success) {
        await refresh();
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка создания тега: ${e.toString()}');
      return false;
    }
  }

  /// Обновление тега
  Future<bool> updateTag({
    required String id,
    String? name,
    String? color,
    TagType? type,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      final result = await _tagsService.updateTag(
        id: id,
        name: name,
        color: color,
        type: type,
      );

      if (result.success) {
        await refresh();
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Ошибка обновления тега: ${e.toString()}');
      return false;
    }
  }

  /// Удаление тега
  Future<bool> deleteTag(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _tagsService.deleteTag(id);

      if (result.success) {
        // Удаляем тег из текущего списка без полной перезагрузки
        final updatedTags = state.tags.where((tag) => tag.id != id).toList();
        state = state.copyWith(
          tags: updatedTags,
          isLoading: false,
          totalCount: state.totalCount - 1,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка удаления тега: ${e.toString()}',
      );
      return false;
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Провайдер контроллера управления тегами
final tagsManagementProvider =
    NotifierProvider<TagsManagementNotifier, TagsManagementState>(() {
      return TagsManagementNotifier();
    });
