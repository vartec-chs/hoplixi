# Система обработки ошибок и логирования

## Обзор

Проект использует многуровневую систему обработки ошибок с автоматическим логированием:

1. **Типизированные ошибки** - `DatabaseError` с различными типами
2. **Централизованный обработчик** - `ErrorHandler` для унифицированной обработки
3. **Автоматическое логирование** - интеграция с `AppLogger`
4. **Graceful degradation** - безопасные fallback значения

## Классы ошибок

### DatabaseError

Основной класс ошибок с типами:

- `invalidPassword` - Неверный пароль
- `databaseNotFound` - База данных не найдена
- `databaseAlreadyExists` - База данных уже существует
- `connectionFailed` - Ошибка подключения
- `operationFailed` - Ошибка операции
- `pathNotAccessible` - Путь недоступен
- `unknown` - Неизвестная ошибка
- `keyError` - Ошибка работы с ключами
- `secureStorageError` - Ошибка безопасного хранилища

Каждая ошибка содержит:
- `code` - Уникальный код ошибки
- `message` - Сообщение об ошибке
- `data` - Дополнительные данные
- `displayMessage` - Сообщение для пользователя

### ErrorHandler

Централизованный обработчик с методами:

#### `handleDatabaseOperation()`
```dart
static DatabaseError handleDatabaseOperation({
  required String operation,
  required dynamic error,
  String? context,
  Map<String, dynamic>? additionalData,
  StackTrace? stackTrace,
})
```

#### `safeExecute()`
```dart
static Future<T> safeExecute<T>({
  required String operation,
  required Future<T> Function() function,
  String? context,
  Map<String, dynamic>? additionalData,
  T? fallbackValue,
})
```

## Использование

### В менеджерах и сервисах

```dart
// Вместо прямого try-catch
try {
  await someOperation();
} catch (e) {
  throw ErrorHandler.handleDatabaseOperation(
    operation: 'operationName',
    error: e,
    context: 'MethodName',
  );
}

// Используйте безопасное выполнение
final result = await ErrorHandler.safeExecute(
  operation: 'getDatabase',
  function: () => database.getData(),
  fallbackValue: <String>[],
);
```

### В провайдерах

```dart
Future<void> createDatabase(CreateDatabaseDto dto) async {
  try {
    state = state.copyWith(error: null);
    final newState = await _manager.createDatabase(dto);
    state = newState;
  } catch (e) {
    final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
    state = state.copyWith(error: errorMessage);
  }
}
```

### В UI

```dart
// Отображение ошибок пользователю
if (state.error != null) {
  return ErrorWidget(message: state.error!);
}
```

## Логирование

### Уровни логирования

- `logDebug()` - Отладочная информация
- `logInfo()` - Информационные сообщения
- `logWarning()` - Предупреждения (некритичные ошибки)
- `logError()` - Ошибки

### Структура логов

```dart
logError(
  'Описание ошибки',
  error: exception,
  stackTrace: stackTrace,
  tag: 'ComponentName',
  data: {
    'operation': 'operationName',
    'context': 'additionalContext',
    'customField': 'customValue',
  },
);
```

### Теги компонентов

- `EncryptedDatabaseManager` - Менеджер базы данных
- `DatabaseHistoryService` - Сервис истории
- `DatabaseStateNotifier` - Провайдер состояния
- `EncryptedDatabase` - Drift база данных
- `ErrorHandler` - Обработчик ошибок

## Паттерны использования

### 1. Операция с безопасным fallback

```dart
Future<List<DatabaseEntry>> getAllDatabases() async {
  return await ErrorHandler.safeExecute(
    operation: 'getAllDatabases',
    function: () => StorageServiceLocator.getAllDatabases(),
    fallbackValue: <DatabaseEntry>[],
    context: 'DatabaseHistoryService',
  );
}
```

### 2. Операция с обработкой ошибок

```dart
Future<void> criticalOperation() async {
  ErrorHandler.logOperationStart(
    operation: 'criticalOperation',
    context: 'ServiceName',
  );

  try {
    await performOperation();
    
    ErrorHandler.logSuccess(
      operation: 'criticalOperation',
      context: 'ServiceName',
    );
  } catch (e, stackTrace) {
    throw ErrorHandler.handleDatabaseOperation(
      operation: 'criticalOperation',
      error: e,
      stackTrace: stackTrace,
      context: 'ServiceName',
    );
  }
}
```

### 3. Некритичная операция

```dart
Future<void> nonCriticalOperation() async {
  try {
    await someOperation();
  } catch (e) {
    logWarning(
      'Некритичная операция завершилась с ошибкой',
      tag: 'ComponentName',
      data: {'error': e.toString()},
    );
    // Продолжаем выполнение без прерывания
  }
}
```

## Конфигурация логирования

Настройка производится через `LoggerConfig`:

```dart
await AppLogger.instance.initialize(
  config: LoggerConfig(
    enableDebug: !MainConstants.isProduction,
    enableInfo: true,
    enableWarning: true,
    enableError: true,
    enableConsoleOutput: true,
    enableFileOutput: true,
    enableCrashReports: true,
  ),
);
```

## Рекомендации

1. **Всегда логируйте начало и завершение критических операций**
2. **Используйте типизированные ошибки вместо общих Exception**
3. **Предоставляйте fallback значения для некритичных операций**
4. **Включайте контекст и дополнительные данные в логи**
5. **Обрабатывайте ошибки на правильном уровне абстракции**
6. **Не логируйте чувствительные данные в production**

## Мониторинг и отладка

- Логи сохраняются в файлы для последующего анализа
- Crash reports создаются автоматически при критических ошибках
- Используйте теги для фильтрации логов по компонентам
- Структурированные данные позволяют легко анализировать ошибки
