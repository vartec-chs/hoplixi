const List<String> historyUpdateCreateTriggers = [
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
];

const List<String> historyUpdateDropStatements = [
  'DROP TRIGGER IF EXISTS password_update_history;',
  'DROP TRIGGER IF EXISTS otp_update_history;',
  'DROP TRIGGER IF EXISTS note_update_history;',
];
