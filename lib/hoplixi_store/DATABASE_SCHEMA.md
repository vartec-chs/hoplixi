# Схема базы данных Hoplixi Password Manager

## Обзор

База данных Hoplixi использует Drift ORM для Flutter/Dart и SQLite с шифрованием SQLCipher. Все ID таблиц используют UUID v4 для повышенной безопасности.

## Таблицы

### 1. HoplixiMeta - Метаданные базы данных

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-255), название базы данных
- `description` - TEXT(0-1024), описание (опционально)
- `password_hash` - TEXT, хеш мастер-пароля
- `salt` - TEXT, соль для хеширования
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)
- `version` - TEXT, версия схемы БД (по умолчанию '1.0.0')

### 2. Icons - Иконки

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-255), название иконки
- `type` - TEXT(1-100), MIME тип (png, jpg, svg, etc.)
- `data` - BLOB, бинарные данные изображения
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)

### 3. Categories - Категории

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-100), название категории
- `description` - TEXT, описание (опционально)
- `icon_id` - TEXT, ссылка на иконку (FK -> Icons.id, опционально)
- `color` - TEXT, цвет в hex формате (опционально)
- `type` - TEXT ENUM, тип категории (notes, password, totp, mixed)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)

### 4. Tags - Теги

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-100), название тега
- `color` - TEXT, цвет в hex формате (опционально)
- `type` - TEXT ENUM, тип тега (notes, password, totp, mixed)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)

### 5. Notes - Заметки

- `id` - TEXT, UUID v4, первичный ключ
- `title` - TEXT(1-255), заголовок заметки
- `content` - TEXT, основное содержимое заметки
- `category_id` - TEXT, ссылка на категорию (FK -> Categories.id, опционально)
- `is_favorite` - BOOLEAN, флаг избранного (по умолчанию false)
- `is_pinned` - BOOLEAN, флаг закрепления (по умолчанию false)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)
- `last_accessed` - DATETIME, время последнего доступа (опционально)

### 6. Passwords - Пароли

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-255), название записи
- `description` - TEXT, описание (опционально)
- `password` - TEXT, зашифрованный пароль
- `url` - TEXT, URL сайта (опционально)
- `notes` - TEXT, заметки (опционально)
- `login` - TEXT, логин/имя пользователя (опционально)
- `email` - TEXT, email (опционально)
- `category_id` - TEXT, ссылка на категорию (FK -> Categories.id, опционально)
- `is_favorite` - BOOLEAN, флаг избранного (по умолчанию false)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)
- `last_accessed` - DATETIME, время последнего доступа (опционально)
- **Ограничение**: CHECK (login IS NOT NULL OR email IS NOT NULL)

### 7. Totps - TOTP коды

- `id` - TEXT, UUID v4, первичный ключ
- `password_id` - TEXT, ссылка на пароль (FK -> Passwords.id, опционально)
- `name` - TEXT(1-255), название TOTP записи
- `description` - TEXT, описание (опционально)
- `secret_cipher` - TEXT, зашифрованный секретный ключ TOTP
- `algorithm` - TEXT, алгоритм HMAC (по умолчанию 'SHA1')
- `digits` - INTEGER, количество цифр в коде (по умолчанию 6)
- `period` - INTEGER, период в секундах (по умолчанию 30)
- `category_id` - TEXT, ссылка на категорию (FK -> Categories.id, опционально)
- `is_favorite` - BOOLEAN, флаг избранного (по умолчанию false)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)
- `last_accessed` - DATETIME, время последнего доступа (опционально)

### 8. Attachments - Вложения

- `id` - TEXT, UUID v4, первичный ключ
- `name` - TEXT(1-255), название файла
- `description` - TEXT, описание (опционально)
- `file_path` - TEXT, путь к файлу на диске
- `mime_type` - TEXT, MIME тип файла
- `file_size` - INTEGER, размер файла в байтах
- `checksum` - TEXT, контрольная сумма файла (опционально)
- `password_id` - TEXT, ссылка на пароль (FK -> Passwords.id, опционально)
- `totp_id` - TEXT, ссылка на TOTP (FK -> Totps.id, опционально)
- `note_id` - TEXT, ссылка на заметку (FK -> Notes.id, опционально)
- `created_at` - DATETIME, время создания (авто)
- `modified_at` - DATETIME, время изменения (авто)
- **Ограничение**: CHECK (точно одно из полей password_id, totp_id, note_id должно быть NOT NULL)

## Связующие таблицы (Many-to-Many)

### 9. PasswordTags - Связь паролей и тегов

- `password_id` - TEXT, ссылка на пароль (FK -> Passwords.id)
- `tag_id` - TEXT, ссылка на тег (FK -> Tags.id)
- `created_at` - DATETIME, время создания связи (авто)
- **Первичный ключ**: (password_id, tag_id)

### 10. TotpTags - Связь TOTP и тегов

