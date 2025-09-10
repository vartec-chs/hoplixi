import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services/categories_service.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';

/// Состояние экрана управления категориями
class CategoriesManagerState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final CategoryType? selectedType;
  final bool isCreating;
  final bool isUpdating;

  const CategoriesManagerState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedType,
    this.isCreating = false,
    this.isUpdating = false,
  });

  CategoriesManagerState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    CategoryType? selectedType,
    bool clearSelectedType = false,
    bool? isCreating,
    bool? isUpdating,
  }) {
    return CategoriesManagerState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

/// Контроллер для управления категориями
class CategoriesManagerController
    extends StateNotifier<CategoriesManagerState> {
  final CategoriesService _categoriesService;

  CategoriesManagerController(this._categoriesService)
    : super(const CategoriesManagerState()) {
    _loadCategories();
  }

  /// Загрузка всех категорий
  Future<void> _loadCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      List<Category> categories;

      if (state.searchQuery.isNotEmpty) {
        categories = await _categoriesService.searchCategories(
          state.searchQuery,
        );
      } else if (state.selectedType != null) {
        categories = await _categoriesService.getCategoriesByType(
          state.selectedType!,
        );
      } else {
        categories = await _categoriesService.getAllCategories();
      }

      state = state.copyWith(categories: categories, isLoading: false);

      logDebug(
        'Категории загружены',
        tag: 'CategoriesManagerController',
        data: {
          'count': categories.length,
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
        error: 'Ошибка загрузки категорий: ${e.toString()}',
      );
    }
  }

  /// Поиск категорий
  Future<void> searchCategories(String query) async {
    state = state.copyWith(searchQuery: query);
    await _loadCategories();
  }

  /// Фильтрация по типу
  Future<void> filterByType(CategoryType? type) async {
    state = state.copyWith(selectedType: type, clearSelectedType: type == null);
    await _loadCategories();
  }

  /// Очистка фильтров
  Future<void> clearFilters() async {
    state = state.copyWith(searchQuery: '', clearSelectedType: true);
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
