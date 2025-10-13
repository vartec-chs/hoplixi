const List<String> insertTimestampCreateTriggers = [
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
];

const List<String> insertTimestampDropStatements = [
  'DROP TRIGGER IF EXISTS insert_hoplixi_meta_timestamps;',
  'DROP TRIGGER IF EXISTS insert_categories_timestamps;',
  'DROP TRIGGER IF EXISTS insert_icons_timestamps;',
  'DROP TRIGGER IF EXISTS insert_tags_timestamps;',
  'DROP TRIGGER IF EXISTS insert_passwords_timestamps;',
  'DROP TRIGGER IF EXISTS insert_otps_timestamps;',
  'DROP TRIGGER IF EXISTS insert_notes_timestamps;',
  'DROP TRIGGER IF EXISTS insert_attachments_timestamps;',
];
