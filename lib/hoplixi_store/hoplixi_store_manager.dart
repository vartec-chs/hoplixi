import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/services/database_connection_service.dart';
import 'package:hoplixi/hoplixi_store/services/database_history_service.dart';
import 'package:hoplixi/hoplixi_store/services/database_validation_service.dart';

import 'state.dart';
import 'dto/db_dto.dart';
import 'dto/database_file_info.dart';
import 'hoplixi_store.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path/path.dart' as p;

class HoplixiStoreManager {
  HoplixiStore? _database;
  DatabaseHistoryService? _historyService;

  static const String _dbExtension = MainConstants.dbExtension;

  HoplixiStore? get database => _database;
  DatabaseHistoryService get historyService =>
      _historyService ??= DatabaseHistoryService();

  bool get hasOpenDatabase => _database != null;

  Future<DatabaseState> createDatabase(CreateDatabaseDto dto) async {
    const String operation = 'createDatabase';

    // Валидация параметров
    DatabaseValidationService.validateCreateDatabaseParams(
      name: dto.name,
      masterPassword: dto.masterPassword,
    );

    final dbPath = await _prepareDatabasePath(dto);
    await DatabaseValidationService.validateDatabaseCreation(dbPath);

    if (hasOpenDatabase) {
      logWarning(
        'Закрытие текущей базы данных перед созданием новой',
        tag: 'EncryptedDatabaseManager',
      );
      await closeDatabase();
    }

    final passwordData = _generatePasswordData(dto.masterPassword);
    final database = await DatabaseConnectionService.createConnection(
      path: dbPath,
      password: dto.masterPassword,
    );

    await DatabaseConnectionService.initializeDatabaseMetadata(
      database: database,
      name: dto.name,
      description: dto.description ?? '',
      passwordData: passwordData,
    );

    await _finalizeDatabaseCreation(database, dto, passwordData, dbPath);

    final state = DatabaseState(
      path: dbPath,
      name: dto.name,
      status: DatabaseStatus.open,
    );

    logDebug(
      'База данных создана',
      tag: 'EncryptedDatabaseManager',
      data: {'operation': operation, 'state': state.toString()},
    );

    return state;
  }

  Future<DatabaseState> openDatabase(OpenDatabaseDto dto) async {
    const String operation = 'openDatabase';
    logInfo(
      'Начало открытия базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': dto.path},
    );

