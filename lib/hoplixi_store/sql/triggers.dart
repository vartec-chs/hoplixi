import 'package:drift/drift.dart';

/// SQL триггеры для автоматического управления метаданными и историей
class DatabaseTriggers {
  /// Список всех SQL команд для создания триггеров
  static const List<String> createTriggerStatements = [
    // Триггеры для автоматического обновления modified_at при UPDATE
    _createModifiedAtTriggerForHoplixiMeta,
    _createModifiedAtTriggerForCategories,
    _createModifiedAtTriggerForIcons,
    _createModifiedAtTriggerForTags,
    _createModifiedAtTriggerForPasswords,
    _createModifiedAtTriggerForTotps,
    _createModifiedAtTriggerForNotes,
    _createModifiedAtTriggerForAttachments,

    // Триггеры для заполнения created_at и modified_at при INSERT
    _createInsertTriggerForHoplixiMeta,
    _createInsertTriggerForCategories,
    _createInsertTriggerForIcons,
    _createInsertTriggerForTags,
    _createInsertTriggerForPasswords,
    _createInsertTriggerForTotps,
    _createInsertTriggerForNotes,
    _createInsertTriggerForAttachments,

    // Триггеры для записи истории при UPDATE
    _createPasswordUpdateHistoryTrigger,
    _createTotpUpdateHistoryTrigger,
    _createNoteUpdateHistoryTrigger,

    // Триггеры для записи истории при DELETE
    _createPasswordDeleteHistoryTrigger,
    _createTotpDeleteHistoryTrigger,
    _createNoteDeleteHistoryTrigger,
  ];

  /// Список команд для удаления всех триггеров
  static const List<String> dropTriggerStatements = [
    'DROP TRIGGER IF EXISTS update_hoplixi_meta_modified_at;',
    'DROP TRIGGER IF EXISTS update_categories_modified_at;',
    'DROP TRIGGER IF EXISTS update_icons_modified_at;',
    'DROP TRIGGER IF EXISTS update_tags_modified_at;',
    'DROP TRIGGER IF EXISTS update_passwords_modified_at;',
    'DROP TRIGGER IF EXISTS update_totps_modified_at;',
    'DROP TRIGGER IF EXISTS update_notes_modified_at;',
    'DROP TRIGGER IF EXISTS update_attachments_modified_at;',
    'DROP TRIGGER IF EXISTS insert_hoplixi_meta_timestamps;',
    'DROP TRIGGER IF EXISTS insert_categories_timestamps;',
    'DROP TRIGGER IF EXISTS insert_icons_timestamps;',
    'DROP TRIGGER IF EXISTS insert_tags_timestamps;',
    'DROP TRIGGER IF EXISTS insert_passwords_timestamps;',
    'DROP TRIGGER IF EXISTS insert_totps_timestamps;',
    'DROP TRIGGER IF EXISTS insert_notes_timestamps;',
    'DROP TRIGGER IF EXISTS insert_attachments_timestamps;',
    'DROP TRIGGER IF EXISTS password_update_history;',
    'DROP TRIGGER IF EXISTS totp_update_history;',
    'DROP TRIGGER IF EXISTS note_update_history;',
    'DROP TRIGGER IF EXISTS password_delete_history;',
    'DROP TRIGGER IF EXISTS totp_delete_history;',
    'DROP TRIGGER IF EXISTS note_delete_history;',
  ];

  // ==================== ТРИГГЕРЫ ОБНОВЛЕНИЯ modified_at ====================

  static const String _createModifiedAtTriggerForHoplixiMeta = '''
    CREATE TRIGGER IF NOT EXISTS update_hoplixi_meta_modified_at
    AFTER UPDATE ON hoplixi_meta
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE hoplixi_meta 
      SET modified_at = strftime('%s', 'now')
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForCategories = '''
    CREATE TRIGGER IF NOT EXISTS update_categories_modified_at
    AFTER UPDATE ON categories
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE categories 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForIcons = '''
    CREATE TRIGGER IF NOT EXISTS update_icons_modified_at
    AFTER UPDATE ON icons
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE icons 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForTags = '''
    CREATE TRIGGER IF NOT EXISTS update_tags_modified_at
    AFTER UPDATE ON tags
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE tags 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForPasswords = '''
    CREATE TRIGGER IF NOT EXISTS update_passwords_modified_at
    AFTER UPDATE ON passwords
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE passwords 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForTotps = '''
    CREATE TRIGGER IF NOT EXISTS update_totps_modified_at
    AFTER UPDATE ON totps
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE totps 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForNotes = '''
    CREATE TRIGGER IF NOT EXISTS update_notes_modified_at
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE notes 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForAttachments = '''
    CREATE TRIGGER IF NOT EXISTS update_attachments_modified_at
    AFTER UPDATE ON attachments
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE attachments 
      SET modified_at = datetime('now') 
      WHERE id = NEW.id;
    END;
  ''';

  // ==================== ТРИГГЕРЫ INSERT для timestamps ====================

  static const String _createInsertTriggerForHoplixiMeta = '''
    CREATE TRIGGER IF NOT EXISTS insert_hoplixi_meta_timestamps
    AFTER INSERT ON hoplixi_meta
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE hoplixi_meta 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForCategories = '''
    CREATE TRIGGER IF NOT EXISTS insert_categories_timestamps
    AFTER INSERT ON categories
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE categories 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForIcons = '''
    CREATE TRIGGER IF NOT EXISTS insert_icons_timestamps
    AFTER INSERT ON icons
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE icons 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForTags = '''
    CREATE TRIGGER IF NOT EXISTS insert_tags_timestamps
    AFTER INSERT ON tags
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE tags 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForPasswords = '''
    CREATE TRIGGER IF NOT EXISTS insert_passwords_timestamps
    AFTER INSERT ON passwords
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE passwords 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForTotps = '''
    CREATE TRIGGER IF NOT EXISTS insert_totps_timestamps
    AFTER INSERT ON totps
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE totps 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForNotes = '''
    CREATE TRIGGER IF NOT EXISTS insert_notes_timestamps
    AFTER INSERT ON notes
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE notes 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForAttachments = '''
    CREATE TRIGGER IF NOT EXISTS insert_attachments_timestamps
    AFTER INSERT ON attachments
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE attachments 
      SET 
        created_at = COALESCE(NEW.created_at, datetime('now')),
        modified_at = COALESCE(NEW.modified_at, datetime('now'))
      WHERE id = NEW.id;
    END;
  ''';

