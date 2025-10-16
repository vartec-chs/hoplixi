import 'dart:convert';
import 'package:synchronized/synchronized.dart';
import 'encryption_service.dart';
import 'storage_manager.dart';
import 'index_manager.dart';

/// Главный класс базы данных
class BoxDB<T> {
  final String name;
  final String path;
  final EncryptionService _encryption;
  final StorageManager _storage;
  final IndexManager _index;
  final Lock _lock = Lock();

  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final String Function(T) _getId;

  bool _isOpen = false;

  BoxDB._({
    required this.name,
    required this.path,
    required EncryptionService encryption,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) : _encryption = encryption,
       _storage = StorageManager(path),
       _index = IndexManager(StorageManager(path)),
       _fromJson = fromJson,
       _toJson = toJson,
       _getId = getId;

  /// Создать новую базу данных
  static Future<BoxDB<T>> create<T>({
    required String name,
    required String basePath,
    String? password,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    final dbPath = '$basePath/$name';

    final encryption = password != null
        ? await EncryptionService.fromPassword(password)
        : await EncryptionService.generate();

    final db = BoxDB<T>._(
      name: name,
      path: dbPath,
      encryption: encryption,
      fromJson: fromJson,
      toJson: toJson,
      getId: getId,
    );

    await db._initialize();

    // Сохранить ключ шифрования в мета (если не используется пароль)
    // if (password == null) {
    //   final exportedKey = await encryption.exportKey();
    //   await db._storage.updateMeta({'encryption_key': exportedKey});
    // }

    return db;
  }

  /// Открыть существующую базу данных
  static Future<BoxDB<T>> open<T>({
    required String name,
    required String basePath,
    String? password,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    final dbPath = '$basePath/$name';
    final storage = StorageManager(dbPath);

    // Создать бэкап перед открытием
    await storage.createBackup();

    // Попытка восстановления при ошибке
    try {
      final isValid = await storage.verifyIntegrity();
      if (!isValid) {
        final restored = await storage.restoreFromBackup();
        if (!restored) {
          throw BoxDBException(
            'БД повреждена и не удалось восстановить из бэкапа',
          );
        }
      }
    } catch (e) {
      final restored = await storage.restoreFromBackup();
      if (!restored) {
        throw BoxDBException('Ошибка при открытии БД: $e');
      }
    }

    // Получить ключ шифрования
    final EncryptionService encryption;
    if (password != null) {
      encryption = await EncryptionService.fromPassword(password);
    } else {
      final meta = await storage.readMeta();
      final exportedKey = meta['encryption_key'] as String?;
      if (exportedKey == null) {
        throw BoxDBException('Не найден ключ шифрования в метаданных');
      }
      encryption = EncryptionService.fromExportedKey(exportedKey);
    }

    final db = BoxDB<T>._(
      name: name,
      path: dbPath,
      encryption: encryption,
      fromJson: fromJson,
      toJson: toJson,
      getId: getId,
    );

    await db._initialize();
    return db;
  }

  /// Инициализация БД
  Future<void> _initialize() async {
    await _storage.initialize();
    await _index.load();
    _isOpen = true;
  }

  /// Вставить запись
  Future<void> insert(T item) async {
    _checkOpen();

    return await _lock.synchronized(() async {
      final id = _getId(item);

      if (_index.exists(id)) {
        throw BoxDBException('Запись с ID "$id" уже существует');
      }

      final json = _toJson(item);
      final jsonString = jsonEncode(json);

      final encrypted = await _encryption.encrypt(jsonString);

      final record = {'id': id, 'data': encrypted.toJson()};

      final lineNumber = await _storage.appendData(record);
      _index.add(id, lineNumber);
      await _index.save();
    });
  }

  /// Получить запись по ID
  Future<T?> get(String id) async {
    _checkOpen();

    final entry = _index.get(id);
    if (entry == null || entry.deleted) {
      return null;
    }

    final record = await _storage.readLine(entry.line);
    if (record == null) {
      return null;
    }

    final encryptedData = EncryptedData.fromJson(
      record['data'] as Map<String, dynamic>,
    );

    final decryptedJson = await _encryption.decrypt(encryptedData);
    final json = jsonDecode(decryptedJson) as Map<String, dynamic>;

    return _fromJson(json);
  }

  /// Обновить запись
  Future<void> update(T item) async {
    _checkOpen();

    return await _lock.synchronized(() async {
      final id = _getId(item);

      if (!_index.exists(id)) {
        throw BoxDBException('Запись с ID "$id" не найдена');
      }

      final json = _toJson(item);
      final jsonString = jsonEncode(json);

      final encrypted = await _encryption.encrypt(jsonString);

      final record = {'id': id, 'data': encrypted.toJson()};

      final lineNumber = await _storage.appendData(record);
      _index.update(id, lineNumber);
      await _index.save();

      // Проверить, нужна ли компактификация (по умолчанию >= 10 удалённых строк)
      if (_index.needsCompaction(threshold: 5)) {
        await _compact();
      }
    });
  }

  /// Удалить запись
  Future<void> delete(String id) async {
    _checkOpen();

    return await _lock.synchronized(() async {
      if (!_index.exists(id)) {
        throw BoxDBException('Запись с ID "$id" не найдена');
      }

      _index.markDeleted(id);
      await _index.save();

      // Проверить, нужна ли компактификация
      if (_index.needsCompaction(threshold: 5)) {
        await _compact();
      }
    });
  }

  /// Получить все записи
  Future<List<T>> getAll() async {
    _checkOpen();

    final ids = _index.getAllIds();
    final items = <T>[];

    for (final id in ids) {
      final item = await get(id);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  Future<List<String>> getAllIndex() async {
    _checkOpen();

    final ids = _index.getAllIds();

    return ids;
  }

  /// Проверить существование записи
  Future<bool> exists(String id) async {
    _checkOpen();
    return _index.exists(id);
  }

  /// Получить количество записей
  Future<int> count() async {
    _checkOpen();
    return _index.count;
  }

  /// Очистить все записи
  Future<void> clear() async {
    _checkOpen();

    return await _lock.synchronized(() async {
      await _index.clear();
      await _index.save();

      // Удалить файл данных и создать новый
      await _storage.initialize();
    });
  }

  /// Получить недавние записи
  ///
  /// [limit] - максимальное количество записей (по умолчанию 10)
  /// [since] - получить записи после указанного времени (опционально)
  ///
  /// Возвращает список записей, отсортированных по времени (новые первыми)
  Future<List<T>> getRecent({int limit = 10, DateTime? since}) async {
    _checkOpen();

    final ids = _index.getRecentIds(limit: limit, since: since);
    final items = <T>[];

    for (final id in ids) {
      final item = await get(id);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Получить записи за указанный период времени
  ///
  /// [from] - начало периода
  /// [to] - конец периода (по умолчанию текущее время)
  ///
  /// Возвращает список записей, отсортированных по времени (новые первыми)
  Future<List<T>> getByTimeRange({required DateTime from, DateTime? to}) async {
    _checkOpen();

    final ids = _index.getIdsByTimeRange(from: from, to: to);
    final items = <T>[];

    for (final id in ids) {
      final item = await get(id);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Получить все записи, отсортированные по времени
  ///
  /// [ascending] - сортировка по возрастанию (старые первыми),
  /// по умолчанию false (новые первыми)
  Future<List<T>> getAllSortedByTime({bool ascending = false}) async {
    _checkOpen();

    final ids = _index.getIdsSortedByTime(ascending: ascending);
    final items = <T>[];

    for (final id in ids) {
      final item = await get(id);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Получить временную метку записи
  ///
  /// Возвращает время создания или последнего обновления записи
  Future<DateTime?> getTimestamp(String id) async {
    _checkOpen();
    return _index.getTimestamp(id);
  }

  /// Компактифицировать БД (удалить помеченные записи)
  Future<void> compact() async {
    _checkOpen();

    return await _lock.synchronized(() async {
      await _compact();
    });
  }

  /// Внутренний метод компактификации (должен вызываться внутри lock)
  Future<void> _compact() async {
    await _storage.compact(_index.toMap());
    await _index
        .load(); // Перезагрузить индекс (deleted_lines уже очищен в meta)
  }

  /// Создать резервную копию
  Future<void> backup() async {
    _checkOpen();

    return await _lock.synchronized(() async {
      await _storage.createBackup();
    });
  }

  /// Закрыть БД
  Future<void> close() async {
    if (!_isOpen) return;

    await _lock.synchronized(() async {
      await _index.save();
      _isOpen = false;
    });
  }

  void _checkOpen() {
    if (!_isOpen) {
      throw BoxDBException('База данных не открыта');
    }
  }
}

/// Исключение БД
class BoxDBException implements Exception {
  final String message;
  BoxDBException(this.message);

  @override
  String toString() => 'BoxDBException: $message';
}
