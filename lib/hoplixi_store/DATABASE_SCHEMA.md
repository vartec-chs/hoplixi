# Схема базы данных Hoplixi Password Manager

## Обзор

База данных Hoplixi использует Drift ORM для Flutter/Dart и SQLite с шифрованием SQLCipher. Все ID таблиц используют UUID v4 для повышенной безопасности.

## Таблицы

### 1. HoplixiMeta - Метаданные базы данных
- `id` - UUID v4, первичный ключ
- `name` - Название базы данных
- `description` - Описание (опционально)
- `password_hash` - Хеш мастер-пароля
- `salt` - Соль для хеширования
- `created_at`, `modified_at` - Временные метки
- `version` - Версия схемы БД

### 2. Icons - Иконки
- `id` - UUID v4, первичный ключ
- `name` - Название иконки
- `type` - MIME тип (png, jpg, svg, etc.)
- `data` - Бинарные данные изображения
- `created_at`, `modified_at` - Временные метки

### 3. Categories - Категории
- `id` - UUID v4, первичный ключ
- `name` - Название категории
- `description` - Описание (опционально)
- `icon_id` - Ссылка на иконку (FK -> Icons.id, опционально)
- `color` - Цвет в hex формате (опционально)
- `type` - Тип категории (ENUM: notes, password, totp, mixed)
- `created_at`, `modified_at` - Временные метки

### 4. Tags - Теги
- `id` - UUID v4, первичный ключ
- `name` - Название тега
- `color` - Цвет в hex формате (опционально)
- `type` - Тип тега (ENUM: notes, password, totp, mixed)
- `created_at`, `modified_at` - Временные метки

### 5. Passwords - Пароли
- `id` - UUID v4, первичный ключ
- `name` - Название записи
- `description` - Описание (опционально)
- `password` - Зашифрованный пароль
- `url` - URL сайта (опционально)
- `notes` - Заметки (опционально)
- `login` - Логин/имя пользователя (опционально)
- `email` - Email (опционально)
- `category_id` - Ссылка на категорию (FK -> Categories.id, опционально)
- `is_favorite` - Флаг избранного (по умолчанию false)
- `created_at`, `modified_at`, `last_accessed` - Временные метки
- **Ограничение**: Должен быть указан либо login, либо email, либо оба

### 6. PasswordTags - Связь паролей и тегов (многие ко многим)
- `password_id` - Ссылка на пароль (FK -> Passwords.id)
- `tag_id` - Ссылка на тег (FK -> Tags.id)
- `created_at` - Время создания связи
- **Первичный ключ**: (password_id, tag_id)

### 7. Totps - TOTP коды
- `id` - UUID v4, первичный ключ
- `password_id` - Ссылка на пароль (FK -> Passwords.id, опционально)
- `name` - Название TOTP записи
- `description` - Описание (опционально)
- `secret_cipher` - Зашифрованный секретный ключ TOTP
- `algorithm` - Алгоритм HMAC (по умолчанию SHA1)
- `digits` - Количество цифр в коде (по умолчанию 6)
- `period` - Период в секундах (по умолчанию 30)
- `category_id` - Ссылка на категорию (FK -> Categories.id, опционально)
- `is_favorite` - Флаг избранного (по умолчанию false)
- `created_at`, `modified_at`, `last_accessed` - Временные метки

### 8. TotpTags - Связь TOTP и тегов (многие ко многим)
- `totp_id` - Ссылка на TOTP (FK -> Totps.id)
- `tag_id` - Ссылка на тег (FK -> Tags.id)
- `created_at` - Время создания связи
- **Первичный ключ**: (totp_id, tag_id)

### 9. Attachments - Вложения
- `id` - UUID v4, первичный ключ
- `name` - Название файла
- `description` - Описание (опционально)
- `file_path` - Путь к файлу на диске
- `mime_type` - MIME тип файла
- `file_size` - Размер файла в байтах
- `checksum` - Контрольная сумма файла (опционально)
- `password_id` - Ссылка на пароль (FK -> Passwords.id, опционально)
- `totp_id` - Ссылка на TOTP (FK -> Totps.id, опционально)
- `created_at`, `modified_at` - Временные метки
- **Ограничение**: Вложение должно принадлежать либо паролю, либо TOTP (но не обоим одновременно)

### 10. PasswordHistories - История паролей
- `id` - UUID v4, первичный ключ
- `original_password_id` - ID оригинального пароля
- `action` - Действие (deleted, modified)
- `name`, `description`, `password`, `url`, `notes`, `login`, `email` - Копии полей
- `category_id`, `category_name` - ID и название категории на момент действия
- `tags` - JSON массив названий тегов
- `original_created_at`, `original_modified_at` - Оригинальные временные метки
- `action_at` - Время выполнения действия

### 11. TotpHistories - История TOTP
- `id` - UUID v4, первичный ключ
- `original_totp_id` - ID оригинального TOTP
- `action` - Действие (deleted, modified)
- `name`, `description`, `secret_cipher`, `algorithm`, `digits`, `period` - Копии полей
- `category_id`, `category_name` - ID и название категории на момент действия
- `tags` - JSON массив названий тегов
- `original_created_at`, `original_modified_at` - Оригинальные временные метки
- `action_at` - Время выполнения действия

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

## Генерация кода

Для генерации кода Drift выполните:
```bash
dart run build_runner build
```
