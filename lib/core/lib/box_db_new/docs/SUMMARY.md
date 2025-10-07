# Резюме проекта BoxDB

## Обзор

BoxDB — это легковесная зашифрованная база данных на Dart с JSON-хранилищем, синхронизированными операциями и поддержкой резервного копирования.

## Основные возможности

### 1. Базовый функционал
- ✅ Создание и открытие БД через `BoxDB.create()` и `BoxDB.open()`
- ✅ CRUD операции: `insert()`, `get()`, `update()`, `delete()`
- ✅ Пакетные операции: `getAll()`, `clear()`, `count()`, `exists()`
- ✅ Поддержка Freezed моделей с JSON сериализацией
- ✅ Append-only архитектура с индексацией

### 2. Безопасность
- ✅ Шифрование AES-GCM 256-bit
- ✅ Поддержка паролей или генерируемых ключей
- ✅ Селективная расшифровка (только при чтении)
- ✅ ID остаются незашифрованными для индексации

### 3. Надёжность
- ✅ Автоматические резервные копии при открытии
- ✅ Ручное создание backup через `backup()`
- ✅ Автоматическое восстановление из backup при ошибках
- ✅ Компактификация данных: `compact()` (вручную или автоматически)
- ✅ Сохранение последних 5 backup'ов

### 4. Управление несколькими БД (BoxManager)
- ✅ Класс `BoxManager` для управления множеством боксов
- ✅ Методы `createBox()`, `openBox()`, `closeBox()`, `closeAll()`
- ✅ Интеграция с `SecureStorage` для хранения ключей шифрования
- ✅ Заглушка `MemorySecureStorage` для тестирования
- ✅ Методы `listBoxes()`, `deleteBox()` для управления

### 5. Экспорт и Импорт
- ✅ Экспорт бокса в зашифрованный архив `.boxz` через `exportBox()`
- ✅ Импорт бокса из архива через `importBox()`
- ✅ Шифрование архива ключом бокса
- ✅ Полное удаление бокса через `deleteBox()`
- ✅ Использование библиотеки `archive` для сжатия

### 6. Запросы по времени (NEW!)
- ✅ Автоматическое отслеживание времени создания/обновления записей
- ✅ `getRecent(limit, since)` - получить последние N записей
- ✅ `getByTimeRange(from, to)` - записи в временном диапазоне
- ✅ `getAllSortedByTime(ascending)` - все записи, отсортированные по времени
- ✅ `getTimestamp(id)` - получить временную метку записи
- ✅ Обратная совместимость со старыми индексами

## Архитектура

```
BoxDB<T>
  ├── EncryptionService (AES-GCM шифрование)
  ├── StorageManager (работа с файлами)
  └── IndexManager (индексация с временными метками)

BoxManager
  ├── Управление несколькими BoxDB
  ├── SecureStorage (хранение ключей)
  └── Export/Import функциональность

Структура на диске:
database_name/
  ├── data.jsonl       # Зашифрованные данные
  ├── index.json       # Индекс: {id: {line, deleted, timestamp}}
  ├── meta.json        # Метаданные (ключ, версия)
  └── backup/          # Резервные копии
      ├── 1234567890/
      └── 1234567891/
```

## Формат индекса (обновлён)

```json
{
  "user_1": {
    "line": 0,
    "deleted": false,
    "timestamp": 1696684800000
  },
  "user_2": {
    "line": 1,
    "deleted": false,
    "timestamp": 1696684805000
  }
}
```

**Поля:**
- `line` - номер строки в data.jsonl (начиная с 0)
- `deleted` - флаг удаления (true/false)
- `timestamp` - время создания/обновления в миллисекундах (Unix epoch)

## Производительность

Операция | Время | Сложность
---------|-------|----------
insert() | ~1-2ms | O(1)
get() | ~0.5-1ms | O(1)
update() | ~1-2ms | O(1)
delete() | ~0.1ms | O(1)
getAll() (1000) | ~100-200ms | O(n)
getRecent() | ~50-100ms | O(n log n)
getByTimeRange() | ~50-100ms | O(n)
compact() (1000) | ~50-100ms | O(n)

## Тестирование

