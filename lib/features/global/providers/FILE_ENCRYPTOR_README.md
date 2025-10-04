# FileEncryptor Provider - Документация

## Обзор

`fileEncryptorProvider` - это Riverpod провайдер для шифрования/дешифрования файлов с использованием AEAD (Authenticated Encryption with Associated Data) через библиотеку libsodium.

**Ключевые особенности:**
- ✅ **AutoDispose** - автоматическое освобождение ресурсов
- ✅ **Безопасное хранение** - ключ в `SecureKey` (защищенная память)
- ✅ **Streaming шифрование** - не загружает весь файл в память
- ✅ **Аутентификация** - встроенная проверка целостности данных
- ✅ **Метаданные** - сохраняет fileId и расширение файла

## Требования

1. База данных должна быть **открыта**
2. Sodium должен быть **инициализирован**
3. В таблице `HoplixiMeta` должен быть ключ шифрования (`attachmentKey` в base64)

## Провайдеры

### 1. `fileEncryptorProvider`

Основной провайдер, возвращающий `FileEncryptorResult`.

**Когда использовать:**
- Нужна проверка успешности инициализации
- Требуется обработка ошибок без исключений
- Для критичных операций

```dart
final encryptorResult = await ref.read(fileEncryptorProvider.future);

if (encryptorResult.success) {
  final encryptor = encryptorResult.data;
  // Используем encryptor...
} else {
  // Обработка ошибки
  ToastHelper.error(encryptorResult.message ?? 'Ошибка инициализации');
}
```

### 2. `fileEncryptorInstanceProvider`

Упрощенный провайдер, сразу возвращающий `AeadFileEncryptor`.

**Когда использовать:**
- Для упрощения кода
- Когда уверены, что БД открыта
- С блоком try-catch

```dart
try {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
  await encryptor.encryptFile(...);
} catch (e) {
  // Обработка ошибки
}
```

## Основные операции

### Шифрование файла

```dart
final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

await encryptor.encryptFile(
  input: File('/path/to/document.pdf'),
  output: File('/path/to/encrypted.enc'),
  fileId: 'document_123',
  fileExtension: 'pdf',
  chunkSize: 64 * 1024, // опционально, по умолчанию 64 KB
  onProgress: (progress) {
    print('${progress.progressPercent}%');
  },
);
```

**Параметры:**
- `input` - исходный файл для шифрования
- `output` - выходной зашифрованный файл
- `fileId` - идентификатор файла (сохраняется в зашифрованном виде)
- `fileExtension` - расширение файла (опционально)
- `chunkSize` - размер блока для потокового шифрования
- `onProgress` - callback для отслеживания прогресса

### Дешифрование файла

```dart
final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

final extension = await encryptor.decryptFile(
  input: File('/path/to/encrypted.enc'),
  output: File('/path/to/decrypted'),
  expectedFileId: 'document_123', // опционально - проверка ID
  useOriginalExtension: true, // автоматически добавит расширение
  onProgress: (progress) {
    print('${progress.progressPercent}%');
  },
);

print('Оригинальное расширение: $extension');
```

**Параметры:**
- `input` - зашифрованный файл
- `output` - выходной расшифрованный файл (или директория)
- `expectedFileId` - ожидаемый ID файла для проверки
- `useOriginalExtension` - автоматически добавить оригинальное расширение
- `chunkSize` - размер блока для потокового дешифрования
- `onProgress` - callback для отслеживания прогресса

## Использование в UI

### В Consumer Widget

```dart
class FileEncryptionButton extends ConsumerWidget {
  const FileEncryptionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encryptorAsync = ref.watch(fileEncryptorProvider);

    return encryptorAsync.when(
      data: (result) {
        if (!result.success) {
          return Text('Ошибка: ${result.message}');
        }
        
        return ElevatedButton(
          onPressed: () async {
            final encryptor = result.data;
            // Шифруем файл...
          },
          child: const Text('Зашифровать'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }
}
```

### В StatefulWidget

```dart
class FileEncryptionScreen extends ConsumerStatefulWidget {
  const FileEncryptionScreen({super.key});

  @override
  ConsumerState<FileEncryptionScreen> createState() => _FileEncryptionScreenState();
}

class _FileEncryptionScreenState extends ConsumerState<FileEncryptionScreen> {
  double _progress = 0.0;

  Future<void> _encryptFile() async {
    try {
      final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
      
      await encryptor.encryptFile(
        input: File('/path/to/file'),
        output: File('/path/to/encrypted'),
        fileId: 'my_file',
        onProgress: (progress) {
          setState(() {
            _progress = progress.progress;
          });
        },
      );
      
      ToastHelper.success('Файл зашифрован');
    } catch (e) {
      ToastHelper.error('Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress),
        ElevatedButton(
          onPressed: _encryptFile,
          child: const Text('Зашифровать'),
        ),
      ],
    );
  }
}
```

