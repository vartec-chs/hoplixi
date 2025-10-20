import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';
import 'package:hoplixi/core/utils/result_pattern/common_errors.dart';
import 'package:hoplixi/features/auth/models/sync_providers.dart';
import 'package:hoplixi/features/cloud_sync/models/local_meta.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

/// CRUD-сервис для работы с LocalMeta в памяти
/// Синглтон, загружает весь файл при инициализации
class LocalMetaCrudService {
  static const _tag = 'LocalMetaCrudService';
  static const _fileName = 'local_meta.json';

  static LocalMetaCrudService? _instance;
  static final Lock _lock = Lock();

  /// Хранилище данных в памяти (ключ = dbId)
  final Map<String, LocalMeta> _storage = {};

  /// Флаг инициализации
  bool _isInitialized = false;

  LocalMetaCrudService._internal();

  /// Получить singleton instance
  static Future<Result<LocalMetaCrudService, AppError>> getInstance() async {
    return _lock.synchronized(() async {
      if (_instance != null && _instance!._isInitialized) {
        return Result.success(_instance!);
      }

      _instance ??= LocalMetaCrudService._internal();

      // Загрузить данные из файла
      final loadResult = await _instance!._loadFromFile();
      return loadResult.map((_) {
        _instance!._isInitialized = true;
        return _instance!;
      });
    });
  }

  /// Получить путь к файлу
  Future<String> get _filePath async {
    final storagesPath = await AppPaths.appStoragePath;
    return p.join(storagesPath, _fileName);
  }

