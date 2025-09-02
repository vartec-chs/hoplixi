import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hoplixi/hoplixi_store/services/database_connection_service.dart';
import 'package:hoplixi/hoplixi_store/services/database_validation_service.dart';

import 'state.dart';
import 'dto/db_dto.dart';
import 'hoplixi_store.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path/path.dart' as p;

class HoplixiStoreManager {
  HoplixiStore? _database;

  static const String _dbExtension = MainConstants.dbExtension;

  HoplixiStore? get database => _database;

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
    // await _recordDatabaseEntry(
    //   path: dbPath,
    //   name: dto.name,
    //   description: dto.description,
    //   masterPassword: dto.masterPassword,
    //   saveMasterPassword: dto.saveMasterPassword,
    // );
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
    // try {
    //   await _recordDatabaseEntry(
    //     path: dto.path,
    //     name: meta.name.isNotEmpty
    //         ? meta.name
    //         : p.basenameWithoutExtension(dto.path),
    //     description: meta.description,
    //     masterPassword: dto.masterPassword,
    //     saveMasterPassword: dto.saveMasterPassword,
    //   );
    //   logDebug(
    //     'Информация о базе данных обновлена в истории',
    //     tag: 'EncryptedDatabaseManager',
    //   );
    // } catch (historyError) {
    //   logWarning(
    //     'Ошибка обновления истории (не критично): $historyError',
    //     tag: 'EncryptedDatabaseManager',
    //     data: {'error': historyError.toString()},
    //   );
  }

  /// Записывает информацию о базе данных в историю
  // Future<void> _recordDatabaseEntry({
  //   required String path,
  //   required String name,
  //   String? description,
  //   String? masterPassword,
  //   bool saveMasterPassword = false,
  // }) async {
  //   try {
  //     await _historyService.recordDatabaseAccess(
  //       path: path,
  //       name: name,
  //       description: description,
  //       masterPassword: masterPassword,
  //       saveMasterPassword: saveMasterPassword,
  //     );
  //     logDebug(
  //       'Информация о базе данных записана в историю',
  //       tag: 'EncryptedDatabaseManager',
  //       data: {'path': path, 'name': name},
  //     );
  //   } catch (e) {
  //     logWarning(
  //       'Не удалось записать информацию о базе данных в историю (не критично)',
  //       tag: 'EncryptedDatabaseManager',
  //       data: {'path': path, 'error': e.toString()},
  //     );
  //   }
  // }
}
