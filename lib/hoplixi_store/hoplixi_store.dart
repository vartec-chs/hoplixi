import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/index.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dao/filters_dao/otp_filter_dao.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/tables/hoplixi_meta.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import 'package:hoplixi/hoplixi_store/sql/triggers.dart';
import 'package:hoplixi/hoplixi_store/services/trigger_management_service.dart';
import 'tables/categories.dart';
import 'tables/icons.dart';
import 'tables/tags.dart';
import 'tables/passwords.dart';
import 'tables/password_tags.dart';
import 'tables/password_histories.dart';
import 'tables/otps.dart';
import 'tables/otp_tags.dart';
import 'tables/otp_histories.dart';
import 'tables/attachments.dart';
import 'tables/notes.dart';
import 'tables/note_tags.dart';
import 'tables/note_histories.dart';
import 'dao/index.dart';

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
    Otps,
    OtpTags,
    OtpHistories,
    Attachments,
    Notes,
    NoteTags,
    NoteHistories,
  ],
  daos: [
    CategoriesDao,
    IconsDao,
    TagsDao,
    PasswordsDao,
    PasswordTagsDao,
    PasswordFilterDao,
    OtpsDao,
    OtpTagsDao,
    AttachmentsDao,
    NotesDao,
    NoteTagsDao,
    PasswordHistoriesDao,
    NoteHistoriesDao,
    OtpHistoriesDao,
    OtpFilterDao,
  ],
)
class HoplixiStore extends _$HoplixiStore {
  HoplixiStore(super.e);

  @override
  int get schemaVersion => 1; // Keep as 1 for clean start

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Создание всех таблиц
        await m.createAll();
        // Создание триггеров после создания таблиц
        logInfo('Создание SQL триггеров', tag: 'DatabaseMigration');
        await DatabaseTriggers.createTriggers(this);
        logInfo('SQL триггеры созданы успешно', tag: 'DatabaseMigration');
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo(
          'Миграция базы данных с версии $from к версии $to',
          tag: 'DatabaseMigration',
        );

        // При обновлении пересоздаем триггеры
        await DatabaseTriggers.dropTriggers(this);
        await DatabaseTriggers.createTriggers(this);

        logInfo('Миграция завершена', tag: 'DatabaseMigration');
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

  // attachmentKey в Base64
  Future<String?> getAttachmentKey() async {
    logDebug('Получение ключа вложений', tag: 'EncryptedDatabase');
    try {
      final result = await (selectOnly(
        hoplixiMeta,
      )..addColumns([hoplixiMeta.attachmentKey])).get();
      final meta = result.first.read(hoplixiMeta.attachmentKey);
      logDebug('Ключ вложений получен', tag: 'EncryptedDatabase');
      return meta;
    } catch (e) {
      logError(
        'Ошибка получения ключа вложений',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'getAttachmentKey',
        details: e.toString(),
        message: 'Ошибка получения ключа вложений',
        stackTrace: StackTrace.current,
      );
    }
  }

  // set attachmentKey в Base64
  Future<void> setAttachmentKey(String key) async {
    logDebug('Установка ключа вложений', tag: 'EncryptedDatabase');
    try {
      final meta = await getDatabaseMeta();
      await (update(hoplixiMeta)..where((tbl) => tbl.id.equals(meta.id))).write(
        HoplixiMetaCompanion(attachmentKey: Value(key)),
      );

      // first
      logDebug('Ключ вложений установлен', tag: 'EncryptedDatabase');
    } catch (e) {
      logError(
        'Ошибка установки ключа вложений',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'setAttachmentKey',
        details: e.toString(),
        message: 'Ошибка установки ключа вложений',
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

  // ==================== МЕТОДЫ УПРАВЛЕНИЯ ТРИГГЕРАМИ ====================

  /// Проверяет, что все триггеры установлены корректно
  Future<bool> verifyTriggers() async {
    logDebug('Проверка триггеров базы данных', tag: 'EncryptedDatabase');
    try {
      return await TriggerManagementService.areTriggersInstalled(this);
    } catch (e) {
      logError(
        'Ошибка проверки триггеров',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  /// Получает список всех установленных триггеров
  Future<List<String>> getInstalledTriggers() async {
    logDebug('Получение списка триггеров', tag: 'EncryptedDatabase');
    try {
      return await TriggerManagementService.getInstalledTriggers(this);
    } catch (e) {
      logError(
        'Ошибка получения списка триггеров',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      return [];
    }
  }

  /// Пересоздает все триггеры (полезно для отладки)
  Future<void> recreateTriggers() async {
    logInfo('Пересоздание триггеров', tag: 'EncryptedDatabase');
    try {
      await TriggerManagementService.recreateTriggers(this);
      logInfo('Триггеры пересозданы успешно', tag: 'EncryptedDatabase');
    } catch (e) {
      logError(
        'Ошибка пересоздания триггеров',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'recreateTriggers',
        details: e.toString(),
        message: 'Ошибка пересоздания триггеров',
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Тестирует работу триггеров
  Future<Map<String, bool>> testTriggers() async {
    logDebug('Тестирование триггеров', tag: 'EncryptedDatabase');
    try {
      return await TriggerManagementService.testTriggers(this);
    } catch (e) {
      logError(
        'Ошибка тестирования триггеров',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  /// Получает статистику по таблицам истории
  Future<Map<String, int>> getHistoryStatistics() async {
    logDebug('Получение статистики истории', tag: 'EncryptedDatabase');
    try {
      return await TriggerManagementService.getHistoryStatistics(this);
    } catch (e) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  /// Очищает старые записи истории
  Future<Map<String, int>> cleanupOldHistory({int daysToKeep = 365}) async {
    logInfo('Очистка старой истории', tag: 'EncryptedDatabase');
    try {
      final result = await TriggerManagementService.cleanupOldHistory(
        this,
        daysToKeep: daysToKeep,
      );
      logInfo(
        'Очистка истории завершена',
        tag: 'EncryptedDatabase',
        data: result,
      );
      return result;
    } catch (e) {
      logError(
        'Ошибка очистки истории',
        error: e,
        tag: 'EncryptedDatabase',
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'cleanupOldHistory',
        details: e.toString(),
        message: 'Ошибка очистки истории',
        stackTrace: StackTrace.current,
      );
    }
  }
}
