// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/lib/sodium_file_encryptor/aead_file_encryptor.dart';
import 'package:hoplixi/features/global/providers/file_encryptor_provider.dart';

/// Примеры использования fileEncryptorProvider
///
/// ВАЖНО: Этот файл содержит только примеры кода и не должен выполняться.
/// Скопируйте нужные примеры в ваш код.

// ============================================================================
// ПРИМЕР 1: Безопасное использование с проверкой результата
// ============================================================================
Future<void> example1SafeUsage(WidgetRef ref) async {
  // Получаем результат инициализации
  final encryptorResult = await ref.read(fileEncryptorProvider.future);

  // Проверяем успешность инициализации
  if (!encryptorResult.success) {
    print('Ошибка: ${encryptorResult.message}');
    return;
  }

  // Безопасно получаем экземпляр encryptor
  final encryptor = encryptorResult.data;

  // Используем encryptor для шифрования
  await encryptor.encryptFile(
    input: File('/path/to/document.pdf'),
    output: File('/path/to/encrypted/document.enc'),
    fileId: 'document_123',
    fileExtension: 'pdf',
  );

  print('Файл успешно зашифрован!');
}

// ============================================================================
// ПРИМЕР 2: Упрощенное использование (может выбросить исключение)
// ============================================================================
Future<void> example2SimpleUsage(WidgetRef ref) async {
  try {
    // Прямое получение экземпляра (выбросит исключение при ошибке)
    final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

    // Шифруем файл
    await encryptor.encryptFile(
      input: File('/path/to/input.txt'),
      output: File('/path/to/output.enc'),
      fileId: 'my_secret_file',
      fileExtension: 'txt',
    );

    print('Шифрование завершено');
  } catch (e) {
    print('Ошибка шифрования: $e');
  }
}

// ============================================================================
// ПРИМЕР 3: Шифрование с отслеживанием прогресса
// ============================================================================
Future<void> example3WithProgress(WidgetRef ref) async {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

  await encryptor.encryptFile(
    input: File('/path/to/large_file.zip'),
    output: File('/path/to/encrypted.enc'),
    fileId: 'backup_2024',
    fileExtension: 'zip',
    chunkSize: 256 * 1024, // 256 KB chunks
    onProgress: (progress) {
      print(
        'Прогресс: ${progress.progressPercent}% '
        '(${progress.processedBytes}/${progress.totalBytes} байт)',
      );
    },
  );
}

// ============================================================================
// ПРИМЕР 4: Дешифрование файла
// ============================================================================
Future<void> example4Decryption(WidgetRef ref) async {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

  // Дешифруем с автоматическим восстановлением расширения
  final originalExtension = await encryptor.decryptFile(
    input: File('/path/to/encrypted.enc'),
    output: File('/path/to/decrypted'),
    useOriginalExtension: true,
  );

  print('Файл расшифрован. Оригинальное расширение: $originalExtension');
}

// ============================================================================
// ПРИМЕР 5: Дешифрование с проверкой ID файла
// ============================================================================
Future<void> example5DecryptionWithIdCheck(WidgetRef ref) async {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

  try {
    await encryptor.decryptFile(
      input: File('/path/to/encrypted.enc'),
      output: File('/path/to/decrypted.pdf'),
      expectedFileId: 'document_123', // Проверка ID
    );
    print('Файл успешно расшифрован и проверен');
  } on CryptoException catch (e) {
    print('Ошибка дешифрования: ${e.message}');
  }
}

// ============================================================================
// ПРИМЕР 6: Использование в сервисе
// ============================================================================
class FileEncryptionService {
  final Ref ref;

  FileEncryptionService(this.ref);

