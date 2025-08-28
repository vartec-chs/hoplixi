# Функционал записи истории баз данных

Этот документ описывает новый функционал для записи, отслеживания и управления ранее открытыми базами данных в приложении Hoplixi.

## 🎯 Основные возможности

### ✅ Автоматическая запись истории
- Каждое создание и открытие базы данных автоматически записывается в историю
- Отслеживается время последнего доступа
- Сохраняется путь к файлу, название и описание

### ✅ Автологин и сохранение паролей
- Возможность сохранения мастер-паролей (с разрешения пользователя)
- Автоматическое открытие баз данных с сохраненными паролями
- Безопасное хранение паролей в зашифрованном виде

### ✅ Избранные базы данных
- Отметка избранных баз данных
- Быстрый доступ к часто используемым базам
- Защита от автоматического удаления при обслуживании

### ✅ Умное управление
- Автоматическая очистка старых записей (> 1 года)
- Статистика использования
- Экспорт/импорт истории для резервного копирования

## 🏗️ Архитектура

### Основные компоненты

1. **EncryptedDatabaseManager** - Основной менеджер баз данных с интегрированной историей
2. **DatabaseHistoryService** - Отдельный сервис для работы с историей
3. **StorageServiceLocator** - Базовое безопасное хранилище
4. **DatabaseEntry** - Модель данных для записи в истории

### Схема работы

```
┌─────────────────────────┐
│  EncryptedDatabaseManager │
├─────────────────────────┤
│ + createDatabase()      │
│ + openDatabase()        │
│ + closeDatabase()       │
│ + getAllDatabases()     │
│ + tryAutoLogin()        │
│ + smartOpen()           │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│  DatabaseHistoryService │
├─────────────────────────┤
│ + recordDatabaseAccess()│
│ + getDatabaseInfo()     │
│ + setFavorite()         │
│ + saveMasterPassword()  │
│ + getStatistics()       │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│  StorageServiceLocator  │
├─────────────────────────┤
│ + addDatabase()         │
│ + getDatabase()         │
│ + getAllDatabases()     │
│ + updateDatabase()      │
└─────────────────────────┘
           │
           ▼
┌─────────────────────────┐
│  EncryptedKeyValueStorage │
├─────────────────────────┤
│ + write()               │
│ + read()                │
│ + readAll()             │
│ + delete()              │
└─────────────────────────┘
```

## 📖 Примеры использования

### Создание новой базы данных

```dart
final dbManager = EncryptedDatabaseManager();
await dbManager.initialize();

final result = await dbManager.createDatabase(CreateDatabaseDto(
  name: 'MyPasswordDB',
  masterPassword: 'secure_password_123',
  description: 'Моя база паролей',
  saveMasterPassword: false, // Не сохраняем пароль при создании
  isFavorite: false,
));

// База автоматически добавляется в историю
```

### Открытие существующей базы данных

```dart
final result = await dbManager.openDatabase(OpenDatabaseDto(
  path: '/path/to/database.db',
  masterPassword: 'password',
  saveMasterPassword: true, // Сохраняем пароль для автологина
));

// Информация автоматически обновляется в истории
```

### Автологин

```dart
// Проверяем, возможен ли автологин
final canAutoLogin = await dbManager.canAutoLogin('/path/to/database.db');

if (canAutoLogin) {
  // Открываем с автологином
  final result = await dbManager.openWithAutoLogin('/path/to/database.db');
  if (result != null) {
    print('База данных открыта автоматически!');
  }
}
```

### Умное открытие

```dart
// Сначала пытается автологин, затем использует предоставленный пароль
final result = await dbManager.smartOpen(
  '/path/to/database.db',
  'fallback_password'
);

if (result != null) {
  print('База данных открыта!');
} else {
  print('Требуется ввод пароля вручную');
}
```

### Работа с историей

```dart
// Получаем все базы данных
final allDatabases = await dbManager.getAllDatabases();

// Получаем недавние базы данных
final recentDatabases = await dbManager.getRecentDatabases(limit: 5);

// Получаем избранные базы данных
final favorites = await dbManager.getFavoriteDatabases();

// Получаем базы данных с сохраненными паролями
final withPasswords = await dbManager.getDatabasesWithSavedPasswords();
```

### Управление избранными

```dart
// Добавляем в избранное
await dbManager.setDatabaseFavorite('/path/to/database.db', true);

// Убираем из избранного
await dbManager.setDatabaseFavorite('/path/to/database.db', false);
```

### Управление сохраненными паролями

```dart
// Сохраняем пароль
await dbManager.saveMasterPassword('/path/to/database.db', 'password');

// Удаляем сохраненный пароль
await dbManager.removeSavedMasterPassword('/path/to/database.db');
```

### Статистика

