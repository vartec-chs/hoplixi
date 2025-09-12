import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Кэш для результатов запросов тегов и категорий
class FilterDataCache {
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  final Map<String, _CacheEntry<List<store.Tag>>> _tagCache = {};
  final Map<String, _CacheEntry<List<store.Category>>> _categoryCache = {};

  /// Получить закэшированные теги
  List<store.Tag>? getCachedTags(String key) {
    final entry = _tagCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _tagCache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Закэшировать теги
  void cacheTags(String key, List<store.Tag> tags) {
    _cleanupCache(_tagCache);
    _tagCache[key] = _CacheEntry(tags);
  }

  /// Получить закэшированные категории
  List<store.Category>? getCachedCategories(String key) {
    final entry = _categoryCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _categoryCache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Закэшировать категории
  void cacheCategories(String key, List<store.Category> categories) {
    _cleanupCache(_categoryCache);
    _categoryCache[key] = _CacheEntry(categories);
  }

  /// Очистить весь кэш
  void clearAll() {
    _tagCache.clear();
    _categoryCache.clear();
  }

  /// Очистить кэш тегов
  void clearTagCache() {
    _tagCache.clear();
  }

  /// Очистить кэш категорий
  void clearCategoryCache() {
    _categoryCache.clear();
  }

  /// Создать ключ для кэширования
  String createKey({
    required String type,
    required int page,
    required int pageSize,
    String? searchTerm,
    String? sortBy,
    bool ascending = true,
  }) {
    final buffer = StringBuffer()
      ..write(type)
      ..write('_p')
      ..write(page)
      ..write('_s')
      ..write(pageSize);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      buffer.write('_q');
      buffer.write(searchTerm);
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      buffer.write('_sb');
      buffer.write(sortBy);
    }

    buffer.write('_asc');
    buffer.write(ascending);

    return buffer.toString();
  }

  /// Очистка устаревших записей из кэша
  void _cleanupCache<T>(Map<String, _CacheEntry<T>> cache) {
    if (cache.length >= _maxCacheSize) {
      // Удаляем самые старые записи
      final entries = cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      for (int i = 0; i < cache.length - _maxCacheSize + 10; i++) {
        cache.remove(entries[i].key);
      }
    }

    // Удаляем устаревшие записи
    cache.removeWhere((key, entry) => entry.isExpired);
  }
}

/// Запись в кэше с таймстампом
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > FilterDataCache._cacheExpiry;
}

/// Провайдер кэша для фильтров
final filterCacheProvider = Provider<FilterDataCache>((ref) {
  return FilterDataCache();
});

/// Состояние загрузки для предотвращения дублирования запросов
class LoadingState {
  final Map<String, Completer<void>> _loadingCompleters = {};

  /// Проверить, выполняется ли запрос
  bool isLoading(String key) => _loadingCompleters.containsKey(key);

  /// Дождаться завершения запроса если он выполняется
  Future<void> waitIfLoading(String key) async {
    final completer = _loadingCompleters[key];
    if (completer != null && !completer.isCompleted) {
      await completer.future;
    }
  }

  /// Начать выполнение запроса
  Completer<void> startLoading(String key) {
    final completer = Completer<void>();
    _loadingCompleters[key] = completer;
    return completer;
  }

  /// Завершить выполнение запроса
  void completeLoading(String key) {
    final completer = _loadingCompleters[key];
    if (completer != null && !completer.isCompleted) {
      completer.complete();
      _loadingCompleters.remove(key);
    }
  }

  /// Завершить выполнение запроса с ошибкой
  void completeLoadingWithError(String key, Object error) {
    final completer = _loadingCompleters[key];
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
      _loadingCompleters.remove(key);
    }
  }

  /// Очистить все состояния загрузки
  void clear() {
    for (final completer in _loadingCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _loadingCompleters.clear();
  }
}

/// Провайдер состояния загрузки
final loadingStateProvider = Provider<LoadingState>((ref) {
  return LoadingState();
});

/// Утилиты для работы с кэшем
class FilterCacheUtils {
  /// Создать ключ для кэширования тегов
  static String createTagCacheKey({
    required TagType type,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) {
    return FilterDataCache().createKey(
      type: 'tag_${type.name}',
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      sortBy: 'name',
      ascending: true,
    );
  }

  /// Создать ключ для кэширования категорий
  static String createCategoryCacheKey({
    required CategoryType type,
    required int page,
    required int pageSize,
    String? searchTerm,
    String? sortBy,
    bool ascending = true,
  }) {
    return FilterDataCache().createKey(
      type: 'category_${type.name}',
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      sortBy: sortBy,
      ascending: ascending,
    );
  }
}
