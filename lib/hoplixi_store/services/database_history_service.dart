import 'dart:io';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../box_db/simple_box_manager.dart';
import '../../box_db/simple_box.dart';
import '../../core/logger/app_logger.dart';
import '../models/database_entry.dart';

/// Сервис для управления историей подключений к базам данных
class DatabaseHistoryService {
  static const String _boxName = 'database_history';
  SimpleBox<DatabaseEntry>? _historyBox;
  SimpleBoxManager? _boxManager;

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      // Получаем директорию для хранения истории
      final appDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory(p.join(appDir.path, MainConstants.appFolderName, 'box'));

      // Инициализируем менеджер коробок
      _boxManager = await SimpleBoxManager.getInstance(
        baseDirectory: historyDir,
      );

      // Открываем коробку для истории
      _historyBox = await _boxManager!.openBox<DatabaseEntry>(
        boxName: _boxName,
        fromMap: _databaseEntryFromMap,
        toMap: _databaseEntryToMap,
        encrypted: true, // Шифруем историю для безопасности
      );

      logDebug(
        'DatabaseHistoryService инициализирован',
        tag: 'DatabaseHistoryService',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации DatabaseHistoryService',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
      );
      rethrow;
    }
  }

  /// Записывает доступ к базе данных в историю
  Future<void> recordDatabaseAccess({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
  }) async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      final now = DateTime.now();

      // Создаем или обновляем запись
      final entry = DatabaseEntry(
        path: path,
        name: name,
        description: description,
        masterPassword: saveMasterPassword ? masterPassword : null,
        saveMasterPassword: saveMasterPassword,
        lastAccessed: now,
        createdAt: now,
      );

      // Используем путь как ключ для обновления существующих записей
      final key = _pathToKey(path);

      // Проверяем, есть ли уже запись с таким путем
      final existingEntry = await _historyBox!.get(key);
      if (existingEntry != null) {
        // Обновляем существующую запись, сохраняя дату создания
        final updatedEntry = entry.copyWith(createdAt: existingEntry.createdAt);
        await _historyBox!.put(key, updatedEntry);
      } else {
        // Создаем новую запись
        await _historyBox!.put(key, entry);
      }

      logDebug(
        'Запись о доступе к БД добавлена в историю',
        tag: 'DatabaseHistoryService',
        data: {
          'path': path,
          'name': name,
          'saveMasterPassword': saveMasterPassword,
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка записи доступа к БД в историю',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
        data: {'path': path, 'name': name},
      );
      rethrow;
    }
  }

  /// Получает все записи истории, отсортированные по дате последнего доступа
  Future<List<DatabaseEntry>> getAllHistory() async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      final entriesList = <DatabaseEntry>[];

      // Получаем все записи через поток
      await for (final entry in _historyBox!.getAll()) {
        entriesList.add(entry);
      }

      // Сортируем по дате последнего доступа (новые сначала)
      entriesList.sort((a, b) {
        final aDate = a.lastAccessed ?? a.createdAt ?? DateTime(1970);
        final bDate = b.lastAccessed ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      logDebug(
        'Получена история БД: ${entriesList.length} записей',
        tag: 'DatabaseHistoryService',
      );

      return entriesList;
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
      );
      return [];
    }
  }

  /// Получает запись по пути к базе данных
  Future<DatabaseEntry?> getEntryByPath(String path) async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      final key = _pathToKey(path);
      return await _historyBox!.get(key);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения записи БД по пути',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Удаляет запись из истории
  Future<void> removeEntry(String path) async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      final key = _pathToKey(path);
      final success = await _historyBox!.delete(key);

      logDebug(
        'Запись ${success ? "удалена" : "не найдена"} из истории БД',
        tag: 'DatabaseHistoryService',
        data: {'path': path, 'success': success},
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления записи из истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
      rethrow;
    }
  }

  /// Очищает всю историю
  Future<void> clearHistory() async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      await _historyBox!.clear();

      logInfo('История БД очищена', tag: 'DatabaseHistoryService');
    } catch (e, stackTrace) {
      logError(
        'Ошибка очистки истории БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
      );
      rethrow;
    }
  }

  /// Получает записи с сохраненными паролями
  Future<List<DatabaseEntry>> getEntriesWithSavedPasswords() async {
    final allEntries = await getAllHistory();
    return allEntries
        .where(
          (entry) =>
              entry.saveMasterPassword &&
              entry.masterPassword != null &&
              entry.masterPassword!.isNotEmpty,
        )
        .toList();
  }

  /// Обновляет информацию о базе данных
  Future<void> updateDatabaseInfo({
    required String path,
    String? name,
    String? description,
  }) async {
    if (_historyBox == null) {
      await initialize();
    }

    try {
      final key = _pathToKey(path);
      final existingEntry = await _historyBox!.get(key);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(
          name: name ?? existingEntry.name,
          description: description ?? existingEntry.description,
          lastAccessed: DateTime.now(),
        );

        await _historyBox!.put(key, updatedEntry);

        logDebug(
          'Информация о БД обновлена',
          tag: 'DatabaseHistoryService',
          data: {'path': path, 'name': name},
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления информации о БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
      rethrow;
    }
  }

  /// Получает статистику истории
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      final allEntries = await getAllHistory();
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

      return {
        'totalEntries': allEntries.length,
        'entriesWithSavedPasswords': entriesWithPasswords,
        'oldestEntry': oldestDate,
        'newestEntry': newestDate,
      };
    } catch (e) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        tag: 'DatabaseHistoryService',
      );
      return {
        'totalEntries': 0,
        'entriesWithSavedPasswords': 0,
        'oldestEntry': null,
        'newestEntry': null,
      };
    }
  }

  /// Закрывает сервис и освобождает ресурсы
  Future<void> dispose() async {
    try {
      if (_boxManager != null) {
        await _boxManager!.closeBox(_boxName);
        _boxManager = null;
      }
      _historyBox = null;

      logDebug('DatabaseHistoryService закрыт', tag: 'DatabaseHistoryService');
    } catch (e) {
      logError(
        'Ошибка закрытия DatabaseHistoryService',
        error: e,
        tag: 'DatabaseHistoryService',
      );
    }
  }

  /// Преобразует путь в ключ для хранения
  String _pathToKey(String path) {
    // Нормализуем путь и используем его как ключ
    return p.normalize(path).toLowerCase();
  }

  /// Преобразует DatabaseEntry в Map для хранения
  Map<String, dynamic> _databaseEntryToMap(DatabaseEntry entry) {
    return {
      'path': entry.path,
      'name': entry.name,
      'description': entry.description,
      'masterPassword': entry.masterPassword,
      'saveMasterPassword': entry.saveMasterPassword,
      'lastAccessed': entry.lastAccessed?.toIso8601String(),
      'createdAt': entry.createdAt?.toIso8601String(),
    };
  }

  /// Преобразует Map в DatabaseEntry
  DatabaseEntry _databaseEntryFromMap(Map<String, dynamic> map) {
    return DatabaseEntry(
      path: map['path'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      masterPassword: map['masterPassword'] as String?,
      saveMasterPassword: map['saveMasterPassword'] as bool? ?? false,
      lastAccessed: map['lastAccessed'] != null
          ? DateTime.parse(map['lastAccessed'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}
