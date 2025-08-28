import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/encrypted_database/interfaces/database_interfaces.dart';
import 'package:hoplixi/encrypted_database/encrypted_database.dart';
import 'package:hoplixi/encrypted_database/services/crypto_service.dart';

/// Реализация сервиса управления подключением к базе данных
class DatabaseConnectionService implements IDatabaseConnectionService {
  final ICryptoService _cryptoService;

  DatabaseConnectionService({ICryptoService? cryptoService})
    : _cryptoService = cryptoService ?? CryptoService();

  @override
  Future<T> createConnection<T>({
    required String path,
    required String password,
  }) async {
    logDebug(
      'Создание подключения к базе данных',
      tag: 'DatabaseConnectionService',
      data: {'path': path},
    );

    try {
      final database = EncryptedDatabase(
        NativeDatabase.createInBackground(
          File(path),
          setup: (rawDb) {
            // Экранируем одинарные кавычки в пароле
            final escapedPassword = password.replaceAll("'", "''");
            rawDb.execute("PRAGMA key = '$escapedPassword';");
          },
        ),
      );
      logDebug(
        'Подключение к базе данных создано',
        tag: 'DatabaseConnectionService',
      );
      return database as T;
    } catch (e) {
      logError(
        'Ошибка создания подключения к базе данных',
        error: e,
        tag: 'DatabaseConnectionService',
        data: {'path': path},
      );
      rethrow;
    }
  }

  @override
  Future<bool> verifyConnection<T>({
    required T database,
    required String password,
  }) async {
    logDebug(
      'Проверка подключения к базе данных',
      tag: 'DatabaseConnectionService',
    );

    try {
      if (database is EncryptedDatabase) {
        final meta = await database.getDatabaseMeta();
        final isValid = _cryptoService.verifyPassword(
          password,
          meta.passwordHash,
          meta.salt,
        );

        logDebug(
          'Результат верификации пароля',
          tag: 'DatabaseConnectionService',
          data: {'isValid': isValid},
        );

        return isValid;
      }
      return false;
    } catch (e) {
      logWarning(
        'Ошибка проверки подключения к базе данных',
        tag: 'DatabaseConnectionService',
        data: {'error': e.toString()},
      );
      return false;
    }
  }

  @override
  Future<void> initializeDatabaseMetadata<T>({
    required T database,
    required String name,
    required String description,
    required Map<String, String> passwordData,
  }) async {
    logDebug(
      'Инициализация метаданных базы данных',
      tag: 'DatabaseConnectionService',
      data: {'name': name},
    );

    try {
      if (database is EncryptedDatabase) {
        await database
            .into(database.databaseMeta)
            .insert(
              DatabaseMetaCompanion.insert(
                name: name,
                description: Value(description),
                passwordHash: passwordData['hash']!,
                salt: passwordData['salt']!,
                createdAt: DateTime.now(),
                modifiedAt: DateTime.now(),
              ),
            );
        logDebug(
          'Метаданные базы данных инициализированы',
          tag: 'DatabaseConnectionService',
        );
      }
    } catch (e) {
      logError(
        'Ошибка инициализации метаданных базы данных',
        error: e,
        tag: 'DatabaseConnectionService',
        data: {'name': name},
      );
      rethrow;
    }
  }

  @override
  Future<void> closeConnection<T>(T? database) async {
    if (database == null) return;

    logDebug(
      'Закрытие подключения к базе данных',
      tag: 'DatabaseConnectionService',
    );

    try {
      if (database is EncryptedDatabase) {
        await database.close();
        logDebug(
          'Подключение к базе данных закрыто',
          tag: 'DatabaseConnectionService',
        );
      }
    } catch (e) {
      logError(
        'Ошибка закрытия подключения к базе данных',
        error: e,
        tag: 'DatabaseConnectionService',
      );
      rethrow;
    }
  }
}
