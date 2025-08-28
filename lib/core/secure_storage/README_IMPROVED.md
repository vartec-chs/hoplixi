# Secure Storage - Безопасное хранилище для менеджера паролей

Этот модуль предоставляет высокобезопасное key-value хранилище, специально разработанное для хранения критически важных данных, таких как пароли, банковские карты и конфиденциальные заметки.

## Основные функции безопасности

### 🔐 Криптография
- **AES-256-GCM** - современный алгоритм шифрования с аутентификацией
- **PBKDF2** - растяжение ключей с 100,000 итераций
- **HMAC-SHA256** - защита от модификации данных
- **Криптографически стойкий ГСЧ** - Fortuna для генерации ключей

### 🛡️ Защита от атак
- **Защита от replay-атак** - временные метки в зашифрованных данных
- **Проверка целостности** - контрольные суммы и HMAC
- **Защита памяти** - автоматическая очистка чувствительных данных
- **Безопасное удаление** - перезапись файлов случайными данными (DOD 5220.22-M)

### 💾 Надежность данных
- **Атомарные операции** - запись через временные файлы
- **Проверка версий** - совместимость форматов данных
- **Восстановление** - устойчивость к повреждению файлов
- **Резервное копирование** - экспорт зашифрованных данных

## Архитектура

```
EncryptedKeyValueStorage
├── Шифрование (AES-256-GCM)
├── Управление ключами (PBKDF2 + SecureStorage)
├── Кэширование (с автоочисткой)
├── Проверка целостности (HMAC + checksums)
└── Безопасное удаление (3-pass overwrite)
```

## Использование

### Базовая инициализация

```dart
final storage = EncryptedKeyValueStorage(
  secureStorage: FlutterSecureStorageImpl(),
  appName: 'MyPasswordManager',
  enableCache: true,
);

await storage.initialize();
```

### Сохранение данных

```dart
final passwordEntry = PasswordEntry(
  id: 'unique_id',
  title: 'Gmail Account',
  username: 'user@gmail.com',
  encryptedPassword: PasswordCrypto.encryptPassword('secret123', masterKey),
  url: 'https://gmail.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await storage.write<PasswordEntry>(
  storageKey: 'passwords',
  key: passwordEntry.id,
  data: passwordEntry,
  toJson: (entry) => entry.toJson(),
);
```

### Чтение данных

```dart
final password = await storage.read<PasswordEntry>(
  storageKey: 'passwords',
  key: 'unique_id',
  fromJson: (json) => PasswordEntry.fromJson(json),
);
```

### Получение всех записей

```dart
final allPasswords = await storage.readAll<PasswordEntry>(
  storageKey: 'passwords',
  fromJson: (json) => PasswordEntry.fromJson(json),
);
```

## Модели данных