- `totp_id` - TEXT, ссылка на TOTP (FK -> Totps.id)
- `tag_id` - TEXT, ссылка на тег (FK -> Tags.id)
- `created_at` - DATETIME, время создания связи (авто)
- **Первичный ключ**: (totp_id, tag_id)

### 11. NoteTags - Связь заметок и тегов

- `note_id` - TEXT, ссылка на заметку (FK -> Notes.id)
- `tag_id` - TEXT, ссылка на тег (FK -> Tags.id)
- `created_at` - DATETIME, время создания связи (авто)
- **Первичный ключ**: (note_id, tag_id)

## Таблицы истории

### 12. PasswordHistories - История паролей

- `id` - TEXT, UUID v4, первичный ключ
- `original_password_id` - TEXT, ID оригинального пароля
- `action` - TEXT(1-50), действие ('deleted', 'modified')
- `name` - TEXT(1-255), название записи
- `description` - TEXT, описание (опционально)
- `password` - TEXT, зашифрованный пароль (опционально для приватности)
- `url` - TEXT, URL сайта (опционально)
- `notes` - TEXT, заметки (опционально)
- `login` - TEXT, логин (опционально)
- `email` - TEXT, email (опционально)
- `category_id` - TEXT, ID категории на момент действия (опционально)
- `category_name` - TEXT, название категории на момент действия (опционально)
- `tags` - TEXT, JSON массив названий тегов (опционально)
- `original_created_at` - DATETIME, оригинальное время создания (опционально)
- `original_modified_at` - DATETIME, оригинальное время изменения (опционально)
- `action_at` - DATETIME, время выполнения действия (авто)

### 13. TotpHistories - История TOTP

- `id` - TEXT, UUID v4, первичный ключ
- `original_totp_id` - TEXT, ID оригинального TOTP
- `action` - TEXT(1-50), действие ('deleted', 'modified')
- `name` - TEXT(1-255), название TOTP записи
- `description` - TEXT, описание (опционально)
- `secret_cipher` - TEXT, зашифрованный секрет (опционально для приватности)
- `algorithm` - TEXT, алгоритм HMAC (опционально)
- `digits` - INTEGER, количество цифр (опционально)
- `period` - INTEGER, период в секундах (опционально)
- `category_id` - TEXT, ID категории на момент действия (опционально)
- `category_name` - TEXT, название категории на момент действия (опционально)
- `tags` - TEXT, JSON массив названий тегов (опционально)
- `original_created_at` - DATETIME, оригинальное время создания (опционально)
- `original_modified_at` - DATETIME, оригинальное время изменения (опционально)
- `action_at` - DATETIME, время выполнения действия (авто)

### 14. NoteHistories - История заметок

- `id` - TEXT, UUID v4, первичный ключ
- `original_note_id` - TEXT, ID оригинальной заметки
- `action` - TEXT(1-50), действие ('deleted', 'modified')
- `title` - TEXT(1-255), заголовок заметки
- `content` - TEXT, содержимое (опционально для приватности)
- `category_id` - TEXT, ID категории на момент действия (опционально)
- `category_name` - TEXT, название категории на момент действия (опционально)
- `tags` - TEXT, JSON массив названий тегов (опционально)
- `was_favorite` - BOOLEAN, был ли избранным (опционально)
- `was_pinned` - BOOLEAN, был ли закреплен (опционально)
- `original_created_at` - DATETIME, оригинальное время создания (опционально)
- `original_modified_at` - DATETIME, оригинальное время изменения (опционально)
- `action_at` - DATETIME, время выполнения действия (авто)

## Enums

### CategoryType / TagType

- `notes` - Для заметок
- `password` - Для паролей
- `totp` - Для TOTP кодов
- `mixed` - Смешанный тип

## Особенности безопасности

1. **UUID v4**: Все ID используют UUID v4 для предотвращения перебора
2. **Шифрование**: Пароли и TOTP секреты хранятся в зашифрованном виде
3. **Целостность файлов**: Вложения имеют контрольные суммы
4. **Аудит**: История изменений и удалений ведется в отдельных таблицах
5. **Foreign Keys**: Включены ограничения внешних ключей
6. **Проверочные ограничения**: Обеспечивают целостность данных

## Связи между таблицами

### Основные связи

- `Categories.icon_id` -> `Icons.id` (многие к одному)
- `Notes.category_id` -> `Categories.id` (многие к одному)
- `Passwords.category_id` -> `Categories.id` (многие к одному)
- `Totps.category_id` -> `Categories.id` (многие к одному)
- `Totps.password_id` -> `Passwords.id` (многие к одному)
- `Attachments.note_id` -> `Notes.id` (многие к одному)
- `Attachments.password_id` -> `Passwords.id` (многие к одному)
- `Attachments.totp_id` -> `Totps.id` (многие к одному)

### Связи многие-ко-многим

- `Notes` ↔ `Tags` через `NoteTags`
- `Passwords` ↔ `Tags` через `PasswordTags`
- `Totps` ↔ `Tags` через `TotpTags`

