import 'package:drift/drift.dart';

import 'triggers/history_delete_triggers.dart';
import 'triggers/history_update_triggers.dart';
import 'triggers/insert_timestamp_triggers.dart';
import 'triggers/meta_touch_triggers.dart';
import 'triggers/modified_at_triggers.dart';

/// SQL триггеры для автоматического управления метаданными и историей
class DatabaseTriggers {
  /// Список всех SQL команд для создания триггеров
  static const List<String> createTriggerStatements = [
    ...modifiedAtCreateTriggers,
    ...insertTimestampCreateTriggers,
    ...historyUpdateCreateTriggers,
    ...historyDeleteCreateTriggers,
    ...metaTouchCreateTriggers,
  ];

  /// Список команд для удаления всех триггеров
  static const List<String> dropTriggerStatements = [
    ...modifiedAtDropStatements,
    ...insertTimestampDropStatements,
    ...historyUpdateDropStatements,
    ...historyDeleteDropStatements,
    ...metaTouchDropStatements,
  ];

  /// Выполняет все SQL команды создания триггеров
  static Future<void> createTriggers(GeneratedDatabase database) async {
    for (final sql in createTriggerStatements) {
      await database.customStatement(sql);
    }
  }

  /// Удаляет все триггеры (полезно для миграций)
  static Future<void> dropTriggers(GeneratedDatabase database) async {
    for (final sql in dropTriggerStatements) {
      await database.customStatement(sql);
    }
  }
}
