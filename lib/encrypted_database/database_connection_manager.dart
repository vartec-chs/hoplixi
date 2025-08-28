import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'encrypted_database.dart';
import 'crypto_utils.dart';

/// Менеджер соединений с зашифрованной базой данных
class DatabaseConnectionManager {
  /// Создает новое подключение к зашифрованной базе данных
  static Future<EncryptedDatabase> createConnection({
    required String path,
    required String password,
  }) async {
    logDebug(
      'Создание подключения к базе данных',
      tag: 'DatabaseConnectionManager',
      data: {'path': path},
    );

    return EncryptedDatabase(
      NativeDatabase.createInBackground(
        File(path),
        setup: (rawDb) {
          // Экранируем одинарные кавычки в пароле
          final escapedPassword = password.replaceAll("'", "''");
          rawDb.execute("PRAGMA key = '$escapedPassword';");
        },
      ),
    );
  }

  /// Проверяет подключение и верифицирует пароль
  static Future<bool> verifyConnection({
    required EncryptedDatabase database,
    required String password,
  }) async {
    try {
      logDebug(
        'Верификация подключения к базе данных',
        tag: 'DatabaseConnectionManager',
      );

      final meta = await database.getDatabaseMeta();
      final isValid = CryptoUtils.verifyPassword(
        password,
        meta.passwordHash,
        meta.salt,
      );

      logDebug(
        'Результат верификации пароля',
        tag: 'DatabaseConnectionManager',
        data: {'isValid': isValid},
      );

      return isValid;
    } catch (e) {
      logError(
        'Ошибка верификации подключения',
        error: e,
        tag: 'DatabaseConnectionManager',
      );
      return false;
    }
  }

  /// Безопасно закрывает подключение к базе данных
  static Future<void> closeConnection(EncryptedDatabase? database) async {
    if (database != null) {
      try {
        logDebug(
          'Закрытие подключения к базе данных',
          tag: 'DatabaseConnectionManager',
        );
        await database.close();
      } catch (e) {
        logError(
          'Ошибка при закрытии подключения',
          error: e,
          tag: 'DatabaseConnectionManager',
        );
        rethrow;
      }
    }
  }

  /// Инициализирует метаданные новой базы данных
  static Future<void> initializeDatabaseMetadata({
    required EncryptedDatabase database,
    required String name,
    required String description,
    required Map<String, String> passwordData,
  }) async {
    logDebug(
      'Инициализация метаданных базы данных',
      tag: 'DatabaseConnectionManager',
      data: {'name': name},
    );

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
  }
}
