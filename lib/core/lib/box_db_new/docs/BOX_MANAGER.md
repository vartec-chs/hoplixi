# BoxManager - Управление несколькими базами данных

`BoxManager` - это класс для централизованного управления несколькими экземплярами `BoxDB`. Он обеспечивает удобный интерфейс для создания, открытия и закрытия баз данных, а также для управления ключами шифрования.

## Основные возможности

- 🔧 Создание и открытие нескольких баз данных
- 🔐 Интеграция с SecureStorage для безопасного хранения ключей
- 🗂️ Отслеживание открытых баз данных
- 🔄 Переиспользование уже открытых экземпляров
- 🛑 Удобное закрытие всех баз данных одной командой

## Быстрый старт

```dart
import 'package:test_box_db/test_box_db.dart';

void main() async {
  // Создать менеджер
  final manager = BoxManager(basePath: 'my_databases');

  // Создать базу данных
  final usersDb = await manager.createBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (user) => user.toJson(),
    getId: (user) => user.id,
  );

  // Работать с базой данных
  await usersDb.insert(User(
    id: '1',
    name: 'Алиса',
    email: 'alice@example.com',
    age: 28,
  ));

  // Закрыть все базы данных
  await manager.closeAll();
}
```

## API

### Конструктор

```dart
BoxManager({
  required String basePath,
  SecureStorage? secureStorage,
})
```

**Параметры:**
- `basePath` - базовый путь для всех баз данных
- `secureStorage` - хранилище ключей (по умолчанию `MemorySecureStorage`)

### Создание базы данных

```dart
Future<BoxDB<T>> createBox<T>({
  required String name,
  String? password,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String Function(T) getId,
})
```

Создаёт новую базу данных. Выбрасывает `BoxManagerException`, если база с таким именем уже существует.

**Параметры:**
- `name` - уникальное имя базы данных
- `password` - опциональный пароль для шифрования
- `fromJson` - функция десериализации
- `toJson` - функция сериализации
- `getId` - функция получения ID

**Пример:**

```dart
// Без пароля (авто-генерация ключа)
final db = await manager.createBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// С паролем
final secureDb = await manager.createBox<User>(
  name: 'secure_users',
  password: 'my_password',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);
```

### Открытие базы данных

```dart
Future<BoxDB<T>> openBox<T>({
  required String name,
  String? password,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String Function(T) getId,
})
```

Открывает существующую базу данных. Если база уже открыта, возвращает существующий экземпляр.

**Пример:**

```dart
final db = await manager.openBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);
```

### Получение базы данных

```dart
BoxDB<T>? getBox<T>(String name)
```

Возвращает открытую базу данных по имени или `null`, если база не открыта.

**Пример:**

```dart
final db = manager.getBox<User>('users');
if (db != null) {
  print('База данных найдена');
}
```

### Проверка состояния

```dart
bool isBoxOpen(String name)
```

Проверяет, открыта ли база данных с указанным именем.

```dart
int get openBoxCount
```

Возвращает количество открытых баз данных.

```dart
List<String> get openBoxNames
```

Возвращает список имён всех открытых баз данных.

**Пример:**

```dart
if (manager.isBoxOpen('users')) {
  print('База данных users открыта');
}

print('Открыто баз данных: ${manager.openBoxCount}');
print('Имена: ${manager.openBoxNames.join(", ")}');
```

### Закрытие базы данных

```dart
Future<void> closeBox(String name)
```

Закрывает конкретную базу данных.

```dart
Future<void> closeAll()
```

Закрывает все открытые базы данных.

**Пример:**

```dart
// Закрыть одну базу данных
await manager.closeBox('users');

// Закрыть все базы данных
await manager.closeAll();
```

### Управление ключами

```dart
Future<void> saveBoxKey(String boxName, String key)
```

Сохраняет ключ шифрования для базы данных.

```dart
Future<String?> loadBoxKey(String boxName)
```

Загружает ключ шифрования для базы данных.

