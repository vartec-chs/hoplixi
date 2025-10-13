# FileEncryptorProvider - Краткий обзор

## 🎯 Назначение

Центральный менеджер для безопасной работы с файлами в Hoplixi:
- Шифрование/дешифрование файлов через AeadFileEncryptor (libsodium)
- Автоматическое отслеживание расшифрованных временных файлов
- **Автоматическое удаление при таймауте неактивности**
- Защита от утечки данных

## 🔐 Интеграция с AppLifecycleProvider

```dart
// В FileEncryptorNotifier автоматически:
ref.listen<AppLifecycleStateData>(
  appLifecycleProvider,
  (previous, next) {
    if (next.dataCleared) {
      cleanup(); // Удаляет все временные файлы
    }
  },
);
```

### Цепочка безопасности

1. Пользователь сворачивает приложение
2. `AppLifecycleNotifier` запускает таймер (120 секунд)
3. Таймер истекает → `dataCleared = true`
4. `FileEncryptorNotifier` автоматически удаляет все временные файлы
5. БД закрывается, приложение требует повторную аутентификацию

**Результат**: Никаких расшифрованных данных не остаётся на устройстве ✓

## 📝 Быстрый старт

### Инициализация

```dart
final manager = ref.read(fileEncryptorProvider.notifier);
await manager.initialize();
```

### Шифрование

```dart
final success = await manager.encryptFile(
  input: File('/path/to/document.pdf'),
  output: File('/encrypted/file.enc'),
  fileId: 'doc_${uuid.v4()}',
  fileExtension: 'pdf',
);
```

### Дешифрование (с автоотслеживанием)

```dart
final extension = await manager.decryptFile(
  input: File('/encrypted/file.enc'),
  output: File('/tmp/temp_file'),
  trackForCleanup: true, // ← Автоматическое удаление
);
```

### Ручная очистка

```dart
// Удалить все временные файлы
final deletedCount = await manager.cleanup();

// Удалить конкретный файл
await manager.removeDecryptedFile('/tmp/specific_file.pdf');
```

## 🛡️ Безопасность

### ✅ Что делает провайдер автоматически

- Отслеживает все расшифрованные файлы
- Удаляет файлы при таймауте неактивности
- Удаляет файлы при dispose провайдера
- Удаляет файлы при закрытии приложения
- Удаляет файлы при logout

### ⚠️ Что нужно помнить

- Используйте `trackForCleanup: true` для временных файлов
- Используйте `trackForCleanup: false` для постоянных файлов
- Не логируйте пути расшифрованных файлов
- Проверяйте `isInitialized` перед использованием

## 📊 Мониторинг

```dart
// Просмотр состояния
final state = ref.watch(fileEncryptorProvider);

print('Инициализирован: ${state.isInitialized}');
print('Временных файлов: ${state.decryptedFiles.length}');
print('Ошибка: ${state.errorMessage}');

// Или через notifier
final manager = ref.read(fileEncryptorProvider.notifier);
print('Файлы: ${manager.decryptedFiles}');
```

## 🔄 Жизненный цикл

```
┌─────────────────────────────────────────┐
│  Приложение активно                     │
│  - Файлы дешифруются и отслеживаются   │
└─────────────────┬───────────────────────┘
                  │
                  │ Пользователь сворачивает приложение
                  ▼
┌─────────────────────────────────────────┐
│  Таймер неактивности (120 сек)          │
│  - AppLifecycleNotifier отсчитывает     │
└─────────────────┬───────────────────────┘
                  │
                  │ Таймер истекает
                  ▼
┌─────────────────────────────────────────┐
│  Автоматическая очистка                 │
│  1. AppLifecycleNotifier:               │
│     dataCleared = true                  │
│  2. FileEncryptorNotifier:              │
│     cleanup() - удаление всех файлов    │
│  3. Закрытие БД                         │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Приложение заблокировано               │
│  - Требуется повторная аутентификация   │
│  - Никаких временных файлов             │
└─────────────────────────────────────────┘
```

## 🧪 Тестирование

```dart
// Проверка автоматической очистки
final manager = ref.read(fileEncryptorProvider.notifier);
final lifecycle = ref.read(appLifecycleProvider.notifier);

await manager.decryptFile(...);
print('Файлов: ${manager.decryptedFiles.length}'); // 1

await lifecycle.clearAll(); // Симуляция таймаута
await Future.delayed(Duration(milliseconds: 100));

print('Файлов: ${manager.decryptedFiles.length}'); // 0 ✓
```

## 📚 Полная документация

См. `file_encryptor_usage_example.md` для детальных примеров и best practices.

## ⚙️ Конфигурация

Настройки в `AppLifecycleNotifier`:
- `_inactivityTimeoutSeconds = 120` - таймаут неактивности

## 🔗 Связанные провайдеры

- `AppLifecycleProvider` - управление жизненным циклом и таймером
- `SodiumProvider` - криптографическая библиотека
- `HoplixiStoreProvider` - база данных и ключ шифрования

## ✨ Ключевые особенности

1. **Notifier API** - синхронный провайдер согласно архитектуре Hoplixi
2. **Автоматическая безопасность** - интеграция с lifecycle
3. **Отслеживание файлов** - полный контроль над временными данными
4. **Zero-trust** - файлы удаляются автоматически при любом подозрительном событии
