import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:hoplixi/core/index.dart';
import '../models/database_entry.dart';
import '../repository/service_results.dart';

/// Результат операции с историей базы данных
class DatabaseHistoryResult extends ServiceResult<DatabaseEntry> {
  final DatabaseEntry? entry;

  DatabaseHistoryResult({required super.success, super.message, this.entry})
    : super(data: entry);

  DatabaseHistoryResult.success({DatabaseEntry? entry, super.message})
    : entry = entry,
      super.success(data: entry);

  DatabaseHistoryResult.error(super.message) : entry = null, super.error();
}

/// Сервис для управления историей подключений к базам данных (v2 на основе box_db_new)
class DatabaseHistoryServiceV2 {
  static const String _boxName = 'database_history';
  BoxDB<DatabaseEntry>? _historyBox;
  final BoxManager _boxManager;

  DatabaseHistoryServiceV2({required BoxManager boxManager})
    : _boxManager = boxManager;

  /// Инициализация сервиса
  Future<ServiceResult<void>> initialize() async {
    try {
      // Проверяем, не открыт ли уже бокс
      if (_boxManager.isBoxOpen(_boxName)) {
        _historyBox = _boxManager.getBox<DatabaseEntry>(_boxName);
        logDebug(
          'DatabaseHistoryServiceV2: бокс уже открыт',
          tag: 'DatabaseHistoryServiceV2',
        );
        return ServiceResult.success(message: 'Сервис уже инициализирован');
      }

      // Проверяем, существует ли бокс
      final boxPath = '${_boxManager.basePath}/$_boxName';
      final boxExists = await Directory(boxPath).exists();

      if (boxExists) {
        // Открываем существующий бокс
        _historyBox = await _boxManager.openBox<DatabaseEntry>(
          name: _boxName,

          fromJson: DatabaseEntry.fromJson,
          toJson: (entry) => entry.toJson(),
          getId: _pathToKey,
        );
        logDebug(
          'DatabaseHistoryServiceV2: существующий бокс открыт',
          tag: 'DatabaseHistoryServiceV2',
        );
      } else {
        // Создаем новый бокс
        final key = await EncryptionService.generate();
        _historyBox = await _boxManager.createBox<DatabaseEntry>(
          name: _boxName,
          password: await key.exportKey(),
          fromJson: DatabaseEntry.fromJson,
          toJson: (entry) => entry.toJson(),
          getId: _pathToKey,
        );
        logDebug(
          'DatabaseHistoryServiceV2: новый бокс создан',
          tag: 'DatabaseHistoryServiceV2',
        );
      }

      return ServiceResult.success(
        message: 'DatabaseHistoryServiceV2 инициализирован',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации DatabaseHistoryServiceV2',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось инициализировать сервис истории: ${e.toString()}',
      );
    }
  }

  /// Записывает доступ к базе данных в историю
  Future<DatabaseHistoryResult> recordDatabaseAccess({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
  }) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return DatabaseHistoryResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final now = DateTime.now();
      final id = _pathStringToKey(path);

      // Проверяем, есть ли уже запись с таким путем
      final existingEntry = await _historyBox!.get(id);

      final DatabaseEntry entry;
      if (existingEntry != null) {
        // Обновляем существующую запись, сохраняя дату создания
        entry = DatabaseEntry(
          path: path,
          name: name,
          description: description,
          masterPassword: saveMasterPassword ? masterPassword : null,
          saveMasterPassword: saveMasterPassword,
          lastAccessed: now,
          createdAt: existingEntry.createdAt, // Сохраняем исходную дату
        );
        await _historyBox!.update(entry);
        logDebug(
          'Обновление существующей записи в истории для пути: $path',
          tag: 'DatabaseHistoryServiceV2',
        );
      } else {
        // Создаем новую запись
        entry = DatabaseEntry(
          path: path,
          name: name,
          description: description,
          masterPassword: saveMasterPassword ? masterPassword : null,
          saveMasterPassword: saveMasterPassword,
          lastAccessed: now,
          createdAt: now, // Устанавливаем дату создания только для новых
        );
        await _historyBox!.insert(entry);
        logDebug(
          'Создание новой записи в истории для пути: $path',
          tag: 'DatabaseHistoryServiceV2',
        );
      }

      logDebug(
        'Запись о доступе к БД добавлена в историю',
        tag: 'DatabaseHistoryServiceV2',
        data: {
          'path': path,
          'name': name,
          'saveMasterPassword': saveMasterPassword,
        },
      );

