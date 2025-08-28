import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';
import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Сервис для управления историей баз данных
///
/// Предоставляет удобные методы для работы с историей открытых баз данных,
/// включая автологин, избранные базы данных и управление сохраненными паролями.
class DatabaseHistoryService {
  /// Генерирует уникальный ID для базы данных на основе пути
  static String generateDatabaseId(String path) {
    final normalizedPath = p.normalize(path);
    final bytes = utf8.encode(normalizedPath);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Добавляет или обновляет запись о базе данных в истории
  static Future<void> recordDatabaseAccess({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
    bool isFavorite = false,
  }) async {
    const String operation = 'recordDatabaseAccess';

    await ErrorHandler.safeExecute(
      operation: operation,
      context: 'DatabaseHistoryService',
      additionalData: {
        'path': path,
        'name': name,
        'saveMasterPassword': saveMasterPassword,
      },
      function: () async {
        final databaseId = generateDatabaseId(path);

        // Проверяем, существует ли уже запись
        final existingEntry = await StorageServiceLocator.getDatabase(
          databaseId,
        );

        if (existingEntry != null) {
          logDebug(
            'Обновление существующей записи в истории',
            tag: 'DatabaseHistoryService',
            data: {'id': databaseId, 'name': name},
          );

          // Обновляем существующую запись
          final updatedEntry = existingEntry.copyWith(
            name: name,
            description: description,
            lastAccessed: DateTime.now(),
            masterPassword: saveMasterPassword
                ? masterPassword
                : existingEntry.masterPassword,
            isMasterPasswordSaved:
                saveMasterPassword || existingEntry.isMasterPasswordSaved,
            isFavorite: isFavorite || existingEntry.isFavorite,
          );
          await StorageServiceLocator.updateDatabase(updatedEntry);
          logDebug('Запись в истории обновлена', tag: 'DatabaseHistoryService');
        } else {
          logDebug(
            'Создание новой записи в истории',
            tag: 'DatabaseHistoryService',
            data: {'id': databaseId, 'name': name},
          );

          // Создаем новую запись
          final newEntry = DatabaseEntry(
            id: databaseId,
            name: name,
            path: path,
            lastAccessed: DateTime.now(),
            description: description,
            masterPassword: saveMasterPassword ? masterPassword : null,
            isMasterPasswordSaved: saveMasterPassword,
            isFavorite: isFavorite,
          );
          await StorageServiceLocator.addDatabase(newEntry);
          logDebug(
            'Новая запись добавлена в историю',
            tag: 'DatabaseHistoryService',
          );
        }
      },
    );
  }

  /// Получает информацию о базе данных по пути
  static Future<DatabaseEntry?> getDatabaseInfo(String path) async {
    try {
      final databaseId = generateDatabaseId(path);
      final result = await StorageServiceLocator.getDatabase(databaseId);
      logDebug(
        'Получение информации о базе данных',
        tag: 'DatabaseHistoryService',
        data: {'path': path, 'found': result != null},
      );
      return result;
    } catch (e) {
      logError(
        'Ошибка получения информации о базе данных',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Обновляет время последнего доступа к базе данных
  static Future<void> updateLastAccessed(String path) async {
    try {
      final databaseId = generateDatabaseId(path);
      await StorageServiceLocator.updateLastAccessed(databaseId);
      logDebug(
        'Время последнего доступа обновлено',
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
    } catch (e) {
      logWarning(
        'Ошибка обновления времени доступа (не критично)',
        tag: 'DatabaseHistoryService',
        data: {'path': path, 'error': e.toString()},
      );
    }
  }

  /// Получает все базы данных из истории
  static Future<List<DatabaseEntry>> getAllDatabases() async {
    try {
      final databases = await StorageServiceLocator.getAllDatabases();
      logDebug(
        'Получен список всех баз данных',
        tag: 'DatabaseHistoryService',
        data: {'count': databases.length},
      );
      return databases;
    } catch (e) {
      logError(
        'Ошибка получения списка баз данных',
        error: e,
        tag: 'DatabaseHistoryService',
      );
      return [];
    }
  }

  /// Получает недавно использованные базы данных
  static Future<List<DatabaseEntry>> getRecentDatabases({
    int limit = 10,
  }) async {
    try {
      final allDatabases = await getAllDatabases();
      final recent = allDatabases.take(limit).toList();
      logDebug(
        'Получен список недавних баз данных',
        tag: 'DatabaseHistoryService',
        data: {'requested': limit, 'found': recent.length},
      );
      return recent;
    } catch (e) {
      logError(
        'Ошибка получения недавних баз данных',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'limit': limit},
      );
      return [];
    }
  }

  /// Получает избранные базы данных
  static Future<List<DatabaseEntry>> getFavoriteDatabases() async {
    try {
      final allDatabases = await getAllDatabases();
      final favorites = allDatabases.where((db) => db.isFavorite).toList();
      logDebug(
        'Получен список избранных баз данных',
        tag: 'DatabaseHistoryService',
        data: {'count': favorites.length},
      );
      return favorites;
    } catch (e) {
      logError(
        'Ошибка получения избранных баз данных',
        error: e,
        tag: 'DatabaseHistoryService',
      );
      return [];
    }
  }

  /// Получает базы данных с сохраненными паролями
  static Future<List<DatabaseEntry>> getDatabasesWithSavedPasswords() async {
    try {
      final allDatabases = await getAllDatabases();
      final withPasswords = allDatabases
          .where((db) => db.isMasterPasswordSaved)
          .toList();
      logDebug(
        'Получен список баз данных с сохраненными паролями',
        tag: 'DatabaseHistoryService',
        data: {'count': withPasswords.length},
      );
      return withPasswords;
    } catch (e) {
      logError(
        'Ошибка получения баз данных с сохраненными паролями',
        error: e,
        tag: 'DatabaseHistoryService',
      );
      return [];
    }
  }

  /// Устанавливает/снимает отметку "избранное" для базы данных
  static Future<void> setFavorite(String path, bool isFavorite) async {
    const String operation = 'setFavorite';
    logInfo(
      'Установка статуса избранного',
      tag: 'DatabaseHistoryService',
      data: {'path': path, 'isFavorite': isFavorite},
    );

    try {
      final databaseId = generateDatabaseId(path);
      final existingEntry = await StorageServiceLocator.getDatabase(databaseId);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(isFavorite: isFavorite);
        await StorageServiceLocator.updateDatabase(updatedEntry);
        logDebug('Статус избранного обновлен', tag: 'DatabaseHistoryService');
      } else {
        logError(
          'База данных не найдена в истории при установке статуса избранного',
          tag: 'DatabaseHistoryService',
          data: {'path': path},
        );
        throw DatabaseError.databaseNotFound(
          path: path,
          message: 'База данных не найдена в истории',
        );
      }
    } catch (e) {
      logError(
        'Ошибка установки статуса избранного',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'operation': operation, 'path': path},
      );
      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: operation,
        details: e.toString(),
        message: 'Не удалось установить статус избранного',
      );
    }
  }

  /// Сохраняет мастер-пароль для базы данных
  ///
  /// ВНИМАНИЕ: Сохранение паролей может представлять угрозу безопасности!
  /// Используйте только с явного согласия пользователя.
  static Future<void> saveMasterPassword(
    String path,
    String masterPassword,
  ) async {
    const String operation = 'saveMasterPassword';
    logWarning(
      'Сохранение мастер-пароля (потенциальная угроза безопасности)',
      tag: 'DatabaseHistoryService',
      data: {'path': path},
    );

    try {
      final databaseId = generateDatabaseId(path);
      final existingEntry = await StorageServiceLocator.getDatabase(databaseId);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(
          masterPassword: masterPassword,
          isMasterPasswordSaved: true,
        );
        await StorageServiceLocator.updateDatabase(updatedEntry);
        logDebug('Мастер-пароль сохранен', tag: 'DatabaseHistoryService');
      } else {
        logError(
          'База данных не найдена в истории при сохранении пароля',
          tag: 'DatabaseHistoryService',
          data: {'path': path},
        );
        throw DatabaseError.databaseNotFound(
          path: path,
          message: 'База данных не найдена в истории',
        );
      }
    } catch (e) {
      logError(
        'Ошибка сохранения мастер-пароля',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'operation': operation, 'path': path},
      );
      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: operation,
        details: e.toString(),
        message: 'Не удалось сохранить мастер-пароль',
      );
    }
  }

  /// Удаляет сохраненный мастер-пароль
  static Future<void> removeSavedPassword(String path) async {
    const String operation = 'removeSavedPassword';
    logInfo(
      'Удаление сохраненного мастер-пароля',
      tag: 'DatabaseHistoryService',
      data: {'path': path},
    );

    try {
      final databaseId = generateDatabaseId(path);
      final existingEntry = await StorageServiceLocator.getDatabase(databaseId);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(
          masterPassword: null,
          isMasterPasswordSaved: false,
        );
        await StorageServiceLocator.updateDatabase(updatedEntry);
        logDebug(
          'Сохраненный мастер-пароль удален',
          tag: 'DatabaseHistoryService',
        );
      } else {
        logError(
          'База данных не найдена в истории при удалении пароля',
          tag: 'DatabaseHistoryService',
          data: {'path': path},
        );
        throw DatabaseError.databaseNotFound(
          path: path,
          message: 'База данных не найдена в истории',
        );
      }
    } catch (e) {
      logError(
        'Ошибка удаления сохраненного мастер-пароля',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'operation': operation, 'path': path},
      );
      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: operation,
        details: e.toString(),
        message: 'Не удалось удалить сохраненный мастер-пароль',
      );
    }
  }

  /// Удаляет базу данных из истории
  static Future<void> removeFromHistory(String path) async {
    try {
      final databaseId = generateDatabaseId(path);
      await StorageServiceLocator.removeDatabase(databaseId);
    } catch (e) {
      print('Ошибка удаления базы данных из истории: $e');
      rethrow;
    }
  }

  /// Очищает всю историю баз данных
  static Future<void> clearHistory() async {
    try {
      await StorageServiceLocator.clearAllDatabases();
    } catch (e) {
      print('Ошибка очистки истории баз данных: $e');
      rethrow;
    }
  }

  /// Обновляет описание базы данных
  static Future<void> updateDescription(
    String path,
    String? description,
  ) async {
    try {
      final databaseId = generateDatabaseId(path);
      final existingEntry = await StorageServiceLocator.getDatabase(databaseId);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(description: description);
        await StorageServiceLocator.updateDatabase(updatedEntry);
      } else {
        throw Exception('База данных не найдена в истории');
      }
    } catch (e) {
      print('Ошибка обновления описания: $e');
      rethrow;
    }
  }

  /// Переименовывает базу данных в истории
  static Future<void> rename(String path, String newName) async {
    try {
      final databaseId = generateDatabaseId(path);
      final existingEntry = await StorageServiceLocator.getDatabase(databaseId);

      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(name: newName);
        await StorageServiceLocator.updateDatabase(updatedEntry);
      } else {
        throw Exception('База данных не найдена в истории');
      }
    } catch (e) {
      print('Ошибка переименования базы данных: $e');
      rethrow;
    }
  }

  /// Проверяет, существует ли база данных в истории
  static Future<bool> existsInHistory(String path) async {
    try {
      final databaseId = generateDatabaseId(path);
      return await StorageServiceLocator.containsDatabase(databaseId);
    } catch (e) {
      print('Ошибка проверки существования в истории: $e');
      return false;
    }
  }

  /// Пытается выполнить автологин для базы данных
  ///
  /// Возвращает сохраненный пароль если он есть, иначе null
  static Future<String?> tryAutoLogin(String path) async {
    try {
      final dbInfo = await getDatabaseInfo(path);
      if (dbInfo != null && dbInfo.isMasterPasswordSaved) {
        logDebug(
          'Найден сохраненный пароль для автологина',
          tag: 'DatabaseHistoryService',
          data: {'path': path},
        );
        return dbInfo.masterPassword;
      } else {
        logDebug(
          'Сохраненный пароль для автологина не найден',
          tag: 'DatabaseHistoryService',
          data: {'path': path, 'hasEntry': dbInfo != null},
        );
      }
      return null;
    } catch (e) {
      logError(
        'Ошибка при попытке автологина',
        error: e,
        tag: 'DatabaseHistoryService',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Получает статистику по истории баз данных
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allDatabases = await getAllDatabases();
      final favoriteDatabases = await getFavoriteDatabases();
      final databasesWithPasswords = await getDatabasesWithSavedPasswords();

      // Подсчитываем базы данных по времени последнего доступа
      final now = DateTime.now();
      final today = allDatabases
          .where(
            (db) =>
                db.lastAccessed.isAfter(now.subtract(const Duration(days: 1))),
          )
          .length;
      final thisWeek = allDatabases
          .where(
            (db) =>
                db.lastAccessed.isAfter(now.subtract(const Duration(days: 7))),
          )
          .length;
      final thisMonth = allDatabases
          .where(
            (db) =>
                db.lastAccessed.isAfter(now.subtract(const Duration(days: 30))),
          )
          .length;

      return {
        'total': allDatabases.length,
        'favorites': favoriteDatabases.length,
        'withSavedPasswords': databasesWithPasswords.length,
        'accessedToday': today,
        'accessedThisWeek': thisWeek,
        'accessedThisMonth': thisMonth,
        'oldestAccess': allDatabases.isNotEmpty
            ? allDatabases
                  .map((db) => db.lastAccessed)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'newestAccess': allDatabases.isNotEmpty
            ? allDatabases
                  .map((db) => db.lastAccessed)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      print('Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Экспортирует историю баз данных (без паролей) для резервного копирования
  static Future<Map<String, dynamic>> exportHistory({
    bool includePasswords = false,
  }) async {
    try {
      final allDatabases = await getAllDatabases();

      final exportData = allDatabases
          .map(
            (db) => {
              'id': db.id,
              'name': db.name,
              'path': db.path,
              'lastAccessed': db.lastAccessed.toIso8601String(),
              'description': db.description,
              'isFavorite': db.isFavorite,
              'isMasterPasswordSaved': db.isMasterPasswordSaved,
              if (includePasswords && db.masterPassword != null)
                'masterPassword': db.masterPassword,
            },
          )
          .toList();

      return {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'databases': exportData,
      };
    } catch (e) {
      print('Ошибка экспорта истории: $e');
      rethrow;
    }
  }

  /// Импортирует историю баз данных из резервной копии
  static Future<void> importHistory(
    Map<String, dynamic> data, {
    bool overwrite = false,
  }) async {
    try {
      final databases = data['databases'] as List<dynamic>?;
      if (databases == null) {
        throw Exception('Неверный формат данных для импорта');
      }

      for (final dbData in databases) {
        final db = DatabaseEntry(
          id: dbData['id'] as String,
          name: dbData['name'] as String,
          path: dbData['path'] as String,
          lastAccessed: DateTime.parse(dbData['lastAccessed'] as String),
          description: dbData['description'] as String?,
          isFavorite: dbData['isFavorite'] as bool? ?? false,
          isMasterPasswordSaved:
              dbData['isMasterPasswordSaved'] as bool? ?? false,
          masterPassword: dbData['masterPassword'] as String?,
        );

        // Проверяем, существует ли уже такая запись
        final exists = await StorageServiceLocator.containsDatabase(db.id);
        if (!exists || overwrite) {
          await StorageServiceLocator.addDatabase(db);
        }
      }
    } catch (e) {
      print('Ошибка импорта истории: $e');
      rethrow;
    }
  }

  /// Выполняет обслуживание истории баз данных
  static Future<void> performMaintenance() async {
    try {
      final allDatabases = await getAllDatabases();
      final now = DateTime.now();

      // Удаляем записи старше 1 года (по желанию)
      final oldThreshold = now.subtract(const Duration(days: 365));
      final oldDatabases = allDatabases
          .where((db) => db.lastAccessed.isBefore(oldThreshold))
          .toList();

      for (final oldDb in oldDatabases) {
        // Только если это не избранная база данных
        if (!oldDb.isFavorite) {
          await StorageServiceLocator.removeDatabase(oldDb.id);
        }
      }

      print(
        'Обслуживание завершено. Удалено ${oldDatabases.length} старых записей.',
      );
    } catch (e) {
      print('Ошибка при обслуживании истории: $e');
    }
  }
}
