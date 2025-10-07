# Архитектура BoxDB

## Обзор

BoxDB - это встраиваемая база данных на Dart с фокусом на безопасность и производительность. Архитектура построена на принципах:

1. **Append-only storage** - все записи добавляются в конец файла
2. **Index-based access** - быстрый доступ через индекс в памяти
3. **Lazy decryption** - расшифровка только при чтении
4. **Immutable models** - использование Freezed для безопасности типов

## Компоненты системы

```
┌─────────────────────────────────────────────────────────┐
│                      BoxDB<T>                           │
│  (Главный интерфейс, управление жизненным циклом)       │
└────────────┬──────────────┬──────────────┬──────────────┘
             │              │              │
             ▼              ▼              ▼
    ┌────────────┐  ┌────────────┐  ┌────────────────┐
    │Encryption  │  │   Index    │  │    Storage     │
    │  Service   │  │  Manager   │  │    Manager     │
    └────────────┘  └────────────┘  └────────────────┘
         │               │                  │
         │               │                  │
         ▼               ▼                  ▼
    ┌────────────┐  ┌────────────┐  ┌────────────────┐
    │ AES-GCM    │  │Index (RAM) │  │  File System   │
    │Cryptography│  │{id→line}   │  │  (JSONL)       │
    └────────────┘  └────────────┘  └────────────────┘
```

## Детальное описание компонентов

### 1. BoxDB<T>

**Ответственность:**
- Координация всех операций
- Управление жизненным циклом БД
- Обеспечение потокобезопасности через Lock
- Валидация операций

**Ключевые методы:**
```dart
class BoxDB<T> {
  // Создание/открытие
  static Future<BoxDB<T>> create<T>(...);
  static Future<BoxDB<T>> open<T>(...);
  
  // CRUD
  Future<void> insert(T item);
  Future<T?> get(String id);
  Future<void> update(T item);
  Future<void> delete(String id);
  
  // Maintenance
  Future<void> compact();
  Future<void> backup();
  Future<void> close();
}
```

**State management:**
```dart
class BoxDB<T> {
  bool _isOpen = false;        // Статус БД
  final Lock _lock = Lock();   // Синхронизация записи
  
  // Зависимости
  final EncryptionService _encryption;
  final StorageManager _storage;
  final IndexManager _index;
  
  // Функции сериализации
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final String Function(T) _getId;
}
```

### 2. EncryptionService

**Ответственность:**
- Шифрование/расшифровка данных
- Управление ключами
- Генерация nonce для каждой операции

**Алгоритм:**
- **AES-GCM** (Galois/Counter Mode)
- **256-bit ключ**
- **Уникальный nonce** для каждой записи
- **MAC** для проверки целостности

**API:**
```dart
class EncryptionService {
  final SecretKey _key;
  final AesGcm _algorithm;
  
  // Создание из пароля (SHA-256)
  static Future<EncryptionService> fromPassword(String password);
  
  // Генерация нового ключа
  static Future<EncryptionService> generate();
  
  // Шифрование
  Future<EncryptedData> encrypt(String plaintext);
  
  // Расшифровка
  Future<String> decrypt(EncryptedData encrypted);
  
  // Экспорт ключа
  Future<String> exportKey();
}
```

**Формат EncryptedData:**
```dart
class EncryptedData {
  final String ciphertext;  // Base64 зашифрованные данные
  final String nonce;       // Base64 уникальный nonce
  final String mac;         // Base64 MAC для проверки
}
```

### 3. IndexManager

**Ответственность:**
- Управление индексом в памяти
- Быстрый поиск записей
- Отслеживание удалённых записей
- Определение необходимости компактификации

**Структура индекса:**
```dart
Map<String, IndexEntry> _index = {
  'user_1': IndexEntry(line: 0, deleted: false),
  'user_2': IndexEntry(line: 1, deleted: false),
  'user_3': IndexEntry(line: 2, deleted: true),  // Удалена
  'user_4': IndexEntry(line: 3, deleted: false),
};
```

