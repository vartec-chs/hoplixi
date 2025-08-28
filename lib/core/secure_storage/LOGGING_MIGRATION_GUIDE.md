# Руководство по миграции на новую систему логирования и обработки ошибок

## Обзор изменений

В модуль `secure_storage` была интегрирована централизованная система логирования и обработки ошибок, аналогичная той, что используется в `encrypted_database`. Это обеспечивает:

- Единообразное логирование всех операций
- Структурированную обработку ошибок
- Детальную диагностику проблем безопасности
- Автоматическое отслеживание критических событий

## Основные компоненты

### 1. SecureStorageError
Заменяет старые исключения (`SecureStorageException`, `EncryptionException`, etc.) на типобезопасные ошибки с дополнительной информацией:

```dart
// ❌ Старый код
try {
  // операция
} catch (SecureStorageException e) {
  print('Error: ${e.message}');
}

// ✅ Новый код
try {
  // операция
} on SecureStorageError catch (e) {
  print('Error: ${e.displayMessage}');
  print('Type: ${e.securityType}');
  print('Severity: ${e.severity}');
  
  if (e.requiresImmediateAttention) {
    // Критическая ошибка - требует немедленного внимания
  }
}
```

### 2. SecureStorageErrorHandler
Централизованный обработчик для всех типов ошибок:

```dart
// Безопасное выполнение операций
final result = await SecureStorageErrorHandler.safeExecute<String>(
  operation: 'read_user_data',
  function: () async {
    return await storage.read<String>(
      storageKey: 'user',
      key: 'name',
      fromJson: (json) => json['value'],
    );
  },
  fallbackValue: 'Unknown User',
);
```

### 3. Автоматическое логирование
Все операции теперь автоматически логируются:

```dart
// Эти операции автоматически создают лог-записи
await storage.write(storageKey: 'test', key: 'data', data: 'value', toJson: (v) => {'value': v});
await storage.read(storageKey: 'test', key: 'data', fromJson: (json) => json['value']);
```

## Миграция существующего кода

### Шаг 1: Обновление обработки ошибок

```dart
// ❌ Старый код
try {
  await storage.write(/* ... */);
} catch (SecureStorageException e) {
  logger.error('Storage error: ${e.message}');
  // Обработка ошибки
}

// ✅ Новый код
try {
  await storage.write(/* ... */);
} on SecureStorageError catch (e) {
  final analysis = SecureStorageErrorHandler.analyzeError(e);
  
  // Логирование происходит автоматически в SecureStorageErrorHandler
  
  if (analysis.shouldNotifyUser) {
    showUserNotification(e.displayMessage);
  }
  
  if (analysis.requiresImmediateAttention) {
    handleCriticalError(e);
  }
}
```

### Шаг 2: Использование safeExecute

```dart
// ❌ Старый код
String userData;
try {
  userData = await storage.read(/* ... */);
} catch (e) {
  userData = 'default';
  logger.warning('Failed to read user data, using default');
}

// ✅ Новый код
final userData = await SecureStorageErrorHandler.safeExecute<String>(
  operation: 'read_user_data',
  function: () => storage.read(/* ... */),
  fallbackValue: 'default',
);
```

### Шаг 3: Мониторинг безопасности

```dart
// Добавьте периодическую диагностику безопасности
Timer.periodic(Duration(hours: 1), (timer) async {
  try {
    final diagnostics = await storage.performSecurityDiagnostics();
    
    if (diagnostics.issues.isNotEmpty) {
      for (final issue in diagnostics.issues) {
        if (issue.severity == SecurityIssueSeverity.critical) {
          // Критическая проблема - немедленное уведомление
          await notifySecurityTeam(issue);
        }
      }
    }
  } catch (e) {
    logError('Security diagnostics failed', error: e);
  }
});
```

## Новые возможности

### 1. Детальная диагностика

```dart
// Получение полной информации о безопасности
final diagnostics = await storage.performSecurityDiagnostics();

print('Storages: ${diagnostics.totalStorages}');
print('Valid keys: ${diagnostics.validKeys}');
print('Security issues: ${diagnostics.issues.length}');

// Анализ каждой проблемы
for (final issue in diagnostics.issues) {
  print('Issue: ${issue.description}');
  print('Severity: ${issue.severity}');
  print('Type: ${issue.type}');
}
```

### 2. Верификация ключей

```dart
// Проверка правильности ключей для всех хранилищ
final keyResults = await storage.verifyAllStorageKeys();

for (final entry in keyResults.entries) {
  if (!entry.value) {
    logError('Invalid key detected for storage: ${entry.key}');
    // Возможно потребуется восстановление ключа
  }
}
```

