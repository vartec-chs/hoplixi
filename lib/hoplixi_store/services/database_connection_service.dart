import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> setupSqlCipher() async {
  if (UniversalPlatform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// Реализация сервиса управления подключением к базе данных
class DatabaseConnectionService {
  static Future<HoplixiStore> createConnection({
    required String path,
    required String password,
  }) async {
    logDebug(
      'Создание подключения к базе данных',
      tag: 'DatabaseConnectionService',
      data: {'path': path},
    );
    try {
      final database = HoplixiStore(
        NativeDatabase.createInBackground(
          File(path),
          isolateSetup: () async {
            await setupSqlCipher();
          },
          setup: (rawDb) {
            rawDb.execute("PRAGMA key = '$password';");
            rawDb.execute('PRAGMA foreign_keys = ON;');
            rawDb.config.doubleQuotedStringLiterals = false;
          },
          enableMigrations: true,
        ),
      );
      logDebug(
        'Подключение к базе данных создано',
        tag: 'DatabaseConnectionService',
      );

      return database;
    } catch (e, s) {
      logError(
        'Ошибка создания подключения к базе данных',
        error: e,
        stackTrace: s,
        tag: 'DatabaseConnectionService',
        data: {'path': path},
      );
      rethrow;
    }
  }

  static Future<bool> verifyConnection({
    required HoplixiStore database,
    required String password,
  }) async {
    logDebug(
      'Проверка подключения к базе данных',
      tag: 'DatabaseConnectionService',
    );

    try {
      await database.getDatabaseMeta();

      logDebug(
        'Результат верификации пароля',
        tag: 'DatabaseConnectionService',
        data: {'isValid': true},
      );

      return true;
    } catch (e) {
      logWarning(
        'Ошибка проверки подключения к базе данных',
        tag: 'DatabaseConnectionService',
        data: {'error': e.toString()},
      );
      return false;
    }
  }

  static Future<void> initializeDatabaseMetadata<T>({
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
      if (database is HoplixiStore) {
        await database
            .into(database.hoplixiMeta)
            .insert(
              HoplixiMetaCompanion.insert(
                name: name,
                description: Value(description),
                passwordHash: passwordData['hash']!,
                salt: passwordData['salt']!,
                attachmentKey: passwordData['attachmentKey']!,
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

  static Future<void> closeConnection<T>(T? database) async {
    if (database == null) return;

    logDebug(
      'Закрытие подключения к базе данных',
      tag: 'DatabaseConnectionService',
    );

    try {
      if (database is HoplixiStore) {
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
