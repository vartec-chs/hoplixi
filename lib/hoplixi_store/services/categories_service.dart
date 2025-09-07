import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'service_results.dart';

/// Сервис для работы с категориями в UI
class CategoriesService {
  final CategoriesDao _categoriesDao;

  CategoriesService(this._categoriesDao);

  /// Создание новой категории с валидацией
  Future<CategoryResult> createCategory({
    required String name,
    String? description,
    String? iconId,
    required String color,
    required CategoryType type,
  }) async {
    try {
      logDebug(
        'Создание категории',
        tag: 'CategoriesService',
        data: {'name': name, 'type': type.name},
      );

      // Валидация имени
      if (name.trim().isEmpty) {
        return CategoryResult.error('Имя категории не может быть пустым');
      }

      if (name.length > 100) {
        return CategoryResult.error('Имя категории слишком длинное (максимум 100 символов)');
      }

      // Проверка существования категории с таким именем
      final exists = await _categoriesDao.categoryExists(name.trim());
      if (exists) {
        return CategoryResult.error('Категория с таким именем уже существует');
      }

      // Создание DTO
      final dto = CreateCategoryDto(
        name: name.trim(),
        description: description?.trim(),
        iconId: iconId,
        color: color,
        type: type,
      );

      final categoryId = await _categoriesDao.createCategory(dto);
      final category = await _categoriesDao.getCategoryById(categoryId);

      logDebug(
        'Категория создана',
        tag: 'CategoriesService',
        data: {'id': categoryId, 'name': name},
      );

      return CategoryResult.success(
        categoryId: categoryId,
        message: 'Категория "$name" успешно создана',
      );
    } catch (e, s) {
      logError(
        'Ошибка создания категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'name': name},
      );
      return CategoryResult.error('Ошибка создания категории: ${e.toString()}');
    }
  }

  /// Обновление категории с валидацией
  Future<CategoryResult> updateCategory({
    required String id,
    String? name,
    String? description,
    String? iconId,
    String? color,
    CategoryType? type,
  }) async {
    try {
      logDebug(
        'Обновление категории',
        tag: 'CategoriesService',
        data: {'id': id},
      );

      // Проверка существования категории
      final existingCategory = await _categoriesDao.getCategoryById(id);
      if (existingCategory == null) {
        return CategoryResult.error('Категория не найдена');
      }

      // Валидация имени, если оно изменяется
      if (name != null) {
        if (name.trim().isEmpty) {
          return CategoryResult.error('Имя категории не может быть пустым');
        }

        if (name.length > 100) {
          return CategoryResult.error('Имя категории слишком длинное (максимум 100 символов)');
        }

        // Проверка уникальности имени (исключая текущую категорию)
        final exists = await _categoriesDao.categoryExists(name.trim(), excludeId: id);
        if (exists) {
          return CategoryResult.error('Категория с таким именем уже существует');
        }
      }

      // Создание DTO
      final dto = UpdateCategoryDto(
        id: id,
        name: name?.trim(),
        description: description?.trim(),
        iconId: iconId,
        color: color,
        type: type,
      );

      final success = await _categoriesDao.updateCategory(dto);
      if (!success) {
        return CategoryResult.error('Не удалось обновить категорию');
      }

      final updatedCategory = await _categoriesDao.getCategoryById(id);

      logDebug(
        'Категория обновлена',
        tag: 'CategoriesService',
        data: {'id': id},
      );

      return CategoryResult.success(
        categoryId: id,
        category: updatedCategory,
        message: 'Категория успешно обновлена',
      );
    } catch (e, s) {
      logError(
        'Ошибка обновления категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'id': id},
      );
      return CategoryResult.error('Ошибка обновления категории: ${e.toString()}');
    }
  }

  /// Удаление категории с проверками
  Future<CategoryResult> deleteCategory(String id) async {
    try {
      logDebug(
        'Удаление категории',
        tag: 'CategoriesService',
        data: {'id': id},
      );

      // Проверка существования категории
      final category = await _categoriesDao.getCategoryById(id);
      if (category == null) {
        return CategoryResult.error('Категория не найдена');
      }

      // TODO: Добавить проверку на использование категории в других записях
      // Здесь можно добавить логику проверки, есть ли пароли/заметки/TOTP в этой категории

      final success = await _categoriesDao.deleteCategory(id);
      if (!success) {
        return CategoryResult.error('Не удалось удалить категорию');
      }

      logDebug(
        'Категория удалена',
        tag: 'CategoriesService',
        data: {'id': id, 'name': category.name},
      );

      return CategoryResult.success(
        message: 'Категория "${category.name}" успешно удалена',
      );
    } catch (e, s) {
      logError(
        'Ошибка удаления категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'id': id},
      );
      return CategoryResult.error('Ошибка удаления категории: ${e.toString()}');
    }
  }

