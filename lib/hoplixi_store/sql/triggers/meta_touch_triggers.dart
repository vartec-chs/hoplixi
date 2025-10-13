const List<String> metaTouchCreateTriggers = [
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_insert
      AFTER INSERT ON categories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_update
      AFTER UPDATE ON categories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_delete
      AFTER DELETE ON categories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_insert
      AFTER INSERT ON icons
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_update
      AFTER UPDATE ON icons
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_delete
      AFTER DELETE ON icons
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_insert
      AFTER INSERT ON tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_update
      AFTER UPDATE ON tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_delete
      AFTER DELETE ON tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_insert
      AFTER INSERT ON passwords
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_update
      AFTER UPDATE ON passwords
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_delete
      AFTER DELETE ON passwords
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_insert
      AFTER INSERT ON password_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_update
      AFTER UPDATE ON password_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_delete
      AFTER DELETE ON password_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_histories_insert
      AFTER INSERT ON password_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_histories_update
      AFTER UPDATE ON password_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_histories_delete
      AFTER DELETE ON password_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_insert
      AFTER INSERT ON otps
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_update
      AFTER UPDATE ON otps
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_delete
      AFTER DELETE ON otps
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_insert
      AFTER INSERT ON otp_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_update
      AFTER UPDATE ON otp_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_delete
      AFTER DELETE ON otp_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_histories_insert
      AFTER INSERT ON otp_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_histories_update
      AFTER UPDATE ON otp_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_histories_delete
      AFTER DELETE ON otp_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_insert
      AFTER INSERT ON notes
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_update
      AFTER UPDATE ON notes
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_delete
      AFTER DELETE ON notes
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_insert
      AFTER INSERT ON note_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_update
      AFTER UPDATE ON note_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_delete
      AFTER DELETE ON note_tags
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_histories_insert
      AFTER INSERT ON note_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_histories_update
      AFTER UPDATE ON note_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_histories_delete
      AFTER DELETE ON note_histories
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_attachments_insert
      AFTER INSERT ON attachments
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_attachments_update
      AFTER UPDATE ON attachments
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
  '''
      CREATE TRIGGER IF NOT EXISTS touch_meta_on_attachments_delete
      AFTER DELETE ON attachments
      BEGIN
        UPDATE hoplixi_meta
        SET modified_at = strftime('%s','now')
        WHERE id = (
          SELECT id FROM hoplixi_meta
          ORDER BY created_at
          LIMIT 1
        );
      END;
    ''',
];

const List<String> metaTouchDropStatements = [
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_histories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_histories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_histories_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_histories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_histories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_histories_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_histories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_histories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_histories_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_attachments_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_attachments_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_attachments_delete;',
];
