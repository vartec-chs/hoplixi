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
    _createModifiedAtTriggerForOtp,
    _createModifiedAtTriggerForNotes,
    _createModifiedAtTriggerForAttachments,

    // Триггеры для заполнения created_at и modified_at при INSERT
    _createInsertTriggerForHoplixiMeta,
    _createInsertTriggerForCategories,
    _createInsertTriggerForIcons,
    _createInsertTriggerForTags,
    _createInsertTriggerForPasswords,
    _createInsertTriggerForOtp,
    _createInsertTriggerForNotes,
    _createInsertTriggerForAttachments,

    // Триггеры для записи истории при UPDATE
    _createPasswordUpdateHistoryTrigger,
    _createOtpUpdateHistoryTrigger,
    _createNoteUpdateHistoryTrigger,

    // Триггеры для записи истории при DELETE
    _createPasswordDeleteHistoryTrigger,
    _createOtpDeleteHistoryTrigger,
    _createNoteDeleteHistoryTrigger,

    // Триггеры для синхронизации hoplixi_meta при изменениях других таблиц
    _createMetaTouchTriggerForCategories,
    _createMetaTouchTriggerForIcons,
    _createMetaTouchTriggerForTags,
    _createMetaTouchTriggerForPasswords,
    _createMetaTouchTriggerForPasswordTags,
    _createMetaTouchTriggerForPasswordHistories,
    _createMetaTouchTriggerForOtps,
    _createMetaTouchTriggerForOtpTags,
    _createMetaTouchTriggerForOtpHistories,
    _createMetaTouchTriggerForNotes,
    _createMetaTouchTriggerForNoteTags,
    _createMetaTouchTriggerForNoteHistories,
    _createMetaTouchTriggerForAttachments,
  ];

  /// Список команд для удаления всех триггеров
  static const List<String> dropTriggerStatements = [
    'DROP TRIGGER IF EXISTS update_hoplixi_meta_modified_at;',
    'DROP TRIGGER IF EXISTS update_categories_modified_at;',
    'DROP TRIGGER IF EXISTS update_icons_modified_at;',
    'DROP TRIGGER IF EXISTS update_tags_modified_at;',
    'DROP TRIGGER IF EXISTS update_passwords_modified_at;',
    'DROP TRIGGER IF EXISTS update_otps_modified_at;',
    'DROP TRIGGER IF EXISTS update_notes_modified_at;',
    'DROP TRIGGER IF EXISTS update_attachments_modified_at;',
    'DROP TRIGGER IF EXISTS insert_hoplixi_meta_timestamps;',
    'DROP TRIGGER IF EXISTS insert_categories_timestamps;',
    'DROP TRIGGER IF EXISTS insert_icons_timestamps;',
    'DROP TRIGGER IF EXISTS insert_tags_timestamps;',
    'DROP TRIGGER IF EXISTS insert_passwords_timestamps;',
    'DROP TRIGGER IF EXISTS insert_otps_timestamps;',
    'DROP TRIGGER IF EXISTS insert_notes_timestamps;',
    'DROP TRIGGER IF EXISTS insert_attachments_timestamps;',
    'DROP TRIGGER IF EXISTS password_update_history;',
    'DROP TRIGGER IF EXISTS otp_update_history;',
    'DROP TRIGGER IF EXISTS note_update_history;',
    'DROP TRIGGER IF EXISTS password_delete_history;',
    'DROP TRIGGER IF EXISTS otp_delete_history;',
    'DROP TRIGGER IF EXISTS note_delete_history;',
    'DROP TRIGGER IF EXISTS touch_meta_on_categories_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_icons_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_tags_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_passwords_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_password_histories_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_otps_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_otp_histories_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_notes_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_note_histories_change;',
    'DROP TRIGGER IF EXISTS touch_meta_on_attachments_change;',
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
      SET modified_at = strftime('%s','now') 
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
      SET modified_at = strftime('%s','now') 
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
      SET modified_at = strftime('%s','now') 
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
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createModifiedAtTriggerForOtp = '''
    CREATE TRIGGER IF NOT EXISTS update_otps_modified_at
    AFTER UPDATE ON otps
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE otps 
      SET modified_at = strftime('%s','now') 
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
      SET modified_at = strftime('%s','now') 
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
      SET modified_at = strftime('%s','now') 
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
      WHERE id = NEW.id;
    END;
  ''';

  static const String _createInsertTriggerForOtp = '''
    CREATE TRIGGER IF NOT EXISTS insert_otps_timestamps
    AFTER INSERT ON otps
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE otps
      SET
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
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
        strftime('%s','now')
      );
    END;
  ''';

  static const String _createOtpUpdateHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS otp_update_history
    AFTER UPDATE ON otps
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.type != NEW.type OR
      OLD.issuer != NEW.issuer OR
      OLD.account_name != NEW.account_name OR
      OLD.secret != NEW.secret OR
      OLD.notes != NEW.notes OR
      OLD.algorithm != NEW.algorithm OR
      OLD.digits != NEW.digits OR
      OLD.period != NEW.period OR
      OLD.counter != NEW.counter OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite
    )
    BEGIN
      INSERT INTO otp_histories (
        id,
        original_otp_id,
        action,
        type,
        issuer,
        account_name,
        secret,
        notes,
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
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.secret,
        OLD.notes,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t
         JOIN otp_tags tt ON t.id = tt.tag_id
         WHERE tt.otp_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
      );
    END;
  ''';

  static const String _createNoteUpdateHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS note_update_history
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.title != NEW.title OR
      OLD.description != NEW.description OR
  OLD.delta_json != NEW.delta_json OR
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
        description,
  delta_json,
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
        OLD.description,
  OLD.delta_json,
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
        strftime('%s','now')
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
        strftime('%s','now')
      );
    END;
  ''';

  static const String _createOtpDeleteHistoryTrigger = '''
    CREATE TRIGGER IF NOT EXISTS otp_delete_history
    BEFORE DELETE ON otps
    FOR EACH ROW
    BEGIN
      INSERT INTO otp_histories (
        id,
        original_otp_id,
        action,
        type,
        issuer,
        account_name,
        secret,
        notes,
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
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.secret,
        OLD.notes,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t
         JOIN otp_tags tt ON t.id = tt.tag_id
         WHERE tt.otp_id = OLD.id),
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
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
        description,
  delta_json,
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
        OLD.description,
  OLD.delta_json,
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
        strftime('%s','now')
      );
    END;
  ''';

  // ==================== ТРИГГЕРЫ СИНХРОНИЗАЦИИ HOPLIXI_META ====================

  static const String _createMetaTouchTriggerForCategories = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_change
      AFTER INSERT OR UPDATE OR DELETE ON categories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForIcons = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_change
      AFTER INSERT OR UPDATE OR DELETE ON icons
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForTags = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_change
      AFTER INSERT OR UPDATE OR DELETE ON tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForPasswords = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_change
      AFTER INSERT OR UPDATE OR DELETE ON passwords
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForPasswordTags = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_change
      AFTER INSERT OR UPDATE OR DELETE ON password_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForPasswordHistories = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_histories_change
      AFTER INSERT OR UPDATE OR DELETE ON password_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForOtps = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_change
      AFTER INSERT OR UPDATE OR DELETE ON otps
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForOtpTags = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_change
      AFTER INSERT OR UPDATE OR DELETE ON otp_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForOtpHistories = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_histories_change
      AFTER INSERT OR UPDATE OR DELETE ON otp_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForNotes = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_change
      AFTER INSERT OR UPDATE OR DELETE ON notes
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForNoteTags = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_change
      AFTER INSERT OR UPDATE OR DELETE ON note_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForNoteHistories = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_histories_change
      AFTER INSERT OR UPDATE OR DELETE ON note_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''';

  static const String _createMetaTouchTriggerForAttachments = '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_attachments_change
      AFTER INSERT OR UPDATE OR DELETE ON attachments
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
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
