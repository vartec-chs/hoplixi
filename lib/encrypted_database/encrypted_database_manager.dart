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

import 'package:hoplixi/core/errors/db_errors.dart';
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
    try {
      final String basePath;

      if (dto.customPath != null) {
        basePath = dto.customPath!;
      } else {
        basePath = await _getDefaultDatabasePath();
      }

      // Ensure directory exists
      final directory = Directory(basePath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final dbPath = p.join(basePath, '${dto.name}.db');

      // Check if database already exists
      if (File(dbPath).existsSync()) {
        throw DatabaseError.databaseAlreadyExists(path: dbPath);
      }

      // Generate password hash and salt
      final passwordData = _generatePasswordHash(dto.masterPassword);

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

      // Register database in registry
      // await _registryService.registerDatabase(
      //   name: dto.name,
      //   path: dbPath,
      //   description: dto.description,
      // );

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

      return DatabaseState(
        path: dbPath,
        name: dto.name,
        status: DatabaseStatus.open,
      );
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: 'createDatabase',
        message: e.toString(),
        details: e.toString(),
      );
    }
  }

  Future<DatabaseState> openDatabase(OpenDatabaseDto dto) async {
    try {
      if (!File(dto.path).existsSync()) {
        throw DatabaseError.databaseNotFound(path: dto.path);
      }

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
        final meta = await database.getDatabaseMeta();

        // Verify password
        if (!_verifyPassword(
          dto.masterPassword,
          meta.passwordHash,
          meta.salt,
        )) {
          await database.close();
          throw const DatabaseError.invalidPassword();
        }

        // Store derived key
        _passwordKey = _deriveKey(dto.masterPassword, meta.salt);

        // Update last accessed time in registry
        // await _registryService.updateLastAccessed(dto.path);

        // Записываем/обновляем информацию о базе данных в истории
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
      } catch (e) {
        await database.close();
        if (e is DatabaseError) rethrow;
        throw const DatabaseError.invalidPassword();
      }

      _database = database;

      return DatabaseState(
        path: dto.path,
        name: p.basenameWithoutExtension(dto.path),
        status: DatabaseStatus.open,
      );
    } catch (e) {
      if (e is DatabaseError) rethrow;
      throw DatabaseError.operationFailed(
        operation: 'openDatabase',
        details: e.toString(),
        message: e.toString(),
      );
    }
  }

  Future<DatabaseState> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    _clearSensitiveData();

    return const DatabaseState(status: DatabaseStatus.closed);
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
    await DatabaseHistoryService.recordDatabaseAccess(
      path: path,
      name: name,
      description: description,
      masterPassword: masterPassword,
      saveMasterPassword: saveMasterPassword,
    );
  }

  /// Обновляет время последнего доступа к базе данных
  Future<void> updateDatabaseLastAccessed(String path) async {
    await DatabaseHistoryService.updateLastAccessed(path);
  }

  /// Получает список всех ранее открытых баз данных
  Future<List<DatabaseEntry>> getAllDatabases() async {
    return await DatabaseHistoryService.getAllDatabases();
  }

  /// Получает информацию о конкретной базе данных
  Future<DatabaseEntry?> getDatabaseInfo(String path) async {
    return await DatabaseHistoryService.getDatabaseInfo(path);
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
    try {
      final savedPassword = await tryAutoLogin(path);
      if (savedPassword != null) {
        final openDto = OpenDatabaseDto(
          path: path,
          masterPassword: savedPassword,
        );
        return await openDatabase(openDto);
      }
      return null;
    } catch (e) {
      print('Ошибка автологина: $e');
      return null;
    }
  }

  /// Умный метод для открытия базы данных
  /// Сначала пытается автологин, если не получается - запрашивает пароль
  Future<DatabaseState?> smartOpen(
    String path, [
    String? providedPassword,
  ]) async {
    try {
      // Сначала пытаемся автологин
      final autoLoginResult = await openWithAutoLogin(path);
      if (autoLoginResult != null) {
        return autoLoginResult;
      }

      // Если автологин не сработал и пароль предоставлен, пытаемся открыть
      if (providedPassword != null) {
        final openDto = OpenDatabaseDto(
          path: path,
          masterPassword: providedPassword,
        );
        return await openDatabase(openDto);
      }

      // Возвращаем null если не смогли открыть
      return null;
    } catch (e) {
      print('Ошибка умного открытия: $e');
      return null;
    }
  }

  /// Проверяет, может ли база данных быть открыта с автологином
  Future<bool> canAutoLogin(String path) async {
    final savedPassword = await tryAutoLogin(path);
    return savedPassword != null;
  }

  // Pick database file using file picker
  Future<String?> pickDatabaseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
      dialogTitle: 'Select Password Database',
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }

  Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _clearSensitiveData();
    // await _registryService.close();
  }
}
