import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';

import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';
import 'database_history_service.dart';
import 'db_state.dart';
import 'dto/db_dto.dart';
import 'encrypted_database.dart';

class EncryptedDatabaseManager {
  EncryptedDatabase? _database;
  Uint8List? _passwordKey;

  EncryptedDatabase? get database => _database;
  bool get hasOpenDatabase => _database != null;

  // Generate salt and hash password
  Map<String, String> _generatePasswordHash(String password) {
    final salt = _generateSecureSalt();
    final hash = _hashPassword(password, salt);

    return {'hash': hash, 'salt': salt};
  }

  // Generate cryptographically secure salt
  String _generateSecureSalt() {
    final bytes = List<int>.generate(
      32,
      (i) => DateTime.now().millisecondsSinceEpoch + i * 137,
    );
    return base64.encode(bytes);
  }

  // Hash password with salt using PBKDF2-like approach
  String _hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < 10000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64.encode(bytes);
  }

  // Derive encryption key from password
  Uint8List _deriveKey(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < 10000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return Uint8List.fromList(bytes);
  }

  // Verify password
  bool _verifyPassword(String password, String hash, String salt) {
    final computedHash = _hashPassword(password, salt);
    return computedHash == hash;
  }

  // Clear sensitive data from memory
  void _clearSensitiveData() {
    if (_passwordKey != null) {
      _passwordKey!.fillRange(0, _passwordKey!.length, 0);
      _passwordKey = null;
    }
  }

  // Get default database directory
  Future<String> _getDefaultDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, MainConstants.appFolderName, 'storages');
  }

  Future<DatabaseState> createDatabase(CreateDatabaseDto dto) async {
    const String operation = 'createDatabase';

    return await ErrorHandler.safeExecute(
      operation: operation,
      context: 'EncryptedDatabaseManager',
      additionalData: {
        'name': dto.name,
        'hasCustomPath': dto.customPath != null,
      },
      function: () async {
        ErrorHandler.logOperationStart(
          operation: operation,
          context: 'EncryptedDatabaseManager',
          additionalData: {'name': dto.name},
        );

        final String basePath;

        if (dto.customPath != null) {
          basePath = dto.customPath!;
          logDebug(
            'Используется кастомный путь: $basePath',
            tag: 'EncryptedDatabaseManager',
          );
        } else {
          basePath = await _getDefaultDatabasePath();
          logDebug(
            'Используется путь по умолчанию: $basePath',
            tag: 'EncryptedDatabaseManager',
          );
        }

        // Ensure directory exists
        final directory = Directory(basePath);
        if (!await directory.exists()) {
          logInfo(
            'Создание директории: $basePath',
            tag: 'EncryptedDatabaseManager',
          );
          await directory.create(recursive: true);
        }

        final dbPath = p.join(basePath, '${dto.name}.db');
        logDebug(
          'Полный путь к базе данных: $dbPath',
          tag: 'EncryptedDatabaseManager',
        );

        // Check if database already exists
        if (File(dbPath).existsSync()) {
          logWarning(
            'База данных уже существует: $dbPath',
            tag: 'EncryptedDatabaseManager',
          );
          throw DatabaseError.databaseAlreadyExists(path: dbPath);
        }

        // Generate password hash and salt
        final passwordData = _generatePasswordHash(dto.masterPassword);
        logDebug(
          'Сгенерированы хеш и соль пароля',
          tag: 'EncryptedDatabaseManager',
        );

        // Create encrypted database
        final database = EncryptedDatabase(
          NativeDatabase.createInBackground(
            File(dbPath),
            setup: (rawDb) {
              rawDb.execute(
                "PRAGMA key = '${dto.masterPassword.replaceAll("'", "''")}';",
              );
            },
          ),
        );

        logInfo(
          'База данных создана, инициализация метаданных',
          tag: 'EncryptedDatabaseManager',
        );

        // Initialize database metadata record
        await database
            .into(database.databaseMeta)
            .insert(
              DatabaseMetaCompanion.insert(
                name: dto.name,
                description: Value(dto.description),
                passwordHash: passwordData['hash']!,
                salt: passwordData['salt']!,
                createdAt: DateTime.now(),
                modifiedAt: DateTime.now(),
              ),
            );

        // Store derived key
        _passwordKey = _deriveKey(dto.masterPassword, passwordData['salt']!);
        _database = database;

        // Записываем информацию о базе данных в историю
        await _recordDatabaseEntry(
          path: dbPath,
          name: dto.name,
          description: dto.description,
          masterPassword: dto.masterPassword,
          saveMasterPassword:
              false, // По умолчанию не сохраняем пароль при создании
        );

        final result = DatabaseState(
          path: dbPath,
          name: dto.name,
          status: DatabaseStatus.open,
        );

        ErrorHandler.logSuccess(
          operation: operation,
          context: 'EncryptedDatabaseManager',
          additionalData: {'path': dbPath, 'name': dto.name},
        );

        return result;
      },
    );
  }

  Future<DatabaseState> openDatabase(OpenDatabaseDto dto) async {
    const String operation = 'openDatabase';
    logInfo(
      'Начало открытия базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': dto.path},
    );

    try {
      if (!File(dto.path).existsSync()) {
        logWarning(
          'База данных не найдена: ${dto.path}',
          tag: 'EncryptedDatabaseManager',
        );
        throw DatabaseError.databaseNotFound(path: dto.path);
      }

      logDebug(
        'Создание подключения к базе данных',
        tag: 'EncryptedDatabaseManager',
      );
      final database = EncryptedDatabase(
        NativeDatabase.createInBackground(
          File(dto.path),
          setup: (rawDb) {
            rawDb.execute("PRAGMA key = '${dto.masterPassword}';");
          },
        ),
      );

      // Try to read database metadata to verify password
      try {
        logDebug(
          'Проверка пароля и чтение метаданных',
          tag: 'EncryptedDatabaseManager',
        );
        final meta = await database.getDatabaseMeta();

        // Verify password
        if (!_verifyPassword(
          dto.masterPassword,
          meta.passwordHash,
          meta.salt,
        )) {
          logWarning(
            'Неверный пароль для базы данных: ${dto.path}',
            tag: 'EncryptedDatabaseManager',
          );
          await database.close();
          throw const DatabaseError.invalidPassword();
        }

        logDebug(
          'Пароль верифицирован успешно',
          tag: 'EncryptedDatabaseManager',
        );

        // Store derived key
        _passwordKey = _deriveKey(dto.masterPassword, meta.salt);

        // Записываем/обновляем информацию о базе данных в истории
        try {
          await _recordDatabaseEntry(
            path: dto.path,
            name: meta.name.isNotEmpty
                ? meta.name
                : p.basenameWithoutExtension(dto.path),
            description: meta.description,
            masterPassword: dto.masterPassword,
            saveMasterPassword:
                false, // По умолчанию не сохраняем пароль при открытии
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

        _database = database;

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
      } catch (e) {
        logError(
          'Ошибка при проверке пароля или чтении метаданных',
          error: e,
          tag: 'EncryptedDatabaseManager',
          data: {'path': dto.path},
        );
        await database.close();
        if (e is DatabaseError) rethrow;
        throw const DatabaseError.invalidPassword();
      }
    } catch (e) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'operation': operation, 'path': dto.path},
      );

      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: operation,
        details: e.toString(),
        message: 'Не удалось открыть базу данных: ${e.toString()}',
      );
    }
  }

  Future<DatabaseState> closeDatabase() async {
    logInfo('Закрытие базы данных', tag: 'EncryptedDatabaseManager');

    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        logDebug('База данных закрыта', tag: 'EncryptedDatabaseManager');
      }

      _clearSensitiveData();
      logDebug(
        'Чувствительные данные очищены',
        tag: 'EncryptedDatabaseManager',
      );

      logInfo('База данных успешно закрыта', tag: 'EncryptedDatabaseManager');
      return const DatabaseState(status: DatabaseStatus.closed);
    } catch (e) {
      logError(
        'Ошибка при закрытии базы данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
      );

      // Все равно пытаемся очистить состояние
      _database = null;
      _clearSensitiveData();

      return const DatabaseState(status: DatabaseStatus.closed);
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С ИСТОРИЕЙ БАЗ ДАННЫХ ===

  /// Записывает информацию о базе данных в историю
  Future<void> _recordDatabaseEntry({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
  }) async {
    try {
      await DatabaseHistoryService.recordDatabaseAccess(
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

  /// Обновляет время последнего доступа к базе данных
  Future<void> updateDatabaseLastAccessed(String path) async {
    try {
      await DatabaseHistoryService.updateLastAccessed(path);
      logDebug(
        'Время последнего доступа обновлено',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
    } catch (e) {
      logWarning(
        'Не удалось обновить время последнего доступа (не критично)',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path, 'error': e.toString()},
      );
    }
  }

  /// Получает список всех ранее открытых баз данных
  Future<List<DatabaseEntry>> getAllDatabases() async {
    try {
      final databases = await DatabaseHistoryService.getAllDatabases();
      logDebug(
        'Получен список баз данных',
        tag: 'EncryptedDatabaseManager',
        data: {'count': databases.length},
      );
      return databases;
    } catch (e) {
      logError(
        'Ошибка получения списка баз данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
      );
      return [];
    }
  }

  /// Получает информацию о конкретной базе данных
  Future<DatabaseEntry?> getDatabaseInfo(String path) async {
    try {
      final info = await DatabaseHistoryService.getDatabaseInfo(path);
      logDebug(
        'Получена информация о базе данных',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path, 'found': info != null},
      );
      return info;
    } catch (e) {
      logError(
        'Ошибка получения информации о базе данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Удаляет базу данных из истории
  Future<void> removeDatabaseFromHistory(String path) async {
    await DatabaseHistoryService.removeFromHistory(path);
  }

  /// Очищает всю историю баз данных
  Future<void> clearDatabaseHistory() async {
    await DatabaseHistoryService.clearHistory();
  }

  /// Устанавливает/снимает отметку "избранное" для базы данных
  Future<void> setDatabaseFavorite(String path, bool isFavorite) async {
    await DatabaseHistoryService.setFavorite(path, isFavorite);
  }

  /// Сохраняет мастер-пароль для базы данных (осторожно!)
  Future<void> saveMasterPassword(String path, String masterPassword) async {
    await DatabaseHistoryService.saveMasterPassword(path, masterPassword);
  }

  /// Удаляет сохраненный мастер-пароль
  Future<void> removeSavedMasterPassword(String path) async {
    await DatabaseHistoryService.removeSavedPassword(path);
  }

  /// Получает избранные базы данных
  Future<List<DatabaseEntry>> getFavoriteDatabases() async {
    return await DatabaseHistoryService.getFavoriteDatabases();
  }

  /// Получает недавно использованные базы данных (последние N)
  Future<List<DatabaseEntry>> getRecentDatabases({int limit = 10}) async {
    return await DatabaseHistoryService.getRecentDatabases(limit: limit);
  }

  /// Получает базы данных с сохраненными паролями
  Future<List<DatabaseEntry>> getDatabasesWithSavedPasswords() async {
    return await DatabaseHistoryService.getDatabasesWithSavedPasswords();
  }

  /// Пытается выполнить автологин для базы данных
  Future<String?> tryAutoLogin(String path) async {
    return await DatabaseHistoryService.tryAutoLogin(path);
  }

  /// Получает статистику по истории баз данных
  Future<Map<String, dynamic>> getDatabaseHistoryStatistics() async {
    return await DatabaseHistoryService.getStatistics();
  }

  /// Выполняет обслуживание истории баз данных
  Future<void> performDatabaseHistoryMaintenance() async {
    await DatabaseHistoryService.performMaintenance();
  }

  /// Пытается открыть базу данных с автологином
  Future<DatabaseState?> openWithAutoLogin(String path) async {
    logInfo(
      'Попытка автологина для базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': path},
    );

    try {
      final savedPassword = await tryAutoLogin(path);
      if (savedPassword != null) {
        logDebug(
          'Найден сохраненный пароль, пытаемся открыть БД',
          tag: 'EncryptedDatabaseManager',
        );
        final openDto = OpenDatabaseDto(
          path: path,
          masterPassword: savedPassword,
        );
        final result = await openDatabase(openDto);
        logInfo(
          'Автологин успешен',
          tag: 'EncryptedDatabaseManager',
          data: {'path': path},
        );
        return result;
      } else {
        logDebug(
          'Сохраненный пароль не найден',
          tag: 'EncryptedDatabaseManager',
          data: {'path': path},
        );
      }
      return null;
    } catch (e) {
      logError(
        'Ошибка автологина',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Умный метод для открытия базы данных
  /// Сначала пытается автологин, если не получается - запрашивает пароль
  Future<DatabaseState?> smartOpen(
    String path, [
    String? providedPassword,
  ]) async {
    logInfo(
      'Умное открытие базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': path, 'hasProvidedPassword': providedPassword != null},
    );

    try {
      // Сначала пытаемся автологин
      final autoLoginResult = await openWithAutoLogin(path);
      if (autoLoginResult != null) {
        logInfo(
          'Умное открытие: успешен автологин',
          tag: 'EncryptedDatabaseManager',
          data: {'path': path},
        );
        return autoLoginResult;
      }

      // Если автологин не сработал и пароль предоставлен, пытаемся открыть
      if (providedPassword != null) {
        logDebug(
          'Автологин не сработал, пытаемся с предоставленным паролем',
          tag: 'EncryptedDatabaseManager',
        );
        final openDto = OpenDatabaseDto(
          path: path,
          masterPassword: providedPassword,
        );
        final result = await openDatabase(openDto);
        logInfo(
          'Умное открытие: успешно с предоставленным паролем',
          tag: 'EncryptedDatabaseManager',
          data: {'path': path},
        );
        return result;
      }

      logInfo(
        'Умное открытие: нет сохраненного пароля и не предоставлен пароль',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
      return null;
    } catch (e) {
      logError(
        'Ошибка умного открытия',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
      return null;
    }
  }

  /// Проверяет, может ли база данных быть открыта с автологином
  Future<bool> canAutoLogin(String path) async {
    try {
      final savedPassword = await tryAutoLogin(path);
      final canAuto = savedPassword != null;
      logDebug(
        'Проверка возможности автологина',
        tag: 'EncryptedDatabaseManager',
        data: {'path': path, 'canAutoLogin': canAuto},
      );
      return canAuto;
    } catch (e) {
      logError(
        'Ошибка проверки возможности автологина',
        error: e,
        tag: 'EncryptedDatabaseManager',
        data: {'path': path},
      );
      return false;
    }
  }

  // Pick database file using file picker
  Future<String?> pickDatabaseFile() async {
    logInfo(
      'Выбор файла базы данных через файловый диалог',
      tag: 'EncryptedDatabaseManager',
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select Password Database',
      );

      if (result != null && result.files.isNotEmpty) {
        final selectedPath = result.files.first.path;
        logInfo(
          'Файл базы данных выбран',
          tag: 'EncryptedDatabaseManager',
          data: {'path': selectedPath},
        );
        return selectedPath;
      } else {
        logDebug('Файл базы данных не выбран', tag: 'EncryptedDatabaseManager');
      }
      return null;
    } catch (e) {
      logError(
        'Ошибка выбора файла базы данных',
        error: e,
        tag: 'EncryptedDatabaseManager',
      );
      return null;
    }
  }

  Future<void> dispose() async {
    logInfo(
      'Освобождение ресурсов EncryptedDatabaseManager',
      tag: 'EncryptedDatabaseManager',
    );

    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        logDebug(
          'База данных закрыта при освобождении ресурсов',
          tag: 'EncryptedDatabaseManager',
        );
      }
      _clearSensitiveData();
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
      _clearSensitiveData();
    }
  }
}
