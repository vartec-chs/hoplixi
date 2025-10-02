import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services/categories_service.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';

/// Состояние экрана управления категориями
class CategoriesManagerState {
  final List<Category> categories;
  final PaginationInfo? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String searchQuery;
  final CategoryType? selectedType;
  final bool isCreating;
  final bool isUpdating;
  final CategorySortBy sortBy;
  final bool ascending;
  final int pageSize;

  const CategoriesManagerState({
    this.categories = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery = '',
    this.selectedType,
    this.isCreating = false,
    this.isUpdating = false,
    this.sortBy = CategorySortBy.name,
    this.ascending = true,
    this.pageSize = 20,
  });

  CategoriesManagerState copyWith({
    List<Category>? categories,
    PaginationInfo? pagination,
    bool clearPagination = false,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    String? searchQuery,
    CategoryType? selectedType,
    bool clearSelectedType = false,
    bool? isCreating,
    bool? isUpdating,
    CategorySortBy? sortBy,
    bool? ascending,
    int? pageSize,
  }) {
    return CategoriesManagerState(
      categories: categories ?? this.categories,
      pagination: clearPagination ? null : (pagination ?? this.pagination),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Получение текущей страницы
  int get currentPage => pagination?.currentPage ?? 1;

  /// Есть ли следующая страница
  bool get hasNextPage => pagination?.hasNextPage ?? false;

  /// Есть ли предыдущая страница
  bool get hasPreviousPage => pagination?.hasPreviousPage ?? false;

  /// Общее количество элементов
  int get totalItems => pagination?.totalItems ?? 0;

  /// Общее количество страниц
  int get totalPages => pagination?.totalPages ?? 0;
}

/// Контроллер для управления категориями
class CategoriesManagerController
    extends StateNotifier<CategoriesManagerState> {
  final CategoriesService _categoriesService;

  CategoriesManagerController(this._categoriesService)
    : super(const CategoriesManagerState()) {
    _loadCategories();
  }

  /// Загрузка категорий с пагинацией
  Future<void> _loadCategories({int page = 1, bool append = false}) async {
    if (append && !state.hasNextPage) return;

    if (append) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      PaginatedCategoriesResult result;

      if (state.searchQuery.isNotEmpty) {
        result = await _categoriesService.searchCategoriesPaginated(
          searchTerm: state.searchQuery,
          page: page,
          pageSize: state.pageSize,
          sortBy: state.sortBy,
          ascending: state.ascending,
        );
      } else if (state.selectedType != null) {
        result = await _categoriesService.getCategoriesByTypePaginated(
          type: state.selectedType!,
          page: page,
          pageSize: state.pageSize,
          sortBy: state.sortBy,
          ascending: state.ascending,
        );
      } else {
        result = await _categoriesService.getCategoriesPaginated(
          page: page,
          pageSize: state.pageSize,
          sortBy: state.sortBy,
          ascending: state.ascending,
        );
      }

      final newCategories = append
          ? [...state.categories, ...result.categories]
          : result.categories;

      state = state.copyWith(
        categories: newCategories,
        pagination: result.pagination,
        isLoading: false,
        isLoadingMore: false,
      );

      logDebug(
        'Категории загружены',
        tag: 'CategoriesManagerController',
        data: {
          'count': result.categories.length,
          'total': result.pagination.totalItems,
          'page': page,
          'append': append,
          'hasFilter': state.selectedType != null,
          'hasSearch': state.searchQuery.isNotEmpty,
        },
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoriesManagerController',
      );

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Ошибка загрузки категорий: ${e.toString()}',
      );
    }
  }

  /// Загрузка следующей страницы
  Future<void> loadNextPage() async {
    if (state.hasNextPage && !state.isLoadingMore) {
      await _loadCategories(page: state.currentPage + 1, append: true);
    }
  }

  /// Обновление сортировки
  Future<void> updateSorting({CategorySortBy? sortBy, bool? ascending}) async {
    state = state.copyWith(
      sortBy: sortBy,
      ascending: ascending,
      clearPagination: true,
    );
    await _loadCategories();
  }

  /// Изменение размера страницы
  Future<void> changePageSize(int newPageSize) async {
    if (newPageSize != state.pageSize) {
      state = state.copyWith(pageSize: newPageSize, clearPagination: true);
      await _loadCategories();
    }
  }

  /// Поиск категорий
  Future<void> searchCategories(String query) async {
    state = state.copyWith(searchQuery: query, clearPagination: true);
    await _loadCategories();
  }

