# Database History Service

Сервис для управления историей подключений к базам данных в приложении Hoplixi с интеграцией SimpleBoxManager.

## Структура

### Модели

- **DatabaseEntry** (`models/database_entry.dart`)
  - `path` - путь к файлу базы данных
  - `name` - название базы данных
  - `description` - описание (опционально)
  - `masterPassword` - мастер-пароль (опционально, только если `saveMasterPassword = true`)
  - `saveMasterPassword` - флаг сохранения пароля
  - `lastAccessed` - дата последнего доступа
  - `createdAt` - дата создания записи

### Сервисы

- **DatabaseHistoryService** (`services/database_history_service.dart`)
  - Управление историей подключений
  - Интеграция с SimpleBoxManager для хранения данных
  - Автоматическое шифрование истории
  - CRUD операции для записей истории

### Интеграция

**HoplixiStoreManager** расширен следующими возможностями:
- Автоматическая запись в историю при создании/открытии БД
- Публичные методы для работы с историей
- Правильное освобождение ресурсов при закрытии

## Основные возможности

### 1. Автоматическая запись истории

При создании или открытии базы данных через `HoplixiStoreManager` информация автоматически сохраняется в историю:

```dart
final manager = HoplixiStoreManager();

// При создании БД
final createDto = CreateDatabaseDto(
  name: 'my_database',
  masterPassword: 'password123',
  saveMasterPassword: true, // Сохранить пароль в истории
);
await manager.createDatabase(createDto); // Автоматически записывается в историю

// При открытии БД
final openDto = OpenDatabaseDto(
  path: '/path/to/database.hpx',
  masterPassword: 'password123',
  saveMasterPassword: false, // Не сохранять пароль
);
await manager.openDatabase(openDto); // Обновляется запись в истории
```

### 2. Управление историей

```dart
final manager = HoplixiStoreManager();

// Получить всю историю
final history = await manager.getDatabaseHistory();

// Получить конкретную запись
final entry = await manager.getDatabaseHistoryEntry('/path/to/db.hpx');

// Получить записи с сохраненными паролями
final withPasswords = await manager.getDatabaseHistoryWithSavedPasswords();

// Удалить запись из истории
await manager.removeDatabaseHistoryEntry('/path/to/old/db.hpx');

// Очистить всю историю
await manager.clearDatabaseHistory();

// Получить статистику
final stats = await manager.getDatabaseHistoryStats();
```

### 3. Прямое использование сервиса

```dart
final manager = HoplixiStoreManager();
final historyService = manager.historyService;

// Ручная запись в историю
await historyService.recordDatabaseAccess(
  path: '/custom/path/db.hpx',
  name: 'Custom Database',
  description: 'Manually added entry',
  masterPassword: null,
  saveMasterPassword: false,
);

// Обновление информации
await historyService.updateDatabaseInfo(
  path: '/custom/path/db.hpx',
  name: 'Updated Name',
  description: 'Updated Description',
);
```

## Безопасность

1. **Шифрование**: История хранится в зашифрованной SimpleBox
2. **Опциональные пароли**: Пароли сохраняются только при `saveMasterPassword = true`
3. **Изолированное хранение**: История хранится отдельно от основных данных

## Хранение данных

- **Местоположение**: `{app_documents}/hoplixi/history/`
- **Формат**: SimpleBox с шифрованием
- **Ключи**: Пути к файлам (нормализованные)
- **Автоматическое резервное копирование**: Поддерживается SimpleBox

## Управление ресурсами

```dart
final manager = HoplixiStoreManager();

try {
  // Работа с базой данных и историей
  await manager.openDatabase(dto);
  await manager.getDatabaseHistory();
} finally {
  // Обязательно освобождаем ресурсы
  await manager.dispose(); // Закрывает БД и сервис истории
}
```

## Примеры использования

Полные примеры доступны в файле `examples/database_history_examples.dart`.

## Архитектура

```
HoplixiStoreManager
├── _database: HoplixiStore?
├── _historyService: DatabaseHistoryService?
└── historyService: DatabaseHistoryService (getter)

DatabaseHistoryService
├── _historyBox: SimpleBox<DatabaseEntry>?
├── _boxManager: SimpleBoxManager?
└── интеграция с SimpleBoxManager для хранения

SimpleBoxManager
├── Шифрованное хранение
├── Автоматические резервные копии
└── Компактификация данных
```

## Особенности реализации

1. **Lazy initialization**: Сервис истории инициализируется при первом обращении
2. **Error handling**: Ошибки истории не прерывают основную работу с БД
3. **Thread safety**: Использует SimpleMutex для синхронизации
4. **Memory efficiency**: SimpleBox загружает данные по требованию
5. **Automatic cleanup**: Правильное освобождение ресурсов

## Тестирование

Для тестирования сервиса используйте временные директории:

```dart
final tempDir = await Directory.systemTemp.createTemp('history_test_');
final boxManager = await SimpleBoxManager.getInstance(baseDirectory: tempDir);
// ... тесты
await boxManager.shutdown();
await tempDir.delete(recursive: true);
```
