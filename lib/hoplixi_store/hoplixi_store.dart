import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/tables/hoplixi_meta.dart';
import 'tables/categories.dart';
import 'tables/icons.dart';
import 'tables/tags.dart';
import 'tables/passwords.dart';
import 'tables/password_tags.dart';
import 'tables/password_histories.dart';

part 'hoplixi_store.g.dart';

@DriftDatabase(
  tables: [
    HoplixiMeta,
    Categories,
    Icons,
    Tags,
    Passwords,
    PasswordTags,
    PasswordHistories,
  ]
)
class HoplixiStore extends _$HoplixiStore {
  HoplixiStore(super.e);

  @override
  int get schemaVersion => 1; // Keep as 1 for clean start

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
        hoplixiMeta,
      ).write(HoplixiMetaCompanion(modifiedAt: Value(DateTime.now())));
      logDebug(
        'Время модификации базы данных обновлено',
        tag: 'EncryptedDatabase',
      );
    } catch (e) {
      logError(
        'Ошибка обновления времени модификации',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'updateModificationTime',
        details: e.toString(),
        message: 'Ошибка обновления времени модификации',
        stackTrace: StackTrace.current,
      );
    }
  }

  Future<HoplixiMetaData> getDatabaseMeta() async {
    logDebug('Получение метаданных базы данных', tag: 'EncryptedDatabase');
    try {
      final meta = await select(hoplixiMeta).getSingle();
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
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'getDatabaseMeta',
        details: e.toString(),
        message: 'Ошибка получения метаданных базы данных',
        stackTrace: StackTrace.current,
      );
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
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.closeError(
        details: e.toString(),
        message: 'Ошибка закрытия базы данных',
        stackTrace: StackTrace.current,
      );
    }
  }
}
