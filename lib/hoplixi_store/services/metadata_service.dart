import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'package:hoplixi/hoplixi_store/dao/icons_dao.dart';
import 'package:hoplixi/hoplixi_store/dao/tags_dao.dart';
import 'categories_service.dart';
import 'icons_service.dart';
import 'tags_service.dart';

/// Главный сервис для работы с метаданными в UI
/// Предоставляет единый интерфейс для работы с категориями, иконками и тегами
class MetadataService {
  final CategoriesService _categoriesService;
  final IconsService _iconsService;
  final TagsService _tagsService;

  MetadataService._(
    this._categoriesService,
    this._iconsService,
    this._tagsService,
  );

  /// Фабричный метод для создания сервиса
  factory MetadataService.create(HoplixiStore database) {
    final categoriesDao = CategoriesDao(database);
    final iconsDao = IconsDao(database);
    final tagsDao = TagsDao(database);

    return MetadataService._(
      CategoriesService(categoriesDao),
      IconsService(iconsDao),
      TagsService(tagsDao),
    );
  }

  /// Геттер для доступа к сервису категорий
  CategoriesService get categories => _categoriesService;

  /// Геттер для доступа к сервису иконок
  IconsService get icons => _iconsService;

  /// Геттер для доступа к сервису тегов
  TagsService get tags => _tagsService;

  /// Получение общей статистики по всем метаданным
  Future<Map<String, dynamic>> getOverallStats() async {
    try {
      final categoriesStats = await _categoriesService.getCategoriesStats();
      final iconsStats = await _iconsService.getIconsStats();
      final tagsStats = await _tagsService.getTagsStats();

      return {
        'categories': categoriesStats,
        'icons': iconsStats,
        'tags': tagsStats,
        'summary': {
          'totalCategories': categoriesStats['total'],
          'totalIcons': iconsStats['total'],
          'totalTags': tagsStats['total'],
          'totalIconsSize': iconsStats['totalSize'],
          'averageIconSize': iconsStats['averageSize'],
          'unusedTagsCount': tagsStats['unusedCount'],
        },
      };
    } catch (e) {
      return {
        'categories': {'total': 0, 'byType': {}},
        'icons': {'total': 0, 'byType': {}, 'totalSize': 0, 'averageSize': 0},
        'tags': {'total': 0, 'byType': {}, 'popular': [], 'unusedCount': 0},
        'summary': {
          'totalCategories': 0,
          'totalIcons': 0,
          'totalTags': 0,
          'totalIconsSize': 0,
          'averageIconSize': 0,
          'unusedTagsCount': 0,
        },
      };
    }
  }

  /// Очистка неиспользуемых элементов
  Future<Map<String, dynamic>> cleanupUnused() async {
    final results = <String, dynamic>{};

    try {
      // Очистка неиспользуемых иконок
      final iconCleanupResult = await _iconsService.cleanupUnusedIcons();
      results['icons'] = {
        'success': iconCleanupResult.success,
        'message': iconCleanupResult.message,
      };

      // TODO: Добавить очистку неиспользуемых категорий и тегов
      // Когда будут реализованы связи с основными сущностями

      results['overall'] = {
        'success': iconCleanupResult.success,
        'message': 'Очистка завершена',
      };
    } catch (e) {
      results['overall'] = {
        'success': false,
        'message': 'Ошибка при очистке: ${e.toString()}',
      };
    }

    return results;
  }

  /// Поиск по всем типам метаданных
  Future<Map<String, dynamic>> searchAll(String query) async {
    try {
      final categoriesResults = await _categoriesService.searchCategories(
        query,
      );
      final iconsResults = await _iconsService.searchIcons(query);
      final tagsResults = await _tagsService.searchTags(query);

      return {
        'categories': categoriesResults,
        'icons': iconsResults,
        'tags': tagsResults,
        'totalResults':
            categoriesResults.length + iconsResults.length + tagsResults.length,
      };
    } catch (e) {
      return {
        'categories': [],
        'icons': [],
        'tags': [],
        'totalResults': 0,
        'error': e.toString(),
      };
    }
  }

