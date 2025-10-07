# Экспорт/Импорт с автоматическим управлением ключами

Начиная с версии, включающей улучшения экспорта/импорта, BoxDB автоматически управляет ключами шифрования при экспорте и импорте боксов.

## Что нового?

### При экспорте бокса

1. **Автоматическая компактификация**: Перед экспортом бокс автоматически компактифицируется, удаляя весь мусор из базы данных
2. **Извлечение ключа**: Ключ шифрования бокса извлекается из `meta.json`
3. **Создание box_key.txt**: В архив добавляется файл `box_key.txt` с ключом шифрования бокса

### При импорте бокса

1. **Извлечение ключа**: Файл `box_key.txt` извлекается из архива
2. **Сохранение в SecureStorage**: Ключ автоматически сохраняется в SecureStorage под именем `box_key_{boxName}`
3. **Удаление файла**: Файл `box_key.txt` удаляется из импортированного бокса для безопасности
4. **Автоматическое открытие**: Бокс можно открыть без пароля - ключ загружается из SecureStorage

## Обновлённый API

### exportBox()

Теперь требует дополнительные параметры для компактификации:

```dart
Future<BoxExportResult> exportBox<T>({
  required String name,
  String? outputPath,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String Function(T) getId,
})
```

**Параметры:**
- `name` - имя бокса для экспорта
- `outputPath` - путь для сохранения архива (опционально)
- `fromJson` - функция десериализации (требуется для компактификации)
- `toJson` - функция сериализации (требуется для компактификации)
- `getId` - функция получения ID (требуется для компактификации)

**Пример:**

```dart
final manager = BoxManager(basePath: 'data');

final result = await manager.exportBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);

print('Архив: ${result.archivePath}');
print('Ключ архива: ${result.encryptionKey}');
```

### importBox()

API не изменился, но теперь автоматически сохраняет ключ:

```dart
Future<void> importBox({
  required String boxName,
  required String encryptionKey,
  required String archivePath,
  bool overwrite = false,
})
```

**Пример:**

```dart
// Импорт автоматически сохранит ключ в SecureStorage
await manager.importBox(
  boxName: 'restored_users',
  encryptionKey: exportResult.encryptionKey,
  archivePath: exportResult.archivePath,
);

// Теперь бокс можно открыть БЕЗ пароля
final db = await manager.openBox<User>(
  name: 'restored_users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
  // password НЕ НУЖЕН - ключ загрузится из SecureStorage
);
```

## Полный пример использования

```dart
import 'dart:io';
import 'package:test_box_db/test_box_db.dart';

void main() async {
  final manager = BoxManager(basePath: 'data');

  // 1. Создать бокс с данными
  var db = await manager.createBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  await db.insert(User(
    id: '1',
    name: 'Alice',
    email: 'alice@example.com',
    age: 28,
  ));

  await manager.closeBox('users');

  // 2. Экспортировать (с компактификацией и сохранением ключа)
  final exportResult = await manager.exportBox<User>(
    name: 'users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  print('Экспорт завершён: ${exportResult.archivePath}');

  // 3. Удалить исходный бокс
  await manager.deleteBox('users');

  // 4. Импортировать (автоматически сохранит ключ в SecureStorage)
  await manager.importBox(
    boxName: 'restored_users',
    encryptionKey: exportResult.encryptionKey,
    archivePath: exportResult.archivePath,
  );

  // 5. Открыть БЕЗ пароля (ключ из SecureStorage)
  db = await manager.openBox<User>(
    name: 'restored_users',
    fromJson: User.fromJson,
    toJson: (u) => u.toJson(),
    getId: (u) => u.id,
  );

  final user = await db.get('1');
  print('Восстановлен: ${user?.name}');

  await manager.closeAll();
}
```

## Безопасность

### Что хранится в архиве?

- **Зашифрованные данные бокса** (data.jsonl)
- **Зашифрованный индекс** (index.json)
- **Метаданные с ключом** (meta.json содержит encryption_key)
- **Файл box_key.txt** с ключом шифрования бокса

**Важно:** Сам архив шифруется отдельным ключом (`encryptionKey` в результате экспорта), который НЕ хранится в архиве.

### Что происходит с ключами?

1. **При экспорте:**
   - Ключ бокса из meta.json копируется в box_key.txt внутри архива
   - Архив шифруется новым случайным ключом
   - Этот ключ архива возвращается пользователю

2. **При импорте:**
   - Архив расшифровывается ключом архива
   - box_key.txt извлекается и сохраняется в SecureStorage
   - box_key.txt удаляется из импортированного бокса
   - meta.json остаётся с ключом (для работы бокса)

### Рекомендации по безопасности

✅ **Хранить:**
- Ключ архива (`exportResult.encryptionKey`) в безопасном месте
- Сам архив можно хранить где угодно (он зашифрован)

❌ **Не делать:**
- Не передавать ключ архива вместе с архивом
- Не хранить ключ в открытом виде
- Не забывать ключ - без него архив не расшифровать

## Преимущества нового подхода

1. **Компактификация**: Экспортированный архив всегда минимального размера
2. **Автоматизация**: Не нужно вручную управлять ключами бокса
3. **Удобство**: После импорта бокс открывается без пароля
4. **Безопасность**: box_key.txt автоматически удаляется после импорта
5. **Двойное шифрование**: Данные бокса + шифрование архива

## Миграция со старой версии

Если вы использовали старый API:

```dart
// Старый код (НЕ работает)
final result = await manager.exportBox('users');
```

Замените на:

```dart
// Новый код
final result = await manager.exportBox<User>(
  name: 'users',
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  getId: (u) => u.id,
);
```

API импорта не изменился, но теперь автоматически сохраняет ключи в SecureStorage.

## Смотрите также

- [example/export_import_with_key_demo.dart](../example/export_import_with_key_demo.dart) - полная демонстрация
- [test/box_export_import_test.dart](../test/box_export_import_test.dart) - тесты функциональности
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) - архитектура системы
