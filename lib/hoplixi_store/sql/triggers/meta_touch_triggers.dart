const List<String> metaTouchCreateTriggers = [
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
];

const List<String> metaTouchDropStatements = [
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
