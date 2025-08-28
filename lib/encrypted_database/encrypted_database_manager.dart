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
import 'db_state.dart';
import 'dto/db_dto.dart';
import 'encrypted_database.dart';

class EncryptedDatabaseManager {
  EncryptedDatabase? _database;
  Uint8List? _passwordKey;

  EncryptedDatabase? get database => _database;
  bool get hasOpenDatabase => _database != null;

  Future<void> initialize() async {
    try {
      // await HiveService.initialize(appVersion: '1.0.0');
      // await _registryService.initialize();
    } catch (e) {
      throw DatabaseError.operationFailed(
        operation: 'initialize',
        message: e.toString(),
        details: e.toString(),
      );
    }
  }

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

  // Get current state
  DatabaseState _getCurrentState() {
    if (_database != null) {
      return const DatabaseState(status: DatabaseStatus.open);
    }
    return const DatabaseState(status: DatabaseStatus.closed);
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
