# Система проверки ключей для безопасного хранилища

## Обзор

Система проверки ключей обеспечивает дополнительный уровень безопасности для зашифрованных хранилищ, гарантируя, что правильный ключ шифрования используется для каждого хранилища. Это защищает от:

- **Повреждения ключей** - обнаружение испорченных ключей шифрования
- **Подмены ключей** - защита от использования неправильных ключей
- **Атак на целостность** - выявление попыток компрометации данных
- **Случайных ошибок** - предотвращение потери данных из-за ошибок в ключах

## Принцип работы

### 1. Регистрация ключа
При создании нового ключа шифрования система:
1. Создает криптографическую подпись ключа используя HMAC-SHA256
2. Дополнительно шифрует тестовое сообщение с помощью AES-GCM
3. Комбинирует результаты для создания уникальной подписи
4. Сохраняет подпись в безопасном хранилище

### 2. Проверка ключа
При каждом доступе к хранилищу система:
1. Получает сохраненную подпись ключа
2. Вычисляет текущую подпись для предоставленного ключа
3. Сравнивает подписи
4. Разрешает или запрещает доступ на основе результата

### 3. Безопасность
- Используется детерминированное шифрование для воспроизводимых подписей
- HMAC-SHA256 обеспечивает криптографическую стойкость
- Подписи хранятся отдельно от основных данных
- Автоматическая очистка чувствительных данных из памяти

## Основные классы

### `KeyVerificationService`
Основной сервис для проверки ключей шифрования:

```dart
final keyVerification = KeyVerificationService(secureStorage: secureStorage);

// Регистрация нового ключа
await keyVerification.registerEncryptionKey(storageKey, encryptionKey);

// Проверка ключа
final isValid = await keyVerification.verifyEncryptionKey(storageKey, encryptionKey);

// Получение статуса
final status = await keyVerification.getVerificationStatus(storageKey);
```

### `EncryptedKeyValueStorage` (обновленный)
Теперь автоматически интегрирует проверку ключей:

```dart
final storage = EncryptedKeyValueStorage(
  secureStorage: secureStorage,
  appName: 'myapp',
  enableCache: true,
);

// Операции автоматически проверяют ключи
await storage.write(storageKey: 'data', key: 'user', data: userData, toJson: (u) => u.toJson());
final user = await storage.read(storageKey: 'data', key: 'user', fromJson: User.fromJson);
```

## Новые методы

### Проверка ключей
```dart
// Проверка ключа конкретного хранилища
final isValid = await storage.verifyStorageKey('user_data');

// Проверка всех ключей
final results = await storage.verifyAllStorageKeys();
// results: {'user_data': true, 'settings': true, 'cache': false}
```

### Диагностика безопасности
```dart
final diagnostics = await storage.performSecurityDiagnostics();

print('Всего хранилищ: ${diagnostics.totalStorages}');
print('Правильных ключей: ${diagnostics.validKeys}');
print('Проблем найдено: ${diagnostics.issues.length}');

for (final issue in diagnostics.issues) {
  print('${issue.severity}: ${issue.description}');
}
```

### Управление ключами
```dart
// Получение статуса верификации
final status = await storage.getKeyVerificationStatus('user_data');
print('Зарегистрирован: ${status.hasSignature}');
print('Дата регистрации: ${status.registrationTime}');

// Принудительная перерегистрация ключа (осторожно!)
await storage.reregisterStorageKey('user_data');

// Список зарегистрированных хранилищ
final storages = await storage.getRegisteredStorages();
```

## Модели данных

### `KeyVerificationStatus`
Информация о статусе верификации:
```dart
class KeyVerificationStatus {
  final String storageKey;
  final bool hasSignature;        // Есть ли зарегистрированная подпись
  final DateTime? registrationTime; // Время регистрации ключа
  final String? signatureHash;    // Хеш подписи для отладки
}
```

### `SecurityDiagnostics`
Результаты диагностики безопасности:
```dart
@freezed
class SecurityDiagnostics with _$SecurityDiagnostics {
  const factory SecurityDiagnostics({
    required int totalStorages,      // Общее количество хранилищ
    required int validKeys,          // Количество правильных ключей
    required int invalidKeys,        // Количество неправильных ключей
    required int intactFiles,        // Количество целых файлов
    required int corruptedFiles,     // Количество поврежденных файлов
    required List<SecurityIssue> issues, // Список найденных проблем
    required DateTime scanTime,      // Время сканирования
  }) = _SecurityDiagnostics;
}
```

