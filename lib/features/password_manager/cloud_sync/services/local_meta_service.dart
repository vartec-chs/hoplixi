import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/local_meta.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Результат операции с LocalMeta
class LocalMetaResult {
  final bool success;
  final String? message;
  final LocalMeta? data;

  LocalMetaResult({
    required this.success,
    this.message,
    this.data,
  });

  LocalMetaResult.success({LocalMeta? data, String? message})
      : success = true,
        message = message ?? 'Операция выполнена успешно',
        data = data;

  LocalMetaResult.error(String message)
      : success = false,
        message = message,
        data = null;
}

/// CRUD сервис для управления LocalMeta с кэшированием в памяти
/// Сингелтон паттерн с автоматической загрузкой при инициализации
class LocalMetaCrudService {
  static LocalMetaCrudService? _instance;

  static LocalMetaCrudService get instance =>
      _instance ??= LocalMetaCrudService._();

  LocalMetaCrudService._();

  // Кэш в памяти
  final List<LocalMeta> _cache = [];
  bool _initialized = false;
  late File _storageFile;

  /// Инициализация сервиса и загрузка данных из файла
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      logDebug(
        'Инициализация LocalMetaCrudService',
        tag: 'LocalMetaCrudService',
      );

      // Получаем директорию приложения
      final appDir = await getApplicationDocumentsDirectory();
      _storageFile = File('${appDir.path}/local_meta_cache.json');

      // Загружаем существующие данные
      await _loadFromFile();

      _initialized = true;