    try {
      // Валидация параметров
      DatabaseValidationService.validateOpenDatabaseParams(
        path: dto.path,
        masterPassword: dto.masterPassword,
      );

      await DatabaseValidationService.validateDatabaseExists(dto.path);

      if (hasOpenDatabase) {
        logWarning(
          'Закрытие текущей базы данных перед созданием новой',
          tag: 'EncryptedDatabaseManager',
        );
        await closeDatabase();
      }

      final database = await DatabaseConnectionService.createConnection(
        path: dto.path,
        password: dto.masterPassword,
      );

      // Проверяем пароль через верификацию подключения
      final isValidPassword = await DatabaseConnectionService.verifyConnection(
        database: database,
        password: dto.masterPassword,
      );

      if (!isValidPassword) {
        await DatabaseConnectionService.closeConnection(database);
        throw const DatabaseError.invalidPassword(
          message: 'Неверный мастер-пароль',
        );
      }

      final meta = await database.getDatabaseMeta();
      await _finalizeOpenDatabase(database, dto, meta);

      logInfo(
        'База данных успешно открыта',
        tag: 'EncryptedDatabaseManager',
        data: {'path': dto.path, 'name': meta.name},
      );

      return DatabaseState(
        path: dto.path,
        name: meta.name.isNotEmpty
            ? meta.name
            : p.basenameWithoutExtension(dto.path),
        status: DatabaseStatus.open,
      );
    } catch (e, s) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'operation': operation, 'path': dto.path},
      );

      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: operation,
        stackTrace: s,
        details: e.toString(),
        message: 'Не удалось открыть базу данных: ${e.toString()}',
      );
    }
  }

  Future<DatabaseState> closeDatabase() async {
    logInfo('Закрытие базы данных', tag: 'EncryptedDatabaseManager');

    try {
      await DatabaseConnectionService.closeConnection(_database);
      _database = null;

      logInfo('База данных успешно закрыта', tag: 'EncryptedDatabaseManager');
      return const DatabaseState(status: DatabaseStatus.closed);
    } catch (e, s) {
      logError(
        'Ошибка при закрытии базы данных',
        error: e,
        stackTrace: s,
        tag: 'EncryptedDatabaseManager',
      );

      _database = null;

      return const DatabaseState(status: DatabaseStatus.closed);
    }
  }

  Future<void> dispose() async {
    logInfo(
      'Освобождение ресурсов EncryptedDatabaseManager',
      tag: 'EncryptedDatabaseManager',
    );

    try {
      if (_database != null) {
        await DatabaseConnectionService.closeConnection(_database);
        _database = null;
        logDebug(
          'База данных закрыта при освобождении ресурсов',
          tag: 'EncryptedDatabaseManager',
        );
      }

      // Закрываем сервис истории
      if (_historyService != null) {
        await _historyService!.dispose();
        _historyService = null;
        logDebug(
          'Сервис истории закрыт при освобождении ресурсов',
          tag: 'EncryptedDatabaseManager',
        );
      }

      logInfo(
        'Ресурсы EncryptedDatabaseManager освобождены',
        tag: 'EncryptedDatabaseManager',
      );
    } catch (e) {
      logError(
        'Ошибка при освобождении ресурсов',
        error: e,
        tag: 'EncryptedDatabaseManager',
      );
      // Все равно пытаемся очистить состояние
      _database = null;
      _historyService = null;
    }
  }

  String _generateSecureSalt() {
    const int saltLength = 32;
    final random = Random.secure();
    final bytes = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    const int iterations = 10000;
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64.encode(bytes);
  }

  Map<String, String> _generatePasswordData(String password) {
    final salt = _generateSecureSalt();
    final hash = _hashPassword(password, salt);
    return {'hash': hash, 'salt': salt};
  }

  /// Получает путь для базы данных по умолчанию
  Future<String> getDefaultDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, MainConstants.appFolderName, 'storages');
  }

  /// Поиск файлов базы данных в папке по умолчанию
  Future<DatabaseFilesResult> findDatabaseFiles() async {
    const String operation = 'findDatabaseFiles';

    try {
      final defaultPath = await getDefaultDatabasePath();
      final directory = Directory(defaultPath);

      logDebug(
        'Поиск файлов БД в папке',
        tag: 'HoplixiStoreManager',
        data: {'path': defaultPath, 'operation': operation},
      );

      // Проверяем, существует ли папка
      if (!await directory.exists()) {
        logDebug(
          'Папка с БД не существует',
          tag: 'HoplixiStoreManager',
          data: {'path': defaultPath},
        );

        return DatabaseFilesResult(files: [], searchPath: defaultPath);
      }

      // Получаем все файлы с расширением .hpx
      final files = await directory
          .list()
          .where(
            (entity) =>
                entity is File &&
                entity.path.toLowerCase().endsWith('.$_dbExtension'),
          )
          .cast<File>()
          .toList();

      // Преобразуем в DatabaseFileInfo и сортируем по дате изменения
      final databaseFiles = <DatabaseFileInfo>[];

      for (final file in files) {
        try {
          final stat = await file.stat();
          final fileName = p.basenameWithoutExtension(file.path);

          final fileInfo = DatabaseFileInfo(
            path: file.path,
            name: fileName,
            displayName: fileName,
            lastModified: stat.modified,
            sizeBytes: stat.size,
          );

          databaseFiles.add(fileInfo);
        } catch (e) {
          logWarning(
            'Ошибка при получении информации о файле',
            tag: 'HoplixiStoreManager',
            data: {'file': file.path, 'error': e.toString()},
          );
        }
      }

      // Сортируем по дате изменения (новые сначала)
      databaseFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      // Находим самый недавно измененный файл
      final mostRecent = databaseFiles.isNotEmpty ? databaseFiles.first : null;

      logInfo(
        'Найдено файлов БД: ${databaseFiles.length}',
        tag: 'HoplixiStoreManager',
        data: {
          'count': databaseFiles.length,
          'mostRecent': mostRecent?.name,
          'path': defaultPath,
        },
      );

      return DatabaseFilesResult(
        files: databaseFiles,
        mostRecent: mostRecent,
        searchPath: defaultPath,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка поиска файлов БД',
        error: e,
        tag: 'HoplixiStoreManager',
        stackTrace: stackTrace,
        data: {'operation': operation},
      );

      // Возвращаем пустой результат в случае ошибки
      return DatabaseFilesResult(
        files: [],
        searchPath: await getDefaultDatabasePath(),
      );
    }
  }

  /// Получает самый недавно измененный файл БД
  Future<DatabaseFileInfo?> getMostRecentDatabaseFile() async {
    final result = await findDatabaseFiles();
    return result.mostRecent;
  }

  /// Подготавливает путь для новой базы данных
  Future<String> _prepareDatabasePath(CreateDatabaseDto dto) async {
    final String basePath;

    if (dto.customPath != null) {
      basePath = dto.customPath!;
      logDebug(
        'Используется кастомный путь: $basePath',
        tag: 'EncryptedDatabaseManager',
      );
    } else {
      basePath = await getDefaultDatabasePath();
      logDebug(
        'Используется путь по умолчанию: $basePath',
        tag: 'EncryptedDatabaseManager',
      );
    }

    await DatabaseValidationService.ensureDirectoryExists(basePath);
    return p.join(basePath, '${dto.name}.$_dbExtension');
  }

  /// Завершает создание базы данных
  Future<void> _finalizeDatabaseCreation(
    HoplixiStore database,
    CreateDatabaseDto dto,
    Map<String, String> passwordData,
    String dbPath,
  ) async {
    // _passwordKey = _cryptoService.deriveKey(
    //   dto.masterPassword,
    //   passwordData['salt']!,
    // );
    _database = database;

    // Записываем информацию о базе данных в историю
    await _recordDatabaseEntry(
      path: dbPath,
      name: dto.name,
      description: dto.description,
      masterPassword: dto.masterPassword,
      saveMasterPassword: dto.saveMasterPassword,
    );
  }

  /// Завершает открытие базы данных
  Future<void> _finalizeOpenDatabase(
    HoplixiStore database,
    OpenDatabaseDto dto,
    dynamic meta,
  ) async {
    // _passwordKey = _cryptoService.deriveKey(dto.masterPassword, meta.salt);
    _database = database;

    // Записываем/обновляем информацию о базе данных в истории
    try {
      await _recordDatabaseEntry(
        path: dto.path,
        name: meta.name.isNotEmpty
            ? meta.name
            : p.basenameWithoutExtension(dto.path),
        description: meta.description,
        masterPassword: dto.masterPassword,
        saveMasterPassword: dto.saveMasterPassword,
      );
      logDebug(
        'Информация о базе данных обновлена в истории',
        tag: 'EncryptedDatabaseManager',
      );
    } catch (historyError) {
      logWarning(
        'Ошибка обновления истории (не критично): $historyError',
        tag: 'EncryptedDatabaseManager',
        data: {'error': historyError.toString()},
      );
    }
  }

  /// Записывает информацию о базе данных в историю
  Future<void> _recordDatabaseEntry({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
  }) async {
    try {
      await historyService.recordDatabaseAccess(
        path: path,
        name: name,
        description: description,
        masterPassword: masterPassword,
        saveMasterPassword: saveMasterPassword,
      );
      logDebug(
        'Информация о базе данных записана в историю',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path, 'name': name},
      );
    } catch (e) {
      logWarning(
        'Не удалось записать информацию о базе данных в историю (не критично)',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path, 'error': e.toString()},
      );
    }
  }

  // Методы для работы с историей

  /// Получить всю историю баз данных
  Future<List<DatabaseEntry>> getDatabaseHistory() async {
    try {
      return await historyService.getAllHistory();
    } catch (e) {
      logError(
        'Ошибка получения истории БД',
        error: e,
        tag: 'HoplixiStoreManager',
      );
      return [];
    }
  }

  /// Получить запись из истории по пути
  Future<DatabaseEntry?> getDatabaseHistoryEntry(String path) async {
    try {
      return await historyService.getEntryByPath(path);
    } catch (e) {
      logError(
        'Ошибка получения записи истории БД',
        error: e,
        tag: 'HoplixiStoreManager',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Удалить запись из истории
  Future<void> removeDatabaseHistoryEntry(String path) async {
    try {
      await historyService.removeEntry(path);
      logInfo(
        'Запись удалена из истории БД',
        tag: 'HoplixiStoreManager',
        data: {'path': path},
      );
    } catch (e) {
      logError(
        'Ошибка удаления записи из истории БД',
        error: e,
        tag: 'HoplixiStoreManager',
        data: {'path': path},
      );
      rethrow;
    }
  }

  /// Очистить всю историю
  Future<void> clearDatabaseHistory() async {
    try {
      await historyService.clearHistory();
      logInfo('История БД очищена', tag: 'HoplixiStoreManager');
    } catch (e) {
      logError(
        'Ошибка очистки истории БД',
        error: e,
        tag: 'HoplixiStoreManager',
      );
      rethrow;
    }
  }

  /// Получить статистику истории
  Future<Map<String, dynamic>> getDatabaseHistoryStats() async {
    try {
      return await historyService.getHistoryStats();
    } catch (e) {
      logError(
        'Ошибка получения статистики истории БД',
        error: e,
        tag: 'HoplixiStoreManager',
      );
      return {
        'totalEntries': 0,
        'entriesWithSavedPasswords': 0,
        'oldestEntry': null,
        'newestEntry': null,
      };
    }
  }

  /// Получить записи с сохраненными паролями
  Future<List<DatabaseEntry>> getDatabaseHistoryWithSavedPasswords() async {
    try {
      return await historyService.getEntriesWithSavedPasswords();
    } catch (e) {
      logError(
        'Ошибка получения записей с сохраненными паролями',
        error: e,
        tag: 'HoplixiStoreManager',
      );
      return [];
    }
  }
}