  /// Загрузить данные из файла
  Future<Result<void, AppError>> _loadFromFile() async {
    try {
      final path = await _filePath;
      final file = File(path);

      if (!await file.exists()) {
        logInfo(
          'Файл $_fileName не найден, создаём пустое хранилище',
          tag: _tag,
        );
        return Result.success(null);
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        logInfo('Файл $_fileName пуст', tag: _tag);
        return Result.success(null);
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>? ?? [];

      _storage.clear();
      for (final item in items) {
        final meta = LocalMeta.fromJson(item as Map<String, dynamic>);
        _storage[meta.dbId] = meta;
      }

      logInfo('Загружено ${_storage.length} записей LocalMeta', tag: _tag);
      return Result.success(null);
    } catch (e, stackTrace) {
      logError(
        'Ошибка загрузки $_fileName',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return Result.failure(
        AppError.unknown('Не удалось загрузить данные LocalMeta', cause: e),
      );
    }
  }

  /// Сохранить данные в файл
  Future<Result<void, AppError>> _saveToFile() async {
    try {
      final path = await _filePath;
      final file = File(path);

      final json = {
        'items': _storage.values.map((meta) => meta.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(
        jsonEncode(json),
        mode: FileMode.write,
        flush: true,
      );

      logDebug('Сохранено ${_storage.length} записей LocalMeta', tag: _tag);
      return Result.success(null);
    } catch (e, stackTrace) {
      logError(
        'Ошибка сохранения $_fileName',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return Result.failure(
        AppError.unknown('Не удалось сохранить данные LocalMeta', cause: e),
      );
    }
  }

  // ========== CRUD операции ==========

  /// Создать новую запись
  Future<Result<LocalMeta, AppError>> create(LocalMeta meta) async {
    return _lock.synchronized(() async {
      if (_storage.containsKey(meta.dbId)) {
        return Result.failure(
          AppError.validation(
            'dbId',
            'LocalMeta с dbId=${meta.dbId} уже существует',
          ),
        );
      }

      _storage[meta.dbId] = meta;
      final saveResult = await _saveToFile();

      return saveResult.map((_) {
        logDebug('Создан LocalMeta: dbId=${meta.dbId}', tag: _tag);
        return meta;
      });
    });
  }

  /// Получить запись по dbId
  Result<LocalMeta, AppError> getByDbId(String dbId) {
    final meta = _storage[dbId];
    if (meta == null) {
      return Result.failure(
        AppError.notFound('LocalMeta с dbId=$dbId не найден'),
      );
    }
    return Result.success(meta);
  }

  /// Обновить существующую запись
  Future<Result<LocalMeta, AppError>> update(LocalMeta meta) async {
    return _lock.synchronized(() async {
      if (!_storage.containsKey(meta.dbId)) {
        return Result.failure(
          AppError.notFound('LocalMeta с dbId=${meta.dbId} не найден'),
        );
      }

      _storage[meta.dbId] = meta;
      final saveResult = await _saveToFile();

      return saveResult.map((_) {
        logDebug('Обновлён LocalMeta: dbId=${meta.dbId}', tag: _tag);
        return meta;
      });
    });
  }

  /// Удалить запись по dbId
  Future<Result<void, AppError>> deleteByDbId(String dbId) async {
    return _lock.synchronized(() async {
      if (!_storage.containsKey(dbId)) {
        return Result.failure(
          AppError.notFound('LocalMeta с dbId=$dbId не найден'),
        );
      }

      _storage.remove(dbId);
      final saveResult = await _saveToFile();

      return saveResult.map((_) {
        logDebug('Удалён LocalMeta: dbId=$dbId', tag: _tag);
        return;
      });
    });
  }

  /// Получить все записи
  Result<List<LocalMeta>, AppError> getAll() {
    return Result.success(List.unmodifiable(_storage.values));
  }

  /// Очистить все записи
  Future<Result<void, AppError>> clear() async {
    return _lock.synchronized(() async {
      _storage.clear();
      final saveResult = await _saveToFile();

      return saveResult.map((_) {
        logInfo('Все записи LocalMeta очищены', tag: _tag);
        return;
      });
    });
  }

  // ========== Методы поиска по полям ==========

  /// Найти по dbName
  Result<List<LocalMeta>, AppError> findByDbName(String dbName) {
    final results = _storage.values
        .where((meta) => meta.dbName == dbName)
        .toList();
    return Result.success(results);
  }

  /// Найти по deviceId
  Result<List<LocalMeta>, AppError> findByDeviceId(String deviceId) {
    final results = _storage.values
        .where((meta) => meta.deviceId == deviceId)
        .toList();
    return Result.success(results);
  }

  /// Найти по enabled
  Result<List<LocalMeta>, AppError> findByEnabled(bool enabled) {
    final results = _storage.values
        .where((meta) => meta.enabled == enabled)
        .toList();
    return Result.success(results);
  }

  /// Найти все включенные
  Result<List<LocalMeta>, AppError> findEnabled() {
    return findByEnabled(true);
  }

  /// Найти все отключенные
  Result<List<LocalMeta>, AppError> findDisabled() {
    return findByEnabled(false);
  }

  /// Найти по наличию lastExportAt (не null)
  Result<List<LocalMeta>, AppError> findWithLastExportAt() {
    final results = _storage.values
        .where((meta) => meta.lastExportAt != null)
        .toList();
    return Result.success(results);
  }

  /// Найти по наличию lastImportedAt (не null)
  Result<List<LocalMeta>, AppError> findWithLastImportedAt() {
    final results = _storage.values
        .where((meta) => meta.lastImportedAt != null)
        .toList();
    return Result.success(results);
  }

  /// Найти записи, экспортированные после указанной даты
  Result<List<LocalMeta>, AppError> findExportedAfter(DateTime date) {
    final results = _storage.values.where((meta) {
      final exportAt = meta.lastExportAt;
      return exportAt != null && exportAt.isAfter(date);
    }).toList();
    return Result.success(results);
  }

  /// Найти записи, импортированные после указанной даты
  Result<List<LocalMeta>, AppError> findImportedAfter(DateTime date) {
    final results = _storage.values.where((meta) {
      final importAt = meta.lastImportedAt;
      return importAt != null && importAt.isAfter(date);
    }).toList();
    return Result.success(results);
  }

  /// Найти записи по deviceId и enabled
  Result<List<LocalMeta>, AppError> findByDeviceIdAndEnabled(
    String deviceId,
    bool enabled,
  ) {
    final results = _storage.values
        .where((meta) => meta.deviceId == deviceId && meta.enabled == enabled)
        .toList();
    return Result.success(results);
  }

  /// Найти по providerType
  Result<List<LocalMeta>, AppError> findByProviderType(ProviderType type) {
    final results = _storage.values
        .where((meta) => meta.providerType == type)
        .toList();
    return Result.success(results);
  }

  /// Найти по providerType и enabled
  Result<List<LocalMeta>, AppError> findByProviderTypeAndEnabled(
    ProviderType type,
    bool enabled,
  ) {
    final results = _storage.values
        .where((meta) => meta.providerType == type && meta.enabled == enabled)
        .toList();
    return Result.success(results);
  }

  /// Найти по deviceId и providerType
  Result<List<LocalMeta>, AppError> findByDeviceIdAndProviderType(
    String deviceId,
    ProviderType type,
  ) {
    final results = _storage.values
        .where((meta) => meta.deviceId == deviceId && meta.providerType == type)
        .toList();
    return Result.success(results);
  }

  /// Найти по всем критериям: deviceId, providerType и enabled
  Result<List<LocalMeta>, AppError> findByDeviceIdProviderTypeAndEnabled(
    String deviceId,
    ProviderType type,
    bool enabled,
  ) {
    final results = _storage.values
        .where(
          (meta) =>
              meta.deviceId == deviceId &&
              meta.providerType == type &&
              meta.enabled == enabled,
        )
        .toList();
    return Result.success(results);
  }

  /// Проверить существование по dbId
  bool existsByDbId(String dbId) {
    return _storage.containsKey(dbId);
  }

  /// Проверить существование по providerType
  bool existsByProviderType(ProviderType type) {
    return _storage.values.any((meta) => meta.providerType == type);
  }

  /// Проверить существование по dbName
  bool existsByDbName(String dbName) {
    return _storage.values.any((meta) => meta.dbName == dbName);
  }

  /// Проверить существование по deviceId
  bool existsByDeviceId(String deviceId) {
    return _storage.values.any((meta) => meta.deviceId == deviceId);
  }

  /// Получить количество записей по провайдеру
  int countByProviderType(ProviderType type) {
    return _storage.values.where((meta) => meta.providerType == type).length;
  }

  /// Получить количество записей
  int get count => _storage.length;

  /// Проверить, пусто ли хранилище
  bool get isEmpty => _storage.isEmpty;

  /// Проверить, не пусто ли хранилище
  bool get isNotEmpty => _storage.isNotEmpty;
}
