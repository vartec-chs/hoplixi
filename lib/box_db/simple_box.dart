import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:synchronized/synchronized.dart';
import 'types.dart';
import 'crypto_box.dart';
import 'errors.dart';

/// Запись в индексе
class IndexEntry {
  final String id;
  final int offset;
  final int length;
  final bool isDeleted;
  final String timestamp;
  final String checksum; // Контрольная сумма записи

  const IndexEntry({
    required this.id,
    required this.offset,
    required this.length,
    required this.isDeleted,
    required this.timestamp,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'offset': offset,
    'length': length,
    'deleted': isDeleted,
    'timestamp': timestamp,
    'checksum': checksum,
  };

  factory IndexEntry.fromJson(Map<String, dynamic> json) => IndexEntry(
    id: json['id'] as String,
    offset: json['offset'] as int,
    length: json['length'] as int,
    isDeleted: json['deleted'] as bool? ?? false,
    timestamp: json['timestamp'] as String,
    checksum: json['checksum'] as String? ?? '',
  );
}

/// Простая коробка без сегментации - все данные в одном файле с индексом
class SimpleBox<T> {
  final Directory boxDirectory;
  final String boxName;
  final FromMapFn<T> fromMap;
  final ToMapFn<T> toMap;
  final CryptoBox? crypto;

  late final File _dataFile;
  late final File _indexFile;
  late final File _backupFile;
  late final File _tempFile;
  late final File _tempIndexFile;
  late final File _lockFile;

  final Map<String, IndexEntry> _index = {};
  bool _isInitialized = false;

  // Блокировки для синхронизации доступа к данным и файлам
  final Lock _dataLock = Lock(); // Основная блокировка для данных
  final Lock _fileLock = Lock(); // Блокировка для файловых операций

  // Генератор UUID для автоматических ID
  static const _uuid = Uuid();

  // Настройки автоматической очистки
  final bool _autoCompactionEnabled;
  final double
  _compactionThreshold; // Процент удаленных записей для запуска компактификации
  final Duration?
  _autoCompactionInterval; // Интервал автоматической компактификации

  Timer? _compactionTimer;
  int _deletedRecordsCount = 0;

  SimpleBox._({
    required this.boxDirectory,
    required this.boxName,
    required this.fromMap,
    required this.toMap,
    this.crypto,
    bool autoCompactionEnabled = true,
    double compactionThreshold = 0.3, // 30% удаленных записей
    Duration? autoCompactionInterval,
  }) : _autoCompactionEnabled = autoCompactionEnabled,
       _compactionThreshold = compactionThreshold,
       _autoCompactionInterval = autoCompactionInterval {
    _dataFile = File(path.join(boxDirectory.path, 'data.jsonl'));
    _indexFile = File(path.join(boxDirectory.path, 'index.jsonl'));
    _backupFile = File(path.join(boxDirectory.path, 'data.backup.jsonl'));
    _tempFile = File(path.join(boxDirectory.path, 'data.temp.jsonl'));
    _tempIndexFile = File(path.join(boxDirectory.path, 'index.temp.jsonl'));
    _lockFile = File(path.join(boxDirectory.path, '.lock'));
  }

  /// Открыть коробку
  static Future<SimpleBox<T>> open<T>({
    required Directory baseDir,
    required String boxName,
    required FromMapFn<T> fromMap,
    required ToMapFn<T> toMap,
    CryptoBox? crypto,
    bool autoCompactionEnabled = true,
    double compactionThreshold = 0.3, // 30% удаленных записей
    Duration? autoCompactionInterval, // например: Duration(hours: 1)
  }) async {
    final boxDirectory = Directory(path.join(baseDir.path, boxName));

    final box = SimpleBox<T>._(
      boxDirectory: boxDirectory,
      boxName: boxName,
      fromMap: fromMap,
      toMap: toMap,
      crypto: crypto,
      autoCompactionEnabled: autoCompactionEnabled,
      compactionThreshold: compactionThreshold,
      autoCompactionInterval: autoCompactionInterval,
    );

    await box._initialize();
    return box;
  }

  /// Инициализация коробки
  Future<void> _initialize() async {
    return await _dataLock.synchronized(() async {
      if (_isInitialized) return;

      // Создаем директорию если не существует
      if (!await boxDirectory.exists()) {
        await boxDirectory.create(recursive: true);
      }

      // Создаем блокировку
      await _acquireFileLock();

      try {
        // Создаем бэкап если файл данных существует
        if (await _dataFile.exists()) {
          await _createBackup();
        }

        // Загружаем индекс и проверяем целостность
        try {
          await _loadIndex();
          await _verifyDataIntegrity();
        } catch (e) {
          print('Warning: Data integrity check failed: $e');
          await _attemptRecovery();
        }

        // Подсчитываем количество удаленных записей (включая tombstones)
        _deletedRecordsCount = await _countDeletedRecords();

        // Запускаем автоматическую компактификацию если включена
        _startAutoCompaction();

        _isInitialized = true;
      } catch (e) {
        await _releaseFileLock();
        rethrow;
      }
    });
  }