## Использование в сервисах

```dart
class AttachmentEncryptionService {
  final Ref ref;

  AttachmentEncryptionService(this.ref);

  Future<ServiceResult<String>> encryptAttachment({
    required File inputFile,
    required String attachmentId,
  }) async {
    try {
      final encryptorResult = await ref.read(fileEncryptorProvider.future);
      
      if (!encryptorResult.success) {
        return ServiceResult.error(
          encryptorResult.message ?? 'Ошибка инициализации шифрования',
        );
      }

      final encryptor = encryptorResult.data;
      final outputFile = File('/encrypted/attachments/$attachmentId.enc');

      await encryptor.encryptFile(
        input: inputFile,
        output: outputFile,
        fileId: attachmentId,
        fileExtension: extension(inputFile.path),
      );

      return ServiceResult.success(
        data: outputFile.path,
        message: 'Файл зашифрован успешно',
      );
    } catch (e, stackTrace) {
      logError('Ошибка шифрования attachment', error: e, stackTrace: stackTrace);
      return ServiceResult.error('Не удалось зашифровать файл: $e');
    }
  }
}
```

## Обновление провайдера

После смены БД или изменения ключа шифрования:

```dart
// Инвалидировать провайдер
ref.invalidate(fileEncryptorProvider);

// Следующее чтение создаст новый экземпляр с актуальным ключом
final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
```

## Обработка ошибок

### CryptoException

Выбрасывается при ошибках шифрования/дешифрования:

```dart
try {
  await encryptor.encryptFile(...);
} on CryptoException catch (e) {
  print('Криптографическая ошибка: ${e.message}');
} catch (e) {
  print('Другая ошибка: $e');
}
```

### Проверка инициализации

```dart
final result = await ref.read(fileEncryptorProvider.future);

switch (result.success) {
  case true:
    final encryptor = result.data;
    // Работаем с encryptor
    break;
  case false:
    print('Ошибка: ${result.message}');
    // База не открыта или ключ недоступен
    break;
}
```

## Безопасность

### ✅ Что делается автоматически:

- Ключ хранится в `SecureKey` (защищенная память libsodium)
- Автоматическая очистка ключа при dispose провайдера
- Логи не содержат чувствительных данных
- Аутентификация данных (AEAD)
- Проверка целостности файла

### ⚠️ Что нужно учитывать:

- Ключ шифрования из БД должен храниться надежно
- Удаленные зашифрованные файлы нельзя восстановить без ключа
- Поврежденные файлы не расшифруются (встроенная проверка целостности)

## Производительность

- **Streaming**: файл обрабатывается блоками (не загружается в память целиком)
- **Chunk size**: по умолчанию 64 KB, можно настроить
- **Рекомендации**:
  - Для больших файлов (>100 MB): chunk size 256 KB или больше
  - Для малых файлов (<1 MB): chunk size 32 KB или меньше
  - Используйте `onProgress` для UI feedback

## Примеры кода

См. файл `file_encryptor_usage_example.dart` для полных примеров использования.

## Архитектура

```
fileEncryptorProvider (AsyncNotifier)
  ↓
  ├─ sodiumProvider (инициализация libsodium)
  ├─ hoplixiStoreManagerProvider (доступ к БД)
  └─ FileEncryptorResult
       ├─ success: bool
       ├─ errorMessage: String?
       └─ encryptor: AeadFileEncryptor?

fileEncryptorInstanceProvider (FutureProvider)
  ↓
  └─ AeadFileEncryptor (прямой доступ или exception)
```

## Связанные файлы

- `lib/core/lib/sodium_file_encryptor/aead_file_encryptor.dart` - основной класс шифрования
- `lib/features/global/providers/sodium_provider.dart` - инициализация Sodium
- `lib/hoplixi_store/providers/hoplixi_store_providers.dart` - провайдеры БД
- `lib/hoplixi_store/tables/hoplixi_meta.dart` - таблица с ключом шифрования

---

**Последнее обновление:** 4 октября 2025 г.
