# DAO (Data Access Objects) для HoplixiStore

Этот каталог содержит все Data Access Objects (DAO) для работы с базой данных HoplixiStore, построенные с использованием библиотеки Drift.

## Структура DAO

### Основные DAO для сущностей

1. **PasswordsDao** (`passwords_dao.dart`)
   - Управление паролями
   - Поиск, фильтрация, избранные пароли
   - Обновление времени доступа

2. **NotesDao** (`notes_dao.dart`)
   - Управление заметками
   - Закрепленные и избранные заметки
   - Поиск по содержимому

3. **CategoriesDao** (`categories_dao.dart`)
   - Управление категориями
   - Фильтрация по типам
   - Подсчет элементов в категориях

4. **TotpsDao** (`totps_dao.dart`)
   - Управление TOTP/HOTP кодами
   - Обновление счетчиков HOTP
   - Связь с паролями

5. **TagsDao** (`tags_dao.dart`)
   - Управление тегами
   - Подсчет использования тегов
   - Поиск неиспользуемых тегов

6. **IconsDao** (`icons_dao.dart`)
   - Управление иконками
   - Анализ размеров файлов
   - Очистка неиспользуемых иконок

7. **AttachmentsDao** (`attachments_dao.dart`)
   - Управление вложениями
   - Проверка целостности файлов
   - Группировка по типам родительских объектов

### DAO для связей многие-ко-многим

1. **PasswordTagsDao** (`password_tags_dao.dart`)
   - Связи между паролями и тегами
   - Поиск паролей по тегам

2. **NoteTagsDao** (`note_tags_dao.dart`)
   - Связи между заметками и тегами
   - Поиск заметок по тегам

3. **TotpTagsDao** (`totp_tags_dao.dart`)
   - Связи между TOTP и тегами
   - Поиск TOTP по тегам

## Ключевые особенности

### Общие методы для всех DAO

- **CRUD операции**: Create, Read, Update, Delete
- **Поиск и фильтрация**: Полнотекстовый поиск, фильтры
- **Stream наблюдения**: Реактивные запросы для UI
- **Batch операции**: Массовые операции для производительности
- **Подсчет и статистика**: Аналитические запросы

### Продвинутые возможности

#### Для связей тегов (password_tags, note_tags, totp_tags):
- Поиск по множественным тегам (AND/OR логика)
- Замена всех тегов объекта
- Подсчет использования тегов
- Очистка потерянных связей

#### Для вложений:
- Проверка целостности файлов
- Анализ размеров и типов файлов
- Обнаружение проблем с файлами

#### Для иконок:
- Анализ использования в категориях
- Управление размерами файлов
- Автоматическая очистка

## Использование DAO

### Базовый пример

```dart
// Получение DAO через базу данных
final passwordsDao = PasswordsDao(database);

// Создание пароля
final passwordId = await passwordsDao.createPassword(CreatePasswordDto(
  name: 'Gmail',
  password: 'encrypted_password',
  login: 'user@gmail.com',
  url: 'https://gmail.com',
));

// Поиск паролей
final passwords = await passwordsDao.searchPasswords('gmail');

// Наблюдение за изменениями
passwordsDao.watchAllPasswords().listen((passwords) {
  // Обновление UI
});
```

### Работа с тегами

```dart
final passwordTagsDao = PasswordTagsDao(database);

// Добавление тегов к паролю
await passwordTagsDao.addTagToPassword(passwordId, tagId);

// Поиск паролей по тегам (AND логика)
final passwords = await passwordTagsDao.getPasswordsByTags(['work', 'important']);

// Замена всех тегов
await passwordTagsDao.replacePasswordTags(passwordId, ['personal', 'email']);
```

### Batch операции

```dart
// Создание множественных паролей
await passwordsDao.createPasswordsBatch([
  CreatePasswordDto(name: 'Password 1', password: 'pass1'),
  CreatePasswordDto(name: 'Password 2', password: 'pass2'),
]);
```

## Генерация кода

Все DAO используют code generation от Drift. После изменения DAO файлов необходимо запустить:

```bash
dart run build_runner build
```

## Архитектурные принципы

1. **Разделение ответственности**: Каждый DAO отвечает за свою сущность
2. **Реактивность**: Все DAO поддерживают Stream для наблюдения
3. **Производительность**: Batch операции для массовых изменений
4. **Целостность**: Автоматическая очистка потерянных связей
5. **Расширяемость**: Легко добавлять новые методы

## Обработка ошибок

Все DAO методы могут бросать исключения:
- `SqliteException` - ошибки базы данных
- `StateError` - нарушение ограничений
- `ArgumentError` - неверные параметры

Рекомендуется оборачивать вызовы DAO в try-catch блоки.

## Транзакции

Для сложных операций используйте транзакции:

```dart
await database.transaction(() async {
  await passwordsDao.createPassword(dto);
  await passwordTagsDao.addTagToPassword(passwordId, tagId);
});
```

## Тестирование

Все DAO можно тестировать с in-memory базой данных:

```dart
final database = HoplixiStore(NativeDatabase.memory());
final dao = PasswordsDao(database);
// Тесты...
```
