import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/index.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dao/filters_dao/otp_filter_dao.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/tables/hoplixi_meta.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import 'package:hoplixi/hoplixi_store/sql/triggers.dart';
import 'package:hoplixi/hoplixi_store/services/trigger_management_service.dart';

import 'dao/index.dart';
import 'tables/index.dart';

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
  static const String _logTag = 'HoplixiStore';
  HoplixiStore(super.e);

  @override
  int get schemaVersion => MainConstants.dbSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Создание всех таблиц
        await m.createAll();
        // Создание триггеров после создания таблиц
        logInfo('Создание SQL триггеров', tag: _logTag);
        await DatabaseTriggers.createTriggers(this);
        logInfo('SQL триггеры созданы успешно', tag: _logTag);
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

        logInfo('Миграция завершена', tag: _logTag);
      },
    );
  }

  Future<HoplixiMetaData> getDatabaseMeta() async {
    logDebug('Получение метаданных базы данных', tag: _logTag);
    try {
      final meta = await select(hoplixiMeta).getSingle();
      logDebug(
        'Метаданные базы данных получены',
        tag: _logTag,
        data: {'name': meta.name},
      );
      return meta;
    } catch (e) {
      logError(
        'Ошибка получения метаданных базы данных',
        error: e,
        tag: _logTag,
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
    logDebug('Получение ключа вложений', tag: _logTag);
    try {
      final result = await (selectOnly(
        hoplixiMeta,
      )..addColumns([hoplixiMeta.attachmentKey])).get();
      final meta = result.first.read(hoplixiMeta.attachmentKey);
      logDebug('Ключ вложений получен', tag: _logTag);
      return meta;
    } catch (e) {
      logError(
        'Ошибка получения ключа вложений',
        error: e,
        tag: _logTag,
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
    logDebug('Установка ключа вложений', tag: _logTag);
    try {
      final meta = await getDatabaseMeta();
      await (update(hoplixiMeta)..where((tbl) => tbl.id.equals(meta.id))).write(
        HoplixiMetaCompanion(attachmentKey: Value(key)),
      );

      // first
      logDebug('Ключ вложений установлен', tag: _logTag);
    } catch (e) {
      logError(
        'Ошибка установки ключа вложений',
        error: e,
        tag: _logTag,
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

  //

  Future<void> closeDatabase() async {
    logInfo('Закрытие базы данных', tag: _logTag);
    try {
      await close();
      logInfo('База данных закрыта', tag: _logTag);
    } catch (e) {
      logError(
        'Ошибка закрытия базы данных',
        error: e,
        tag: _logTag,
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
    logDebug('Проверка триггеров базы данных', tag: _logTag);
    try {
      return await TriggerManagementService.areTriggersInstalled(this);
    } catch (e) {
      logError(
        'Ошибка проверки триггеров',
        error: e,
        tag: _logTag,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  /// Получает список всех установленных триггеров
  Future<List<String>> getInstalledTriggers() async {
    logDebug('Получение списка триггеров', tag: _logTag);
    try {
      return await TriggerManagementService.getInstalledTriggers(this);
    } catch (e) {
      logError(
        'Ошибка получения списка триггеров',
        error: e,
        tag: _logTag,
        stackTrace: StackTrace.current,
      );
      return [];
    }
  }

  /// Пересоздает все триггеры (полезно для отладки)
  Future<void> recreateTriggers() async {
    logInfo('Пересоздание триггеров', tag: _logTag);
    try {
      await TriggerManagementService.recreateTriggers(this);
      logInfo('Триггеры пересозданы успешно', tag: _logTag);
    } catch (e) {
      logError(
        'Ошибка пересоздания триггеров',
        error: e,
        tag: _logTag,
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
    logDebug('Тестирование триггеров', tag: _logTag);
    try {
      return await TriggerManagementService.testTriggers(this);
    } catch (e) {
      logError(
        'Ошибка тестирования триггеров',
        error: e,
        tag: _logTag,
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  /// Получает статистику по таблицам истории
  Future<Map<String, int>> getHistoryStatistics() async {
    logDebug('Получение статистики истории', tag: _logTag);
    try {
      return await TriggerManagementService.getHistoryStatistics(this);
    } catch (e) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        tag: _logTag,
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  /// Очищает старые записи истории
  Future<Map<String, int>> cleanupOldHistory({int daysToKeep = 365}) async {
    logInfo('Очистка старой истории', tag: _logTag);
    try {
      final result = await TriggerManagementService.cleanupOldHistory(
        this,
        daysToKeep: daysToKeep,
      );
      logInfo('Очистка истории завершена', tag: _logTag, data: result);
      return result;
    } catch (e) {
      logError(
        'Ошибка очистки истории',
        error: e,
        tag: _logTag,
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

  /// Получает метаданные базы данных для синхронизации
  Future<DatabaseMetaForSync> getDatabaseMetaForSync() async {
    logDebug(
      'Получение метаданных базы данных для синхронизации',
      tag: _logTag,
    );
    try {
      final meta = await getDatabaseMeta();
      final processedName = meta.name.toLowerCase().replaceAll(' ', '_');
      final result = DatabaseMetaForSync(
        id: meta.id,
        name: processedName,
        lastModified: meta.modifiedAt,
      );
      logDebug(
        'Метаданные для синхронизации получены',
        tag: _logTag,
        data: {'id': result.id, 'name': result.name},
      );
      return result;
    } catch (e) {
      logError(
        'Ошибка получения метаданных для синхронизации',
        error: e,
        tag: _logTag,
        stackTrace: StackTrace.current,
      );
      throw DatabaseError.operationFailed(
        operation: 'getDatabaseMetaForSync',
        details: e.toString(),
        message: 'Ошибка получения метаданных для синхронизации',
        stackTrace: StackTrace.current,
      );
    }
  }
}