      logDebug(
        'LocalMetaCrudService инициализирован',
        tag: 'LocalMetaCrudService',
        data: {'cachedItems': _cache.length},
      );
    } catch (e, s) {
      logError(
        'Ошибка инициализации LocalMetaCrudService',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      rethrow;
    }
  }

  /// Загрузка данных из файла в кэш
  Future<void> _loadFromFile() async {
    try {
      if (!_storageFile.existsSync()) {
        logDebug(
          'Файл кэша не найден, создан пустой кэш',
          tag: 'LocalMetaCrudService',
        );
        _cache.clear();
        return;
      }

      final content = await _storageFile.readAsString();
      final jsonData = jsonDecode(content) as List<dynamic>;

      _cache.clear();
      for (final item in jsonData) {
        final localMeta = LocalMeta.fromJson(item as Map<String, dynamic>);
        _cache.add(localMeta);
      }

      logDebug(
        'Данные загружены из файла',
        tag: 'LocalMetaCrudService',
        data: {'count': _cache.length},
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки данных из файла',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      _cache.clear();
    }
  }

  /// Сохранение кэша в файл
  Future<void> _saveToFile() async {
    try {
      final jsonData = _cache.map((item) => item.toJson()).toList();
      final content = jsonEncode(jsonData);
      await _storageFile.writeAsString(content);

      logDebug(
        'Данные сохранены в файл',
        tag: 'LocalMetaCrudService',
        data: {'count': _cache.length},
      );
    } catch (e, s) {
      logError(
        'Ошибка сохранения данных в файл',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
    }
  }

  // ============================================================================
  // CREATE операции
  // ============================================================================

  /// Добавление нового LocalMeta в кэш
  Future<LocalMetaResult> create(LocalMeta localMeta) async {
    try {
      logDebug(
        'Создание новой записи LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'id': localMeta.id, 'dbId': localMeta.dbId},
      );

      // Проверка, что запись с таким id уже не существует
      if (_cache.any((item) => item.id == localMeta.id)) {
        return LocalMetaResult.error(
          'Запись с ID ${localMeta.id} уже существует',
        );
      }

      _cache.add(localMeta);
      await _saveToFile();

      logDebug(
        'Запись LocalMeta создана',
        tag: 'LocalMetaCrudService',
        data: {'id': localMeta.id},
      );

      return LocalMetaResult.success(
        data: localMeta,
        message: 'Запись успешно создана',
      );
    } catch (e, s) {
      logError(
        'Ошибка создания записи LocalMeta',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка создания: ${e.toString()}');
    }
  }

  /// Добавление нескольких записей
  Future<LocalMetaResult> createMultiple(List<LocalMeta> items) async {
    try {
      logDebug(
        'Создание нескольких записей LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'count': items.length},
      );

      final newItems = <LocalMeta>[];

      for (final item in items) {
        if (!_cache.any((existing) => existing.id == item.id)) {
          newItems.add(item);
        }
      }

      _cache.addAll(newItems);
      await _saveToFile();

      logDebug(
        'Записи LocalMeta созданы',
        tag: 'LocalMetaCrudService',
        data: {'created': newItems.length, 'skipped': items.length - newItems.length},
      );

      return LocalMetaResult.success(
        message: 'Добавлено ${newItems.length} записей',
      );
    } catch (e, s) {
      logError(
        'Ошибка создания нескольких записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка создания: ${e.toString()}');
    }
  }

  // ============================================================================
  // READ операции
  // ============================================================================

  /// Получение всех записей
  Future<List<LocalMeta>> getAll() async {
    try {
      logDebug(
        'Получение всех записей LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'count': _cache.length},
      );
      return List.unmodifiable(_cache);
    } catch (e, s) {
      logError(
        'Ошибка получения всех записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return [];
    }
  }

  /// Получение записи по ID
  Future<LocalMeta?> getById(String id) async {
    try {
      logDebug(
        'Получение записи по ID',
        tag: 'LocalMetaCrudService',
        data: {'id': id},
      );
      return _cache.firstWhereOrNull((item) => item.id == id);
    } catch (e, s) {
      logError(
        'Ошибка получения записи по ID',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return null;
    }
  }

  /// Получение по dbId
  Future<LocalMeta?> getByDbId(String dbId) async {
    try {
      logDebug(
        'Получение записи по dbId',
        tag: 'LocalMetaCrudService',
        data: {'dbId': dbId},
      );
      return _cache.firstWhereOrNull((item) => item.dbId == dbId);
    } catch (e, s) {
      logError(
        'Ошибка получения записи по dbId',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return null;
    }
  }

  /// Получение по deviceId
  Future<LocalMeta?> getByDeviceId(String deviceId) async {
    try {
      logDebug(
        'Получение записи по deviceId',
        tag: 'LocalMetaCrudService',
        data: {'deviceId': deviceId},
      );
      return _cache.firstWhereOrNull((item) => item.deviceId == deviceId);
    } catch (e, s) {
      logError(
        'Ошибка получения записи по deviceId',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return null;
    }
  }

  /// Получение по dbName
  Future<LocalMeta?> getByDbName(String dbName) async {
    try {
      logDebug(
        'Получение записи по dbName',
        tag: 'LocalMetaCrudService',
        data: {'dbName': dbName},
      );
      return _cache.firstWhereOrNull((item) => item.dbName == dbName);
    } catch (e, s) {
      logError(
        'Ошибка получения записи по dbName',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return null;
    }
  }

  /// Поиск по нескольким критериям
  Future<List<LocalMeta>> search({
    String? dbId,
    String? dbName,
    String? deviceId,
  }) async {
    try {
      logDebug(
        'Поиск записей с фильтром',
        tag: 'LocalMetaCrudService',
        data: {'dbId': dbId, 'dbName': dbName, 'deviceId': deviceId},
      );

      var results = _cache.toList();

      if (dbId != null) {
        results = results.where((item) => item.dbId.contains(dbId)).toList();
      }

      if (dbName != null) {
        results =
            results.where((item) => item.dbName.contains(dbName)).toList();
      }

      if (deviceId != null) {
        results =
            results.where((item) => item.deviceId.contains(deviceId)).toList();
      }

      logDebug(
        'Поиск завершен',
        tag: 'LocalMetaCrudService',
        data: {'found': results.length},
      );

      return List.unmodifiable(results);
    } catch (e, s) {
      logError(
        'Ошибка поиска записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return [];
    }
  }

  /// Получение записей с фильтром по временному диапазону (lastExportAt)
  Future<List<LocalMeta>> getByExportDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      logDebug(
        'Получение записей по диапазону дат экспорта',
        tag: 'LocalMetaCrudService',
        data: {'start': startDate, 'end': endDate},
      );

      final results = _cache.where((item) {
        if (item.lastExportAt == null) return false;
        return item.lastExportAt!.isAfter(startDate) &&
            item.lastExportAt!.isBefore(endDate);
      }).toList();

      return List.unmodifiable(results);
    } catch (e, s) {
      logError(
        'Ошибка получения записей по диапазону дат',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return [];
    }
  }

  /// Получение записей, которые никогда не экспортировались
  Future<List<LocalMeta>> getNeverExported() async {
    try {
      logDebug(
        'Получение записей, никогда не экспортировавшихся',
        tag: 'LocalMetaCrudService',
      );

      final results =
          _cache.where((item) => item.lastExportAt == null).toList();

      return List.unmodifiable(results);
    } catch (e, s) {
      logError(
        'Ошибка получения невыгруженных записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return [];
    }
  }

  // ============================================================================
  // UPDATE операции
  // ============================================================================

  /// Обновление записи
  Future<LocalMetaResult> update(LocalMeta localMeta) async {
    try {
      logDebug(
        'Обновление записи LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'id': localMeta.id},
      );

      final index = _cache.indexWhere((item) => item.id == localMeta.id);
      if (index == -1) {
        return LocalMetaResult.error('Запись с ID ${localMeta.id} не найдена');
      }

      _cache[index] = localMeta;
      await _saveToFile();

      logDebug(
        'Запись LocalMeta обновлена',
        tag: 'LocalMetaCrudService',
        data: {'id': localMeta.id},
      );

      return LocalMetaResult.success(
        data: localMeta,
        message: 'Запись успешно обновлена',
      );
    } catch (e, s) {
      logError(
        'Ошибка обновления записи',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка обновления: ${e.toString()}');
    }
  }

  /// Обновление времени последнего экспорта
  Future<LocalMetaResult> updateLastExportAt(String id) async {
    try {
      logDebug(
        'Обновление времени экспорта',
        tag: 'LocalMetaCrudService',
        data: {'id': id},
      );

      final index = _cache.indexWhere((item) => item.id == id);
      if (index == -1) {
        return LocalMetaResult.error('Запись с ID $id не найдена');
      }

      final updated = _cache[index].copyWith(lastExportAt: DateTime.now());
      _cache[index] = updated;
      await _saveToFile();

      return LocalMetaResult.success(
        data: updated,
        message: 'Время экспорта обновлено',
      );
    } catch (e, s) {
      logError(
        'Ошибка обновления времени экспорта',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка обновления: ${e.toString()}');
    }
  }

  /// Обновление времени последнего импорта
  Future<LocalMetaResult> updateLastImportedAt(String id) async {
    try {
      logDebug(
        'Обновление времени импорта',
        tag: 'LocalMetaCrudService',
        data: {'id': id},
      );

      final index = _cache.indexWhere((item) => item.id == id);
      if (index == -1) {
        return LocalMetaResult.error('Запись с ID $id не найдена');
      }

      final updated = _cache[index].copyWith(lastImportedAt: DateTime.now());
      _cache[index] = updated;
      await _saveToFile();

      return LocalMetaResult.success(
        data: updated,
        message: 'Время импорта обновлено',
      );
    } catch (e, s) {
      logError(
        'Ошибка обновления времени импорта',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка обновления: ${e.toString()}');
    }
  }

  // ============================================================================
  // DELETE операции
  // ============================================================================

  /// Удаление записи по ID
  Future<LocalMetaResult> delete(String id) async {
    try {
      logDebug(
        'Удаление записи LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'id': id},
      );

      final index = _cache.indexWhere((item) => item.id == id);
      if (index == -1) {
        return LocalMetaResult.error('Запись с ID $id не найдена');
      }

      final deleted = _cache.removeAt(index);
      await _saveToFile();

      logDebug(
        'Запись LocalMeta удалена',
        tag: 'LocalMetaCrudService',
        data: {'id': id},
      );

      return LocalMetaResult.success(
        data: deleted,
        message: 'Запись успешно удалена',
      );
    } catch (e, s) {
      logError(
        'Ошибка удаления записи',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка удаления: ${e.toString()}');
    }
  }

  /// Удаление нескольких записей
  Future<LocalMetaResult> deleteMultiple(List<String> ids) async {
    try {
      logDebug(
        'Удаление нескольких записей LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'count': ids.length},
      );

      int deletedCount = 0;
      for (final id in ids) {
        final index = _cache.indexWhere((item) => item.id == id);
        if (index != -1) {
          _cache.removeAt(index);
          deletedCount++;
        }
      }

      await _saveToFile();

      logDebug(
        'Записи LocalMeta удалены',
        tag: 'LocalMetaCrudService',
        data: {'deleted': deletedCount},
      );

      return LocalMetaResult.success(
        message: 'Удалено $deletedCount записей',
      );
    } catch (e, s) {
      logError(
        'Ошибка удаления нескольких записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка удаления: ${e.toString()}');
    }
  }

  /// Удаление всех записей
  Future<LocalMetaResult> deleteAll() async {
    try {
      logDebug(
        'Удаление всех записей LocalMeta',
        tag: 'LocalMetaCrudService',
        data: {'count': _cache.length},
      );

      final count = _cache.length;
      _cache.clear();
      await _saveToFile();

      logDebug(
        'Все записи LocalMeta удалены',
        tag: 'LocalMetaCrudService',
        data: {'count': count},
      );

      return LocalMetaResult.success(
        message: 'Удалено $count записей',
      );
    } catch (e, s) {
      logError(
        'Ошибка удаления всех записей',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return LocalMetaResult.error('Ошибка удаления: ${e.toString()}');
    }
  }

  // ============================================================================
  // Утилиты и статистика
  // ============================================================================

  /// Получение количества записей в кэше
  int get cacheSize => _cache.length;

  /// Проверка инициализации
  bool get isInitialized => _initialized;

  /// Получение статистики
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      logDebug(
        'Получение статистики',
        tag: 'LocalMetaCrudService',
      );

      final totalCount = _cache.length;
      final neverExported =
          _cache.where((item) => item.lastExportAt == null).length;
      final neverImported =
          _cache.where((item) => item.lastImportedAt == null).length;

      final lastExport = _cache
          .where((item) => item.lastExportAt != null)
          .fold<DateTime?>(null, (prev, item) {
        if (prev == null) return item.lastExportAt;
        return item.lastExportAt!.isAfter(prev) ? item.lastExportAt : prev;
      });

      final lastImport = _cache
          .where((item) => item.lastImportedAt != null)
          .fold<DateTime?>(null, (prev, item) {
        if (prev == null) return item.lastImportedAt;
        return item.lastImportedAt!.isAfter(prev) ? item.lastImportedAt : prev;
      });

      return {
        'totalCount': totalCount,
        'neverExported': neverExported,
        'neverImported': neverImported,
        'lastExportAt': lastExport?.toIso8601String(),
        'lastImportedAt': lastImport?.toIso8601String(),
        'uniqueDatabases': _cache.map((item) => item.dbId).toSet().length,
        'uniqueDevices': _cache.map((item) => item.deviceId).toSet().length,
      };
    } catch (e, s) {
      logError(
        'Ошибка получения статистики',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
      return {};
    }
  }

  /// Очистка кэша и переинициализация
  Future<void> reset() async {
    try {
      logDebug(
        'Сброс LocalMetaCrudService',
        tag: 'LocalMetaCrudService',
      );

      _cache.clear();
      await _saveToFile();
      _initialized = false;

      logDebug(
        'LocalMetaCrudService успешно сброшен',
        tag: 'LocalMetaCrudService',
      );
    } catch (e, s) {
      logError(
        'Ошибка сброса сервиса',
        error: e,
        stackTrace: s,
        tag: 'LocalMetaCrudService',
      );
    }
  }
}

/// Расширение для удобной работы с List
extension LocalMetaListExt on List<LocalMeta> {
  LocalMeta? firstWhereOrNull(bool Function(LocalMeta) test) {
    try {
      return firstWhere(test);
    } on StateError {
      return null;
    }
  }
}