**API:**
```dart
class IndexManager {
  Map<String, IndexEntry> _index;
  
  // CRUD на индексе
  void add(String id, int lineNumber);
  IndexEntry? get(String id);
  void update(String id, int newLineNumber);
  void markDeleted(String id);
  
  // Утилиты
  bool exists(String id);
  List<String> getAllIds();
  int get count;
  int get deletedCount;
  
  // Компактификация
  bool needsCompaction({double threshold = 0.3});
  
  // Персистентность
  Future<void> load();
  Future<void> save();
}
```

**Формат на диске (index.json):**
```json
{
  "user_1": {"line": 0, "deleted": false},
  "user_2": {"line": 1, "deleted": false},
  "user_3": {"line": 2, "deleted": true}
}
```

### 4. StorageManager

**Ответственность:**
- Работа с файловой системой
- Чтение/запись JSONL файла
- Управление backup'ами
- Компактификация файлов

**Файловая структура:**
```
database_name/
├── data.jsonl       # Основные данные
├── index.json       # Индекс
├── meta.json        # Метаданные
└── backup/
    ├── 1234567890/  # Timestamp
    │   ├── data.jsonl
    │   ├── index.json
    │   └── meta.json
    └── 1234567891/
```

**API:**
```dart
class StorageManager {
  final String dbPath;
  
  // Инициализация
  Future<void> initialize();
  
  // Работа с данными
  Future<int> appendData(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> readLine(int lineNumber);
  
  // Индекс и мета
  Future<Map<String, dynamic>> readIndex();
  Future<void> writeIndex(Map<String, dynamic> index);
  Future<Map<String, dynamic>> readMeta();
  Future<void> updateMeta(Map<String, dynamic> updates);
  
  // Backup
  Future<void> createBackup();
  Future<bool> restoreFromBackup();
  
  // Компактификация
  Future<void> compact(Map<String, dynamic> validIndex);
  
  // Проверка
  Future<bool> verifyIntegrity();
}
```

## Потоки данных

### Вставка записи (insert)

```
User object
    │
    ▼
toJson() → Map<String, dynamic>
    │
    ▼
jsonEncode() → String
    │
    ▼
EncryptionService.encrypt() → EncryptedData
    │
    ▼
{id: "plain", data: {ciphertext, nonce, mac}}
    │
    ▼
StorageManager.appendData() → line number
    │
    ▼
IndexManager.add(id, line)
    │
    ▼
IndexManager.save() → index.json
```

### Чтение записи (get)

```
String id
    │
    ▼
IndexManager.get(id) → IndexEntry{line, deleted}
    │
    ▼
StorageManager.readLine(line) → {id, data: {...}}
    │
    ▼
EncryptedData.fromJson(data)
    │
    ▼
EncryptionService.decrypt() → String (JSON)
    │
    ▼
jsonDecode() → Map<String, dynamic>
    │
    ▼
fromJson() → User object
```

### Обновление записи (update)

```
User object (modified)
    │
    ▼
[Same as insert: serialize + encrypt]
    │
    ▼
StorageManager.appendData() → new line number
    │
    ▼
IndexManager.update(id, newLine)
    │
    ▼
Check: needsCompaction()?
    │
    ├─ Yes → compact()
    │
    └─ No  → IndexManager.save()
```

### Компактификация (compact)

```
IndexManager.toMap() → {id: {line, deleted}}
    │
    ▼
Filter: deleted == false
    │
    ▼
For each valid entry:
    │
    ├─ StorageManager.readLine(oldLine)
    │
    ├─ Write to temp file
    │
    └─ Update index with newLine
    │
    ▼
Replace old data.jsonl with temp
    │
    ▼
IndexManager.save() → new index.json
```

## Синхронизация и потокобезопасность

### Lock Strategy