  // ==================== ТРИГГЕРЫ ИСТОРИИ ПРИ UPDATE ====================

  static const String _createPasswordUpdateHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS password_update_history
    AFTER UPDATE ON passwords
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description != NEW.description OR
      OLD.password != NEW.password OR
      OLD.url != NEW.url OR
      OLD.notes != NEW.notes OR
      OLD.login != NEW.login OR
      OLD.email != NEW.email OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite
    )
    BEGIN
      INSERT INTO password_histories (
        id,
        original_password_id,
        action,
        name,
        description,
        password,
        url,
        notes,
        login,
        email,
        category_id,
        category_name,
        tags,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.name,
        OLD.description,
        OLD.password,
        OLD.url,
        OLD.notes,
        OLD.login,
        OLD.email,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN password_tags pt ON t.id = pt.tag_id 
         WHERE pt.password_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

  static const String _createTotpUpdateHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS totp_update_history
    AFTER UPDATE ON totps
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description != NEW.description OR
      OLD.type != NEW.type OR
      OLD.issuer != NEW.issuer OR
      OLD.account_name != NEW.account_name OR
      OLD.secret_cipher != NEW.secret_cipher OR
      OLD.algorithm != NEW.algorithm OR
      OLD.digits != NEW.digits OR
      OLD.period != NEW.period OR
      OLD.counter != NEW.counter OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite
    )
    BEGIN
      INSERT INTO totp_histories (
        id,
        original_totp_id,
        action,
        name,
        description,
        type,
        issuer,
        account_name,
        algorithm,
        digits,
        period,
        counter,
        category_id,
        category_name,
        tags,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.name,
        OLD.description,
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN totp_tags tt ON t.id = tt.tag_id 
         WHERE tt.totp_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

  static const String _createNoteUpdateHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS note_update_history
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.title != NEW.title OR
      OLD.content != NEW.content OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_pinned != NEW.is_pinned
    )
    BEGIN
      INSERT INTO note_histories (
        id,
        original_note_id,
        action,
        title,
        content,
        category_id,
        category_name,
        tags,
        was_favorite,
        was_pinned,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.title,
        OLD.content,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN note_tags nt ON t.id = nt.tag_id 
         WHERE nt.note_id = OLD.id),
        OLD.is_favorite,
        OLD.is_pinned,
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

  // ==================== ТРИГГЕРЫ ИСТОРИИ ПРИ DELETE ====================

  static const String _createPasswordDeleteHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS password_delete_history
    BEFORE DELETE ON passwords
    FOR EACH ROW
    BEGIN
      INSERT INTO password_histories (
        id,
        original_password_id,
        action,
        name,
        description,
        password,
        url,
        notes,
        login,
        email,
        category_id,
        category_name,
        tags,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.name,
        OLD.description,
        OLD.password,
        OLD.url,
        OLD.notes,
        OLD.login,
        OLD.email,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN password_tags pt ON t.id = pt.tag_id 
         WHERE pt.password_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

  static const String _createTotpDeleteHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS totp_delete_history
    BEFORE DELETE ON totps
    FOR EACH ROW
    BEGIN
      INSERT INTO totp_histories (
        id,
        original_totp_id,
        action,
        name,
        description,
        type,
        issuer,
        account_name,
        algorithm,
        digits,
        period,
        counter,
        category_id,
        category_name,
        tags,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.name,
        OLD.description,
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN totp_tags tt ON t.id = tt.tag_id 
         WHERE tt.totp_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

  static const String _createNoteDeleteHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS note_delete_history
    BEFORE DELETE ON notes
    FOR EACH ROW
    BEGIN
      INSERT INTO note_histories (
        id,
        original_note_id,
        action,
        title,
        content,
        category_id,
        category_name,
        tags,
        was_favorite,
        was_pinned,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.title,
        OLD.content,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN note_tags nt ON t.id = nt.tag_id 
         WHERE nt.note_id = OLD.id),
        OLD.is_favorite,
        OLD.is_pinned,
        OLD.created_at,
        OLD.modified_at,
        datetime('now')
      );
    END;
  ''';

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