- **Всего тестов:** 68
  - `test/box_db_test.dart`: 25 тестов (базовый функционал)
  - `test/box_manager_test.dart`: 17 тестов (управление боксами)
  - `test/box_export_import_test.dart`: 14 тестов (экспорт/импорт)
  - `test/box_recent_test.dart`: 12 тестов (запросы по времени)

- **Покрытие:**
  - ✅ CRUD операции
  - ✅ Шифрование/расшифровка
  - ✅ Backup и восстановление
  - ✅ Компактификация
  - ✅ Управление несколькими БД
  - ✅ Экспорт/импорт
  - ✅ Временные запросы
  - ✅ Обработка ошибок

## Примеры использования

### Базовое использование

```dart
// Создать БД
final db = await BoxDB.create<User>(
  name: 'users',
  basePath: 'data',
  password: 'my_password',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// CRUD
await db.insert(User(id: '1', name: 'Alice', ...));
final user = await db.get('1');
await db.update(user!.copyWith(age: 26));
await db.delete('1');

await db.close();
```

### Управление несколькими БД

```dart
final manager = BoxManager(
  basePath: 'databases',
  secureStorage: FlutterSecureStorage(),
);

// Создать боксы
await manager.createBox<User>(
  name: 'users',
  password: 'pass1',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

await manager.createBox<Product>(
  name: 'products',
  fromJson: Product.fromJson,
  toJson: (p) => p.toJson(),
  getId: (p) => p.id,
);

// Работать с боксами
final usersBox = manager.getBox<User>('users');
await usersBox?.insert(user);

// Закрыть все
await manager.closeAll();
```

### Экспорт и Импорт

```dart
// Экспорт
final result = await manager.exportBox('users');
print('Архив создан: ${result.archivePath}');
print('Ключ: ${result.encryptionKey}');

// Импорт
await manager.importBox(
  archivePath: result.archivePath,
  encryptionKey: result.encryptionKey,
);

// Полное удаление
await manager.deleteBox('users');
```

### Запросы по времени

```dart
// Последние 10 записей
final recent = await db.getRecent(limit: 10);

// Записи за последние 24 часа
final yesterday = DateTime.now().subtract(Duration(days: 1));
final recentDay = await db.getRecent(since: yesterday);

// Записи за период
final lastWeek = await db.getByTimeRange(
  from: DateTime.now().subtract(Duration(days: 7)),
);

// Все записи по времени
final sorted = await db.getAllSortedByTime(ascending: true);

// Время записи
final timestamp = await db.getTimestamp('user_1');
print('Created/Updated: $timestamp');
```

## Зависимости

```yaml
dependencies:
  path: ^1.9.1
  synchronized: ^3.4.0
  cryptography: ^2.7.0
  crypto: ^3.0.6
  archive: ^4.0.7

dev_dependencies:
  freezed: ^3.2.3
  json_annotation: ^4.9.0
  build_runner: ^2.4.15
  freezed_annotation: ^2.4.6
  json_serializable: ^6.9.4
  test: ^1.25.13
```

## Документация

- **README.md** - Быстрый старт и обзор
- **docs/API.md** - Полная документация API
- **docs/ARCHITECTURE.md** - Архитектура и детали реализации
- **docs/EXAMPLES.md** - Примеры использования
- **example/** - Рабочие примеры кода

## Use Cases

1. **Локальное хранилище пользовательских данных**
   - Оффлайн-first приложения
   - Кеширование
   - Настройки пользователя

2. **Защищённое хранение**
   - Конфиденциальные данные
   - Медицинские записи
   - Финансовая информация

3. **Логирование и аудит**
   - История действий пользователя
   - Отслеживание изменений
   - Временные метки событий

4. **Синхронизация**
   - Определение изменений с момента последней синхронизации
   - Экспорт/импорт данных между устройствами
   - Резервное копирование

5. **Аналитика**
   - Отчёты за период
   - Статистика по времени
   - Анализ активности

## Roadmap (будущие улучшения)

- [ ] Индексы по полям (для быстрого поиска)
- [ ] Поддержка запросов WHERE
- [ ] Транзакции
- [ ] Репликация между устройствами
- [ ] Инкрементальный экспорт (только изменения)
- [ ] Web поддержка (IndexedDB backend)
- [ ] Сжатие данных перед шифрованием

## Лицензия

MIT License

## Версия

Текущая версия: 0.1.0+1
Dart SDK: ^3.9.2
