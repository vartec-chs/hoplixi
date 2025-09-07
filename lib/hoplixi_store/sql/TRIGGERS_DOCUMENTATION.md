# SQL Триггеры для автоматического управления метаданными и историей

## Обзор

В Hoplixi реализована система SQL триггеров для автоматического управления метаданными времени и ведения истории изменений. Это обеспечивает:

1. **Автоматическое обновление `modified_at`** при любых изменениях
2. **Автоматическое заполнение `created_at` и `modified_at`** при создании записей
3. **Автоматическое ведение истории** изменений и удалений

## Типы триггеров

### 1. Триггеры обновления modified_at

Автоматически обновляют поле `modified_at` при любом `UPDATE` операции:

```sql
CREATE TRIGGER IF NOT EXISTS update_passwords_modified_at
AFTER UPDATE ON passwords
FOR EACH ROW
WHEN NEW.modified_at = OLD.modified_at
BEGIN
  UPDATE passwords 
  SET modified_at = datetime('now') 
  WHERE id = NEW.id;
END;
```

**Таблицы с этими триггерами:**
- `hoplixi_meta`
- `categories`
- `icons`
- `tags`
- `passwords`
- `totps`
- `notes`
- `attachments`

### 2. Триггеры заполнения timestamps при INSERT

Автоматически заполняют `created_at` и `modified_at` если они не указаны:

```sql
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
```

### 3. Триггеры истории изменений

#### При UPDATE
Автоматически сохраняют старую версию записи в таблицы истории при изменении:

```sql
CREATE TRIGGER IF NOT EXISTS password_update_history
AFTER UPDATE ON passwords
FOR EACH ROW
WHEN OLD.id = NEW.id AND (
  OLD.name != NEW.name OR
  OLD.password != NEW.password OR
  -- другие поля...
)
BEGIN
  INSERT INTO password_histories (
    id, original_password_id, action, name, password, ..., action_at
  ) VALUES (
    -- UUID генерация
    lower(hex(randomblob(4))) || '-' || ...,
    OLD.id, 'modified', OLD.name, OLD.password, ..., datetime('now')
  );
END;
```

#### При DELETE
Автоматически сохраняют удаляемую запись в таблицы истории:

```sql
CREATE TRIGGER IF NOT EXISTS password_delete_history
BEFORE DELETE ON passwords
FOR EACH ROW
BEGIN
  INSERT INTO password_histories (
    id, original_password_id, action, ..., action_at
  ) VALUES (
    -- UUID генерация
    ..., OLD.id, 'deleted', ..., datetime('now')
  );
END;
```

## Использование в коде

### Автоматическое создание при миграции

Триггеры автоматически создаются при создании базы данных:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await DatabaseTriggers.createTriggers(this);
    },
  );
}
```

### Проверка работы триггеров

```dart
// Проверить, что все триггеры установлены
final areInstalled = await database.verifyTriggers();

// Получить список установленных триггеров
final triggers = await database.getInstalledTriggers();

// Протестировать работу триггеров
final testResults = await database.testTriggers();
```

### Управление историей

```dart
// Получить статистику по таблицам истории
final stats = await database.getHistoryStatistics();
// Результат: {'password_history': 150, 'totp_history': 50, 'note_history': 30}

// Очистить старую историю (старше 1 года)
final deleted = await database.cleanupOldHistory(daysToKeep: 365);
// Результат: {'password_history': 50, 'totp_history': 20, 'note_history': 10}
```

### Пересоздание триггеров

```dart
// Пересоздать все триггеры (полезно для отладки)
await database.recreateTriggers();
```

## Особенности реализации

### UUID генерация в SQL

Триггеры используют SQL функции для генерации UUID v4:

```sql
lower(hex(randomblob(4))) || '-' || 
lower(hex(randomblob(2))) || '-4' || 
substr(lower(hex(randomblob(2))),2) || '-' || 
substr('ab89',abs(random()) % 4 + 1, 1) || 
substr(lower(hex(randomblob(2))),2) || '-' || 
lower(hex(randomblob(6)))
```

### Сбор тегов в JSON

Триггеры автоматически собирают связанные теги в JSON массив:

```sql
(SELECT json_group_array(t.name) FROM tags t 
 JOIN password_tags pt ON t.id = pt.tag_id 
 WHERE pt.password_id = OLD.id)
```

### Условная активация

Триггеры срабатывают только при реальных изменениях:

```sql
WHEN OLD.name != NEW.name OR OLD.password != NEW.password OR ...
```

## Преимущества

1. **Надежность**: Метаданные обновляются автоматически, исключая человеческие ошибки
2. **Производительность**: Операции выполняются на уровне базы данных
3. **Консистентность**: Все изменения записываются в историю атомарно
4. **Простота**: Не нужно помнить об обновлении метаданных в коде
5. **Аудит**: Полная история всех изменений и удалений

## Мониторинг и отладка

### Просмотр истории изменений

```sql
-- История изменений пароля
SELECT action, name, action_at 
FROM password_histories 
WHERE original_password_id = 'some-uuid'
ORDER BY action_at DESC;

-- Статистика действий
SELECT action, COUNT(*) as count
FROM password_histories
GROUP BY action;
```

### Проверка триггеров

```sql
-- Список всех триггеров
SELECT name FROM sqlite_master 
WHERE type='trigger' 
ORDER BY name;

-- Код конкретного триггера
SELECT sql FROM sqlite_master 
WHERE type='trigger' AND name='password_update_history';
```

## Рекомендации

1. **Тестирование**: Регулярно тестируйте работу триггеров через `testTriggers()`
2. **Мониторинг**: Отслеживайте размер таблиц истории через `getHistoryStatistics()`
3. **Очистка**: Настройте периодическую очистку старой истории через `cleanupOldHistory()`
4. **Бэкап**: Всегда делайте бэкап перед `recreateTriggers()`

## Известные ограничения

1. UUID генерация в SQL менее производительна чем в Dart
2. Триггеры могут замедлить операции INSERT/UPDATE
3. Размер таблиц истории может расти быстро
4. Восстановление после ошибок в триггерах может быть сложным

Для критически важных операций рассмотрите возможность временного отключения триггеров и ручного управления историей в коде.