  /// Шифрует файл и возвращает путь к зашифрованному файлу
  Future<String?> encryptUserFile({
    required String inputPath,
    required String outputPath,
    required String fileId,
    String? extension,
  }) async {
    try {
      final encryptorResult = await ref.read(fileEncryptorProvider.future);

      if (!encryptorResult.success) {
        print(
          'Не удалось инициализировать шифрование: '
          '${encryptorResult.message}',
        );
        return null;
      }

      final encryptor = encryptorResult.data;

      await encryptor.encryptFile(
        input: File(inputPath),
        output: File(outputPath),
        fileId: fileId,
        fileExtension: extension,
      );

      return outputPath;
    } catch (e) {
      print('Ошибка шифрования файла: $e');
      return null;
    }
  }

  /// Дешифрует файл и возвращает путь к расшифрованному файлу
  Future<String?> decryptUserFile({
    required String inputPath,
    required String outputPath,
  }) async {
    try {
      final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

      await encryptor.decryptFile(
        input: File(inputPath),
        output: File(outputPath),
        useOriginalExtension: true,
      );

      return outputPath;
    } catch (e) {
      print('Ошибка дешифрования файла: $e');
      return null;
    }
  }
}

// ============================================================================
// ПРИМЕР 7: Обновление провайдера при смене БД
// ============================================================================
Future<void> example7RefreshOnDatabaseChange(WidgetRef ref) async {
  // После открытия новой БД или смены ключа
  ref.invalidate(fileEncryptorProvider);

  // Теперь провайдер пересоздастся с новым ключом
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
}

// ============================================================================
// ПРИМЕР 8: Использование в Consumer Widget
// ============================================================================
/*
class FileEncryptionWidget extends ConsumerWidget {
  const FileEncryptionWidget({super.key});

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
            // Используем encryptor...
          },
          child: const Text('Зашифровать файл'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка загрузки: $error'),
    );
  }
}
*/

// ============================================================================
// ПРИМЕР 9: Пакетное шифрование файлов
// ============================================================================
Future<void> example9BatchEncryption(WidgetRef ref) async {
  final encryptor = await ref.read(fileEncryptorInstanceProvider.future);

  final filesToEncrypt = [
    {'input': '/file1.txt', 'output': '/enc/file1.enc', 'id': 'file_1'},
    {'input': '/file2.pdf', 'output': '/enc/file2.enc', 'id': 'file_2'},
    {'input': '/file3.jpg', 'output': '/enc/file3.enc', 'id': 'file_3'},
  ];

  for (final fileInfo in filesToEncrypt) {
    try {
      await encryptor.encryptFile(
        input: File(fileInfo['input']!),
        output: File(fileInfo['output']!),
        fileId: fileInfo['id']!,
      );
      print('Зашифрован: ${fileInfo['id']}');
    } catch (e) {
      print('Ошибка при шифровании ${fileInfo['id']}: $e');
    }
  }
}

// ============================================================================
// ЗАМЕТКИ ПО ИСПОЛЬЗОВАНИЮ
// ============================================================================
/*

1. AUTODISPOSE:
   - Провайдер автоматически освобождает ресурсы при отсутствии подписчиков
   - Ключ шифрования удаляется из памяти автоматически
   - При следующем использовании провайдер инициализируется заново

2. ТРЕБОВАНИЯ:
   - База данных должна быть открыта
   - В таблице HoplixiMeta должен быть ключ шифрования (attachmentKey)
   - Sodium должен быть инициализирован

3. ОБРАБОТКА ОШИБОК:
   - Используйте fileEncryptorProvider для безопасной проверки
   - fileEncryptorInstanceProvider выбросит исключение при ошибке
   - Всегда оборачивайте операции в try-catch

4. ПРОИЗВОДИТЕЛЬНОСТЬ:
   - Шифрование работает потоково (streaming)
   - Не загружает весь файл в память
   - Можно настроить chunkSize для оптимизации

5. БЕЗОПАСНОСТЬ:
   - Ключ хранится в SecureKey (защищенная память)
   - Автоматическая очистка при dispose
   - Логи не содержат чувствительных данных

*/