  /// Фильтрация по типу
  Future<void> filterByType(CategoryType? type) async {
    state = state.copyWith(
      selectedType: type,
      clearSelectedType: type == null,
      clearPagination: true,
    );
    await _loadCategories();
  }

  /// Очистка фильтров
  Future<void> clearFilters() async {
    state = state.copyWith(
      searchQuery: '',
      clearSelectedType: true,
      clearPagination: true,
    );
    await _loadCategories();
  }

  /// Создание новой категории
  Future<bool> createCategory({
    required String name,
    String? description,
    String? iconId,
    required String color,
    required CategoryType type,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);

    try {
      logDebug(
        'Создание категории: $name, $description, $iconId, $color, $type',
        tag: 'CategoriesManagerController',
      );
      final result = await _categoriesService.createCategory(
        name: name,
        description: description,
        iconId: iconId,
        color: color,
        type: type,
      );

      if (result.success) {
        logInfo(
          'Категория создана успешно',
          tag: 'CategoriesManagerController',
          data: {'name': name, 'categoryId': result.categoryId},
        );

        state = state.copyWith(isCreating: false);
        await _loadCategories(); // Перезагружаем список
        return true;
      } else {
        state = state.copyWith(
          isCreating: false,
          error: result.message ?? 'Ошибка создания категории',
        );
        return false;
      }
    } catch (e, s) {
      logError(
        'Ошибка создания категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesManagerController',
        data: {'name': name},
      );

      state = state.copyWith(
        isCreating: false,
        error: 'Ошибка создания категории: ${e.toString()}',
      );
      return false;
    }
  }

  /// Обновление категории
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    String? iconId,
    String? color,
    CategoryType? type,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      logDebug(
        'Обновление категории: $name, $description, $iconId, $color, $type',
        tag: 'CategoriesManagerController',
      );
      final result = await _categoriesService.updateCategory(
        id: id,
        name: name,
        description: description,
        iconId: iconId,
        color: color,
        type: type,
      );

      if (result.success) {
        logInfo(
          'Категория обновлена успешно',
          tag: 'CategoriesManagerController',
          data: {'id': id},
        );

        state = state.copyWith(isUpdating: false);
        await _loadCategories(); // Перезагружаем список
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.message ?? 'Ошибка обновления категории',
        );
        return false;
      }
    } catch (e, s) {
      logError(
        'Ошибка обновления категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesManagerController',
        data: {'id': id},
      );

      state = state.copyWith(
        isUpdating: false,
        error: 'Ошибка обновления категории: ${e.toString()}',
      );
      return false;
    }
  }

  /// Удаление категории
  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _categoriesService.deleteCategory(id);

      if (result.success) {
        logInfo(
          'Категория удалена успешно',
          tag: 'CategoriesManagerController',
          data: {'id': id},
        );

        await _loadCategories(); // Перезагружаем список
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message ?? 'Ошибка удаления категории',
        );
        return false;
      }
    } catch (e, s) {
      logError(
        'Ошибка удаления категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesManagerController',
        data: {'id': id},
      );

      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка удаления категории: ${e.toString()}',
      );
      return false;
    }
  }

  /// Обновление списка категорий
  Future<void> refresh() async {
    await _loadCategories();
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Провайдер для контроллера управления категориями
final categoriesManagerControllerProvider =
    StateNotifierProvider<CategoriesManagerController, CategoriesManagerState>((
      ref,
    ) {
      final categoriesService = ref.watch(categoriesServiceProvider);
      return CategoriesManagerController(categoriesService);
    });

/// Провайдеры для удобного доступа к состоянию
final categoriesListProvider = Provider<List<Category>>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.categories;
});

final categoriesLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.isLoading;
});

final categoriesErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.error;
});

final categoriesSearchQueryProvider = Provider<String>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.searchQuery;
});

final categoriesSelectedTypeProvider = Provider<CategoryType?>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.selectedType;
});

final categoriesCreatingProvider = Provider<bool>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.isCreating;
});

final categoriesUpdatingProvider = Provider<bool>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.isUpdating;
});

final categoriesPaginationProvider = Provider<PaginationInfo?>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.pagination;
});

final categoriesLoadingMoreProvider = Provider<bool>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.isLoadingMore;
});

final categoriesHasNextPageProvider = Provider<bool>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.hasNextPage;
});

final categoriesSortingProvider =
    Provider<({CategorySortBy sortBy, bool ascending})>((ref) {
      final state = ref.watch(categoriesManagerControllerProvider);
      return (sortBy: state.sortBy, ascending: state.ascending);
    });

final categoriesPageSizeProvider = Provider<int>((ref) {
  final state = ref.watch(categoriesManagerControllerProvider);
  return state.pageSize;
});
