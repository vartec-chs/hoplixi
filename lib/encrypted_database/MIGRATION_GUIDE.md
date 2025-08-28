# Encrypted Database Module - Migration Guide

## Обзор

Модуль `encrypted_database` был полностью рефакторен для улучшения архитектуры, тестируемости и сопровождаемости. Новая версия предоставляет современную архитектуру с использованием Dependency Injection, интерфейсов и улучшенной обработки ошибок.

## Что изменилось

### 1. Новые компоненты

#### Интерфейсы
- `ICryptoService` - для криптографических операций
- `IDatabaseValidationService` - для валидации данных
- `IDatabaseConnectionService` - для управления подключениями
- `IDatabaseHistoryService` - для работы с историей БД
- `IEncryptedDatabaseManager` - основной интерфейс менеджера

#### Сервисы
- `CryptoService` - улучшенный криптографический сервис
- `DatabaseValidationService` - сервис валидации
- `DatabaseConnectionService` - сервис подключений
- `DatabaseHistoryService` - сервис истории

#### Менеджеры
- `EncryptedDatabaseManagerV2` - новый менеджер с DI
- `DatabaseStateV2Notifier` - новый нотификатор состояния

### 2. Устаревшие компоненты

Следующие классы помечены как `@Deprecated` но остаются функциональными:
- `CryptoUtils` → используйте `CryptoService`
- `DatabaseValidators` → используйте `DatabaseValidationService`

## Миграция

### Для новых проектов

Используйте новые провайдеры V2:

```dart
// Получение менеджера
final manager = ref.read(databaseManagerV2Provider);

// Состояние базы данных
final state = ref.watch(databaseStateV2Provider);
final notifier = ref.read(databaseStateV2Provider.notifier);

// Создание БД
await notifier.createDatabase(CreateDatabaseDto(
  name: 'MyDatabase',
  masterPassword: 'securePassword',
));

// Открытие БД
await notifier.openDatabase(OpenDatabaseDto(
  path: '/path/to/database.db',
  masterPassword: 'securePassword',
));

// Умное открытие (с автологином)
final success = await notifier.smartOpen('/path/to/database.db');
```

### Для существующих проектов

Старые классы продолжают работать без изменений:

```dart
// Это продолжает работать
final manager = EncryptedDatabaseManager();
await manager.createDatabase(dto);
```

Постепенно заменяйте на новые версии:

```dart
// Замените на это
final manager = ref.read(databaseManagerV2Provider);
await manager.createDatabase(dto);
```

## Новые возможности

### 1. Улучшенная обработка состояний

```dart
final state = ref.watch(databaseStateV2Provider);

switch (state.status) {
  case DatabaseStatus.loading:
    return CircularProgressIndicator();
  case DatabaseStatus.open:
    return DatabaseOpenScreen();
  case DatabaseStatus.error:
    return ErrorScreen(error: state.error);
  case DatabaseStatus.closed:
    return WelcomeScreen();
}
```

### 2. Умное открытие баз данных

```dart
// Автоматически пытается автологин, затем запрашивает пароль
final success = await notifier.smartOpen(dbPath);

// Проверка возможности автологина
final canAuto = await notifier.canAutoLogin(dbPath);
```

### 3. Тестируемость

Все сервисы можно легко мокать:

```dart
class MockCryptoService implements ICryptoService {
  @override
  String generateSecureSalt() => 'test_salt';
  
  // ... другие методы
}

// Использование в тестах
final manager = EncryptedDatabaseManagerV2(
  cryptoService: MockCryptoService(),
  // ... другие мок-сервисы
);
```

## Структура файлов

```
lib/encrypted_database/
├── interfaces/
│   └── database_interfaces.dart       # Все интерфейсы
├── services/
│   ├── crypto_service.dart           # Криптография
│   ├── database_validation_service.dart # Валидация
│   ├── database_connection_service.dart # Подключения
│   └── database_history_service.dart    # История
├── encrypted_database_manager_v2.dart   # Новый менеджер
├── encrypted_database_providers_v2.dart # Новые провайдеры
├── examples/
│   └── refactored_examples.dart         # Примеры использования
└── index.dart                           # Экспорты
```

## Обратная совместимость

✅ Все существующие API продолжают работать
✅ Никаких breaking changes
✅ Deprecation warnings помогут в миграции
✅ Постепенная миграция возможна

## Рекомендации

1. **Для новых проектов**: Используйте только V2 компоненты
2. **Для существующих проектов**: Мигрируйте постепенно
3. **Тестирование**: Используйте новые интерфейсы для моков
4. **Обработка ошибок**: Используйте новые состояния и ErrorHandler

## Примеры использования

Полные примеры доступны в:
- `examples/refactored_examples.dart` - Полный пример UI и сервисов
- `REFACTORING_REPORT.md` - Подробный отчет о изменениях

## Поддержка

При возникновении проблем с миграцией:
1. Проверьте примеры в `examples/`
2. Прочитайте документацию в интерфейсах
3. Используйте новые провайдеры для State Management
4. Создайте issue с описанием проблемы
