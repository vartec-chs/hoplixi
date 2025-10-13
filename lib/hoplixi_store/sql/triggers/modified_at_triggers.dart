const List<String> modifiedAtCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_hoplixi_meta_modified_at
    AFTER UPDATE ON hoplixi_meta
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE hoplixi_meta 
      SET modified_at = strftime('%s', 'now')
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_categories_modified_at
    AFTER UPDATE ON categories
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE categories 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_icons_modified_at
    AFTER UPDATE ON icons
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE icons 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_tags_modified_at
    AFTER UPDATE ON tags
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE tags 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_passwords_modified_at
    AFTER UPDATE ON passwords
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE passwords 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_otps_modified_at
    AFTER UPDATE ON otps
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE otps 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_notes_modified_at
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE notes 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS update_attachments_modified_at
    AFTER UPDATE ON attachments
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE attachments 
      SET modified_at = strftime('%s','now') 
      WHERE id = NEW.id;
    END;
  ''',
];

const List<String> modifiedAtDropStatements = [
  'DROP TRIGGER IF EXISTS update_hoplixi_meta_modified_at;',
  'DROP TRIGGER IF EXISTS update_categories_modified_at;',
  'DROP TRIGGER IF EXISTS update_icons_modified_at;',
  'DROP TRIGGER IF EXISTS update_tags_modified_at;',
  'DROP TRIGGER IF EXISTS update_passwords_modified_at;',
  'DROP TRIGGER IF EXISTS update_otps_modified_at;',
  'DROP TRIGGER IF EXISTS update_notes_modified_at;',
  'DROP TRIGGER IF EXISTS update_attachments_modified_at;',
];
