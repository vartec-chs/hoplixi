import 'package:drift/drift.dart';
import 'package:hoplixi/encrypted_database/dao/categories_dao.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'tables/categories.dart';
import 'tables/database_meta.dart';

part 'encrypted_database.g.dart';

@DriftDatabase(tables: [DatabaseMeta, Categories], daos: [CategoriesDao])
class EncryptedDatabase extends _$EncryptedDatabase {
  EncryptedDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> updateModificationTime() async {
    logDebug(
      'Обновление времени модификации базы данных',
      tag: 'EncryptedDatabase',
    );
    try {
      await update(
        databaseMeta,
      ).write(DatabaseMetaCompanion(modifiedAt: Value(DateTime.now())));
      logDebug(
        'Время модификации базы данных обновлено',
        tag: 'EncryptedDatabase',
      );
    } catch (e) {
      logError(
        'Ошибка обновления времени модификации',
        error: e,
        tag: 'EncryptedDatabase',
      );
      rethrow;
    }
  }

  Future<DatabaseMetaData> getDatabaseMeta() async {
    logDebug('Получение метаданных базы данных', tag: 'EncryptedDatabase');
    try {
      final meta = await select(databaseMeta).getSingle();
      logDebug(
        'Метаданные базы данных получены',
        tag: 'EncryptedDatabase',
        data: {'name': meta.name},
      );
      return meta;
    } catch (e) {
      logError(
        'Ошибка получения метаданных базы данных',
        error: e,
        tag: 'EncryptedDatabase',
      );
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    logInfo('Закрытие базы данных', tag: 'EncryptedDatabase');
    try {
      await close();
      logInfo('База данных закрыта', tag: 'EncryptedDatabase');
    } catch (e) {
      logError(
        'Ошибка закрытия базы данных',
        error: e,
        tag: 'EncryptedDatabase',
      );
      rethrow;
    }
  }
}