      return DatabaseHistoryResult.success(
        entry: entry,
        message: 'Запись успешно сохранена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка записи доступа к БД в историю',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path, 'name': name},
      );
      return DatabaseHistoryResult.error(
        'Не удалось записать доступ к БД: ${e.toString()}',
      );
    }
  }

  /// Получает все записи истории, отсортированные по дате последнего доступа
  Future<ServiceResult<List<DatabaseEntry>>> getAllHistory() async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      // Получаем все записи, уже отсортированные по времени (новые сначала)
      final entriesList = await _historyBox!.getAllSortedByTime(
        ascending: false,
      );

      logDebug(
        'Получена история БД: ${entriesList.length} записей',
        tag: 'DatabaseHistoryServiceV2',
      );

      return ServiceResult.success(
        data: entriesList,
        message: 'История успешно получена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось получить историю: ${e.toString()}',
      );
    }
  }

  /// Получает запись по пути к базе данных
  Future<DatabaseHistoryResult> getEntryByPath(String path) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return DatabaseHistoryResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final id = _pathStringToKey(path);
      final entry = await _historyBox!.get(id);

      if (entry == null) {
        return DatabaseHistoryResult.error('Запись не найдена');
      }

      return DatabaseHistoryResult.success(
        entry: entry,
        message: 'Запись успешно получена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения записи БД по пути',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path},
      );
      return DatabaseHistoryResult.error(
        'Не удалось получить запись: ${e.toString()}',
      );
    }
  }

  /// Удаляет запись из истории
  Future<ServiceResult<void>> removeEntry(String path) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final id = _pathStringToKey(path);
      await _historyBox!.delete(id);

      logDebug(
        'Запись удалена из истории БД',
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path},
      );

      return ServiceResult.success(message: 'Запись успешно удалена');
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления записи из истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path},
      );
      return ServiceResult.error('Не удалось удалить запись: ${e.toString()}');
    }
  }

  /// Очищает всю историю
  Future<ServiceResult<void>> clearHistory() async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      await _historyBox!.clear();

      logInfo('История БД очищена', tag: 'DatabaseHistoryServiceV2');

      return ServiceResult.success(message: 'История успешно очищена');
    } catch (e, stackTrace) {
      logError(
        'Ошибка очистки истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось очистить историю: ${e.toString()}',
      );
    }
  }

  /// Получает записи с сохраненными паролями
  Future<ServiceResult<List<DatabaseEntry>>>
  getEntriesWithSavedPasswords() async {
    final result = await getAllHistory();

    if (!result.success || result.data == null) {
      return ServiceResult.error(
        result.message ?? 'Не удалось получить историю',
      );
    }

    try {
      final entriesWithPasswords = result.data!
          .where(
            (entry) =>
                entry.saveMasterPassword &&
                entry.masterPassword != null &&
                entry.masterPassword!.isNotEmpty,
          )
          .toList();

      return ServiceResult.success(
        data: entriesWithPasswords,
        message: 'Записи с паролями получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка фильтрации записей с паролями',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось отфильтровать записи: ${e.toString()}',
      );
    }
  }

  /// Обновляет информацию о базе данных
  Future<DatabaseHistoryResult> updateDatabaseInfo({
    required String path,
    String? name,
    String? description,
  }) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return DatabaseHistoryResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final id = _pathStringToKey(path);
      final existingEntry = await _historyBox!.get(id);

      if (existingEntry == null) {
        return DatabaseHistoryResult.error('Запись не найдена');
      }

      final updatedEntry = existingEntry.copyWith(
        name: name ?? existingEntry.name,
        description: description ?? existingEntry.description,
        lastAccessed: DateTime.now(),
      );

      await _historyBox!.update(updatedEntry);

      logDebug(
        'Информация о БД обновлена',
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path, 'name': name},
      );

      return DatabaseHistoryResult.success(
        entry: updatedEntry,
        message: 'Информация успешно обновлена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления информации о БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
        data: {'path': path},
      );
      return DatabaseHistoryResult.error(
        'Не удалось обновить информацию: ${e.toString()}',
      );
    }
  }

  /// Получает недавние записи
  ///
  /// [limit] - максимальное количество записей (по умолчанию 10)
  /// [since] - получить записи после указанного времени (опционально)
  Future<ServiceResult<List<DatabaseEntry>>> getRecent({
    int limit = 10,
    DateTime? since,
  }) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final entries = await _historyBox!.getRecent(limit: limit, since: since);

      logDebug(
        'Получено ${entries.length} недавних записей',
        tag: 'DatabaseHistoryServiceV2',
      );

      return ServiceResult.success(
        data: entries,
        message: 'Недавние записи получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения недавних записей',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось получить недавние записи: ${e.toString()}',
      );
    }
  }

  /// Получает записи за указанный период времени
  Future<ServiceResult<List<DatabaseEntry>>> getByTimeRange({
    required DateTime from,
    DateTime? to,
  }) async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final entries = await _historyBox!.getByTimeRange(from: from, to: to);

      logDebug(
        'Получено ${entries.length} записей за период',
        tag: 'DatabaseHistoryServiceV2',
      );

      return ServiceResult.success(
        data: entries,
        message: 'Записи за период получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения записей за период',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось получить записи за период: ${e.toString()}',
      );
    }
  }

  /// Получает статистику истории
  Future<ServiceResult<Map<String, dynamic>>> getHistoryStats() async {
    try {
      final result = await getAllHistory();

      if (!result.success || result.data == null) {
        return ServiceResult.error(
          result.message ?? 'Не удалось получить историю',
        );
      }

      final allEntries = result.data!;
      final entriesWithPasswords = allEntries
          .where((e) => e.saveMasterPassword)
          .length;

      DateTime? oldestDate;
      DateTime? newestDate;

      if (allEntries.isNotEmpty) {
        final dates = allEntries
            .map((e) => e.createdAt)
            .where((d) => d != null)
            .cast<DateTime>()
            .toList();

        if (dates.isNotEmpty) {
          dates.sort();
          oldestDate = dates.first;
        }

        final accessDates = allEntries
            .map((e) => e.lastAccessed ?? e.createdAt)
            .where((d) => d != null)
            .cast<DateTime>()
            .toList();

        if (accessDates.isNotEmpty) {
          accessDates.sort();
          newestDate = accessDates.last;
        }
      }

      final stats = {
        'totalEntries': allEntries.length,
        'entriesWithSavedPasswords': entriesWithPasswords,
        'oldestEntry': oldestDate,
        'newestEntry': newestDate,
      };

      return ServiceResult.success(data: stats, message: 'Статистика получена');
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось получить статистику: ${e.toString()}',
      );
    }
  }

  /// Получает количество записей в истории
  Future<ServiceResult<int>> getCount() async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      final count = await _historyBox!.count();

      return ServiceResult.success(
        data: count,
        message: 'Количество записей получено',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества записей',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось получить количество: ${e.toString()}',
      );
    }
  }

  /// Выполняет компактификацию хранилища (удаление помеченных записей)
  Future<ServiceResult<void>> compact() async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      await _historyBox!.compact();

      logInfo(
        'Компактификация истории БД выполнена',
        tag: 'DatabaseHistoryServiceV2',
      );

      return ServiceResult.success(message: 'Компактификация выполнена');
    } catch (e, stackTrace) {
      logError(
        'Ошибка компактификации истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось выполнить компактификацию: ${e.toString()}',
      );
    }
  }

  /// Создает резервную копию истории
  Future<ServiceResult<void>> createBackup() async {
    if (_historyBox == null) {
      final initResult = await initialize();
      if (!initResult.success) {
        return ServiceResult.error(
          initResult.message ?? 'Ошибка инициализации',
        );
      }
    }

    try {
      await _historyBox!.backup();

      logInfo(
        'Резервная копия истории БД создана',
        tag: 'DatabaseHistoryServiceV2',
      );

      return ServiceResult.success(message: 'Резервная копия создана');
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания резервной копии истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
      return ServiceResult.error(
        'Не удалось создать резервную копию: ${e.toString()}',
      );
    }
  }

  /// Закрывает сервис и освобождает ресурсы
  Future<void> dispose() async {
    try {
      if (_historyBox != null) {
        await _boxManager.closeBox(_boxName);
        _historyBox = null;
      }

      logDebug(
        'DatabaseHistoryServiceV2 закрыт',
        tag: 'DatabaseHistoryServiceV2',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка закрытия DatabaseHistoryServiceV2',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryServiceV2',
      );
    }
  }

  /// Преобразует путь в ключ для хранения (для getId callback)
  String _pathToKey(DatabaseEntry entry) {
    // Нормализуем путь и используем его как ключ
    return p.normalize(entry.path).toLowerCase();
  }

  /// Преобразует путь строку в ключ для хранения
  String _pathStringToKey(String path) {
    // Нормализуем путь и используем его как ключ
    return p.normalize(path).toLowerCase();
  }
}