  /// Получение категории по ID
  Future<Category?> getCategory(String id) async {
    try {
      return await _categoriesDao.getCategoryById(id);
    } catch (e, s) {
      logError(
        'Ошибка получения категории',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'id': id},
      );
      return null;
    }
  }

  /// Получение всех категорий
  Future<List<Category>> getAllCategories() async {
    try {
      return await _categoriesDao.getAllCategories();
    } catch (e, s) {
      logError(
        'Ошибка получения всех категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
      );
      return [];
    }
  }

  /// Получение категорий по типу
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    try {
      return await _categoriesDao.getCategoriesByType(type);
    } catch (e, s) {
      logError(
        'Ошибка получения категорий по типу',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'type': type.name},
      );
      return [];
    }
  }

  /// Поиск категорий
  Future<List<Category>> searchCategories(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllCategories();
      }
      return await _categoriesDao.searchCategories(query.trim());
    } catch (e, s) {
      logError(
        'Ошибка поиска категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'query': query},
      );
      return [];
    }
  }

  /// Получение категорий с подсчетом элементов
  Future<List<CategoryWithItemCount>> getCategoriesWithItemCount(CategoryType type) async {
    try {
      return await _categoriesDao.getCategoriesWithItemCount(type);
    } catch (e, s) {
      logError(
        'Ошибка получения категорий с подсчетом элементов',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'type': type.name},
      );
      return [];
    }
  }

  /// Получение статистики категорий
  Future<Map<String, dynamic>> getCategoriesStats() async {
    try {
      final total = await _categoriesDao.getCategoriesCount();
      final byType = await _categoriesDao.getCategoriesCountByType();
      
      return {
        'total': total,
        'byType': byType,
      };
    } catch (e, s) {
      logError(
        'Ошибка получения статистики категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
      );
      return {
        'total': 0,
        'byType': <String, int>{},
      };
    }
  }

  /// Stream для наблюдения за всеми категориями
  Stream<List<Category>> watchAllCategories() {
    return _categoriesDao.watchAllCategories();
  }

  /// Stream для наблюдения за категориями по типу
  Stream<List<Category>> watchCategoriesByType(CategoryType type) {
    return _categoriesDao.watchCategoriesByType(type);
  }

  /// Массовое создание категорий
  Future<CategoryResult> createCategoriesBatch(List<Map<String, dynamic>> categoriesData) async {
    try {
      logDebug(
        'Массовое создание категорий',
        tag: 'CategoriesService',
        data: {'count': categoriesData.length},
      );

      final dtos = <CreateCategoryDto>[];
      
      for (final data in categoriesData) {
        // Валидация каждой категории
        final name = data['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          return CategoryResult.error('Одна из категорий имеет пустое имя');
        }

        if (name.length > 100) {
          return CategoryResult.error('Имя категории "$name" слишком длинное');
        }

        // Проверка уникальности
        final exists = await _categoriesDao.categoryExists(name.trim());
        if (exists) {
          return CategoryResult.error('Категория "$name" уже существует');
        }

        dtos.add(CreateCategoryDto(
          name: name.trim(),
          description: (data['description'] as String?)?.trim(),
          iconId: data['iconId'] as String?,
          color: data['color'] as String? ?? '#2196F3',
          type: data['type'] as CategoryType? ?? CategoryType.mixed,
        ));
      }

      await _categoriesDao.createCategoriesBatch(dtos);

      logDebug(
        'Массовое создание категорий завершено',
        tag: 'CategoriesService',
        data: {'count': dtos.length},
      );

      return CategoryResult.success(
        message: 'Успешно создано ${dtos.length} категорий',
      );
    } catch (e, s) {
      logError(
        'Ошибка массового создания категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoriesService',
        data: {'count': categoriesData.length},
      );
      return CategoryResult.error('Ошибка массового создания категорий: ${e.toString()}');
    }
  }

  /// Валидация данных категории
  CategoryResult validateCategoryData({
    required String name,
    String? description,
    required CategoryType type,
  }) {
    if (name.trim().isEmpty) {
      return CategoryResult.error('Имя категории не может быть пустым');
    }

    if (name.length > 100) {
      return CategoryResult.error('Имя категории слишком длинное (максимум 100 символов)');
    }

    if (description != null && description.length > 500) {
      return CategoryResult.error('Описание категории слишком длинное (максимум 500 символов)');
    }

    return CategoryResult.success(message: 'Данные категории корректны');
  }
}