## Ограничения целостности

1. **Passwords**: CHECK (login IS NOT NULL OR email IS NOT NULL)
2. **Attachments**: CHECK (точно одно из полей password_id, totp_id, note_id должно быть NOT NULL)

## Генерация кода

Для генерации кода Drift выполните:

```bash
dart run build_runner build
```

## SQL представление схемы

```sql
-- Основные таблицы
CREATE TABLE hoplixi_meta (
    id TEXT PRIMARY KEY,
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT(1024),
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version TEXT NOT NULL DEFAULT '1.0.0'
);

CREATE TABLE icons (
    id TEXT PRIMARY KEY,
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    type TEXT(100) NOT NULL CHECK(length(type) >= 1),
    data BLOB NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT(100) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    icon_id TEXT,
    color TEXT,
    type TEXT NOT NULL CHECK(type IN ('notes', 'password', 'totp', 'mixed')),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (icon_id) REFERENCES icons(id)
);

CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    name TEXT(100) NOT NULL CHECK(length(name) >= 1),
    color TEXT,
    type TEXT NOT NULL CHECK(type IN ('notes', 'password', 'totp', 'mixed')),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    title TEXT(255) NOT NULL CHECK(length(title) >= 1),
    content TEXT NOT NULL,
    category_id TEXT,
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    is_pinned BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed DATETIME,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE passwords (
    id TEXT PRIMARY KEY,
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    password TEXT NOT NULL,
    url TEXT,
    notes TEXT,
    login TEXT,
    email TEXT,
    category_id TEXT,
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed DATETIME,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    CHECK (login IS NOT NULL OR email IS NOT NULL)
);

CREATE TABLE totps (
    id TEXT PRIMARY KEY,
    password_id TEXT,
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    secret_cipher TEXT NOT NULL,
    algorithm TEXT NOT NULL DEFAULT 'SHA1',
    digits INTEGER NOT NULL DEFAULT 6,
    period INTEGER NOT NULL DEFAULT 30,
    category_id TEXT,
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed DATETIME,
    FOREIGN KEY (password_id) REFERENCES passwords(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE attachments (
    id TEXT PRIMARY KEY,
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    file_path TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    checksum TEXT,
    password_id TEXT,
    totp_id TEXT,
    note_id TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (password_id) REFERENCES passwords(id),
    FOREIGN KEY (totp_id) REFERENCES totps(id),
    FOREIGN KEY (note_id) REFERENCES notes(id),
    CHECK ((password_id IS NOT NULL AND totp_id IS NULL AND note_id IS NULL) OR 
           (password_id IS NULL AND totp_id IS NOT NULL AND note_id IS NULL) OR 
           (password_id IS NULL AND totp_id IS NULL AND note_id IS NOT NULL))
);

-- Связующие таблицы
CREATE TABLE note_tags (
    note_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (note_id, tag_id),
    FOREIGN KEY (note_id) REFERENCES notes(id),
    FOREIGN KEY (tag_id) REFERENCES tags(id)
);

CREATE TABLE password_tags (
    password_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (password_id, tag_id),
    FOREIGN KEY (password_id) REFERENCES passwords(id),
    FOREIGN KEY (tag_id) REFERENCES tags(id)
);

CREATE TABLE totp_tags (
    totp_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (totp_id, tag_id),
    FOREIGN KEY (totp_id) REFERENCES totps(id),
    FOREIGN KEY (tag_id) REFERENCES tags(id)
);

-- Таблицы истории
CREATE TABLE note_histories (
    id TEXT PRIMARY KEY,
    original_note_id TEXT NOT NULL,
    action TEXT(50) NOT NULL CHECK(length(action) >= 1),
    title TEXT(255) NOT NULL CHECK(length(title) >= 1),
    content TEXT,
    category_id TEXT,
    category_name TEXT,
    tags TEXT,
    was_favorite BOOLEAN,
    was_pinned BOOLEAN,
    original_created_at DATETIME,
    original_modified_at DATETIME,
    action_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE password_histories (
    id TEXT PRIMARY KEY,
    original_password_id TEXT NOT NULL,
    action TEXT(50) NOT NULL CHECK(length(action) >= 1),
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    password TEXT,
    url TEXT,
    notes TEXT,
    login TEXT,
    email TEXT,
    category_id TEXT,
    category_name TEXT,
    tags TEXT,
    original_created_at DATETIME,
    original_modified_at DATETIME,
    action_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE totp_histories (
    id TEXT PRIMARY KEY,
    original_totp_id TEXT NOT NULL,
    action TEXT(50) NOT NULL CHECK(length(action) >= 1),
    name TEXT(255) NOT NULL CHECK(length(name) >= 1),
    description TEXT,
    secret_cipher TEXT,
    algorithm TEXT,
    digits INTEGER,
    period INTEGER,
    category_id TEXT,
    category_name TEXT,
    tags TEXT,
    original_created_at DATETIME,
    original_modified_at DATETIME,
    action_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```
