# FileEncryptor Provider - Быстрый старт

## Установка

Провайдер уже настроен и готов к использованию. Убедитесь, что:
- ✅ База данных открыта
- ✅ Sodium инициализирован

## Самый простой способ

```dart
// 1. Получить encryptor
final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

// 2. Зашифровать файл
await encryptor.encryptFile(
  input: File('/path/to/file.pdf'),
  output: File('/path/to/encrypted.enc'),
  fileId: 'my_file_123',
  fileExtension: 'pdf',
);

// 3. Расшифровать файл
await encryptor.decryptFile(
  input: File('/path/to/encrypted.enc'),
  output: File('/path/to/decrypted'),
  useOriginalExtension: true,
);
```

## Безопасный способ (с проверкой)

```dart
final result = await ref.read(fileEncryptorProvider.future);

if (result.success) {
  final encryptor = result.data;
  // Работаем с encryptor
} else {
  // Обработка ошибки
  print('Ошибка: ${result.message}');
}
```

## С отслеживанием прогресса

```dart
await encryptor.encryptFile(
  input: inputFile,
  output: outputFile,
  fileId: 'file_id',
  onProgress: (progress) {
    print('${progress.progressPercent}%');
  },
);
```

## Обработка ошибок

```dart
try {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
  await encryptor.encryptFile(...);
} on CryptoException catch (e) {
  print('Crypto error: ${e.message}');
} catch (e) {
  print('Other error: $e');
}
```

---

📖 **Полная документация:** `FILE_ENCRYPTOR_README.md`  
💡 **Примеры:** `file_encryptor_usage_example.dart`
