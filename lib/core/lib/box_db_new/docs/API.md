# BoxDB API Documentation

## Table of Contents

- [Core Concepts](#core-concepts)
- [Database Operations](#database-operations)
- [CRUD Operations](#crud-operations)
- [Security](#security)
- [Performance](#performance)
- [Error Handling](#error-handling)

## Core Concepts

### Architecture

BoxDB использует append-only подход с индексацией для эффективного хранения:

```
database_name/
├── data.jsonl       # Append-only файл с зашифрованными данными
├── index.json       # Индекс: {id: {line: number, deleted: bool}}
├── meta.json        # Метаданные БД (ключ шифрования, версия, и т.д.)
└── backup/          # Автоматические резервные копии
    ├── 1234567890/  # Timestamp-based backups
    └── 1234567891/
```

### Data Flow

**Запись (Insert/Update):**
1. Сериализация объекта в JSON
2. Шифрование JSON данных (кроме ID)
3. Append в data.jsonl
4. Обновление индекса

**Чтение (Get):**
1. Поиск позиции в индексе
2. Чтение строки из data.jsonl
3. Расшифровка данных
4. Десериализация в объект

## Database Operations

### BoxDB.create<T>()

Создаёт новую базу данных.

**Signature:**
```dart
static Future<BoxDB<T>> create<T>({
  required String name,
  required String basePath,
  String? password,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String Function(T) getId,
})
```

**Parameters:**
- `name` - Имя базы данных (создаётся директория с этим именем)
- `basePath` - Базовый путь для размещения БД
- `password` - Опциональный пароль для шифрования. Если null, генерируется случайный ключ
- `fromJson` - Функция десериализации JSON → Object
- `toJson` - Функция сериализации Object → JSON
- `getId` - Функция извлечения ID из объекта

**Returns:** `Future<BoxDB<T>>`

**Example:**
```dart
final db = await BoxDB.create<User>(
  name: 'users_db',
  basePath: 'data',
  password: 'secure_password_123',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);
```

**Throws:**
- `BoxDBException` если БД уже существует или не удалось создать

---

### BoxDB.open<T>()

Открывает существующую базу данных.

**Signature:**
```dart
static Future<BoxDB<T>> open<T>({
  required String name,
  required String basePath,
  String? password,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String Function(T) getId,
})
```

**Behavior:**
1. Автоматически создаёт backup перед открытием
2. Проверяет целостность файлов
3. При ошибке пытается восстановиться из backup

**Example:**
```dart
final db = await BoxDB.open<User>(
  name: 'users_db',
  basePath: 'data',
  password: 'secure_password_123', // Должен совпадать с паролем при create
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);
```

**Throws:**
- `BoxDBException` если БД не найдена или не удалось восстановить

---

### close()

Закрывает БД, сохраняя индекс.

**Signature:**
```dart
Future<void> close()
```

**Example:**
```dart
await db.close();
```

**Note:** После вызова close() любые операции с БД вызовут `BoxDBException`.

---

## CRUD Operations

### insert()

Вставляет новую запись в БД.

**Signature:**
```dart
Future<void> insert(T item)
```

**Behavior:**
1. Проверяет уникальность ID
2. Сериализует объект
3. Шифрует данные
4. Добавляет в файл
5. Обновляет индекс

**Example:**
```dart
await db.insert(User(
  id: 'user_123',
  name: 'Alice',
  email: 'alice@example.com',
  age: 25,
));
```

**Throws:**
- `BoxDBException` если запись с таким ID уже существует
- `BoxDBException` если БД закрыта

**Performance:** O(1) - append-only операция

---

### get()

Получает запись по ID.

**Signature:**
```dart
Future<T?> get(String id)
```

**Returns:** Объект типа T или null если не найден

**Example:**
```dart
final user = await db.get('user_123');
if (user != null) {
  print('Found: ${user.name}');
}
```

**Performance:** O(1) - прямой доступ по индексу

**Security:** Данные расшифровываются только при вызове этого метода

---

### update()

Обновляет существующую запись.

**Signature:**
```dart
Future<void> update(T item)
```

**Behavior:**
1. Проверяет существование записи
2. Добавляет обновлённую версию в конец файла
3. Обновляет индекс на новую позицию
4. Старая версия остаётся в файле до компактификации

**Example:**
```dart
final user = await db.get('user_123');
if (user != null) {
  await db.update(user.copyWith(age: 26));
}
```

**Throws:**
- `BoxDBException` если запись не найдена
- `BoxDBException` если БД закрыта

**Note:** Может автоматически вызвать компактификацию при накоплении > 30% удалённых записей

---

### delete()

Удаляет запись (помечает как удалённую в индексе).

**Signature:**
```dart
Future<void> delete(String id)
```

**Behavior:**
1. Помечает запись как deleted в индексе
2. Физическое удаление происходит при компактификации

**Example:**
```dart
await db.delete('user_123');
```

**Throws:**
- `BoxDBException` если запись не найдена
- `BoxDBException` если БД закрыта

---

### getAll()

Получает все активные записи.

**Signature:**
```dart
Future<List<T>> getAll()
```

**Returns:** Список всех не удалённых записей

**Example:**
```dart
final allUsers = await db.getAll();
print('Total users: ${allUsers.length}');
for (final user in allUsers) {
  print('- ${user.name}');
}
```

**Performance:** O(n) где n - количество записей

**Note:** Расшифровывает все записи - может быть медленно для больших БД

---

### exists()

Проверяет существование записи.

**Signature:**
```dart
Future<bool> exists(String id)
```

**Example:**
```dart
if (await db.exists('user_123')) {
  await db.delete('user_123');
}
```

**Performance:** O(1) - проверка индекса

---

### count()

Возвращает количество активных записей.

**Signature:**
```dart
Future<int> count()
```

**Example:**
```dart
final total = await db.count();
print('Database has $total records');
```

**Performance:** O(1) - подсчёт в индексе

---

### clear()

Удаляет все записи из БД.

**Signature:**
```dart
Future<void> clear()
```

**Behavior:**
1. Очищает индекс
2. Пересоздаёт data.jsonl файл

**Example:**
```dart
await db.clear();
```

---

## Time-Based Query Operations

BoxDB автоматически отслеживает время создания и обновления каждой записи. Это позволяет выполнять запросы на основе временных меток.

### getRecent()

Получает последние записи, отсортированные по времени (от новых к старым).

**Signature:**
```dart
Future<List<T>> getRecent({int limit = 10, DateTime? since})
```

**Parameters:**
- `limit` - Максимальное количество записей (по умолчанию 10)
- `since` - Опциональный фильтр: вернуть только записи после указанного времени

**Returns:** Список последних записей

**Example:**
```dart
// Получить 5 последних записей
final recent5 = await db.getRecent(limit: 5);

// Получить записи за последние 24 часа
final yesterday = DateTime.now().subtract(Duration(days: 1));
final recentDay = await db.getRecent(since: yesterday);

// Получить все последние записи с момента последней проверки
final checkpoint = lastCheckTime;
final newRecords = await db.getRecent(since: checkpoint);
```

**Performance:** O(n log n) где n - количество записей (из-за сортировки)

**Use Cases:**
- Отображение последней активности
- Синхронизация изменений
- Логирование действий пользователя
- Feed/Timeline функциональность

---

### getByTimeRange()

Получает записи в указанном временном диапазоне.

**Signature:**
```dart
Future<List<T>> getByTimeRange({
  required DateTime from,
  DateTime? to,
})
```

**Parameters:**
- `from` - Начало временного диапазона
- `to` - Конец временного диапазона (по умолчанию текущее время)

**Returns:** Список записей в указанном диапазоне

**Example:**
```dart
// Записи за прошлую неделю
final weekAgo = DateTime.now().subtract(Duration(days: 7));
final lastWeek = await db.getByTimeRange(from: weekAgo);

// Записи за конкретный период
final start = DateTime(2025, 1, 1);
final end = DateTime(2025, 1, 31);
final january = await db.getByTimeRange(from: start, to: end);

// Записи с начала месяца
final monthStart = DateTime(
  DateTime.now().year,
  DateTime.now().month,
  1,
);
final thisMonth = await db.getByTimeRange(from: monthStart);
```

**Performance:** O(n) где n - количество записей

**Use Cases:**
- Отчёты за период
- Анализ активности
- Экспорт данных за временной промежуток
- Статистика по времени

---

### getAllSortedByTime()

Получает все записи, отсортированные по времени.

**Signature:**
```dart
Future<List<T>> getAllSortedByTime({bool ascending = false})
```

**Parameters:**
- `ascending` - Порядок сортировки:
  - `false` (по умолчанию): от новых к старым
  - `true`: от старых к новым

**Returns:** Список всех записей, отсортированный по времени

**Example:**
```dart
// От новых к старым (по умолчанию)
final newestFirst = await db.getAllSortedByTime();

// От старых к новым
final oldestFirst = await db.getAllSortedByTime(ascending: true);

// Показать хронологию
for (final item in oldestFirst) {
  final timestamp = await db.getTimestamp(item.id);
  print('${timestamp}: ${item.name}');
}
```

**Performance:** O(n log n) где n - количество записей

**Note:** Расшифровывает все записи - может быть медленно для больших БД

**Use Cases:**
- Полная хронология событий
- Экспорт в хронологическом порядке
- Анализ временной последовательности
- Отладка и аудит

---

### getTimestamp()

Получает временную метку создания или последнего обновления записи.

**Signature:**
```dart
Future<DateTime?> getTimestamp(String id)
```

**Parameters:**
- `id` - ID записи

**Returns:** 
- `DateTime` если запись существует
- `null` если запись не найдена

**Example:**
```dart
// Получить время создания/обновления
final timestamp = await db.getTimestamp('user_123');
if (timestamp != null) {
  print('Last modified: $timestamp');
  
  // Проверить, изменялась ли запись недавно
  final hourAgo = DateTime.now().subtract(Duration(hours: 1));
  if (timestamp.isAfter(hourAgo)) {
    print('Recently modified!');
  }
}

// Сравнить время создания двух записей
final time1 = await db.getTimestamp('record1');
final time2 = await db.getTimestamp('record2');
if (time1 != null && time2 != null) {
  if (time1.isAfter(time2)) {
    print('record1 is newer');
  }
}
```

**Performance:** O(1) - прямой доступ к индексу

**Note:** 
- Время обновляется при `insert()` и `update()`
- После `update()` возвращается время последнего обновления

**Use Cases:**
- Определение свежести данных
- Кеш-валидация
- Синхронизация
- Аудит изменений

---

### Timestamp Behavior

**Automatic Tracking:**
- ✅ Время записывается автоматически при `insert()`
- ✅ Время обновляется автоматически при `update()`
- ✅ Временные метки сохраняются при компактификации
- ✅ Временные метки сохраняются в индексе

**Backward Compatibility:**
- Существующие БД без временных меток получают `DateTime.now()` при загрузке
- Новые записи всегда имеют точные временные метки

**Example - Update Behavior:**
```dart
// Создать запись
await db.insert(user);
final created = await db.getTimestamp(user.id); // Время создания

await Future.delayed(Duration(seconds: 5));

// Обновить запись
await db.update(user.copyWith(age: 26));
final updated = await db.getTimestamp(user.id); // Время обновления

print(updated!.isAfter(created!)); // true
print(updated.difference(created).inSeconds); // ~5 секунд
```

**Time Precision:**
- Использует системное время через `DateTime.now()`
- Точность зависит от платформы (обычно микросекунды)
- Сохраняется как миллисекунды с эпохи Unix

---

## Maintenance Operations

### compact()

Компактифицирует БД, физически удаляя помеченные записи.

**Signature:**
```dart
Future<void> compact()
```

**Behavior:**
1. Создаёт новый временный файл
2. Копирует только активные записи
3. Обновляет индекс
4. Заменяет старый файл новым

**Example:**
```dart
// Вручную запустить компактификацию
await db.compact();
```

**Automatic:** Вызывается автоматически при:
- > 30% удалённых записей после delete()
- > 30% устаревших версий после update()

**Performance:** O(n) где n - количество активных записей

---

### backup()

Создаёт резервную копию БД.

**Signature:**
```dart
Future<void> backup()
```

**Behavior:**
1. Создаёт timestamp-based директорию в backup/
2. Копирует data.jsonl, index.json, meta.json
3. Сохраняет только последние 5 backup'ов

**Example:**
```dart
// Создать backup перед критической операцией
await db.backup();
```

**Automatic:** Создаётся автоматически при вызове `open()`

---

## Security

### Encryption Service

BoxDB использует **AES-GCM** с 256-битным ключом.

**Encrypted Data Format:**
```json
{
  "id": "plain_text_id",
  "data": {
    "ciphertext": "base64_encrypted_data",
    "nonce": "base64_unique_nonce",
    "mac": "base64_message_auth_code"
  }
}
```

### Password-based Encryption

```dart
final db = await BoxDB.create<User>(
  password: 'my_secure_password',
  // Ключ генерируется: SHA256(password)
  // ...
);
```

**Security Notes:**
- Используйте сильный пароль (минимум 12 символов)
- Пароль не сохраняется нигде
- При потере пароля данные невосстановимы

### Generated Key Encryption

```dart
final db = await BoxDB.create<User>(
  // password не указан
  // Генерируется случайный 256-bit ключ
  // Ключ сохраняется в meta.json в base64
  // ...
);
```

**Security Notes:**
- Безопаснее, чем password-based (истинная энтропия)
- meta.json должен быть защищён на уровне ОС
- При потере meta.json данные невосстановимы

### What is Encrypted

✅ **Encrypted:**
- Все поля модели данных
- Вложенные объекты
- Списки и массивы

❌ **Not Encrypted:**
- ID записи (нужен для индексации)

### Security Best Practices

1. **Использование паролей:**
   ```dart
   // ✅ Хорошо
   password: generateSecurePassword(16)
   
   // ❌ Плохо
   password: '123456'
   ```

2. **Защита meta.json:**
   ```dart
   // Установить права доступа только для владельца
   // Unix: chmod 600 databases/my_db/meta.json
   ```

3. **Резервное копирование:**
   ```dart
   // Регулярные backup'ы
   await db.backup();
   
   // Сохранить backup в безопасное место
   ```

---

## Performance

### Benchmarks

Операция | Время | Сложность
---------|-------|----------
insert() | ~1-2ms | O(1)
get() | ~0.5-1ms | O(1)
update() | ~1-2ms | O(1)
delete() | ~0.1ms | O(1)
getAll() (1000 записей) | ~100-200ms | O(n)
compact() (1000 записей) | ~50-100ms | O(n)

### Memory Usage

- **Индекс:** ~100 bytes на запись
- **Данные:** Хранятся на диске, не в памяти
- **Чтение:** Загружается только запрошенная запись

**Example:**
```
1,000 записей:
- Индекс в памяти: ~100 KB
- Данные на диске: ~500 KB (зависит от размера объектов)
```

### Optimization Tips

1. **Batch Operations:**
   ```dart
   // ✅ Параллельные вставки
   await Future.wait(users.map((u) => db.insert(u)));
   
   // ❌ Последовательные
   for (final u in users) {
     await db.insert(u);
   }
   ```

2. **Избегать getAll() для больших БД:**
   ```dart
   // ❌ Плохо для больших БД
   final all = await db.getAll();
   
   // ✅ Лучше
   final user = await db.get(knownId);
   ```

3. **Регулярная компактификация:**
   ```dart
   // После множества delete/update
   if (deletedRatio > 0.3) {
     await db.compact();
   }
   ```

---

## Error Handling

### Exceptions

#### BoxDBException

Базовое исключение для всех ошибок БД.

**Common Cases:**
```dart
try {
  await db.insert(user);
} on BoxDBException catch (e) {
  if (e.message.contains('уже существует')) {
    // Дубликат ID
  } else if (e.message.contains('не найдена')) {
    // Запись не найдена
  } else if (e.message.contains('не открыта')) {
    // БД закрыта
  }
}
```

#### EncryptionException

Ошибки шифрования/расшифровки.

**Common Cases:**
```dart
try {
  final db = await BoxDB.open<User>(
    password: 'wrong_password',
    // ...
  );
} on EncryptionException catch (e) {
  // Неверный пароль или повреждённые данные
  print('Encryption error: ${e.message}');
}
```

### Automatic Recovery

При открытии БД происходит автоматическая проверка целостности:

```dart
try {
  final db = await BoxDB.open<User>(...);
} catch (e) {
  // BoxDB автоматически попытается:
  // 1. Восстановиться из последнего backup
  // 2. Если backup'а нет - выбросит исключение
}
```

### Best Practices

```dart
// 1. Всегда закрывать БД
try {
  final db = await BoxDB.open<User>(...);
  // работа с БД
} finally {
  await db.close();
}

// 2. Обработка критических операций
try {
  await db.backup(); // backup перед критической операцией
  await criticalOperation();
} catch (e) {
  // Восстановление из backup если что-то пошло не так
  await db.close();
  final db = await BoxDB.open<User>(...); // Восстановится из backup
}

// 3. Проверка существования
if (await db.exists(id)) {
  await db.update(item);
} else {
  await db.insert(item);
}
```

---

## Advanced Topics

### Custom Models

Любой класс с Freezed может использоваться с BoxDB:

```dart
@freezed
class Product with _$Product {
  const Product._();
  
  const factory Product({
    required String id,
    required String name,
    required double price,
    required List<String> tags,
    Map<String, dynamic>? metadata,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => 
      _$ProductFromJson(json);
}

final db = await BoxDB.create<Product>(
  name: 'products',
  basePath: 'data',
  fromJson: Product.fromJson,
  toJson: (p) => p.toJson(),
  getId: (p) => p.id,
);
```

### Multiple Databases

```dart
final usersDb = await BoxDB.open<User>(
  name: 'users',
  basePath: 'data',
  // ...
);

final productsDb = await BoxDB.open<Product>(
  name: 'products',
  basePath: 'data',
  // ...
);

// Независимые БД, можно использовать параллельно
await Future.wait([
  usersDb.insert(user),
  productsDb.insert(product),
]);
```

### Thread Safety

Все операции записи синхронизированы:

```dart
// Безопасно выполнять параллельно из разных изоляторов
await Future.wait([
  db.insert(user1),
  db.insert(user2),
  db.update(user3),
  db.delete('user4'),
]);
```

**Note:** Каждая операция получает эксклюзивный lock на время выполнения.
