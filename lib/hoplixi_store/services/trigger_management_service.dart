import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/sql/triggers.dart';

/// Сервис для управления SQL триггерами базы данных
class TriggerManagementService {
  static const String _tag = 'TriggerManagementService';

  /// Проверяет, созданы ли все триггеры в базе данных
  static Future<bool> areTriggersInstalled(GeneratedDatabase database) async {
    try {
      logDebug('Проверка установленных триггеров', tag: _tag);

      final result = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' AND name LIKE '%_modified_at' OR name LIKE '%_timestamps' OR name LIKE '%_history'",
          )
          .get();

      logDebug('Найдено триггеров: ${result.length}', tag: _tag);

      // Ожидаем как минимум основные триггеры
      const expectedMinimumTriggers =
          15; // 8 modified_at + 8 timestamps + 6 history

      return result.length >= expectedMinimumTriggers;
    } catch (e) {
      logError('Ошибка проверки триггеров', error: e, tag: _tag);
      return false;
    }
  }

  /// Получает список всех установленных триггеров
  static Future<List<String>> getInstalledTriggers(
    GeneratedDatabase database,
  ) async {
    try {
      final result = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name",
          )
          .get();

      return result.map((row) => row.data['name'] as String).toList();
    } catch (e) {
      logError('Ошибка получения списка триггеров', error: e, tag: _tag);
      return [];
    }
  }

  /// Пересоздает все триггеры (полезно для отладки)
  static Future<void> recreateTriggers(GeneratedDatabase database) async {
    try {
      logInfo('Пересоздание всех триггеров', tag: _tag);

      await DatabaseTriggers.dropTriggers(database);
      await DatabaseTriggers.createTriggers(database);

      logInfo('Триггеры успешно пересозданы', tag: _tag);
    } catch (e) {
      logError('Ошибка пересоздания триггеров', error: e, tag: _tag);
      rethrow;
    }
  }

  /// Проверяет работу триггеров на тестовых данных
  static Future<Map<String, bool>> testTriggers(
    GeneratedDatabase database,
  ) async {
    final results = <String, bool>{};

    try {
      logInfo('Тестирование работы триггеров', tag: _tag);

      // Тест триггера modified_at для категорий
      results['modified_at_trigger'] = await _testModifiedAtTrigger(database);

      // Тест триггера истории для паролей
      results['password_history_trigger'] = await _testPasswordHistoryTrigger(
        database,
      );

      logInfo('Результаты тестирования триггеров: $results', tag: _tag);
    } catch (e) {
      logError('Ошибка тестирования триггеров', error: e, tag: _tag);
    }

    return results;
  }

  /// Тестирует триггер обновления modified_at
  static Future<bool> _testModifiedAtTrigger(GeneratedDatabase database) async {
    try {
      // Создаем тестовую категорию
      await database.customStatement('''
        INSERT INTO categories (id, name, created_at, modified_at) 
        VALUES ('test-trigger-category', 'Test Category', datetime('now', '-1 minute'), datetime('now', '-1 minute'))
      ''');

      // Ждем немного
      await Future.delayed(const Duration(milliseconds: 100));

      // Обновляем название
      await database.customStatement('''
        UPDATE categories SET name = 'Updated Test Category' WHERE id = 'test-trigger-category'
      ''');

      // Проверяем, что modified_at обновился
      final result = await database.customSelect('''
        SELECT created_at, modified_at FROM categories WHERE id = 'test-trigger-category'
      ''').getSingle();

      final createdAt = DateTime.parse(result.data['created_at'] as String);
      final modifiedAt = DateTime.parse(result.data['modified_at'] as String);

      final success = modifiedAt.isAfter(createdAt);

      // Очищаем тестовые данные
      await database.customStatement('''
        DELETE FROM categories WHERE id = 'test-trigger-category'
      ''');

      return success;
    } catch (e) {
      logError('Ошибка тестирования триггера modified_at', error: e, tag: _tag);
      return false;
    }
  }

  /// Тестирует триггер истории паролей
  static Future<bool> _testPasswordHistoryTrigger(
    GeneratedDatabase database,
  ) async {
    try {
      // Создаем тестовый пароль
      await database.customStatement('''
        INSERT INTO passwords (id, name, password, created_at, modified_at) 
        VALUES ('test-trigger-password', 'Test Password', 'encrypted_pass', datetime('now'), datetime('now'))
      ''');

      // Обновляем пароль (должен сработать триггер истории)
      await database.customStatement('''
        UPDATE passwords SET name = 'Updated Test Password' WHERE id = 'test-trigger-password'
      ''');

      // Проверяем, что запись в истории создалась
      final historyCount = await database.customSelect('''
        SELECT COUNT(*) as count FROM password_histories 
        WHERE original_password_id = 'test-trigger-password' AND action = 'modified'
      ''').getSingle();

      final success = (historyCount.data['count'] as int) > 0;

      // Очищаем тестовые данные
      await database.customStatement('''
        DELETE FROM password_histories WHERE original_password_id = 'test-trigger-password'
      ''');
      await database.customStatement('''
        DELETE FROM passwords WHERE id = 'test-trigger-password'
      ''');

      return success;
    } catch (e) {
      logError(
        'Ошибка тестирования триггера истории паролей',
        error: e,
        tag: _tag,
      );
      return false;
    }
  }

  /// Получает статистику по записям в таблицах истории
  static Future<Map<String, int>> getHistoryStatistics(
    GeneratedDatabase database,
  ) async {
    try {
      final passwordHistoryCount = await database
          .customSelect('SELECT COUNT(*) as count FROM password_histories')
          .getSingle();

      final totpHistoryCount = await database
          .customSelect('SELECT COUNT(*) as count FROM totp_histories')
          .getSingle();

      final noteHistoryCount = await database
          .customSelect('SELECT COUNT(*) as count FROM note_histories')
          .getSingle();

      return {
        'password_history': passwordHistoryCount.data['count'] as int,
        'totp_history': totpHistoryCount.data['count'] as int,
        'note_history': noteHistoryCount.data['count'] as int,
      };
    } catch (e) {
      logError('Ошибка получения статистики истории', error: e, tag: _tag);
      return {};
    }
  }

  /// Очищает старые записи истории (старше указанного количества дней)
  static Future<Map<String, int>> cleanupOldHistory(
    GeneratedDatabase database, {
    int daysToKeep = 365,
  }) async {
    try {
      logInfo('Очистка старой истории (старше $daysToKeep дней)', tag: _tag);

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = cutoffDate.toIso8601String();

      // Удаляем старые записи из каждой таблицы истории и считаем количество
      final passwordCountBefore = await database
          .customSelect(
            'SELECT COUNT(*) as count FROM password_histories WHERE action_at < \'$cutoffDateStr\'',
          )
          .getSingle();

      await database.customStatement(
        'DELETE FROM password_histories WHERE action_at < \'$cutoffDateStr\'',
      );

      final totpCountBefore = await database
          .customSelect(
            'SELECT COUNT(*) as count FROM totp_histories WHERE action_at < \'$cutoffDateStr\'',
          )
          .getSingle();

      await database.customStatement(
        'DELETE FROM totp_histories WHERE action_at < \'$cutoffDateStr\'',
      );

      final noteCountBefore = await database
          .customSelect(
            'SELECT COUNT(*) as count FROM note_histories WHERE action_at < \'$cutoffDateStr\'',
          )
          .getSingle();

      await database.customStatement(
        'DELETE FROM note_histories WHERE action_at < \'$cutoffDateStr\'',
      );

      final deletedCounts = {
        'password_history': passwordCountBefore.data['count'] as int,
        'totp_history': totpCountBefore.data['count'] as int,
        'note_history': noteCountBefore.data['count'] as int,
      };

      logInfo('Очистка завершена: $deletedCounts', tag: _tag);

      return deletedCounts;
    } catch (e) {
      logError('Ошибка очистки старой истории', error: e, tag: _tag);
      return {};
    }
  }
}
