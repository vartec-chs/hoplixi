import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/lib/sodium_file_encryptor/aead_file_encryptor.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/features/global/providers/sodium_provider.dart';
import 'package:sodium/sodium.dart';

/// Провайдер для работы с шифрованием файлов
/// Получает ключ шифрования из БД и создает экземпляр AeadFileEncryptor
///
/// **Требования:**
/// - База данных должна быть открыта
/// - Sodium должен быть инициализирован
/// - В БД должен быть сохранен ключ шифрования (в base64)
///
/// **Использование с проверкой результата:**
/// ```dart
/// final encryptorResult = await ref.read(fileEncryptorProvider.future);
/// if (encryptorResult.success) {
///   final encryptor = encryptorResult.data;
///   await encryptor.encryptFile(
///     input: inputFile,
///     output: outputFile,
///     fileId: 'document_123',
///     fileExtension: 'pdf',
///   );
/// } else {
///   ToastHelper.error(encryptorResult.message ?? 'Ошибка шифрования');
/// }
/// ```
///
/// **Упрощенное использование (выбросит исключение при ошибке):**
/// ```dart
/// final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
/// await encryptor.encryptFile(...);
/// ```
final fileEncryptorProvider =
    AsyncNotifierProvider.autoDispose<
      FileEncryptorNotifier,
      FileEncryptorResult
    >(FileEncryptorNotifier.new);

/// Упрощенный провайдер для прямого доступа к AeadFileEncryptor
/// Выбрасывает исключение, если инициализация не удалась
///
/// **Использование:**
/// ```dart
/// // Получение экземпляра (async)
/// final encryptor = await ref.read(fileEncryptorInstanceProvider.future);
///
/// // Шифрование файла
/// await encryptor.encryptFile(
///   input: File('/path/to/input.pdf'),
///   output: File('/path/to/output.enc'),
///   fileId: 'doc_123',
///   fileExtension: 'pdf',
///   onProgress: (progress) {
///     print('Progress: ${progress.progressPercent}%');
///   },
/// );
///
/// // Дешифрование файла
/// final extension = await encryptor.decryptFile(
///   input: File('/path/to/encrypted.enc'),
///   output: File('/path/to/decrypted'),
///   useOriginalExtension: true,
/// );
/// ```
final fileEncryptorInstanceProvider =
    FutureProvider.autoDispose<AeadFileEncryptor>((ref) async {
      final result = await ref.watch(fileEncryptorProvider.future);
      if (!result.success) {
        throw StateError(
          result.errorMessage ?? 'Не удалось инициализировать FileEncryptor',
        );
      }
      return result.data;
    });

/// Нотификатор для управления шифрованием файлов
class FileEncryptorNotifier extends AsyncNotifier<FileEncryptorResult> {
  @override
  Future<FileEncryptorResult> build() async {
    const String tag = 'FileEncryptorNotifier';

    try {
      logDebug('Инициализация FileEncryptor', tag: tag);

      // Получаем экземпляр Sodium
      final sodium = await ref.watch(sodiumProvider.future);

      // Получаем менеджер БД из глобального состояния
      final storeManager = ref.watch(hoplixiStoreManagerProvider);

      // Проверяем, что БД открыта
      if (!storeManager.hasOpenDatabase) {
        logError(
          'Попытка инициализации FileEncryptor при закрытой БД',
          tag: tag,
        );
        return FileEncryptorResult.error('База данных не открыта');
      }

      // Получаем ключ шифрования из БД (в base64)
      final keyBase64 = await storeManager.getAttachmentKey();

      // Декодируем ключ из base64
      final keyBytes = base64Decode(keyBase64);
      final secureKey = SecureKey.fromList(
        sodium,
        Uint8List.fromList(keyBytes),
      );

      // Создаем экземпляр AeadFileEncryptor
      final encryptor = AeadFileEncryptor.fromKey(sodium, secureKey);

      logInfo('FileEncryptor инициализирован успешно', tag: tag);

      return FileEncryptorResult.success(encryptor);
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации FileEncryptor',
        error: e,
        stackTrace: stackTrace,
        tag: tag,
      );
      return FileEncryptorResult.error(
        'Ошибка инициализации шифрования файлов: ${e.toString()}',
      );
    }
  }

  /// Пересоздать провайдер (например, после смены БД или изменения ключа)
  void refresh() {
    ref.invalidateSelf();
  }
}

/// Результат инициализации FileEncryptor
///
/// Используется для безопасной обработки ошибок инициализации
class FileEncryptorResult {
  final bool success;
  final String? errorMessage;
  final AeadFileEncryptor? encryptor;

  const FileEncryptorResult._({
    required this.success,
    this.errorMessage,
    this.encryptor,
  });

  /// Создает успешный результат с экземпляром encryptor
  factory FileEncryptorResult.success(AeadFileEncryptor encryptor) {
    return FileEncryptorResult._(success: true, encryptor: encryptor);
  }

  /// Создает результат с ошибкой
  factory FileEncryptorResult.error(String message) {
    return FileEncryptorResult._(success: false, errorMessage: message);
  }

  /// Получить данные или выбросить исключение при ошибке
  ///
  /// Используйте для упрощенного доступа, когда уверены в успехе
  AeadFileEncryptor get data {
    if (!success || encryptor == null) {
      throw StateError(errorMessage ?? 'FileEncryptor не инициализирован');
    }
    return encryptor!;
  }

  /// Безопасное получение данных (возвращает null при ошибке)
  AeadFileEncryptor? get dataOrNull => encryptor;

  /// Получить сообщение об ошибке или null
  String? get message => errorMessage;
}
