# Примеры использования BoxDB

## 1. Базовый CRUD

```dart
import 'package:test_box_db/test_box_db.dart';

void basicCrud() async {
  // Создать БД
  final db = await BoxDB.create<User>(
    name: 'users',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // CREATE
  await db.insert(User(
    id: '1',
    name: 'Alice',
    email: 'alice@example.com',
    age: 25,
  ));

  // READ
  final user = await db.get('1');
  print(user?.name); // Alice

  // UPDATE
  if (user != null) {
    await db.update(user.copyWith(age: 26));
  }

  // DELETE
  await db.delete('1');

  await db.close();
}
```

## 2. Работа с паролем

```dart
void withPassword() async {
  const password = 'my_secure_password_123';

  // Создание с паролем
  final db = await BoxDB.create<User>(
    name: 'secure_users',
    basePath: 'data',
    password: password,
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  await db.insert(User(
    id: '1',
    name: 'Secret User',
    email: 'secret@example.com',
    age: 30,
  ));

  await db.close();

  // Открытие с тем же паролем
  final db2 = await BoxDB.open<User>(
    name: 'secure_users',
    basePath: 'data',
    password: password, // Должен совпадать!
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  final user = await db2.get('1');
  print(user?.name); // Secret User

  await db2.close();
}
```

## 3. Массовые операции

```dart
void batchOperations() async {
  final db = await BoxDB.create<User>(
    name: 'batch_users',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Генерация тестовых данных
  final users = List.generate(
    100,
    (i) => User(
      id: 'user_$i',
      name: 'User $i',
      email: 'user$i@example.com',
      age: 20 + (i % 50),
    ),
  );

  // Параллельная вставка
  print('Вставка 100 пользователей...');
  final stopwatch = Stopwatch()..start();

  await Future.wait(users.map((u) => db.insert(u)));

  stopwatch.stop();
  print('Завершено за ${stopwatch.elapsedMilliseconds}ms');

  // Получить все
  final all = await db.getAll();
  print('Всего записей: ${all.length}');

  await db.close();
}
```

## 4. Обработка ошибок

```dart
void errorHandling() async {
  final db = await BoxDB.create<User>(
    name: 'error_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  final user = User(
    id: '1',
    name: 'Test',
    email: 'test@example.com',
    age: 25,
  );

  try {
    await db.insert(user);
    print('✅ Вставка успешна');
  } catch (e) {
    print('❌ Ошибка при вставке: $e');
  }

  try {
    // Попытка вставить дубликат
    await db.insert(user);
  } on BoxDBException catch (e) {
    print('⚠️  Ожидаемая ошибка: ${e.message}');
  }

  try {
    // Попытка обновить несуществующую запись
    await db.update(User(
      id: 'nonexistent',
      name: 'Ghost',
      email: 'ghost@example.com',
      age: 0,
    ));
  } on BoxDBException catch (e) {
    print('⚠️  Ожидаемая ошибка: ${e.message}');
  }

  // Безопасное обновление
  if (await db.exists('1')) {
    await db.update(user.copyWith(age: 26));
    print('✅ Обновление успешно');
  }

  await db.close();
}
```

## 5. Backup и восстановление

```dart
void backupAndRestore() async {
  final db = await BoxDB.create<User>(
    name: 'backup_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Вставить данные
  await db.insert(User(
    id: '1',
    name: 'Important User',
    email: 'important@example.com',
    age: 30,
  ));

  // Создать backup перед критической операцией
  print('Создание backup...');
  await db.backup();

  // Критическая операция
  try {
    // ... что-то опасное ...
    await db.delete('1');
  } catch (e) {
    print('Ошибка! Нужно восстановление');
  }

  await db.close();

  // При следующем открытии создаётся backup автоматически
  final db2 = await BoxDB.open<User>(
    name: 'backup_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  print('БД открыта с автоматическим backup');
  
  await db2.close();
}
```

## 6. Компактификация

```dart
void compactionExample() async {
  final db = await BoxDB.create<User>(
    name: 'compact_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Вставить много записей
  for (var i = 0; i < 100; i++) {
    await db.insert(User(
      id: 'user_$i',
      name: 'User $i',
      email: 'user$i@example.com',
      age: 20 + i,
    ));
  }

  print('Вставлено: ${await db.count()}');

  // Удалить половину
  for (var i = 0; i < 50; i++) {
    await db.delete('user_$i');
  }

  print('После удаления: ${await db.count()}');

  // Компактификация
  print('Компактификация...');
  await db.compact();
  print('✅ Завершено');

  await db.close();
}
```

## 7. Проверка существования

```dart
void existsExample() async {
  final db = await BoxDB.create<User>(
    name: 'exists_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  final user = User(
    id: '1',
    name: 'Test',
    email: 'test@example.com',
    age: 25,
  );

  // Вставить если не существует
  if (!await db.exists('1')) {
    await db.insert(user);
    print('✅ Пользователь создан');
  } else {
    print('⚠️  Пользователь уже существует');
  }

  // Обновить если существует
  if (await db.exists('1')) {
    await db.update(user.copyWith(age: 26));
    print('✅ Пользователь обновлён');
  }

  await db.close();
}
```

## 8. Статистика БД

```dart
void statsExample() async {
  final db = await BoxDB.create<User>(
    name: 'stats_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Вставить данные
  for (var i = 0; i < 50; i++) {
    await db.insert(User(
      id: 'user_$i',
      name: 'User $i',
      email: 'user$i@example.com',
      age: 20 + i,
    ));
  }

  // Статистика
  final count = await db.count();
  print('📊 Всего записей: $count');

  // Удалить 10 записей
  for (var i = 0; i < 10; i++) {
    await db.delete('user_$i');
  }

  final newCount = await db.count();
  print('📊 После удаления: $newCount');
  print('📊 Удалено: ${count - newCount}');

  await db.close();
}
```