### `SecurityIssue`
Описание проблемы безопасности:
```dart
@freezed
class SecurityIssue with _$SecurityIssue {
  const factory SecurityIssue({
    required SecurityIssueType type,        // Тип проблемы
    required String storageKey,             // Ключ хранилища
    required String description,            // Описание проблемы
    required SecurityIssueSeverity severity, // Серьезность
    DateTime? detectedAt,                   // Время обнаружения
  }) = _SecurityIssue;
}

enum SecurityIssueType {
  invalidKey,           // Неправильный ключ
  corruptedFile,        // Поврежденный файл
  corruptedSignature,   // Поврежденная подпись
  missingSignature,     // Отсутствующая подпись
  keyMismatch,          // Несоответствие ключа
}

enum SecurityIssueSeverity {
  low,      // Низкая
  medium,   // Средняя
  high,     // Высокая
  critical, // Критическая
}
```

## Обработка ошибок

### Типы исключений
```dart
try {
  await storage.read(storageKey: 'data', key: 'user', fromJson: User.fromJson);
} on ValidationException catch (e) {
  // Ключ не прошел проверку
  print('Ошибка валидации ключа: ${e.message}');
} on EncryptionException catch (e) {
  // Ошибка шифрования/дешифрования
  print('Ошибка шифрования: ${e.message}');
} on SecureStorageException catch (e) {
  // Общая ошибка хранилища
  print('Ошибка хранилища: ${e.message}');
}
```

### Автоматическое восстановление
Система автоматически пытается восстановиться в следующих случаях:

1. **Отсутствующая подпись** - Если ключ существует, но подпись отсутствует (например, после обновления), система автоматически создает подпись
2. **Поврежденный кэш** - Если ключ в кэше не проходит проверку, он автоматически перезагружается
3. **Несовместимость версий** - Система обеспечивает совместимость с существующими хранилищами

## Миграция существующих хранилищ

Система полностью совместима с существующими хранилищами:

1. **Первый запуск** - При первом доступе к существующему хранилищу автоматически создается подпись ключа
2. **Прозрачная работа** - Существующий код продолжает работать без изменений
3. **Постепенное внедрение** - Проверка ключей включается автоматически для всех операций

## Рекомендации по использованию

### 1. Инициализация приложения
```dart
class AppSecurityManager {
  late final EncryptedKeyValueStorage _storage;
  
  Future<void> initialize() async {
    _storage = EncryptedKeyValueStorage(
      secureStorage: FlutterSecureStorageImpl(),
      appName: 'myapp',
      enableCache: true,
    );
    
    await _storage.initialize();
    
    // Проверяем безопасность при запуске
    final diagnostics = await _storage.performSecurityDiagnostics();
    
    final criticalIssues = diagnostics.issues
        .where((issue) => issue.severity == SecurityIssueSeverity.critical)
        .toList();
    
    if (criticalIssues.isNotEmpty) {
      throw SecurityException('Critical security issues detected!');
    }
  }
}
```

### 2. Регулярный мониторинг
```dart
// Планируем регулярную проверку безопасности
Timer.periodic(Duration(hours: 24), (_) async {
  final diagnostics = await storage.performSecurityDiagnostics();
  
  if (diagnostics.issues.isNotEmpty) {
    // Логируем или отправляем отчет
    logger.warning('Security issues found: ${diagnostics.issues.length}');
  }
});
```

### 3. Обработка критических ошибок
```dart
Future<void> handleSecurityIncident(SecurityIssue issue) async {
  switch (issue.severity) {
    case SecurityIssueSeverity.critical:
      // Блокируем доступ к приложению
      await lockApplication();
      await notifySecurityTeam(issue);
      break;
      
    case SecurityIssueSeverity.high:
      // Показываем предупреждение пользователю
      await showSecurityWarning(issue);
      break;
      
    case SecurityIssueSeverity.medium:
    case SecurityIssueSeverity.low:
      // Логируем для анализа
      logger.warning('Security issue: ${issue.description}');
      break;
  }
}
```

## Производительность

- **Кэширование** - Ключи кэшируются в памяти для быстрого доступа
- **Ленивая проверка** - Подписи проверяются только при необходимости
- **Пакетные операции** - Диагностика выполняется пакетно для эффективности
- **Автоочистка** - Кэш автоматически очищается для экономии памяти

## Безопасность

- **Криптографические стандарты** - Использование проверенных алгоритмов (AES-GCM, HMAC-SHA256)
- **Детерминированность** - Подписи воспроизводимы для одного и того же ключа
- **Изоляция** - Подписи хранятся отдельно от основных данных
- **Очистка памяти** - Автоматическое обнуление чувствительных данных
- **Защита от атак** - Обнаружение попыток подмены ключей и данных

## Заключение

Система проверки ключей предоставляет надежный механизм защиты зашифрованных данных от компрометации и повреждения. Она автоматически интегрируется в существующий код и обеспечивает дополнительный уровень безопасности без значительного влияния на производительность.
