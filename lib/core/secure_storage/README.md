# Безопасное Key-Value Хранилище

Система безопасного хранения данных с шифрованием, где каждый тип данных хранится в отдельном файле с собственным ключом шифрования.

## ⭐ НОВОЕ: StorageServiceLocator

**StorageServiceLocator** - это новая единая точка доступа ко всему функционалу хранилища. Он заменяет прямое использование `typed_storage_services.dart` и предоставляет более удобный статический API.

### Преимущества нового подхода:

- 🎯 **Единая точка доступа** - все методы в одном классе
- 🚀 **Простота использования** - статические методы без Riverpod провайдеров  
- 🛡️ **Типобезопасность** - все методы типизированы
- ⚡ **Высокая производительность** - встроенная оптимизация
- 📊 **Расширенная аналитика** - статистика и мониторинг
- 🔧 **Автоматическое обслуживание** - очистка кэша и просроченных данных

## Особенности

- 🔐 **Шифрование**: Каждый файл хранилища имеет уникальный ключ шифрования
- 🔑 **Безопасность**: Ключи хранятся в FlutterSecureStorage
- 📁 **Разделение**: Разные типы данных в отдельных файлах
- ⚡ **Асинхронность**: Полностью асинхронный API
- 🧊 **Freezed**: Использует Freezed для типобезопасных моделей данных
- 🎯 **Типизация**: Типизированные хранилища для удобства использования
- 💾 **Кэширование**: Опциональное кэширование для повышения производительности
- ✅ **Валидация**: Проверка целостности данных через контрольные суммы

## Структура

```
lib/core/secure_storage/
├── index.dart                           # Главный экспорт
├── secure_key_value_storage.dart        # Интерфейс хранилища
├── encrypted_key_value_storage.dart     # Реализация с шифрованием
├── secure_storage_models.dart           # Модели данных
├── typed_storage_services.dart          # Типизированные сервисы
└── examples/
    └── storage_examples.dart            # Примеры использования
```

## Быстрый старт с StorageServiceLocator

### 1. Инициализация в main.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';

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
```

### 2. Работа с базами данных

```dart
// Добавление базы данных
final database = DatabaseEntry(
  id: 'unique_id',
  name: 'Название базы',
  path: '/path/to/database.db',
  lastAccessed: DateTime.now(),
  description: 'Описание базы данных',
);

await StorageServiceLocator.addDatabase(database);

// Получение всех баз данных
final allDatabases = await StorageServiceLocator.getAllDatabases();

// Обновление времени доступа
await StorageServiceLocator.updateLastAccessed('unique_id');
```

### 3. Работа с сессиями авторизации

```dart
// Создание сессии
final session = AuthSession(
  sessionId: 'session_001',
  userId: 'user_123',
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(hours: 24)),
);

await StorageServiceLocator.saveSession(session);

// Получение активных сессий
final activeSessions = await StorageServiceLocator.getActiveSessions();

// Автоматическая очистка просроченных сессий
await StorageServiceLocator.clearExpiredSessions();
```

### 4. Расширенные функции

```dart
// Получение статистики
final stats = await StorageServiceLocator.getStorageStatistics();
print('Общий размер: ${stats['totalSize']} байт');

// Проверка целостности
final integrity = await StorageServiceLocator.verifyAllStoragesIntegrity();

// Автоматическое обслуживание
await StorageServiceLocator.performMaintenance();
```

## Миграция с старого API

Если вы использовали `typed_storage_services.dart`, просто замените:

```dart
// Старый способ
final databaseStorage = ref.read(databaseListStorageProvider);
await databaseStorage.addDatabase(database);

// Новый способ  
await StorageServiceLocator.addDatabase(database);
```

## Классический API (для справки)

### 2. Работа с базами данных

```dart
class DatabaseManager extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _addDatabase(ref),
      child: Text('Add Database'),
    );
  }

  Future<void> _addDatabase(WidgetRef ref) async {
    final storage = ref.read(databaseListStorageProvider);
    
    final database = DatabaseEntry(
      id: 'db_${DateTime.now().millisecondsSinceEpoch}',
      name: 'My Database',
      path: '/path/to/database.db',
      lastAccessed: DateTime.now(),
      description: 'My database description',
    );
    
    await storage.addDatabase(database);
    
    // Получить все базы данных
    final databases = await storage.getAllDatabases();
    print('Total databases: ${databases.length}');
  }
}
```

### 3. Работа с сессиями авторизации

```dart
class AuthManager extends ConsumerWidget {
  Future<void> _createSession(WidgetRef ref) async {
    final storage = ref.read(authSessionStorageProvider);
    
    final session = AuthSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: 24)),
      refreshToken: 'refresh_token_here',
      metadata: {'device': 'mobile'},
    );
    
    await storage.saveSession(session);
    
    // Проверить активные сессии
    final activeSessions = await storage.getActiveSessions();
    print('Active sessions: ${activeSessions.length}');
  }
}
```

### 4. Использование низкоуровневого API

```dart
class CustomDataManager {
  final EncryptedKeyValueStorage storage;
  