  /// Создание блокировки файла для предотвращения конкурентного доступа
  Future<void> _acquireFileLock() async {
    try {
      final maxRetries = 10;
      const retryDelay = Duration(milliseconds: 100);

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          if (await _lockFile.exists()) {
            // Проверяем, не является ли блокировка устаревшей (больше 30 секунд)
            final lockStat = await _lockFile.stat();
            final now = DateTime.now();
            final lockAge = now.difference(lockStat.modified);

            if (lockAge.inSeconds > 30) {
              print(
                'Warning: Removing stale lock file (age: ${lockAge.inSeconds}s)',
              );
              try {
                await _lockFile.delete();
              } catch (e) {
                // Если не можем удалить, возможно другой процесс уже это сделал
                if (attempt == maxRetries - 1) {
                  throw ManifestError('Cannot remove stale lock file: $e');
                }
                await Future.delayed(retryDelay);
                continue;
              }
            } else {
              if (attempt == maxRetries - 1) {
                throw ManifestError(
                  'Box is locked by another process (lock age: ${lockAge.inSeconds}s)',
                );
              }
              await Future.delayed(retryDelay);
              continue;
            }
          }

          // Пытаемся создать блокировку атомарно
          final lockContent = '${DateTime.now().toIso8601String()}\n${pid}\n';

          // Используем временный файл для атомарного создания блокировки
          final tempLockFile = File('${_lockFile.path}.tmp');
          await tempLockFile.writeAsString(lockContent);

          try {
            // Пытаемся переименовать временный файл в файл блокировки
            // Это атомарная операция на большинстве файловых систем
            await tempLockFile.rename(_lockFile.path);
            return; // Успешно получили блокировку
          } catch (e) {
            // Блокировка уже существует, убираем временный файл
            try {
              await tempLockFile.delete();
            } catch (_) {}

            if (attempt == maxRetries - 1) {
              throw ManifestError(
                'Failed to acquire file lock after $maxRetries attempts: $e',
              );
            }
            await Future.delayed(retryDelay);
          }
        } catch (e) {
          if (e is ManifestError) rethrow;
          if (attempt == maxRetries - 1) {
            throw ManifestError('Failed to acquire file lock: $e');
          }
          await Future.delayed(retryDelay);
        }
      }
    } on FileSystemException catch (e) {
      throw ManifestError(
        'Failed to acquire file lock due to file system error: ${e.message}',
      );
    }
  }

  /// Освобождение блокировки файла
  Future<void> _releaseFileLock() async {
    try {
      if (await _lockFile.exists()) {
        await _lockFile.delete();
      }
    } catch (e) {
      print('Warning: Failed to release file lock: $e');
    }
  }

  /// Подсчет удаленных записей включая tombstones
  Future<int> _countDeletedRecords() async {
    return await _fileLock.synchronized(() async {
      if (!await _indexFile.exists()) {
        return 0;
      }

      try {
        final lines = await _indexFile.readAsLines();

        // Собираем информацию о всех записях по ID
        final Map<String, List<IndexEntry>> entriesById = {};
        final Set<String> deletedIds = {};

        for (final line in lines) {
          if (line.isEmpty || line == '\n') continue;

          try {
            final Map<String, dynamic> json = jsonDecode(line);
            final entry = IndexEntry.fromJson(json);

            // Группируем записи по ID
            entriesById.putIfAbsent(entry.id, () => []).add(entry);

            // Отмечаем ID как удаленный, если хотя бы одна запись помечена как удаленная
            if (entry.isDeleted) {
              deletedIds.add(entry.id);
            }
          } catch (e) {
            print(
              'Warning: Failed to parse index line during count: $line, error: $e',
            );
            continue;
          }
        }

        // Подсчитываем количество записей для удаленных ID
        int deletedCount = 0;
        for (final id in deletedIds) {
          deletedCount += entriesById[id]?.length ?? 0;
        }

        return deletedCount;
      } catch (e) {
        print('Warning: Failed to count deleted records: $e');
        return 0;
      }
    });
  }

  /// Создание бэкапа основного файла
  Future<void> _createBackup() async {
    try {
      if (await _dataFile.exists()) {
        await _dataFile.copy(_backupFile.path);
      }
    } catch (e) {
      throw ManifestError('Failed to create backup: $e');
    }
  }

  /// Загрузка индекса из файла
  Future<void> _loadIndex() async {
    return await _fileLock.synchronized(() async {
      _index.clear();

      if (!await _indexFile.exists()) {
        // Если индекс не существует, но есть данные, нужно его пересоздать
        if (await _dataFile.exists()) {
          await _rebuildIndex();
        }
        return;
      }

      try {
        final lines = await _indexFile.readAsLines();

        // Сначала собираем все записи, группируя по ID
        final Map<String, List<IndexEntry>> entriesById = {};
        final Set<String> deletedIds = {};

        for (final line in lines) {
          if (line.isEmpty || line == '\n') continue;

          try {
            final Map<String, dynamic> json = jsonDecode(line);
            final entry = IndexEntry.fromJson(json);

            // Группируем записи по ID
            entriesById.putIfAbsent(entry.id, () => []).add(entry);

            // Отмечаем ID как удаленный, если хотя бы одна запись помечена как удаленная
            if (entry.isDeleted) {
              deletedIds.add(entry.id);
            }
          } catch (e) {
            print('Warning: Failed to parse index line: $line, error: $e');
            continue;
          }
        }

        // Теперь обрабатываем записи: если ID помечен как удаленный,
        // исключаем все записи с этим ID из активного индекса
        for (final id in entriesById.keys) {
          if (deletedIds.contains(id)) {
            // ID помечен как удаленный - удаляем из активного индекса
            _index.remove(id);
          } else {
            // Берем последнюю (самую свежую) не удаленную запись для этого ID
            final entries = entriesById[id]!;
            final activeEntries = entries.where((e) => !e.isDeleted).toList();

            if (activeEntries.isNotEmpty) {
              // Сортируем по timestamp и берем самую свежую
              activeEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              _index[id] = activeEntries.first;
            }
          }
        }
      } catch (e) {
        throw SegmentCorruptError('Failed to load index from file: $e');
      }
    });
  }

  /// Пересоздание индекса из файла данных
  Future<void> _rebuildIndex() async {
    return await _fileLock.synchronized(() async {
      _index.clear();

      if (!await _dataFile.exists()) {
        return;
      }

      try {
        final file = await _dataFile.open();
        int offset = 0;

        // Сначала собираем все записи, группируя по ID
        final Map<String, List<IndexEntry>> entriesById = {};
        final Set<String> deletedIds = {};

        try {
          while (true) {
            final startOffset = offset;
            final lineBytes = <int>[];

            // Читаем строку байт за байтом
            while (true) {
              final bytes = await file.read(1);
              if (bytes.isEmpty) break;

              offset += 1;
              if (bytes[0] == 10) break; // '\n'
              lineBytes.add(bytes[0]);
            }

            if (lineBytes.isEmpty) break;

            final line = utf8.decode(lineBytes);
            if (line.isEmpty || line == '\n') continue;

            try {
              String jsonData = line;

              // Расшифровка если нужно
              if (crypto != null) {
                try {
                  final container = jsonDecode(line) as Map<String, dynamic>;
                  if (!container.containsKey('payload') ||
                      !container.containsKey('nonce') ||
                      !container.containsKey('mac')) {
                    throw DecryptionError(
                      'Invalid encryption container format',
                    );
                  }
                  jsonData = await crypto!.decryptFromContainer(container);
                } catch (e) {
                  print(
                    'Warning: Failed to decrypt data line during index rebuild: $line, error: $e',
                  );
                  continue;
                }
              }

              final Map<String, dynamic> record = jsonDecode(jsonData);
              final String id = record['id'] as String;
              final bool isDeleted = record['deleted'] as bool? ?? false;
              final String timestamp =
                  record['timestamp'] as String? ??
                  DateTime.now().toUtc().toIso8601String();

              final length = offset - startOffset;
              final entry = IndexEntry(
                id: id,
                offset: startOffset,
                length: length,
                isDeleted: isDeleted,
                timestamp: timestamp,
                checksum: _calculateChecksum(line),
              );

              // Группируем записи по ID
              entriesById.putIfAbsent(id, () => []).add(entry);

              // Отмечаем ID как удаленный, если хотя бы одна запись помечена как удаленная
              if (isDeleted) {
                deletedIds.add(id);
              }
            } catch (e) {
              print(
                'Warning: Failed to parse data line during index rebuild: $line, error: $e',
              );
              continue;
            }
          }
        } finally {
          await file.close();
        }

        // Теперь обрабатываем записи: если ID помечен как удаленный,
        // исключаем все записи с этим ID из активного индекса
        for (final id in entriesById.keys) {
          if (deletedIds.contains(id)) {
            // ID помечен как удаленный - удаляем из активного индекса
            _index.remove(id);
          } else {
            // Берем последнюю (самую свежую) не удаленную запись для этого ID
            final entries = entriesById[id]!;
            final activeEntries = entries.where((e) => !e.isDeleted).toList();

            if (activeEntries.isNotEmpty) {
              // Сортируем по timestamp и берем самую свежую
              activeEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              _index[id] = activeEntries.first;
            }
          }
        }

        // Сохраняем пересозданный индекс
        await _saveIndex();
      } catch (e) {
        throw SegmentCorruptError('Failed to rebuild index: $e');
      }
    });
  }

  /// Сохранение индекса в файл
  Future<void> _saveIndex() async {
    return await _fileLock.synchronized(() async {
      try {
        final sink = _tempIndexFile.openWrite();

        try {
          for (final entry in _index.values) {
            final json = jsonEncode(entry.toJson());
            sink.writeln(json);
          }
        } finally {
          await sink.close();
        }

        // Атомарная замена файла индекса
        if (await _indexFile.exists()) {
          await _indexFile.delete();
        }
        await _tempIndexFile.rename(_indexFile.path);
      } catch (e) {
        // Очищаем временный файл при ошибке
        if (await _tempIndexFile.exists()) {
          await _tempIndexFile.delete();
        }
        throw WriterError('Failed to save index to file: $e');
      }
    });
  }

  /// Вычисление контрольной суммы для строки данных (консистентный метод)
  String _calculateChecksum(String data) {
    // Убираем завершающий перенос строки для консистентности
    final normalizedData = data.endsWith('\n')
        ? data.substring(0, data.length - 1)
        : data;
    final bytes = utf8.encode(normalizedData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Проверка целостности данных
  Future<void> _verifyDataIntegrity() async {
    if (!await _dataFile.exists() || _index.isEmpty) {
      return;
    }

    final corruptedEntries = <String>[];

    for (final entry in _index.values) {
      if (entry.isDeleted) continue;

      try {
        final file = await _dataFile.open();
        try {
          await file.setPosition(entry.offset);
          final bytes = await file.read(entry.length);
          final line = utf8.decode(bytes);
          // Удаляем только завершающий символ новой строки
          final normalizedLine = line.endsWith('\n')
              ? line.substring(0, line.length - 1)
              : line;

          final calculatedChecksum = _calculateChecksum(normalizedLine);
          if (calculatedChecksum != entry.checksum) {
            corruptedEntries.add(entry.id);
            print('Warning: Checksum mismatch for record ${entry.id}');
          }
        } finally {
          await file.close();
        }
      } catch (e) {
        corruptedEntries.add(entry.id);
        print('Warning: Failed to verify record ${entry.id}: $e');
      }
    }

    if (corruptedEntries.isNotEmpty) {
      throw SegmentCorruptError(
        'Data integrity check failed. Corrupted records: ${corruptedEntries.join(', ')}',
      );
    }
  }

  /// Попытка восстановления из бэкапа при обнаружении повреждений
  Future<void> _attemptRecovery() async {
    print('Attempting to recover from backup...');

    if (!await _backupFile.exists()) {
      throw ManifestError(
        'Data is corrupted and no backup file exists. Cannot recover.',
      );
    }

    try {
      // Копируем бэкап в основной файл
      await _backupFile.copy(_dataFile.path);

      // Удаляем поврежденный индекс
      if (await _indexFile.exists()) {
        await _indexFile.delete();
      }

      // Пересоздаем индекс из восстановленных данных
      await _rebuildIndex();

      // Проверяем целостность восстановленных данных
      await _verifyDataIntegrity();

      print('Successfully recovered from backup');
    } catch (e) {
      throw ManifestError('Failed to recover from backup: $e');
    }
  }

  /// Добавить документ с автоматически сгенерированным ID
  Future<String> add(T document) async {
    _ensureInitialized();
    if (document == null) {
      throw ArgumentError('Document cannot be null');
    }

    final id = _uuid.v4();
    await _writeRecord(id, document, deleted: false);
    return id;
  }

  /// Добавить документ с указанным ID (устаревший метод)
  // @Deprecated('Use add() method instead for auto-generated IDs')
  Future<void> put(String id, T document) async {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (document == null) {
      throw ArgumentError('Document cannot be null');
    }

    await _writeRecord(id, document, deleted: false);
  }

  /// Получить документ по ID
  Future<T?> get(String id) async {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    return await _dataLock.synchronized(() async {
      final entry = _index[id];
      if (entry == null || entry.isDeleted) {
        return null;
      }

      return await _readRecord(entry);
    });
  }

  /// Обновить существующий документ
  Future<bool> update(String id, T document) async {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (document == null) {
      throw ArgumentError('Document cannot be null');
    }

    return await _dataLock.synchronized(() async {
      final entry = _index[id];
      if (entry == null || entry.isDeleted) {
        return false; // Документ не найден
      }

      // Для обновления используем ту же логику записи, что и для новых записей
      // Это добавит новую запись в конец файла, а старая запись останется как tombstone
      await _writeRecordUnsafe(id, document, deleted: false);
      return true;
    });
  }

  /// Обновить существующий документ на месте (перезаписать в том же месте файла)
  ///
  /// ВАЖНО: Этот метод безопасно перезаписывает данные в том же месте файла:
  /// 1. Сначала записывает JSON данные
  /// 2. Заполняет оставшееся место пробелами (если новые данные короче)
  /// 3. Записывает '\n' в последний байт блока
  ///
  /// Такой подход гарантирует, что при чтении '\n' будет последним символом,
  /// что позволит правильно нормализовать строку и сохранить корректность контрольных сумм.
  ///
  /// Если новая запись не помещается в старое место, то старая запись помечается как удаленная
  /// в индексе, а новая добавляется в конец файла.
  Future<bool> updateInPlace(String id, T document) async {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (document == null) {
      throw ArgumentError('Document cannot be null');
    }

    return await _dataLock.synchronized(() async {
      final entry = _index[id];
      if (entry == null || entry.isDeleted) {
        return false; // Документ не найден
      }

      // Создаем новую запись
      final record = {
        'id': id,
        'data': toMap(document),
        'deleted': false,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      String jsonLine = jsonEncode(record);

      // Шифрование если нужно
      if (crypto != null) {
        try {
          final encrypted = await crypto!.encryptUtf8WithAutoNonce(jsonLine);
          jsonLine = jsonEncode(encrypted);
        } catch (e) {
          throw WriterError('Failed to encrypt record: $e');
        }
      }

      // Кодируем JSON без переноса строки для расчета размера
      final jsonBytes = utf8.encode(jsonLine);
      final newLength = jsonBytes.length + 1; // +1 для '\n' в конце

      // Проверяем, помещается ли новая запись в старое место
      if (newLength <= entry.length) {
        // Обновляем на месте
        try {
          // Используем FileMode.writeOnly для произвольной записи
          await _fileLock.synchronized(() async {
            final file = await _dataFile.open(mode: FileMode.writeOnly);
            try {
              await file.setPosition(entry.offset);

              // Записываем JSON данные
              await file.writeFrom(jsonBytes);

              // Если новая запись короче старой, заполняем пробелами
              if (newLength < entry.length) {
                final paddingLength = entry.length - newLength;
                final padding = List.filled(paddingLength, 32); // пробелы
                await file.writeFrom(padding);
              }

              // Записываем '\n' в последний байт
              await file.setPosition(entry.offset + entry.length - 1);
              await file.writeFrom([10]); // '\n'

              await file.flush();
            } finally {
              await file.close();
            }
          });

          // Вычисляем контрольную сумму от того, что фактически записано в блок
          String actualRecordedData = jsonLine;
          if (newLength < entry.length) {
            // Добавляем пробелы, которые были записаны как padding
            final paddingLength = entry.length - newLength;
            final padding = ' ' * paddingLength;
            actualRecordedData = jsonLine + padding;
          }

          final newChecksum = _calculateChecksum(actualRecordedData);
          final updatedEntry = IndexEntry(
            id: id,
            offset: entry.offset,
            length: entry.length, // сохраняем старую длину
            isDeleted: false,
            timestamp: record['timestamp'] as String,
            checksum: newChecksum,
          );

          _index[id] = updatedEntry;
          await _saveIndex();

          return true;
        } catch (e) {
          throw WriterError('Failed to update record in place: $e');
        }
      } else {
        // Новая запись не помещается в старое место
        // Помечаем старую запись как tombstone в индексе
        final oldEntry = IndexEntry(
          id: id,
          offset: entry.offset,
          length: entry.length,
          isDeleted: true,
          timestamp: DateTime.now().toUtc().toIso8601String(),
          checksum: entry.checksum, // сохраняем старую контрольную сумму
        );

        // Добавляем tombstone в индексный файл
        await _appendToIndex(oldEntry);

        // Увеличиваем счетчик удаленных записей
        _deletedRecordsCount++;

        // Добавляем новую запись в конец файла
        await _writeRecordUnsafe(id, document, deleted: false);

        // Проверяем необходимость автоматической компактификации
        await _checkAutoCompaction();

        return true;
      }
    });
  }

  /// Удалить документ по ID
  Future<bool> delete(String id) async {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    return await _dataLock.synchronized(() async {
      final entry = _index[id];
      if (entry == null || entry.isDeleted) {
        return false; // Документ не найден или уже удален
      }

      await _writeRecordUnsafe(id, null, deleted: true);
      return true;
    });
  }

  /// Чтение записи из файла по индексу
  Future<T> _readRecord(IndexEntry entry) async {
    return await _fileLock.synchronized(() async {
      try {
        final file = await _dataFile.open();

        try {
          await file.setPosition(entry.offset);
          final bytes = await file.read(entry.length);
          final line = utf8.decode(bytes);
          // Удаляем только завершающий символ новой строки
          final normalizedLine = line.endsWith('\n')
              ? line.substring(0, line.length - 1)
              : line;

          // TODO: ошибки при обовлении данных - контрольная сумма не совпадает
          // Проверяем контрольную сумму при чтении (консистентно)
          final calculatedChecksum = _calculateChecksum(normalizedLine);
          if (calculatedChecksum != entry.checksum) {
            throw SegmentCorruptError(
              'Checksum mismatch for record ${entry.id}. Expected: ${entry.checksum}, Got: $calculatedChecksum',
            );
          }

          String jsonData = normalizedLine;

          // Расшифровка если нужно
          if (crypto != null) {
            try {
              final container = jsonDecode(line) as Map<String, dynamic>;
              if (!container.containsKey('payload') ||
                  !container.containsKey('nonce') ||
                  !container.containsKey('mac')) {
                throw DecryptionError('Invalid encryption container format');
              }
              jsonData = await crypto!.decryptFromContainer(container);
            } catch (e) {
              throw DecryptionError('Failed to decrypt record ${entry.id}: $e');
            }
          }

          final Map<String, dynamic> record = jsonDecode(jsonData);
          final data = record['data'] as Map<String, dynamic>;
          return fromMap(data);
        } finally {
          await file.close();
        }
      } catch (e) {
        throw SegmentCorruptError('Failed to read record ${entry.id}: $e');
      }
    });
  }

  /// Запись записи в файл с использованием RandomAccessFile для надежности
  Future<void> _writeRecord(
    String id,
    T? document, {
    required bool deleted,
  }) async {
    return await _dataLock.synchronized(() async {
      await _writeRecordUnsafe(id, document, deleted: deleted);
    });
  }

  /// Запись записи в файл без блокировки мьютекса (для использования внутри synchronized блоков)
  Future<void> _writeRecordUnsafe(
    String id,
    T? document, {
    required bool deleted,
  }) async {
    if (!deleted && document == null) {
      throw ArgumentError('Document cannot be null when not deleted');
    }

    try {
      final record = {
        'id': id,
        'data': deleted ? null : toMap(document!),
        'deleted': deleted,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      String jsonLine = jsonEncode(record);

      // Шифрование если нужно
      if (crypto != null) {
        try {
          final encrypted = await crypto!.encryptUtf8WithAutoNonce(jsonLine);
          jsonLine = jsonEncode(encrypted);
        } catch (e) {
          throw WriterError('Failed to encrypt record: $e');
        }
      }

      // Получаем текущий размер файла (это будет offset новой записи)
      final fileSize = await _dataFile.exists() ? await _dataFile.length() : 0;

      // Записываем с использованием RandomAccessFile для большей надежности
      await _fileLock.synchronized(() async {
        final file = await _dataFile.open(mode: FileMode.writeOnlyAppend);
        try {
          await file.setPosition(fileSize);
          final lineWithNewline = '$jsonLine\n';
          final bytes = utf8.encode(lineWithNewline);
          await file.writeFrom(bytes);
          await file.flush(); // Принудительная синхронизация с диском
        } finally {
          await file.close();
        }
      });

      // Получаем новый размер файла
      final newSize = await _dataFile.length();
      final length = newSize - fileSize;

      // Вычисляем контрольную сумму для записанной строки (консистентно)
      final checksum = _calculateChecksum(jsonLine);

      final entry = IndexEntry(
        id: id,
        offset: fileSize,
        length: length,
        isDeleted: deleted,
        timestamp: record['timestamp'] as String,
        checksum: checksum,
      );

      // Обновляем счетчик удаленных записей
      final existingEntry = _index[id];
      if (deleted) {
        _index.remove(id);
        if (existingEntry != null && !existingEntry.isDeleted) {
          _deletedRecordsCount++;
        }
      } else {
        _index[id] = entry;
        if (existingEntry != null && existingEntry.isDeleted) {
          _deletedRecordsCount--;
        }
      }

      // Добавляем запись в индекс с использованием RandomAccessFile
      await _appendToIndex(entry);

      // Проверяем необходимость автоматической компактификации после удаления
      if (deleted) {
        await _checkAutoCompaction();
      }
    } catch (e) {
      throw WriterError('Failed to write record: $e');
    }
  }

  /// Добавить запись в индексный файл с использованием RandomAccessFile
  Future<void> _appendToIndex(IndexEntry entry) async {
    return await _fileLock.synchronized(() async {
      try {
        final json = jsonEncode(entry.toJson());
        final lineWithNewline = '$json\n';

        final file = await _indexFile.open(mode: FileMode.writeOnlyAppend);
        try {
          final bytes = utf8.encode(lineWithNewline);
          await file.writeFrom(bytes);
          await file.flush(); // Принудительная синхронизация с диском
        } finally {
          await file.close();
        }
      } catch (e) {
        throw WriterError('Failed to append to index: $e');
      }
    });
  }

  /// Запуск автоматической компактификации
  void _startAutoCompaction() {
    if (!_autoCompactionEnabled) return;

    // Запускаем периодический таймер если указан интервал
    final interval = _autoCompactionInterval;
    if (interval != null) {
      _compactionTimer = Timer.periodic(interval, (timer) async {
        try {
          await _performAutoCompaction();
        } catch (e) {
          print('Warning: Auto compaction failed: $e');
        }
      });
    }
  }

  /// Выполнение автоматической компактификации
  Future<void> _performAutoCompaction() async {
    if (!_autoCompactionEnabled || !_isInitialized) return;

    final totalRecords = _index.length;
    if (totalRecords == 0) return;

    final deletionRatio = _deletedRecordsCount / totalRecords;

    if (deletionRatio >= _compactionThreshold) {
      print(
        'Auto compaction triggered: ${(_deletedRecordsCount / totalRecords * 100).toStringAsFixed(1)}% deleted records',
      );
      await compact();
      print('Auto compaction completed');
    }
  }

  /// Проверка необходимости компактификации после удаления
  Future<void> _checkAutoCompaction() async {
    if (!_autoCompactionEnabled) return;

    final totalRecords = _index.length;
    if (totalRecords == 0) return;

    final deletionRatio = _deletedRecordsCount / totalRecords;

    if (deletionRatio >= _compactionThreshold) {
      print(
        'Auto compaction triggered after deletion: ${(_deletedRecordsCount / totalRecords * 100).toStringAsFixed(1)}% deleted records',
      );
      await compact();
      print('Auto compaction completed');
    }
  }

  /// Получить все документы как поток
  Stream<T> getAll() async* {
    _ensureInitialized();

    // Получаем копию индекса под блокировкой для безопасной итерации
    final List<IndexEntry> entries = await _dataLock.synchronized(() async {
      return _index.values.where((entry) => !entry.isDeleted).toList();
    });

    for (final entry in entries) {
      try {
        yield await _readRecord(entry);
      } catch (e) {
        print('Warning: Failed to read record ${entry.id}: $e');
        continue;
      }
    }
  }

  /// Запрос с предикатом
  Stream<T> query(bool Function(T) predicate) async* {
    _ensureInitialized();

    // Получаем копию индекса под блокировкой для безопасной итерации
    final List<IndexEntry> entries = await _dataLock.synchronized(() async {
      return _index.values.where((entry) => !entry.isDeleted).toList();
    });

    for (final entry in entries) {
      try {
        final document = await _readRecord(entry);
        if (predicate(document)) {
          yield document;
        }
      } catch (e) {
        print('Warning: Failed to read record ${entry.id}: $e');
        continue;
      }
    }
  }

  /// Получить все ключи
  List<String> getAllKeys() {
    _ensureInitialized();
    // Этот метод читает только индекс, который уже защищен _dataLock в других операциях
    return _index.keys.where((key) => !_index[key]!.isDeleted).toList();
  }

  /// Проверить существование документа
  bool containsKey(String id) {
    _ensureInitialized();
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    final entry = _index[id];
    return entry != null && !entry.isDeleted;
  }

  /// Получить количество документов
  int get length {
    _ensureInitialized();
    return _index.values.where((entry) => !entry.isDeleted).length;
  }

  /// Очистить все данные
  Future<void> clear() async {
    _ensureInitialized();

    return await _dataLock.synchronized(() async {
      _index.clear();
      _deletedRecordsCount = 0; // Сбрасываем счетчик удаленных записей

      // Создаем пустые файлы
      await _dataFile.writeAsString('');
      await _indexFile.writeAsString('');
    });
  }

  /// Компактификация - переписать файл без удаленных записей
  Future<void> compact() async {
    _ensureInitialized();

    return await _dataLock.synchronized(() async {
      final activeEntries = _index.values
          .where((entry) => !entry.isDeleted)
          .toList();

      if (activeEntries.isEmpty) {
        await clear();
        return;
      }

      try {
        // Читаем все активные записи
        final records = <Map<String, dynamic>>[];

        for (final entry in activeEntries) {
          try {
            final document = await _readRecord(entry);
            records.add({
              'id': entry.id,
              'data': toMap(document),
              'deleted': false,
              'timestamp': entry.timestamp,
            });
          } catch (e) {
            print(
              'Warning: Failed to read record ${entry.id} during compaction: $e',
            );
            continue;
          }
        }

        // Записываем во временный файл с использованием RandomAccessFile
        final tempFile = await _tempFile.open(mode: FileMode.write);
        final newIndex = <String, IndexEntry>{};
        int offset = 0;

        try {
          for (final record in records) {
            String jsonLine = jsonEncode(record);

            // Шифрование если нужно
            if (crypto != null) {
              try {
                final encrypted = await crypto!.encryptUtf8WithAutoNonce(
                  jsonLine,
                );
                jsonLine = jsonEncode(encrypted);
              } catch (e) {
                throw WriterError(
                  'Failed to encrypt record during compaction: $e',
                );
              }
            }

            final startOffset = offset;
            final lineWithNewline = '$jsonLine\n';
            final bytes = utf8.encode(lineWithNewline);
            await tempFile.writeFrom(bytes);
            offset += bytes.length;

            // Создаем новую запись индекса
            final recordChecksum = _calculateChecksum(jsonLine);
            final entry = IndexEntry(
              id: record['id'] as String,
              offset: startOffset,
              length: offset - startOffset,
              isDeleted: false,
              timestamp: record['timestamp'] as String,
              checksum: recordChecksum,
            );
            newIndex[entry.id] = entry;
          }

          await tempFile.flush(); // Принудительная синхронизация
        } finally {
          await tempFile.close();
        }

        // Атомарная замена файлов
        if (await _dataFile.exists()) {
          await _dataFile.delete();
        }
        await _tempFile.rename(_dataFile.path);

        // Обновляем индекс
        _index.clear();
        _index.addAll(newIndex);
        _deletedRecordsCount = 0; // Сбрасываем счетчик удаленных записей
        await _saveIndex();
      } catch (e) {
        // Очищаем временный файл при ошибке
        if (await _tempFile.exists()) {
          await _tempFile.delete();
        }
        throw WriterError('Failed to compact box: $e');
      }
    });
  }

  /// Восстановить из бэкапа
  Future<void> restoreFromBackup() async {
    _ensureInitialized();

    if (!await _backupFile.exists()) {
      throw ManifestError('Backup file does not exist');
    }

    try {
      // Копируем бэкап в основной файл
      await _backupFile.copy(_dataFile.path);

      // Удаляем старый индекс и пересоздаем из восстановленных данных
      if (await _indexFile.exists()) {
        await _indexFile.delete();
      }

      await _rebuildIndex();
    } catch (e) {
      throw ManifestError('Failed to restore from backup: $e');
    }
  }

  /// Получить статистику коробки
  Future<Map<String, dynamic>> getStats() async {
    _ensureInitialized();

    return await _dataLock.synchronized(() async {
      final dataFileSize = await _dataFile.exists()
          ? await _dataFile.length()
          : 0;
      final indexFileSize = await _indexFile.exists()
          ? await _indexFile.length()
          : 0;
      final backupFileSize = await _backupFile.exists()
          ? await _backupFile.length()
          : 0;

      final activeRecords = _index.values
          .where((entry) => !entry.isDeleted)
          .length;

      // Получаем правильный подсчет удаленных записей из индексного файла
      final deletedRecords = await _countDeletedRecords();
      final totalRecords = activeRecords + deletedRecords;

      return {
        'boxName': boxName,
        'totalRecords': totalRecords,
        'activeRecords': activeRecords,
        'deletedRecords': deletedRecords,
        'encrypted': crypto != null,
        'dataFileSize': dataFileSize,
        'indexFileSize': indexFileSize,
        'backupFileSize': backupFileSize,
        'hasBackup': await _backupFile.exists(),
        'autoCompaction': getAutoCompactionInfo(),
      };
    });
  }

  /// Проверить целостность данных вручную
  Future<Map<String, dynamic>> checkIntegrity() async {
    _ensureInitialized();

    return await _dataLock.synchronized(() async {
      final result = {
        'isValid': true,
        'corruptedRecords': <String>[],
        'totalChecked': 0,
        'errors': <String>[],
      };

      if (!await _dataFile.exists() || _index.isEmpty) {
        return result;
      }

      final corruptedEntries = <String>[];
      final errors = <String>[];
      int totalChecked = 0;

      for (final entry in _index.values) {
        if (entry.isDeleted) continue;

        totalChecked++;

        try {
          final file = await _dataFile.open();
          try {
            await file.setPosition(entry.offset);
            final bytes = await file.read(entry.length);
            final line = utf8.decode(bytes);
            // Удаляем только завершающий символ новой строки
            final normalizedLine = line.endsWith('\n')
                ? line.substring(0, line.length - 1)
                : line;

            final calculatedChecksum = _calculateChecksum(normalizedLine);
            if (calculatedChecksum != entry.checksum) {
              corruptedEntries.add(entry.id);
              errors.add('Checksum mismatch for record ${entry.id}');
            }

            // Дополнительная проверка структуры данных
            try {
              String jsonData = normalizedLine;

              // Проверяем расшифровку если нужно
              if (crypto != null) {
                final container = jsonDecode(line) as Map<String, dynamic>;
                if (!container.containsKey('payload') ||
                    !container.containsKey('nonce') ||
                    !container.containsKey('mac')) {
                  corruptedEntries.add(entry.id);
                  errors.add(
                    'Invalid encryption container for record ${entry.id}',
                  );
                  continue;
                }
                jsonData = await crypto!.decryptFromContainer(container);
              }

              final record = jsonDecode(jsonData) as Map<String, dynamic>;
              if (!record.containsKey('id') ||
                  !record.containsKey('data') ||
                  !record.containsKey('deleted')) {
                corruptedEntries.add(entry.id);
                errors.add('Invalid record structure for record ${entry.id}');
              }
            } catch (e) {
              corruptedEntries.add(entry.id);
              errors.add(
                'Failed to parse record structure for ${entry.id}: $e',
              );
            }
          } finally {
            await file.close();
          }
        } catch (e) {
          corruptedEntries.add(entry.id);
          errors.add('Failed to verify record ${entry.id}: $e');
        }
      }

      result['isValid'] = corruptedEntries.isEmpty;
      result['corruptedRecords'] = corruptedEntries;
      result['totalChecked'] = totalChecked;
      result['errors'] = errors;

      return result;
    });
  }

  /// Включить автоматическую компактификацию
  void enableAutoCompaction({
    double? compactionThreshold,
    Duration? autoCompactionInterval,
  }) {
    _ensureInitialized();

    // Останавливаем существующий таймер
    _compactionTimer?.cancel();
    _compactionTimer = null;

    // Перезапускаем с новыми настройками если нужно
    if (autoCompactionInterval != null) {
      _compactionTimer = Timer.periodic(autoCompactionInterval, (timer) async {
        try {
          await _performAutoCompaction();
        } catch (e) {
          print('Warning: Auto compaction failed: $e');
        }
      });
    }
  }

  /// Отключить автоматическую компактификацию
  void disableAutoCompaction() {
    _compactionTimer?.cancel();
    _compactionTimer = null;
  }

  /// Принудительно запустить компактификацию если нужно
  Future<bool> forceCompactionIfNeeded() async {
    _ensureInitialized();

    final totalRecords = _index.length;
    if (totalRecords == 0) return false;

    final deletionRatio = _deletedRecordsCount / totalRecords;

    if (deletionRatio >= _compactionThreshold) {
      await compact();
      return true;
    }

    return false;
  }

  /// Получить информацию об автоматической компактификации
  Map<String, dynamic> getAutoCompactionInfo() {
    return {
      'enabled': _autoCompactionEnabled,
      'threshold': _compactionThreshold,
      'interval': _autoCompactionInterval?.inMilliseconds,
      'deletedRecordsCount': _deletedRecordsCount,
      'totalRecords': _index.length,
      'deletionRatio': _index.length > 0
          ? _deletedRecordsCount / _index.length
          : 0.0,
      'needsCompaction':
          _index.length > 0 &&
          (_deletedRecordsCount / _index.length) >= _compactionThreshold,
    };
  }

  /// Закрыть коробку
  Future<void> close() async {
    return await _dataLock.synchronized(() async {
      // Останавливаем таймер автоматической компактификации
      _compactionTimer?.cancel();
      _compactionTimer = null;

      // Сохраняем индекс перед закрытием
      if (_isInitialized) {
        try {
          await _saveIndex();
        } catch (e) {
          print('Warning: Failed to save index during close: $e');
        }
      }

      // Освобождаем блокировку файла
      await _releaseFileLock();

      _index.clear();
      _deletedRecordsCount = 0;
      _isInitialized = false;
    });
  }

  /// Проверить инициализацию
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw ManifestError('Box is not initialized');
    }
  }
}