### 3. Проверка статуса верификации

```dart
// Получение статуса верификации для конкретного хранилища
final status = await storage.getKeyVerificationStatus('user_data');

if (!status.hasSignature) {
  logWarning('Storage has no verification signature');
} else if (!status.isValid) {
  logError('Storage verification failed - possible security breach');
}
```

## Типы ошибок и их обработка

### Критические ошибки (требуют немедленного внимания)

```dart
// keyNotFound, keyValidationFailed, securityBreach, initializationFailed
if (error.requiresImmediateAttention) {
  // Немедленное уведомление пользователя
  // Возможно потребуется блокировка приложения
  // Сбор диагностической информации
}
```

### Ошибки высокой важности

```dart
// encryptionFailed, decryptionFailed, fileCorrupted
if (error.severity == SecuritySeverity.high) {
  // Уведомление пользователя
  // Попытка восстановления из резервной копии
  // Дополнительная проверка безопасности
}
```

### Обычные ошибки

```dart
// fileAccessFailed, operationFailed, validationFailed
if (error.severity == SecuritySeverity.medium || error.severity == SecuritySeverity.low) {
  // Повторная попытка операции
  // Логирование для анализа
  // Использование fallback значений
}
```

## Лучшие практики

### 1. Всегда используйте safeExecute для критических операций

```dart
// ✅ Рекомендуется
final result = await SecureStorageErrorHandler.safeExecute(
  operation: 'critical_operation',
  function: () => performCriticalOperation(),
  fallbackValue: defaultValue,
);
```

### 2. Анализируйте ошибки перед обработкой

```dart
// ✅ Рекомендуется
on SecureStorageError catch (e) {
  final analysis = SecureStorageErrorHandler.analyzeError(e);
  
  // Принимайте решения на основе анализа
  if (analysis.isSecurityRelated) {
    handleSecurityIssue(e);
  } else {
    handleRegularError(e);
  }
}
```

### 3. Регулярно выполняйте диагностику безопасности

```dart
// ✅ Рекомендуется
// В приложении или при старте
await performSecurityCheck();

async void performSecurityCheck() {
  final diagnostics = await storage.performSecurityDiagnostics();
  
  if (diagnostics.issues.isNotEmpty) {
    logWarning('Security issues detected: ${diagnostics.issues.length}');
    // Анализ и обработка проблем
  }
}
```

### 4. Используйте контекстное логирование

```dart
// ✅ Рекомендуется
SecureStorageErrorHandler.logOperationStart(
  operation: 'user_login',
  context: 'authentication',
  additionalData: {'userId': userId},
);

// ... выполнение операции ...

SecureStorageErrorHandler.logSuccess(
  operation: 'user_login',
  context: 'authentication',
  additionalData: {'userId': userId},
);
```

## Примеры интеграции

### Для пользовательских данных

```dart
class UserDataService {
  final EncryptedKeyValueStorage _storage;
  
  Future<UserProfile?> loadUserProfile(String userId) async {
    return SecureStorageErrorHandler.safeExecute<UserProfile?>(
      operation: 'load_user_profile',
      function: () async {
        return await _storage.read<UserProfile>(
          storageKey: 'user_profiles',
          key: userId,
          fromJson: UserProfile.fromJson,
        );
      },
      context: 'user_data_service',
      additionalData: {'userId': userId},
      fallbackValue: null,
    );
  }
}
```

### Для настроек приложения

```dart
class SettingsService {
  final EncryptedKeyValueStorage _storage;
  
  Future<AppSettings> loadSettings() async {
    return SecureStorageErrorHandler.safeExecute<AppSettings>(
      operation: 'load_app_settings',
      function: () async {
        final settings = await _storage.read<AppSettings>(
          storageKey: 'app_settings',
          key: 'main',
          fromJson: AppSettings.fromJson,
        );
        return settings ?? AppSettings.defaultSettings();
      },
      fallbackValue: AppSettings.defaultSettings(),
    );
  }
}
```

## Обратная совместимость

Старые исключения помечены как `@Deprecated`, но продолжают работать для обратной совместимости:

```dart
// Продолжает работать, но рекомендуется обновить
try {
  // операция
} catch (SecureStorageException e) {
  // старая обработка
}
```

Однако рекомендуется как можно скорее перейти на новую систему для получения всех преимуществ улучшенной обработки ошибок и логирования.