  /// Экспорт всех метаданных в виде Map для бэкапа/восстановления
  Future<Map<String, dynamic>> exportMetadata() async {
    try {
      final categories = await _categoriesService.getAllCategories();
      final icons = await _iconsService.getAllIcons();
      final tags = await _tagsService.getAllTags();

      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'categories': categories
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'description': c.description,
                'iconId': c.iconId,
                'color': c.color,
                'type': c.type.name,
                'createdAt': c.createdAt.toIso8601String(),
                'modifiedAt': c.modifiedAt.toIso8601String(),
              },
            )
            .toList(),
        'icons': icons
            .map(
              (i) => {
                'id': i.id,
                'name': i.name,
                'type': i.type.name,
                'data': i.data, // Base64 encoded или как есть
                'createdAt': i.createdAt.toIso8601String(),
                'modifiedAt': i.modifiedAt.toIso8601String(),
              },
            )
            .toList(),
        'tags': tags
            .map(
              (t) => {
                'id': t.id,
                'name': t.name,
                'color': t.color,
                'type': t.type.name,
                'createdAt': t.createdAt.toIso8601String(),
                'modifiedAt': t.modifiedAt.toIso8601String(),
              },
            )
            .toList(),
      };
    } catch (e) {
      throw Exception('Ошибка экспорта метаданных: ${e.toString()}');
    }
  }

  /// Получение рекомендаций для UI
  Future<Map<String, dynamic>> getRecommendations() async {
    try {
      // Популярные теги
      final popularTags = await _tagsService.getPopularTags(limit: 5);

      // Иконки с информацией об использовании
      final iconsWithUsage = await _iconsService.getIconsWithUsage();
      final mostUsedIcons = iconsWithUsage.take(5).toList();

      // Неиспользуемые элементы
      final unusedTags = await _tagsService.getUnusedTags();
      final unusedIcons = await _iconsService.getUnusedIcons();

      // Крупные иконки (больше 100KB)
      final largeIcons = await _iconsService.getLargeIcons();

      return {
        'popularTags': popularTags
            .map(
              (t) => {
                'name': t.tag.name,
                'color': t.tag.color,
                'usage': t.usageCount,
              },
            )
            .toList(),
        'mostUsedIcons': mostUsedIcons
            .map(
              (i) => {
                'name': i.icon.name,
                'usage': i.usageCount,
                'size': _iconsService.formatFileSize(i.icon.data.length),
              },
            )
            .toList(),
        'cleanup': {
          'unusedTagsCount': unusedTags.length,
          'unusedIconsCount': unusedIcons.length,
          'largeIconsCount': largeIcons.length,
          'canCleanup': unusedTags.isNotEmpty || unusedIcons.isNotEmpty,
        },
      };
    } catch (e) {
      return {
        'popularTags': [],
        'mostUsedIcons': [],
        'cleanup': {
          'unusedTagsCount': 0,
          'unusedIconsCount': 0,
          'largeIconsCount': 0,
          'canCleanup': false,
        },
        'error': e.toString(),
      };
    }
  }

  /// Валидация целостности метаданных
  Future<Map<String, dynamic>> validateIntegrity() async {
    try {
      final issues = <String>[];

      // Проверка иконок без категорий
      final unusedIcons = await _iconsService.getUnusedIcons();
      if (unusedIcons.isNotEmpty) {
        issues.add('Найдено ${unusedIcons.length} неиспользуемых иконок');
      }

      // Проверка тегов без записей
      final unusedTags = await _tagsService.getUnusedTags();
      if (unusedTags.isNotEmpty) {
        issues.add('Найдено ${unusedTags.length} неиспользуемых тегов');
      }

      // Проверка крупных иконок
      final largeIcons = await _iconsService.getLargeIcons(
        sizeInBytes: 500 * 1024,
      ); // 500KB
      if (largeIcons.isNotEmpty) {
        issues.add(
          'Найдено ${largeIcons.length} очень крупных иконок (>500KB)',
        );
      }

      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'suggestions': _getIntegritySuggestions(issues),
      };
    } catch (e) {
      return {
        'isValid': false,
        'issues': ['Ошибка проверки целостности: ${e.toString()}'],
        'suggestions': [],
      };
    }
  }

  /// Получение предложений по исправлению проблем целостности
  List<String> _getIntegritySuggestions(List<String> issues) {
    final suggestions = <String>[];

    for (final issue in issues) {
      if (issue.contains('неиспользуемых иконок')) {
        suggestions.add(
          'Рекомендуется удалить неиспользуемые иконки для экономии места',
        );
      }
      if (issue.contains('неиспользуемых тегов')) {
        suggestions.add(
          'Рекомендуется удалить неиспользуемые теги для упрощения интерфейса',
        );
      }
      if (issue.contains('крупных иконок')) {
        suggestions.add(
          'Рекомендуется оптимизировать или заменить крупные иконки',
        );
      }
    }

    return suggestions;
  }
}