```dart
class BoxDB<T> {
  final Lock _lock = Lock();
  
  // Все операции ЗАПИСИ синхронизированы
  Future<void> insert(T item) async {
    return await _lock.synchronized(() async {
      // ... критическая секция
    });
  }
  
  // Операции ЧТЕНИЯ не блокируются (если нет записи)
  Future<T?> get(String id) async {
    // Прямой доступ к индексу и файлу
    // Безопасно благодаря append-only модели
  }
}
```

### Параллельные операции

**Безопасно:**
```dart
// Множественные вставки
await Future.wait([
  db.insert(user1),  // Lock
  db.insert(user2),  // Lock
  db.insert(user3),  // Lock
]);
// Выполняются последовательно благодаря Lock
```

**Также безопасно:**
```dart
// Смешанные операции
await Future.wait([
  db.get('1'),      // Без lock
  db.get('2'),      // Без lock
  db.insert(user),  // Lock
  db.update(user2), // Lock
]);
```

## Обработка ошибок и восстановление

### Стратегия backup

```
open() вызван
    │
    ▼
createBackup() → backup/{timestamp}/
    │
    ▼
verifyIntegrity()
    │
    ├─ OK → continue
    │
    └─ ERROR → restoreFromBackup()
               │
               ├─ Success → continue
               │
               └─ Failure → throw BoxDBException
```

### Политика backup'ов

- Создаётся при каждом `open()`
- Хранятся последние 5 backup'ов
- Старые удаляются автоматически

### Восстановление

```dart
try {
  final db = await BoxDB.open<User>(...);
} catch (e) {
  // Автоматическое восстановление уже произошло
  // Если не удалось - exception
}
```

## Оптимизация производительности

### Append-only модель

**Преимущества:**
- Быстрая запись (O(1))
- Нет блокировки чтения
- История изменений (до компактификации)

**Недостатки:**
- Рост размера файла
- Нужна периодическая компактификация

### Компактификация

**Автоматическая:**
```dart
if (deletedCount / totalCount > 0.3) {
  await compact();
}
```

**Ручная:**
```dart
await db.compact();
```

### Индекс в памяти

**Размер:**
- ~100 bytes на запись
- Для 10,000 записей: ~1 MB

**Преимущества:**
- O(1) доступ к любой записи
- Нет чтения всего файла

## Безопасность

### Defense in depth

1. **Шифрование на уровне записи**
   - Каждая запись шифруется отдельно
   - Уникальный nonce

2. **MAC для целостности**
   - Проверка при расшифровке
   - Защита от модификации

3. **ID в plaintext**
   - Позволяет индексацию
   - Минимальная утечка информации

### Threat model

**Защищает от:**
- ✅ Чтения файлов БД
- ✅ Модификации данных
- ✅ Подмены записей

**НЕ защищает от:**
- ❌ Доступ к процессу в памяти
- ❌ Компрометация ОС
- ❌ Физический доступ к ключам

## Масштабирование

### Ограничения

- **Размер индекса:** ограничен RAM
- **Размер файла:** ограничен FS
- **Конкуренция:** один процесс

### Рекомендации

**Хорошо для:**
- < 1M записей
- Однопользовательские приложения
- Embedded системы

**Не подходит для:**
- > 10M записей
- Высококонкурентные системы
- Распределённые системы

## Будущие улучшения

1. **Вторичные индексы**
   ```dart
   db.createIndex('email', (user) => user.email);
   final users = await db.findBy('email', 'alice@example.com');
   ```

2. **Транзакции**
   ```dart
   await db.transaction((tx) async {
     await tx.insert(user1);
     await tx.insert(user2);
     // Atomic commit
   });
   ```

3. **Streaming API**
   ```dart
   await for (final user in db.stream()) {
     print(user);
   }
   ```

4. **Сжатие**
   ```dart
   final db = await BoxDB.create<User>(
     compression: CompressionType.gzip,
     // ...
   );
   ```

## Заключение

BoxDB - это баланс между:
- **Простотой** использования
- **Безопасностью** данных
- **Производительностью** операций
- **Надёжностью** хранения

Подходит для встраиваемых систем, мобильных приложений и небольших серверных компонентов, где требуется локальное шифрованное хранилище с простым API.
