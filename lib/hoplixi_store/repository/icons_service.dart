import 'dart:typed_data';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/dao/icons_dao.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'service_results.dart';

/// Сервис для работы с иконками в UI
class IconsService {
  final IconsDao _iconsDao;

  IconsService(this._iconsDao);

  /// Создание новой иконки с валидацией
  Future<IconResult> createIcon({
    required String name,
    required IconType type,
    required Uint8List data,
  }) async {
    try {
      logDebug(
        'Создание иконки',
        tag: 'IconsService',
        data: {'name': name, 'type': type.name, 'size': data.length},
      );

      // Валидация имени
      if (name.trim().isEmpty) {
        return IconResult.error('Имя иконки не может быть пустым');
      }

      if (name.length > 100) {
        return IconResult.error(
          'Имя иконки слишком длинное (максимум 100 символов)',
        );
      }

      // Валидация размера файла (максимум 1 МБ)
      if (data.length > 1024 * 1024) {
        return IconResult.error(
          'Размер иконки слишком большой (максимум 1 МБ)',
        );
      }

      // Проверка существования иконки с таким именем
      final exists = await _iconsDao.iconExists(name.trim());
      if (exists) {
        return IconResult.error('Иконка с таким именем уже существует');
      }

      // Создание DTO
      final dto = CreateIconDto(name: name.trim(), type: type, data: data);

      final iconId = await _iconsDao.createIcon(dto);

      logDebug(
        'Иконка создана',
        tag: 'IconsService',
        data: {'id': iconId, 'name': name},
      );

      return IconResult.success(
        iconId: iconId,
        message: 'Иконка "$name" успешно создана',
      );
    } catch (e, s) {
      logError(
        'Ошибка создания иконки',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'name': name},
      );
      return IconResult.error('Ошибка создания иконки: ${e.toString()}');
    }
  }

  /// Обновление иконки с валидацией
  Future<IconResult> updateIcon({
    required String id,
    String? name,
    IconType? type,
    Uint8List? data,
  }) async {
    try {
      logDebug('Обновление иконки', tag: 'IconsService', data: {'id': id});

      // Проверка существования иконки
      final existingIcon = await _iconsDao.getIconById(id);
      if (existingIcon == null) {
        return IconResult.error('Иконка не найдена');
      }

      // Валидация имени, если оно изменяется
      if (name != null) {
        if (name.trim().isEmpty) {
          return IconResult.error('Имя иконки не может быть пустым');
        }

        if (name.length > 100) {
          return IconResult.error(
            'Имя иконки слишком длинное (максимум 100 символов)',
          );
        }

        // Проверка уникальности имени (исключая текущую иконку)
        final exists = await _iconsDao.iconExists(name.trim(), excludeId: id);
        if (exists) {
          return IconResult.error('Иконка с таким именем уже существует');
        }
      }

      // Валидация размера данных
      if (data != null && data.length > 1024 * 1024) {
        return IconResult.error(
          'Размер иконки слишком большой (максимум 1 МБ)',
        );
      }

      // Создание DTO
      final dto = UpdateIconDto(
        id: id,
        name: name?.trim(),
        type: type,
        data: data,
      );

      final success = await _iconsDao.updateIcon(dto);
      if (!success) {
        return IconResult.error('Не удалось обновить иконку');
      }

      logDebug('Иконка обновлена', tag: 'IconsService', data: {'id': id});

      return IconResult.success(
        iconId: id,
        message: 'Иконка успешно обновлена',
      );
    } catch (e, s) {
      logError(
        'Ошибка обновления иконки',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'id': id},
      );
      return IconResult.error('Ошибка обновления иконки: ${e.toString()}');
    }
  }

  /// Удаление иконки с проверками
  Future<IconResult> deleteIcon(String id) async {
    try {
      logDebug('Удаление иконки', tag: 'IconsService', data: {'id': id});

      // Проверка существования иконки
      final icon = await _iconsDao.getIconById(id);
      if (icon == null) {
        return IconResult.error('Иконка не найдена');
      }

      // TODO: Проверить, используется ли иконка в категориях
      // Здесь можно добавить проверку на использование иконки

      final success = await _iconsDao.deleteIcon(id);
      if (!success) {
        return IconResult.error('Не удалось удалить иконку');
      }

      logDebug(
        'Иконка удалена',
        tag: 'IconsService',
        data: {'id': id, 'name': icon.name},
      );

      return IconResult.success(
        message: 'Иконка "${icon.name}" успешно удалена',
      );
    } catch (e, s) {
      logError(
        'Ошибка удаления иконки',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'id': id},
      );
      return IconResult.error('Ошибка удаления иконки: ${e.toString()}');
    }
  }

  /// Получение иконки по ID
  Future<IconData?> getIcon(String id) async {
    try {
      return await _iconsDao.getIconById(id);
    } catch (e, s) {
      logError(
        'Ошибка получения иконки',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'id': id},
      );
      return null;
    }
  }

  /// Получение всех иконок
  Future<List<IconData>> getAllIcons() async {
    try {
      return await _iconsDao.getAllIcons();
    } catch (e, s) {
      logError(
        'Ошибка получения всех иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
      );
      return [];
    }
  }

  /// Получение иконок по типу
  Future<List<IconData>> getIconsByType(IconType type) async {
    try {
      return await _iconsDao.getIconsByType(type);
    } catch (e, s) {
      logError(
        'Ошибка получения иконок по типу',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'type': type.name},
      );
      return [];
    }
  }

  /// Поиск иконок
  Future<List<IconData>> searchIcons(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllIcons();
      }
      return await _iconsDao.searchIcons(query.trim());
    } catch (e, s) {
      logError(
        'Ошибка поиска иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'query': query},
      );
      return [];
    }
  }

  /// Получение статистики иконок
  Future<Map<String, dynamic>> getIconsStats() async {
    try {
      final total = await _iconsDao.getIconsCount();
      final byType = await _iconsDao.getIconsCountByType();
      final totalSize = await _iconsDao.getTotalIconsSize();

      return {
        'total': total,
        'byType': byType,
        'totalSize': totalSize,
        'averageSize': total > 0 ? (totalSize / total).round() : 0,
      };
    } catch (e, s) {
      logError(
        'Ошибка получения статистики иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
      );
      return {
        'total': 0,
        'byType': <String, int>{},
        'totalSize': 0,
        'averageSize': 0,
      };
    }
  }

  /// Получение крупных иконок
  Future<List<IconWithSize>> getLargeIcons({
    int sizeInBytes = 100 * 1024,
  }) async {
    try {
      return await _iconsDao.getIconsLargerThan(sizeInBytes);
    } catch (e, s) {
      logError(
        'Ошибка получения крупных иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'sizeLimit': sizeInBytes},
      );
      return [];
    }
  }

  /// Получение иконок с информацией об использовании
  Future<List<IconWithUsage>> getIconsWithUsage() async {
    try {
      return await _iconsDao.getIconsWithUsage();
    } catch (e, s) {
      logError(
        'Ошибка получения иконок с информацией об использовании',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
      );
      return [];
    }
  }

  /// Получение неиспользуемых иконок
  Future<List<IconData>> getUnusedIcons() async {
    try {
      return await _iconsDao.getUnusedIcons();
    } catch (e, s) {
      logError(
        'Ошибка получения неиспользуемых иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
      );
      return [];
    }
  }

  /// Очистка неиспользуемых иконок
  Future<IconResult> cleanupUnusedIcons() async {
    try {
      logDebug('Очистка неиспользуемых иконок', tag: 'IconsService');

      final deletedCount = await _iconsDao.cleanupUnusedIcons();

      logDebug(
        'Очистка неиспользуемых иконок завершена',
        tag: 'IconsService',
        data: {'deletedCount': deletedCount},
      );

      return IconResult.success(
        message: deletedCount > 0
            ? 'Удалено $deletedCount неиспользуемых иконок'
            : 'Неиспользуемые иконки не найдены',
      );
    } catch (e, s) {
      logError(
        'Ошибка очистки неиспользуемых иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
      );
      return IconResult.error('Ошибка очистки иконок: ${e.toString()}');
    }
  }

  /// Stream для наблюдения за всеми иконками
  Stream<List<IconData>> watchAllIcons() {
    return _iconsDao.watchAllIcons();
  }

  /// Stream для наблюдения за иконками по типу
  Stream<List<IconData>> watchIconsByType(IconType type) {
    return _iconsDao.watchIconsByType(type);
  }

  /// Массовое создание иконок
  Future<IconResult> createIconsBatch(
    List<Map<String, dynamic>> iconsData,
  ) async {
    try {
      logDebug(
        'Массовое создание иконок',
        tag: 'IconsService',
        data: {'count': iconsData.length},
      );

      final dtos = <CreateIconDto>[];

      for (final data in iconsData) {
        // Валидация каждой иконки
        final name = data['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          return IconResult.error('Одна из иконок имеет пустое имя');
        }

        if (name.length > 100) {
          return IconResult.error('Имя иконки "$name" слишком длинное');
        }

        final iconData = data['data'] as Uint8List?;
        if (iconData == null) {
          return IconResult.error('Отсутствуют данные для иконки "$name"');
        }

        if (iconData.length > 1024 * 1024) {
          return IconResult.error('Иконка "$name" слишком большая');
        }

        // Проверка уникальности
        final exists = await _iconsDao.iconExists(name.trim());
        if (exists) {
          return IconResult.error('Иконка "$name" уже существует');
        }

        dtos.add(
          CreateIconDto(
            name: name.trim(),
            type: data['type'] as IconType? ?? IconType.png,
            data: iconData,
          ),
        );
      }

      await _iconsDao.createIconsBatch(dtos);

      logDebug(
        'Массовое создание иконок завершено',
        tag: 'IconsService',
        data: {'count': dtos.length},
      );

      return IconResult.success(
        message: 'Успешно создано ${dtos.length} иконок',
      );
    } catch (e, s) {
      logError(
        'Ошибка массового создания иконок',
        error: e,
        stackTrace: s,
        tag: 'IconsService',
        data: {'count': iconsData.length},
      );
      return IconResult.error(
        'Ошибка массового создания иконок: ${e.toString()}',
      );
    }
  }

  /// Валидация данных иконки
  IconResult validateIconData({
    required String name,
    required IconType type,
    required Uint8List data,
  }) {
    if (name.trim().isEmpty) {
      return IconResult.error('Имя иконки не может быть пустым');
    }

    if (name.length > 100) {
      return IconResult.error(
        'Имя иконки слишком длинное (максимум 100 символов)',
      );
    }

    if (data.isEmpty) {
      return IconResult.error('Данные иконки не могут быть пустыми');
    }

    if (data.length > 1024 * 1024) {
      return IconResult.error('Размер иконки слишком большой (максимум 1 МБ)');
    }

    return IconResult.success(message: 'Данные иконки корректны');
  }

  /// Получение размера файла в удобочитаемом формате
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