  CustomDataManager(this.storage);
  
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await storage.write<Map<String, dynamic>>(
      storageKey: 'user_preferences',
      key: 'general',
      data: preferences,
      toJson: (data) => data,
    );
  }
  
  Future<Map<String, dynamic>?> getUserPreferences() async {
    return await storage.read<Map<String, dynamic>>(
      storageKey: 'user_preferences', 
      key: 'general',
      fromJson: (json) => json,
    );
  }
}
```

## API Reference

### EncryptedKeyValueStorage

Основной класс для работы с зашифрованным хранилищем.

#### Методы

- `initialize()` - Инициализация хранилища
- `write<T>()` - Записать данные
- `read<T>()` - Прочитать данные
- `readAll<T>()` - Прочитать все данные из файла
- `delete()` - Удалить ключ
- `deleteAll()` - Удалить все данные из файла
- `deleteStorage()` - Удалить весь файл хранилища
- `containsKey()` - Проверить существование ключа
- `getKeys()` - Получить все ключи
- `clearCache()` - Очистить кэш

### DatabaseListStorage

Типизированное хранилище для управления списком баз данных.

#### Методы

- `addDatabase()` - Добавить базу данных
- `getDatabase()` - Получить базу данных по ID
- `getAllDatabases()` - Получить все базы данных
- `updateDatabase()` - Обновить базу данных
- `removeDatabase()` - Удалить базу данных
- `updateLastAccessed()` - Обновить время последнего доступа

### AuthSessionStorage

Типизированное хранилище для управления сессиями авторизации.

#### Методы

- `saveSession()` - Сохранить сессию
- `getSession()` - Получить сессию по ID
- `getAllSessions()` - Получить все сессии
- `getActiveSessions()` - Получить активные сессии
- `removeSession()` - Удалить сессию
- `clearExpiredSessions()` - Очистить истекшие сессии
- `isSessionValid()` - Проверить валидность сессии

## Модели данных

### DatabaseEntry

```dart
@freezed
class DatabaseEntry with _$DatabaseEntry {
  const factory DatabaseEntry({
    required String id,
    required String name,
    required String path,
    required DateTime lastAccessed,
    String? description,
  }) = _DatabaseEntry;
}
```

### AuthSession

```dart
@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String sessionId,
    required String userId,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? refreshToken,
    Map<String, dynamic>? metadata,
  }) = _AuthSession;
}
```

## Безопасность

### Шифрование

- Каждый файл хранилища имеет уникальный 256-битный ключ шифрования
- Ключи генерируются с использованием криптографически стойкого генератора случайных чисел
- Ключи хранятся в FlutterSecureStorage с платформо-специфичной защитой

### Целостность данных

- Каждый файл содержит метаданные с контрольной суммой SHA-256
- При загрузке проверяется целостность данных
- Автоматическое обнаружение повреждений файлов

### Валидация

- Проверка структуры JSON при десериализации
- Обработка ошибок с информативными сообщениями
- Graceful handling поврежденных данных

## Обработка ошибок

```dart
try {
  await storage.write(/* ... */);
} on EncryptionException catch (e) {
  print('Ошибка шифрования: $e');
} on FileAccessException catch (e) {
  print('Ошибка доступа к файлу: $e');
} on ValidationException catch (e) {
  print('Ошибка валидации: $e');
} on SecureStorageException catch (e) {
  print('Общая ошибка хранилища: $e');
}
```

## Производительность

### Кэширование

- Автоматическое кэширование ключей шифрования
- Опциональное кэширование данных для повышения скорости
- Метод `clearCache()` для очистки кэша при необходимости

### Оптимизации

- Ленивая загрузка данных
- Батчинг операций записи
- Минимизация операций с файловой системой

## Платформы

Поддерживаются все платформы Flutter, кроме Web:
- ✅ Android
- ✅ iOS  
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ❌ Web (не поддерживается из-за ограничений файловой системы)

## Зависимости

- `flutter_secure_storage` - для безопасного хранения ключей
- `crypto` - для вычисления хэшей и шифрования
- `path_provider` - для получения путей к каталогам
- `freezed` - для генерации immutable моделей
- `riverpod` - для dependency injection

## Миграция и версионирование

Хранилище поддерживает версионирование через метаданные файлов. При необходимости можно добавить логику миграции для обновления формата данных.

## Лицензия

Этот код является частью проекта Hoplixi.