```dart
Future<bool> hasBoxKey(String boxName)
```

Проверяет наличие ключа для базы данных.

```dart
Future<void> deleteBoxKey(String boxName)
```

Удаляет ключ базы данных.

```dart
Future<void> clearAllKeys()
```

Удаляет все ключи.

**Пример:**

```dart
// Сохранить ключ
await manager.saveBoxKey('users', 'secret_key');

// Проверить наличие
if (await manager.hasBoxKey('users')) {
  // Загрузить ключ
  final key = await manager.loadBoxKey('users');
  print('Ключ: $key');
}

// Удалить ключ
await manager.deleteBoxKey('users');

// Удалить все ключи
await manager.clearAllKeys();
```

### Экспорт и импорт

```dart
Future<BoxExportResult> exportBox(String name, {String? outputPath})
```

Экспортирует бокс в зашифрованный архив (.boxz).

**Возвращает:** `BoxExportResult` с путём к архиву, именем бокса и ключом шифрования.

**Параметры:**
- `name` - имя бокса для экспорта
- `outputPath` - путь для сохранения архива (опционально)

```dart
Future<void> importBox({
  required String boxName,
  required String encryptionKey,
  required String archivePath,
  bool overwrite = false,
})
```

Импортирует бокс из зашифрованного архива.

**Параметры:**
- `boxName` - имя для импортированного бокса
- `encryptionKey` - ключ шифрования архива
- `archivePath` - путь к архиву
- `overwrite` - перезаписать существующий бокс

**Пример:**

```dart
// Экспорт бокса
final result = await manager.exportBox('users');
print('Архив: ${result.archivePath}');
print('Ключ: ${result.encryptionKey}');

// Импорт под другим именем
await manager.importBox(
  boxName: 'users_backup',
  encryptionKey: result.encryptionKey,
  archivePath: result.archivePath,
);

// Импорт с перезаписью
await manager.importBox(
  boxName: 'users',
  encryptionKey: result.encryptionKey,
  archivePath: result.archivePath,
  overwrite: true,
);
```

### Удаление бокса

```dart
Future<void> deleteBox(String name, {bool deleteKeys = true})
```

Полностью удаляет бокс: директорию, файлы и ключи из SecureStorage.

**Параметры:**
- `name` - имя бокса
- `deleteKeys` - удалить ключи из SecureStorage (по умолчанию true)

**Пример:**

```dart
// Удалить бокс полностью
await manager.deleteBox('old_db');

// Удалить бокс, но сохранить ключи
await manager.deleteBox('temp_db', deleteKeys: false);
```

## BoxExportResult

Результат экспорта бокса.

**Поля:**
- `archivePath: String` - путь к созданному архиву
- `boxName: String` - имя экспортированного бокса
- `encryptionKey: String` - ключ шифрования архива (base64)

**Методы:**
- `toJson()` - конвертация в JSON
- `fromJson(Map)` - создание из JSON

## SecureStorage

`SecureStorage` - это интерфейс для безопасного хранения ключей шифрования.

### MemorySecureStorage

Заглушка для тестирования, которая хранит ключи в памяти.

```dart
final storage = MemorySecureStorage();

await storage.write('key', 'value');
final value = await storage.read('key');

print('Ключей: ${storage.length}');
print('Все ключи: ${storage.keys}');

await storage.delete('key');
await storage.deleteAll();
```

### Будущая интеграция с flutter_secure_storage

В будущем планируется интеграция с `flutter_secure_storage`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureStorageAdapter implements SecureStorage {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter(this._storage);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) async =>
      await _storage.read(key: key) != null;

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

// Использование
final manager = BoxManager(
  basePath: 'databases',
  secureStorage: FlutterSecureStorageAdapter(
    const FlutterSecureStorage(),
  ),
);
```

## Примеры использования

### Управление несколькими базами данных

```dart
final manager = BoxManager(basePath: 'databases');

// Создать несколько баз данных
final usersDb = await manager.createBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

