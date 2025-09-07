import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/dao/tags_dao.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'service_results.dart';

/// Сервис для работы с тегами в UI
class TagsService {
  final TagsDao _tagsDao;

  TagsService(this._tagsDao);

  /// Создание нового тега с валидацией
  Future<TagResult> createTag({
    required String name,
    String? color,
    required TagType type,
  }) async {
    try {
      logDebug(
        'Создание тега',
        tag: 'TagsService',
        data: {'name': name, 'type': type.name},
      );

      // Валидация имени
      if (name.trim().isEmpty) {
        return TagResult.error('Имя тега не может быть пустым');
      }

      if (name.length > 50) {
        return TagResult.error(
          'Имя тега слишком длинное (максимум 50 символов)',
        );
      }

      // Валидация цвета
      if (color != null && !_isValidColor(color)) {
        return TagResult.error('Неверный формат цвета');
      }

      // Проверка существования тега с таким именем
      final exists = await _tagsDao.tagExists(name.trim());
      if (exists) {
        return TagResult.error('Тег с таким именем уже существует');
      }

      // Создание DTO
      final dto = CreateTagDto(name: name.trim(), color: color, type: type);

      final tagId = await _tagsDao.createTag(dto);

      logDebug(
        'Тег создан',
        tag: 'TagsService',
        data: {'id': tagId, 'name': name},
      );

      return TagResult.success(
        tagId: tagId,
        message: 'Тег "$name" успешно создан',
      );
    } catch (e, s) {
      logError(
        'Ошибка создания тега',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'name': name},
      );
      return TagResult.error('Ошибка создания тега: ${e.toString()}');
    }
  }

  /// Обновление тега с валидацией
  Future<TagResult> updateTag({
    required String id,
    String? name,
    String? color,
    TagType? type,
  }) async {
    try {
      logDebug('Обновление тега', tag: 'TagsService', data: {'id': id});

      // Проверка существования тега
      final existingTag = await _tagsDao.getTagById(id);
      if (existingTag == null) {
        return TagResult.error('Тег не найден');
      }

      // Валидация имени, если оно изменяется
      if (name != null) {
        if (name.trim().isEmpty) {
          return TagResult.error('Имя тега не может быть пустым');
        }

        if (name.length > 50) {
          return TagResult.error(
            'Имя тега слишком длинное (максимум 50 символов)',
          );
        }

        // Проверка уникальности имени (исключая текущий тег)
        final exists = await _tagsDao.tagExists(name.trim(), excludeId: id);
        if (exists) {
          return TagResult.error('Тег с таким именем уже существует');
        }
      }

      // Валидация цвета
      if (color != null && !_isValidColor(color)) {
        return TagResult.error('Неверный формат цвета');
      }

      // Создание DTO
      final dto = UpdateTagDto(
        id: id,
        name: name?.trim(),
        color: color,
        type: type,
      );

      final success = await _tagsDao.updateTag(dto);
      if (!success) {
        return TagResult.error('Не удалось обновить тег');
      }

      logDebug('Тег обновлен', tag: 'TagsService', data: {'id': id});

      return TagResult.success(tagId: id, message: 'Тег успешно обновлен');
    } catch (e, s) {
      logError(
        'Ошибка обновления тега',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'id': id},
      );
      return TagResult.error('Ошибка обновления тега: ${e.toString()}');
    }
  }

  /// Удаление тега с проверками
  Future<TagResult> deleteTag(String id) async {
    try {
      logDebug('Удаление тега', tag: 'TagsService', data: {'id': id});

      // Проверка существования тега
      final tag = await _tagsDao.getTagById(id);
      if (tag == null) {
        return TagResult.error('Тег не найден');
      }

      // TODO: Добавить проверку на использование тега в записях
      // Здесь можно добавить логику проверки, используется ли тег

      final success = await _tagsDao.deleteTag(id);
      if (!success) {
        return TagResult.error('Не удалось удалить тег');
      }

      logDebug(
        'Тег удален',
        tag: 'TagsService',
        data: {'id': id, 'name': tag.name},
      );

      return TagResult.success(message: 'Тег "${tag.name}" успешно удален');
    } catch (e, s) {
      logError(
        'Ошибка удаления тега',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'id': id},
      );
      return TagResult.error('Ошибка удаления тега: ${e.toString()}');
    }
  }

  /// Получение тега по ID
  Future<Tag?> getTag(String id) async {
    try {
      return await _tagsDao.getTagById(id);
    } catch (e, s) {
      logError(
        'Ошибка получения тега',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'id': id},
      );
      return null;
    }
  }

  /// Получение всех тегов
  Future<List<Tag>> getAllTags() async {
    try {
      return await _tagsDao.getAllTags();
    } catch (e, s) {
      logError(
        'Ошибка получения всех тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
      );
      return [];
    }
  }

  /// Получение тегов по типу
  Future<List<Tag>> getTagsByType(TagType type) async {
    try {
      return await _tagsDao.getTagsByType(type);
    } catch (e, s) {
      logError(
        'Ошибка получения тегов по типу',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'type': type.name},
      );
      return [];
    }
  }

  /// Поиск тегов
  Future<List<Tag>> searchTags(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllTags();
      }
      return await _tagsDao.searchTags(query.trim());
    } catch (e, s) {
      logError(
        'Ошибка поиска тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'query': query},
      );
      return [];
    }
  }

  /// Получение тегов с подсчетом использования
  Future<List<TagWithUsageCount>> getTagsWithUsageCount(TagType type) async {
    try {
      return await _tagsDao.getTagsWithUsageCount(type);
    } catch (e, s) {
      logError(
        'Ошибка получения тегов с подсчетом использования',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'type': type.name},
      );
      return [];
    }
  }

  /// Получение популярных тегов
  Future<List<TagWithUsageCount>> getPopularTags({int limit = 10}) async {
    try {
      return await _tagsDao.getPopularTags(limit: limit);
    } catch (e, s) {
      logError(
        'Ошибка получения популярных тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'limit': limit},
      );
      return [];
    }
  }

  /// Получение неиспользуемых тегов
  Future<List<Tag>> getUnusedTags() async {
    try {
      return await _tagsDao.getUnusedTags();
    } catch (e, s) {
      logError(
        'Ошибка получения неиспользуемых тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
      );
      return [];
    }
  }

  /// Получение статистики тегов
  Future<Map<String, dynamic>> getTagsStats() async {
    try {
      final total = await _tagsDao.getTagsCount();
      final byType = await _tagsDao.getTagsCountByType();
      final popular = await getPopularTags(limit: 5);
      final unused = await getUnusedTags();

      return {
        'total': total,
        'byType': byType,
        'popular': popular
            .map(
              (t) => {
                'name': t.tag.name,
                'usage': t.usageCount,
                'color': t.tag.color,
              },
            )
            .toList(),
        'unusedCount': unused.length,
      };
    } catch (e, s) {
      logError(
        'Ошибка получения статистики тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
      );
      return {
        'total': 0,
        'byType': <String, int>{},
        'popular': <Map<String, dynamic>>[],
        'unusedCount': 0,
      };
    }
  }

  /// Stream для наблюдения за всеми тегами
  Stream<List<Tag>> watchAllTags() {
    return _tagsDao.watchAllTags();
  }

  /// Stream для наблюдения за тегами по типу
  Stream<List<Tag>> watchTagsByType(TagType type) {
    return _tagsDao.watchTagsByType(type);
  }

  /// Массовое создание тегов
  Future<TagResult> createTagsBatch(List<Map<String, dynamic>> tagsData) async {
    try {
      logDebug(
        'Массовое создание тегов',
        tag: 'TagsService',
        data: {'count': tagsData.length},
      );

      final dtos = <CreateTagDto>[];

      for (final data in tagsData) {
        // Валидация каждого тега
        final name = data['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          return TagResult.error('Один из тегов имеет пустое имя');
        }

        if (name.length > 50) {
          return TagResult.error('Имя тега "$name" слишком длинное');
        }

        final color = data['color'] as String?;
        if (color != null && !_isValidColor(color)) {
          return TagResult.error('Неверный формат цвета для тега "$name"');
        }

        // Проверка уникальности
        final exists = await _tagsDao.tagExists(name.trim());
        if (exists) {
          return TagResult.error('Тег "$name" уже существует');
        }

        dtos.add(
          CreateTagDto(
            name: name.trim(),
            color: color,
            type: data['type'] as TagType? ?? TagType.mixed,
          ),
        );
      }

      await _tagsDao.createTagsBatch(dtos);

      logDebug(
        'Массовое создание тегов завершено',
        tag: 'TagsService',
        data: {'count': dtos.length},
      );

      return TagResult.success(message: 'Успешно создано ${dtos.length} тегов');
    } catch (e, s) {
      logError(
        'Ошибка массового создания тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'count': tagsData.length},
      );
      return TagResult.error(
        'Ошибка массового создания тегов: ${e.toString()}',
      );
    }
  }

  /// Валидация данных тега
  TagResult validateTagData({
    required String name,
    String? color,
    required TagType type,
  }) {
    if (name.trim().isEmpty) {
      return TagResult.error('Имя тега не может быть пустым');
    }

    if (name.length > 50) {
      return TagResult.error('Имя тега слишком длинное (максимум 50 символов)');
    }

    if (color != null && !_isValidColor(color)) {
      return TagResult.error('Неверный формат цвета');
    }

    return TagResult.success(message: 'Данные тега корректны');
  }

  /// Получение предложений тегов на основе поиска
  Future<List<Tag>> getTagSuggestions(
    String query, {
    TagType? type,
    int limit = 10,
  }) async {
    try {
      if (query.trim().isEmpty) {
        // Возвращаем популярные теги
        final popular = await getPopularTags(limit: limit);
        final tags = popular.map((t) => t.tag).toList();

        if (type != null) {
          return tags
              .where((tag) => tag.type == type || tag.type == TagType.mixed)
              .toList();
        }
        return tags;
      }

      // Поиск тегов
      final searchResults = await searchTags(query);
      var filteredResults = searchResults;

      if (type != null) {
        filteredResults = searchResults
            .where((tag) => tag.type == type || tag.type == TagType.mixed)
            .toList();
      }

      return filteredResults.take(limit).toList();
    } catch (e, s) {
      logError(
        'Ошибка получения предложений тегов',
        error: e,
        stackTrace: s,
        tag: 'TagsService',
        data: {'query': query, 'type': type?.name},
      );
      return [];
    }
  }

  /// Получение цветов тегов по умолчанию
  List<String> getDefaultTagColors() {
    return [
      '#2196F3', // Синий
      '#4CAF50', // Зеленый
      '#FF9800', // Оранжевый
      '#F44336', // Красный
      '#9C27B0', // Фиолетовый
      '#607D8B', // Синий-серый
      '#795548', // Коричневый
      '#009688', // Бирюзовый
      '#E91E63', // Розовый
      '#3F51B5', // Индиго
      '#FFEB3B', // Желтый
      '#8BC34A', // Светло-зеленый
    ];
  }

  /// Получение случайного цвета для тега
  String getRandomTagColor() {
    final colors = getDefaultTagColors();
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  /// Валидация цвета (простая проверка HEX формата)
  bool _isValidColor(String color) {
    final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    return hexColorRegex.hasMatch(color);
  }
}
