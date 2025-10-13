const List<String> historyDeleteCreateTriggers = [
  '''
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
  ''',
  '''
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
  ''',
  '''
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
  ''',
];

const List<String> historyDeleteDropStatements = [
  'DROP TRIGGER IF EXISTS password_delete_history;',
  'DROP TRIGGER IF EXISTS otp_delete_history;',
  'DROP TRIGGER IF EXISTS note_delete_history;',
];