### PasswordEntry
Основная модель для хранения паролей:
```dart
PasswordEntry(
  id: 'unique_id',
  title: 'Account Name',
  username: 'user@example.com',
  encryptedPassword: 'encrypted_data',
  url: 'https://example.com',
  notes: 'Additional notes',
  category: 'Social',
  tags: ['important', 'work'],
  customFields: {'Security Question': 'encrypted_answer'},
  isFavorite: true,
  expiresAt: DateTime(2024, 12, 31),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

### SecureNote
Для хранения конфиденциальных заметок:
```dart
SecureNote(
  id: 'note_id',
  title: 'Important Information',
  encryptedContent: 'encrypted_note_content',
  category: 'Personal',
  tags: ['private'],
  isFavorite: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

### CreditCardEntry
Для хранения данных банковских карт:
```dart
CreditCardEntry(
  id: 'card_id',
  cardholderName: 'John Doe',
  encryptedNumber: 'encrypted_card_number',
  encryptedCvv: 'encrypted_cvv',
  expiryMonth: '12',
  expiryYear: '2025',
  issuer: 'Visa',
  nickname: 'Main Card',
  notes: 'Personal card',
  isFavorite: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

## Настройки безопасности

```dart
final settings = SecuritySettings(
  autoLockTimeoutSeconds: 300,     // Автоблокировка через 5 минут
  requireAuthOnStartup: true,      // Требовать аутентификацию при запуске
  enableEncryption: true,          // Включить шифрование
  maxFailedAttempts: 5,           // Максимум неудачных попыток
  enableSecureDelete: true,        // Безопасное удаление файлов
  enableIntegrityChecks: true,     // Проверка целостности
  enableDebugLogging: false,       // Отладочные логи
);

await storage.write(
  storageKey: 'settings',
  key: 'security',
  data: settings,
  toJson: (s) => s.toJson(),
);
```

## Продвинутые функции

### Проверка целостности
```dart
final integrityResults = await storage.verifyAllStoragesIntegrity();
print('Passwords storage: ${integrityResults['passwords']}');
print('Notes storage: ${integrityResults['secure_notes']}');
```

### Статистика хранилища
```dart
final passwordManager = PasswordManagerExample();
final stats = await passwordManager.getStorageStatistics();
print('Total items: ${stats['item_counts']['total']}');
print('Total size: ${stats['storage_sizes']['total']} bytes');
```

### Резервное копирование
```dart
final backup = await passwordManager.createBackup();
// backup содержит зашифрованные данные, безопасные для хранения
```

### Очистка кэша и ресурсов
```dart
await storage.clearCache();    // Очистка кэша для экономии памяти
storage.dispose();             // Освобождение всех ресурсов
```

## Безопасность в производстве

### Рекомендации по развертыванию

1. **Мастер-пароль**: Используйте сильный мастер-пароль для дополнительного шифрования
2. **Биометрия**: Интегрируйте с биометрической аутентификацией
3. **Резервные копии**: Создавайте зашифрованные резервные копии
4. **Аудит**: Регулярно проверяйте целостность данных
5. **Обновления**: Следите за обновлениями безопасности

### Дополнительные меры

```dart
// Включение дополнительного шифрования с мастер-паролем
final derivedKey = storage.deriveKeyFromPassword(masterPassword, salt);

// Проверка целостности при запуске
final integrityOk = await storage.verifyAllStoragesIntegrity();
if (!integrityOk.values.every((valid) => valid)) {
  // Обработка нарушения целостности
}

// Автоматическая очистка кэша
Timer.periodic(Duration(minutes: 5), (_) => storage.clearCache());
```

## Обработка ошибок

```dart
try {
  await storage.write(/* ... */);
} on EncryptionException catch (e) {
  // Ошибка шифрования/дешифрования
  print('Encryption error: $e');
} on FileAccessException catch (e) {
  // Ошибка доступа к файлу
  print('File access error: $e');
} on ValidationException catch (e) {
  // Ошибка проверки целостности
  print('Validation error: $e');
} on SecureStorageException catch (e) {
  // Общая ошибка хранилища
  print('Storage error: $e');
}
```

## Производительность

- **Кэширование**: Автоматическое кэширование с очисткой каждые 5 минут
- **Ленивая загрузка**: Данные загружаются только при необходимости
- **Атомарные операции**: Минимизация блокировок файловой системы
- **Оптимизация памяти**: Автоматическая очистка чувствительных данных

## Совместимость

- ✅ Windows
- ✅ macOS  
- ✅ Linux
- ✅ Android
- ✅ iOS
- ✅ Web (с ограничениями)

## Зависимости

- `crypto` - SHA256, HMAC
- `pointycastle` - AES-GCM, PBKDF2
- `flutter_secure_storage` - Хранение ключей шифрования
- `path_provider` - Доступ к файловой системе
- `freezed` - Immutable модели данных

## Что было улучшено

### 1. Криптография
- ✅ Заменен простой XOR на **AES-256-GCM**
- ✅ Добавлено **PBKDF2** для растяжения ключей
- ✅ Использование **криптографически стойкого ГСЧ**
- ✅ **HMAC-SHA256** для защиты от модификации

### 2. Защита от атак
- ✅ **Временные метки** против replay-атак
- ✅ **Проверка целостности** с несколькими уровнями
- ✅ **Защита памяти** - автоочистка чувствительных данных
- ✅ **Безопасное удаление** файлов (DOD 5220.22-M)

### 3. Надежность
- ✅ **Атомарные операции** записи
- ✅ **Версионирование** форматов данных
- ✅ **Проверка целостности** всех хранилищ
- ✅ **Экспорт зашифрованных** резервных копий

### 4. Модели для менеджера паролей
- ✅ **PasswordEntry** - хранение паролей
- ✅ **SecureNote** - конфиденциальные заметки
- ✅ **CreditCardEntry** - банковские карты
- ✅ **SecuritySettings** - настройки безопасности

### 5. Дополнительные функции
- ✅ **Статистика хранилища** - размеры и количество
- ✅ **Поиск и фильтрация** данных
- ✅ **Управление ресурсами** - dispose() и clearCache()
- ✅ **Мониторинг целостности** всех файлов

Это хранилище теперь готово для использования в профессиональном менеджере паролей с высокими требованиями к безопасности.
