import 'dart:typed_data';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

import 'interfaces/database_interfaces.dart';
import 'services/crypto_service.dart';
import 'services/database_validation_service.dart';
import 'services/database_connection_service.dart';
import 'services/database_history_service.dart';
import 'db_state.dart';
import 'dto/db_dto.dart';
import 'encrypted_database.dart';

/// Рефакторенный менеджер зашифрованных баз данных
///
/// Использует Dependency Injection и разделенные сервисы для лучшей
/// архитектуры и тестируемости
class EncryptedDatabaseManager implements IEncryptedDatabaseManager {
  EncryptedDatabase? _database;
  Uint8List? _passwordKey;

  // Зависимости
  final ICryptoService _cryptoService;
  final IDatabaseValidationService _validationService;
  final IDatabaseConnectionService _connectionService;
  final IDatabaseHistoryService _historyService;

  static const String _dbExtension = MainConstants.dbExtension;

  EncryptedDatabaseManager({
    ICryptoService? cryptoService,
    IDatabaseValidationService? validationService,
    IDatabaseConnectionService? connectionService,
    IDatabaseHistoryService? historyService,
  }) : _cryptoService = cryptoService ?? CryptoService(),
       _validationService = validationService ?? DatabaseValidationService(),
       _connectionService = connectionService ?? DatabaseConnectionService(),
       _historyService = historyService ?? DatabaseHistoryService();

  @override
  EncryptedDatabase? get database => _database;

  @override
  bool get hasOpenDatabase => _database != null;

  // === ПРИВАТНЫЕ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  /// Очищает чувствительные данные из памяти
  void _clearSensitiveData() {
    _cryptoService.clearSensitiveData(_passwordKey);
    _passwordKey = null;
  }

  /// Получает путь для базы данных по умолчанию
  Future<String> _getDefaultDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, MainConstants.appFolderName, 'storages');
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
      basePath = await _getDefaultDatabasePath();
      logDebug(
        'Используется путь по умолчанию: $basePath',
        tag: 'EncryptedDatabaseManager',
      );
    }

    await _validationService.ensureDirectoryExists(basePath);
    return p.join(basePath, '${dto.name}.$_dbExtension');
  }

  /// Завершает создание базы данных
  Future<void> _finalizeDatabaseCreation(
    EncryptedDatabase database,
    CreateDatabaseDto dto,
    Map<String, String> passwordData,
    String dbPath,
  ) async {
    _passwordKey = _cryptoService.deriveKey(
      dto.masterPassword,
      passwordData['salt']!,
    );
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
    EncryptedDatabase database,
    OpenDatabaseDto dto,
    dynamic meta,
  ) async {
    _passwordKey = _cryptoService.deriveKey(dto.masterPassword, meta.salt);
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
      await _historyService.recordDatabaseAccess(
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

  // === ОСНОВНЫЕ МЕТОДЫ ===

  @override
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

        // Валидация параметров
        _validationService.validateCreateDatabaseParams(
          name: dto.name,
          masterPassword: dto.masterPassword,
        );

        final dbPath = await _prepareDatabasePath(dto);
        await _validationService.validateDatabaseCreation(dbPath);

        final passwordData = _cryptoService.generatePasswordData(
          dto.masterPassword,
        );
        final database = await _connectionService
            .createConnection<EncryptedDatabase>(
              path: dbPath,
              password: dto.masterPassword,
            );

        await _connectionService.initializeDatabaseMetadata(
          database: database,
          name: dto.name,
          description: dto.description ?? '',
          passwordData: passwordData,
        );

        await _finalizeDatabaseCreation(database, dto, passwordData, dbPath);

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

  @override
  Future<DatabaseState> openDatabase(OpenDatabaseDto dto) async {
    const String operation = 'openDatabase';
    logInfo(
      'Начало открытия базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': dto.path},
    );

    try {
      // Валидация параметров
      _validationService.validateOpenDatabaseParams(
        path: dto.path,
        masterPassword: dto.masterPassword,
      );

      await _validationService.validateDatabaseExists(dto.path);

      final database = await _connectionService
          .createConnection<EncryptedDatabase>(
            path: dto.path,
            password: dto.masterPassword,
          );

      // Проверяем пароль через верификацию подключения
      final isValidPassword = await _connectionService.verifyConnection(
        database: database,
        password: dto.masterPassword,
      );

      if (!isValidPassword) {
        await _connectionService.closeConnection(database);
        throw const DatabaseError.invalidPassword();
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

  @override
  Future<DatabaseState> closeDatabase() async {
    logInfo('Закрытие базы данных', tag: 'EncryptedDatabaseManager');

    try {
      await _connectionService.closeConnection(_database);
      _database = null;
      _clearSensitiveData();

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

  @override
  Future<DatabaseState?> openWithAutoLogin(String path) async {
    logInfo(
      'Попытка автологина для базы данных',
      tag: 'EncryptedDatabaseManager',
      data: {'path': path},
    );

    try {
      final savedPassword = await _historyService.tryAutoLogin(path);
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

  @override
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

  @override
  Future<bool> canAutoLogin(String path) async {
    try {
      final savedPassword = await _historyService.tryAutoLogin(path);
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

  @override
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

  @override
  Future<void> dispose() async {
    logInfo(
      'Освобождение ресурсов EncryptedDatabaseManager',
      tag: 'EncryptedDatabaseManager',
    );

    try {
      if (_database != null) {
        await _connectionService.closeConnection(_database);
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

  // === ДЕЛЕГИРУЕМЫЕ МЕТОДЫ ИСТОРИИ ===

  @override
  Future<void> updateDatabaseLastAccessed(String path) async {
    await _historyService.updateLastAccessed(path);
  }

  @override
  Future<List<DatabaseEntry>> getAllDatabases() async {
    return await _historyService.getAllDatabases();
  }

  @override
  Future<DatabaseEntry?> getDatabaseInfo(String path) async {
    return await _historyService.getDatabaseInfo(path);
  }

  @override
  Future<void> removeDatabaseFromHistory(String path) async {
    await _historyService.removeFromHistory(path);
  }

  @override
  Future<void> clearDatabaseHistory() async {
    await _historyService.clearHistory();
  }

  @override
  Future<void> setDatabaseFavorite(String path, bool isFavorite) async {
    await _historyService.setFavorite(path, isFavorite);
  }

  @override
  Future<void> saveMasterPassword(String path, String masterPassword) async {
    await _historyService.saveMasterPassword(path, masterPassword);
  }

  @override
  Future<void> removeSavedMasterPassword(String path) async {
    await _historyService.removeSavedPassword(path);
  }

  @override
  Future<List<DatabaseEntry>> getFavoriteDatabases() async {
    return await _historyService.getFavoriteDatabases();
  }

  @override
  Future<List<DatabaseEntry>> getRecentDatabases({int limit = 10}) async {
    return await _historyService.getRecentDatabases(limit: limit);
  }

  @override
  Future<List<DatabaseEntry>> getDatabasesWithSavedPasswords() async {
    return await _historyService.getDatabasesWithSavedPasswords();
  }

  @override
  Future<String?> tryAutoLogin(String path) async {
    return await _historyService.tryAutoLogin(path);
  }

  @override
  Future<Map<String, dynamic>> getDatabaseHistoryStatistics() async {
    return await _historyService.getStatistics();
  }

  @override
  Future<void> performDatabaseHistoryMaintenance() async {
    await _historyService.performMaintenance();
  }
}