final adminsDb = await manager.createBox<User>(
  name: 'admins',
  password: 'admin_password',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// Работать с базами данных
await usersDb.insert(User(id: '1', name: 'Алиса', email: 'alice@example.com', age: 28));
await adminsDb.insert(User(id: '1', name: 'Админ', email: 'admin@example.com', age: 45));

// Получить информацию
print('Открыто БД: ${manager.openBoxCount}');
print('Имена: ${manager.openBoxNames.join(", ")}');

// Закрыть все базы данных
await manager.closeAll();
```

### Переиспользование экземпляров

```dart
// Создать базу данных
await manager.createBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// Попытка открыть снова вернёт тот же экземпляр
final db1 = manager.getBox<User>('users');
final db2 = await manager.openBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// db1 и db2 - это один и тот же объект
print(db1 == db2); // true
```

### Работа с ключами

```dart
final manager = BoxManager(basePath: 'databases');

// Создать БД без пароля (авто-генерация ключа)
await manager.createBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// Ключ автоматически сохранён в SecureStorage
if (await manager.hasBoxKey('users')) {
  final key = await manager.loadBoxKey('users');
  print('Ключ сохранён: ${key?.substring(0, 10)}...');
}
```

## Обработка ошибок

```dart
try {
  final db = await manager.createBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Попытка создать БД с тем же именем
  await manager.createBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );
} on BoxManagerException catch (e) {
  print('Ошибка менеджера: $e');
} catch (e) {
  print('Неожиданная ошибка: $e');
}
```

## Best Practices

1. **Всегда закрывайте базы данных** - используйте `closeAll()` при завершении работы приложения
2. **Используйте единый менеджер** - создавайте один экземпляр `BoxManager` для всего приложения
3. **Проверяйте существование** - используйте `isBoxOpen()` или `getBox()` перед открытием
4. **Переиспользуйте экземпляры** - не создавайте несколько экземпляров одной БД
5. **Защищайте критичные данные** - используйте пароли для чувствительных баз данных
6. **Регулярно экспортируйте** - создавайте резервные копии важных данных
7. **Сохраняйте ключи** - храните ключи экспорта в безопасном месте
8. **Тестируйте восстановление** - периодически проверяйте, что архивы можно импортировать

## Примеры использования экспорта/импорта

### Резервное копирование

```dart
final manager = BoxManager(basePath: 'databases');

// Создать резервную копию
final result = await manager.exportBox('users');

// Сохранить информацию о резервной копии
print('Сохраните эти данные в безопасном месте:');
print('Архив: ${result.archivePath}');
print('Ключ: ${result.encryptionKey}');
```

### Миграция данных

```dart
// Экспорт на старом устройстве
final exportResult = await manager.exportBox('users');

// ... передать архив и ключ на новое устройство ...

// Импорт на новом устройстве
await manager.importBox(
  boxName: 'users',
  encryptionKey: receivedKey,
  archivePath: receivedArchivePath,
);
```

### Восстановление после сбоя

```dart
try {
  // Попытка открыть повреждённую БД
  final db = await manager.openBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );
} catch (e) {
  print('БД повреждена, восстанавливаем из архива...');
  
  // Удалить повреждённую БД
  await manager.deleteBox('users');
  
  // Восстановить из последнего архива
  await manager.importBox(
    boxName: 'users',
    encryptionKey: backupKey,
    archivePath: backupPath,
  );
  
  print('БД успешно восстановлена!');
}
```

### Клонирование бокса

```dart
// Экспорт
final result = await manager.exportBox('production_db');

// Импорт под другим именем для тестирования
await manager.importBox(
  boxName: 'test_db',
  encryptionKey: result.encryptionKey,
  archivePath: result.archivePath,
);

// Теперь можно тестировать на копии данных
final testDb = await manager.openBox<User>(
  name: 'test_db',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);
```

## См. также

- [API Reference](API.md) - полная документация API
- [Architecture](ARCHITECTURE.md) - архитектура системы
- [Examples](EXAMPLES.md) - примеры использования