## 9. Множественные БД

```dart
void multipleDatabases() async {
  // БД пользователей
  final usersDb = await BoxDB.create<User>(
    name: 'users',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // БД продуктов (предполагая, что есть модель Product)
  // final productsDb = await BoxDB.create<Product>(...)

  // Работа с разными БД параллельно
  await usersDb.insert(User(
    id: '1',
    name: 'Alice',
    email: 'alice@example.com',
    age: 25,
  ));

  // await productsDb.insert(Product(...))

  print('✅ Данные вставлены в обе БД');

  await usersDb.close();
  // await productsDb.close();
}
```

## 10. Lifecycle management

```dart
class UserRepository {
  BoxDB<User>? _db;

  Future<void> open() async {
    _db = await BoxDB.create<User>(
      name: 'users',
      basePath: 'data',
      fromJson: User.fromJson,
      toJson: (u) => u.toJson(),
      getId: (u) => u.id,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> addUser(User user) async {
    if (_db == null) throw Exception('БД не открыта');
    await _db!.insert(user);
  }

  Future<User?> getUser(String id) async {
    if (_db == null) throw Exception('БД не открыта');
    return await _db!.get(id);
  }

  Future<List<User>> getAllUsers() async {
    if (_db == null) throw Exception('БД не открыта');
    return await _db!.getAll();
  }
}

void repositoryPattern() async {
  final repo = UserRepository();

  try {
    await repo.open();

    await repo.addUser(User(
      id: '1',
      name: 'Alice',
      email: 'alice@example.com',
      age: 25,
    ));

    final user = await repo.getUser('1');
    print('User: ${user?.name}');

    final all = await repo.getAllUsers();
    print('Total: ${all.length}');
  } finally {
    await repo.close();
  }
}
```

## 11. Миграция данных

```dart
void migration() async {
  // Старая БД
  final oldDb = await BoxDB.open<User>(
    name: 'old_users',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Новая БД с паролем
  final newDb = await BoxDB.create<User>(
    name: 'new_users',
    basePath: 'data',
    password: 'secure_password',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Копирование данных
  print('Миграция данных...');
  final users = await oldDb.getAll();
  
  for (final user in users) {
    await newDb.insert(user);
  }

  print('✅ Мигрировано ${users.length} записей');

  await oldDb.close();
  await newDb.close();
}
```

## 12. Поиск и фильтрация

```dart
void searchAndFilter() async {
  final db = await BoxDB.create<User>(
    name: 'search_test',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  // Вставить тестовые данные
  final users = [
    User(id: '1', name: 'Alice', email: 'alice@example.com', age: 25),
    User(id: '2', name: 'Bob', email: 'bob@example.com', age: 30),
    User(id: '3', name: 'Charlie', email: 'charlie@example.com', age: 35),
    User(id: '4', name: 'David', email: 'david@example.com', age: 40),
  ];

  for (final user in users) {
    await db.insert(user);
  }

  // Получить всех и фильтровать
  final all = await db.getAll();

  // Пользователи старше 30
  final over30 = all.where((u) => u.age > 30).toList();
  print('Старше 30: ${over30.map((u) => u.name).join(", ")}');

  // Поиск по имени
  final alice = all.firstWhere(
    (u) => u.name == 'Alice',
    orElse: () => throw Exception('Не найден'),
  );
  print('Найден: ${alice.name}');

  // Поиск по email
  final byEmail = all.where(
    (u) => u.email.contains('charlie'),
  ).toList();
  print('По email: ${byEmail.map((u) => u.name).join(", ")}');

  await db.close();
}
```

## 13. Benchmark

```dart
void benchmark() async {
  final db = await BoxDB.create<User>(
    name: 'benchmark',
    basePath: 'data',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  final stopwatch = Stopwatch();

  // Insert benchmark
  print('=== INSERT BENCHMARK ===');
  stopwatch.start();
  for (var i = 0; i < 1000; i++) {
    await db.insert(User(
      id: 'user_$i',
      name: 'User $i',
      email: 'user$i@example.com',
      age: 20 + (i % 50),
    ));
  }
  stopwatch.stop();
  print('1000 вставок: ${stopwatch.elapsedMilliseconds}ms');
  print('Средняя: ${stopwatch.elapsedMilliseconds / 1000}ms');

  // Get benchmark
  print('\n=== GET BENCHMARK ===');
  stopwatch.reset();
  stopwatch.start();
  for (var i = 0; i < 1000; i++) {
    await db.get('user_$i');
  }
  stopwatch.stop();
  print('1000 чтений: ${stopwatch.elapsedMilliseconds}ms');
  print('Средняя: ${stopwatch.elapsedMilliseconds / 1000}ms');

  // Update benchmark
  print('\n=== UPDATE BENCHMARK ===');
  stopwatch.reset();
  stopwatch.start();
  for (var i = 0; i < 100; i++) {
    final user = await db.get('user_$i');
    if (user != null) {
      await db.update(user.copyWith(age: user.age + 1));
    }
  }
  stopwatch.stop();
  print('100 обновлений: ${stopwatch.elapsedMilliseconds}ms');
  print('Средняя: ${stopwatch.elapsedMilliseconds / 100}ms');

  await db.close();
}
```

Эти примеры демонстрируют различные сценарии использования BoxDB от базовых CRUD операций до продвинутых паттернов вроде миграции данных и repository pattern.
