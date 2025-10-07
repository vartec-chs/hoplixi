# BoxDB - Краткое руководство

## Что это?

BoxDB - безопасная локальная база данных на Dart с автоматическим шифрованием, интеграцией с Freezed и поддержкой JSONL формата.

## Быстрый старт (3 шага)

### 1. Создайте модель с Freezed

```dart
@freezed
class User with _$User {
  const User._();
  
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Создайте БД

```dart
final db = await BoxDB.create<User>(
  name: 'users',
  basePath: 'data',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);
```

### 3. Используйте CRUD

```dart
// Create
await db.insert(User(id: '1', name: 'Alice', email: 'alice@mail.com', age: 25));

// Read
final user = await db.get('1');

// Update
await db.update(user!.copyWith(age: 26));

// Delete
await db.delete('1');
```

## Ключевые возможности

| Функция | Описание |
|---------|----------|
| 🔐 **Шифрование** | AES-GCM 256-bit, расшифровка только при чтении |
| 💾 **Эффективность** | JSONL формат, не загружает всё в память |
| ⚡ **Скорость** | O(1) для insert/get/update/delete |
| 🔒 **Безопасность** | ID в plaintext, данные зашифрованы |
| ♻️ **Backup** | Автоматический backup при открытии |
| 🗜️ **Компактификация** | Автоматическая очистка при >30% мусора |
| 🔄 **Синхронизация** | Thread-safe операции с Lock |

## Структура БД

```
my_database/
├── data.jsonl       # Зашифрованные записи (append-only)
├── index.json       # {id: {line: N, deleted: bool}}
├── meta.json        # Метаданные + ключ шифрования
└── backup/          # Автоматические копии
    └── {timestamp}/
```

## Примеры

### С паролем

```dart
final db = await BoxDB.create<User>(
  name: 'secure_db',
  basePath: 'data',
  password: 'my_password',  // SHA256 → AES key
  // ...
);
```

### Без пароля (генерируемый ключ)

```dart
final db = await BoxDB.create<User>(
  name: 'auto_db',
  basePath: 'data',
  // password не указан → генерируется случайный ключ
  // Ключ сохраняется в meta.json
  // ...
);
```

### Открытие существующей БД

```dart
final db = await BoxDB.open<User>(
  name: 'my_db',
  basePath: 'data',
  password: 'my_password',  // Должен совпадать
  // ...
);
// При открытии автоматически создаётся backup
```

### Массовые операции

```dart
// Параллельная вставка
await Future.wait([
  db.insert(user1),
  db.insert(user2),
  db.insert(user3),
]);

// Получить все
final all = await db.getAll();
```

### Maintenance

```dart
// Backup вручную
await db.backup();

// Компактификация вручную
await db.compact();

// Статистика
final count = await db.count();
final exists = await db.exists('user_123');
```

## API Cheatsheet

| Метод | Возвращает | Описание |
|-------|-----------|----------|
| `create<T>()` | `Future<BoxDB<T>>` | Создать новую БД |
| `open<T>()` | `Future<BoxDB<T>>` | Открыть существующую |
| `insert(item)` | `Future<void>` | Вставить запись |
| `get(id)` | `Future<T?>` | Получить по ID |
| `update(item)` | `Future<void>` | Обновить запись |
| `delete(id)` | `Future<void>` | Удалить запись |
| `getAll()` | `Future<List<T>>` | Все записи |
| `exists(id)` | `Future<bool>` | Проверка существования |
| `count()` | `Future<int>` | Количество записей |
| `clear()` | `Future<void>` | Удалить все |
| `compact()` | `Future<void>` | Компактификация |
| `backup()` | `Future<void>` | Создать backup |
| `close()` | `Future<void>` | Закрыть БД |

## Обработка ошибок

```dart
try {
  await db.insert(user);
} on BoxDBException catch (e) {
  if (e.message.contains('уже существует')) {
    // Дубликат
  }
} on EncryptionException catch (e) {
  // Неверный пароль
}
```

## Best Practices

✅ **DO:**
- Всегда закрывать БД после использования
- Использовать сильные пароли (12+ символов)
- Создавать backup перед критическими операциями
- Использовать `exists()` перед `update()`

❌ **DON'T:**
- Не использовать `getAll()` для огромных БД
- Не терять пароль (данные невосстановимы)
- Не редактировать файлы БД вручную
- Не забывать вызывать `close()`

## Производительность

**Бенчмарки (средние значения):**
- Insert: ~1-2ms
- Get: ~0.5-1ms  
- Update: ~1-2ms
- Delete: ~0.1ms
- GetAll (1000 записей): ~100-200ms

**Память:**
- Индекс: ~100 bytes/запись
- Данные: на диске, не в RAM

## Тестирование

```bash
# Запустить все тесты
dart test

# Запустить пример
dart run bin/test_box_db.dart
```

✅ **24 теста** включены в проект.

## Безопасность

**Что шифруется:**
- ✅ Все поля данных
- ✅ Вложенные объекты
- ✅ Массивы

**Что НЕ шифруется:**
- ❌ ID (нужен для индекса)

**Формат зашифрованной записи:**
```json
{
  "id": "user_123",
  "data": {
    "ciphertext": "...",
    "nonce": "...",
    "mac": "..."
  }
}
```

## Поддержка

- 📚 Документация: `docs/API.md`
- 💡 Примеры: `example/example.dart`
- 🧪 Тесты: `test/box_db_test.dart`
- 🚀 Демо: `bin/test_box_db.dart`

## Лицензия

MIT
