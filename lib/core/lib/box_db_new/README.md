# BoxDB - Безопасная локальная база данных с шифрованием

BoxDB - это легковесная, безопасная база данных на Dart с автоматическим шифрованием данных, поддержкой JSON и интеграцией с Freezed.

## Основные возможности

✨ **Шифрование данных** - AES-GCM шифрование всех записей  
📦 **Freezed интеграция** - Работа с иммутабельными моделями данных  
🔄 **Асинхронность** - Все операции асинхронные  
🔒 **Потокобезопасность** - Синхронизация с использованием `synchronized`  
💾 **Эффективное хранение** - JSONL формат, не держит всё в памяти  
🔐 **Selective decryption** - Расшифровка только при чтении  
📊 **Индексация** - Быстрый поиск по ID  
♻️ **Backup/Restore** - Автоматическое резервное копирование  
🗜️ **Компактификация** - Автоматическая очистка удалённых записей  
🗂️ **BoxManager** - Управление несколькими базами данных  
📤 **Экспорт/Импорт** - Зашифрованные архивы для переноса данных  
🗑️ **Полное удаление** - Удаление бокса с очисткой всех данных  
⏰ **Временные запросы** - Получение записей по времени создания/обновления  

## Быстрый старт

### Работа с одной базой данных

```dart
import 'package:test_box_db/test_box_db.dart';

// Создание БД
final db = await BoxDB.create<User>(
  name: 'users_db',
  basePath: 'databases',
  password: 'my_secure_password',
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);

// CRUD операции
await db.insert(User(id: '1', name: 'John', email: 'john@mail.com', age: 30));
final user = await db.get('1');
await db.update(user!.copyWith(age: 31));
await db.delete('1');

await db.close();
```

### Управление несколькими базами данных

```dart
import 'package:test_box_db/test_box_db.dart';

// Создать менеджер
final manager = BoxManager(basePath: 'databases');

// Создать несколько БД
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
await usersDb.insert(User(id: '1', name: 'Alice', email: 'alice@mail.com', age: 28));
await adminsDb.insert(User(id: '1', name: 'Admin', email: 'admin@mail.com', age: 45));

// Закрыть все базы данных
await manager.closeAll();
```

### Экспорт и импорт баз данных

```dart
import 'package:test_box_db/test_box_db.dart';

final manager = BoxManager(basePath: 'databases');

// Создать и заполнить бокс
final db = await manager.createBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

await db.insert(User(id: '1', name: 'Alice', email: 'alice@mail.com', age: 28));
await manager.closeBox('users');

// Экспортировать в зашифрованный архив
final exportResult = await manager.exportBox('users');
print('Архив: ${exportResult.archivePath}');
print('Ключ: ${exportResult.encryptionKey}');

// Удалить бокс
await manager.deleteBox('users');

// Восстановить из архива
await manager.importBox(
  boxName: 'users_restored',
  encryptionKey: exportResult.encryptionKey,
  archivePath: exportResult.archivePath,
);

await manager.closeAll();
```

### Запросы по времени

```dart
import 'package:test_box_db/test_box_db.dart';

final db = await BoxDB.create<User>(
  name: 'users',
  basePath: 'databases',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

// Добавить записи
await db.insert(User(id: '1', name: 'Alice', email: 'alice@mail.com', age: 25));
await Future.delayed(Duration(seconds: 1));
await db.insert(User(id: '2', name: 'Bob', email: 'bob@mail.com', age: 30));
await Future.delayed(Duration(seconds: 1));
await db.insert(User(id: '3', name: 'Charlie', email: 'charlie@mail.com', age: 22));

// Получить последние 2 записи
final recent = await db.getRecent(limit: 2);
// [Charlie, Bob]

// Записи за последние 24 часа
final yesterday = DateTime.now().subtract(Duration(days: 1));
final recentDay = await db.getRecent(since: yesterday);

// Записи за период
final lastWeek = await db.getByTimeRange(
  from: DateTime.now().subtract(Duration(days: 7)),
);

// Все записи, отсортированные по времени (от старых к новым)
final sorted = await db.getAllSortedByTime(ascending: true);

// Получить время создания/обновления записи
final timestamp = await db.getTimestamp('1');
print('Created/Updated: $timestamp');

await db.close();
```

## Тестирование

```bash
dart test
```

✅ 68 тестов пройдено успешно (25 BoxDB + 17 BoxManager + 14 Export/Import + 12 Time Queries)

## Документация

- [API Reference](docs/API.md) - Полная документация API
- [BoxManager Guide](docs/BOX_MANAGER.md) - Управление несколькими БД
- [Architecture](docs/ARCHITECTURE.md) - Архитектура системы
- [Examples](docs/EXAMPLES.md) - Примеры использования
- [Quick Start](QUICKSTART.md) - Быстрое начало работы