```dart
final stats = await dbManager.getDatabaseHistoryStatistics();
print('Всего баз данных: ${stats['total']}');
print('Избранных: ${stats['favorites']}');
print('С сохраненными паролями: ${stats['withSavedPasswords']}');
print('Использованных сегодня: ${stats['accessedToday']}');
```

## 🔐 Безопасность

### Хранение паролей

- Мастер-пароли хранятся в том же безопасном хранилище, что и другие данные
- Используется AES-256-GCM шифрование
- Каждый файл хранилища имеет уникальный ключ шифрования
- Ключи хранятся в платформо-специфичном безопасном хранилище

### Рекомендации

1. **Не включайте сохранение паролей по умолчанию** - пользователь должен явно согласиться
2. **Предупреждайте пользователей** о рисках сохранения паролей
3. **Предоставляйте возможность удаления** сохраненных паролей
4. **Регулярно напоминайте** о необходимости обновления паролей

### Пример UI предупреждения

```dart
// При попытке сохранить пароль
await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Сохранить мастер-пароль?'),
    content: Text(
      'ВНИМАНИЕ: Сохранение пароля может представлять угрозу безопасности. '
      'Пароль будет зашифрован, но при компрометации устройства может быть '
      'получен злоумышленником. Продолжить?'
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Отмена'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Сохранить'),
      ),
    ],
  ),
);
```

## 🛠️ Обслуживание

### Автоматическое обслуживание

```dart
// Выполняется автоматически при вызове
await dbManager.performDatabaseHistoryMaintenance();
```

Автоматическое обслуживание включает:
- Удаление записей старше 1 года (кроме избранных)
- Очистку кэша
- Проверку целостности данных

### Ручное управление

```dart
// Очистка конкретной записи
await dbManager.removeDatabaseFromHistory('/path/to/database.db');

// Полная очистка истории (осторожно!)
await dbManager.clearDatabaseHistory();
```

## 📊 Модель данных

### DatabaseEntry

```dart
class DatabaseEntry {
  final String id;                    // Уникальный ID (хэш пути)
  final String name;                  // Название базы данных
  final String path;                  // Полный путь к файлу
  final DateTime lastAccessed;        // Время последнего доступа
  final String? description;          // Описание (опционально)
  final String? masterPassword;       // Сохраненный пароль (опционально)
  final bool isFavorite;              // Флаг избранного
  final bool isMasterPasswordSaved;   // Флаг сохраненного пароля
}
```

## 🚀 Инициализация в main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/encrypted_database/encrypted_database_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // Инициализируем сервис-локатор
  StorageServiceLocator.initialize(container);
  
  // Инициализируем хранилище
  await StorageServiceLocator.initializeStorage();
  
  runApp(UncontrolledProviderScope(
    container: container, 
    child: MyApp()
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoplixi',
      home: DatabaseManagerScreen(),
    );
  }
}
```

## 🧪 Тестирование

### Пример тестового сценария

```dart
void main() {
  group('Database History Tests', () {
    late EncryptedDatabaseManager manager;
    
    setUp(() async {
      manager = EncryptedDatabaseManager();
      await manager.initialize();
    });
    
    test('should record database creation in history', () async {
      final dto = CreateDatabaseDto(
        name: 'TestDB',
        masterPassword: 'test_password',
        description: 'Test database',
      );
      
      final result = await manager.createDatabase(dto);
      expect(result.status, DatabaseStatus.open);
      
      final history = await manager.getAllDatabases();
      expect(history.length, 1);
      expect(history.first.name, 'TestDB');
    });
    
    test('should support auto-login', () async {
      const dbPath = '/test/path/database.db';
      
      // Сохраняем пароль
      await manager.saveMasterPassword(dbPath, 'test_password');
      
      // Проверяем автологин
      final canAutoLogin = await manager.canAutoLogin(dbPath);
      expect(canAutoLogin, true);
      
      final savedPassword = await manager.tryAutoLogin(dbPath);
      expect(savedPassword, 'test_password');
    });
  });
}
```

## 📝 TODO

- [ ] Добавить UI компоненты для работы с историей
- [ ] Реализовать поиск в истории баз данных
- [ ] Добавить группировку баз данных по категориям
- [ ] Интегрировать с системой уведомлений
- [ ] Добавить синхронизацию истории между устройствами
- [ ] Реализовать автоматическое создание резервных копий истории

## 🐛 Известные ограничения

1. **Платформа Web не поддерживается** из-за ограничений файловой системы
2. **Сохранение паролей представляет риск** - используйте с осторожностью
3. **Автоматическая очистка** может удалить важные записи (кроме избранных)

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи приложения
2. Убедитесь в правильной инициализации StorageServiceLocator
3. Проверьте права доступа к файловой системе
4. Выполните обслуживание хранилища

---

*Документация актуальна на момент создания функционала записи истории баз данных.*
