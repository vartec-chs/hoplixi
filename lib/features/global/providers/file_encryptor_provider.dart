import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/lib/sodium_file_encryptor/aead_file_encryptor.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/features/global/providers/sodium_provider.dart';
import 'package:hoplixi/features/global/providers/app_lifecycle_provider.dart';
import 'package:sodium/sodium.dart';

/// Центральный провайдер для работы с шифрованием файлов
///
/// Управляет всеми операциями с файлами:
/// - Шифрование/дешифрование
/// - Отслеживание расшифрованных файлов
/// - Автоматическая очистка временных файлов
///
/// **Требования:**
/// - База данных должна быть открыта
/// - Sodium должен быть инициализирован
/// - В БД должен быть сохранен ключ шифрования (в base64)
///
/// **Использование:**
/// ```dart
/// final manager = ref.read(fileEncryptorProvider.notifier);
///
/// // Дешифрование с автоматическим отслеживанием
/// final result = await manager.decryptFile(
///   input: encryptedFile,
///   output: tempFile,
/// );
///
/// // Очистка всех временных файлов
/// await manager.cleanup();
/// ```
final fileEncryptorProvider =
    NotifierProvider<FileEncryptorNotifier, FileEncryptorState>(
      FileEncryptorNotifier.new,
    );

/// Состояние менеджера шифрования файлов
class FileEncryptorState {
  /// Инициализирован ли encryptor
  final bool isInitialized;

  /// Список путей к расшифрованным файлам (для последующей очистки)
  final List<String> decryptedFiles;

  /// Сообщение об ошибке инициализации
  final String? errorMessage;

  const FileEncryptorState({
    required this.isInitialized,
    required this.decryptedFiles,
    this.errorMessage,
  });

  FileEncryptorState copyWith({
    bool? isInitialized,
    List<String>? decryptedFiles,
    String? errorMessage,
  }) {
    return FileEncryptorState(
      isInitialized: isInitialized ?? this.isInitialized,
      decryptedFiles: decryptedFiles ?? this.decryptedFiles,
      errorMessage: errorMessage,
    );
  }
}

/// Нотификатор для управления шифрованием файлов и временными файлами
///
/// Центральный менеджер для всех операций с файлами:
/// - Шифрование/дешифрование файлов
/// - Отслеживание расшифрованных временных файлов
/// - Автоматическая очистка при закрытии или по команде
class FileEncryptorNotifier extends Notifier<FileEncryptorState> {
  static const String _tag = 'FileEncryptorNotifier';

  AeadFileEncryptor? _encryptor;

  @override
  FileEncryptorState build() {
    // Отслеживаем состояние жизненного цикла приложения
    ref.listen<AppLifecycleStateData>(appLifecycleProvider, (previous, next) {
      // Если данные были очищены (таймер истёк), удаляем все временные файлы
      if (next.dataCleared && (previous?.dataCleared != true)) {
        logInfo(
          'AppLifecycle: данные очищены, запуск cleanup временных файлов',
          tag: _tag,
        );
        cleanup();
      }
    });

    // Автоматическая очистка при dispose провайдера
    ref.onDispose(() {
      cleanup();
    });

    return const FileEncryptorState(isInitialized: false, decryptedFiles: []);
  }

  /// Инициализация encryptor'а
  ///
  /// Должна быть вызвана перед использованием операций шифрования
  Future<void> initialize() async {
    try {
      logDebug('Инициализация FileEncryptor', tag: _tag);

      // Получаем экземпляр Sodium
      final sodium = await ref.read(sodiumProvider.future);

      // Получаем менеджер БД из глобального состояния
      final storeManager = ref.read(hoplixiStoreManagerProvider);

      // Проверяем, что БД открыта
      if (!storeManager.hasOpenDatabase) {
        logError(
          'Попытка инициализации FileEncryptor при закрытой БД',
          tag: _tag,
        );
        state = state.copyWith(
          isInitialized: false,
          errorMessage: 'База данных не открыта',
        );
        return;
      }

      late String keyBase64;

      try {
        // Получаем ключ шифрования из БД (в base64)

        keyBase64 = await storeManager.getAttachmentKey();
        if (keyBase64.isEmpty) {
          throw Exception('Ключ шифрования не найден в БД');
        }
      } catch (e) {
        keyBase64 = AeadFileEncryptor.generateKeyBase64(sodium);

        await storeManager.setAttachmentKey(keyBase64);

        logInfo(
          'Сгенерирован и сохранен новый ключ шифрования в БД',
          tag: _tag,
        );
        return;
      }

      // Декодируем ключ из base64
      final keyBytes = base64Decode(keyBase64);
      final secureKey = SecureKey.fromList(
        sodium,
        Uint8List.fromList(keyBytes),
      );

      // Создаем экземпляр AeadFileEncryptor
      _encryptor = AeadFileEncryptor.fromKey(sodium, secureKey);

      state = state.copyWith(isInitialized: true, errorMessage: null);

      logInfo('FileEncryptor инициализирован успешно', tag: _tag);
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации FileEncryptor',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      state = state.copyWith(
        isInitialized: false,
        errorMessage: 'Ошибка инициализации: ${e.toString()}',
      );
    }
  }

  /// Шифрование файла
  ///
  /// **Параметры:**
  /// - `input`: Исходный файл для шифрования
  /// - `output`: Файл для сохранения зашифрованных данных
  /// - `fileId`: Уникальный идентификатор файла (UUID)
  /// - `fileExtension`: Расширение файла (сохраняется в метаданных)
  /// - `onProgress`: Callback для отслеживания прогресса
  ///
  /// **Возвращает:** `true` при успехе, `false` при ошибке
  Future<bool> encryptFile({
    required File input,
    required File output,
    required String fileId,
    required String fileExtension,
    void Function(CryptoProgress)? onProgress,
  }) async {
    if (!state.isInitialized || _encryptor == null) {
      logError(
        'Попытка шифрования при неинициализированном encryptor',
        tag: _tag,
      );
      return false;
    }

    try {
      await _encryptor!.encryptFile(
        input: input,
        output: output,
        fileId: fileId,
        fileExtension: fileExtension,
        onProgress: onProgress,
      );
      logInfo('Файл успешно зашифрован: $fileId', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка шифрования файла',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return false;
    }
  }

  /// Дешифрование файла с автоматическим отслеживанием
  ///
  /// Расшифрованный файл автоматически добавляется в список для последующей очистки
  ///
  /// **Параметры:**
  /// - `input`: Зашифрованный файл
  /// - `output`: Файл для сохранения расшифрованных данных
  /// - `useOriginalExtension`: Добавить оригинальное расширение из метаданных
  /// - `onProgress`: Callback для отслеживания прогресса
  /// - `trackForCleanup`: Отслеживать файл для автоматической очистки (по умолчанию true)
  ///
  /// **Возвращает:** Оригинальное расширение файла или null при ошибке
  Future<String?> decryptFile({
    required File input,
    required File output,
    bool useOriginalExtension = true,
    void Function(CryptoProgress)? onProgress,
    bool trackForCleanup = true,
  }) async {
    if (!state.isInitialized || _encryptor == null) {
      logError(
        'Попытка дешифрования при неинициализированном encryptor',
        tag: _tag,
      );
      return null;
    }

    try {
      final extension = await _encryptor!.decryptFile(
        input: input,
        output: output,
        useOriginalExtension: useOriginalExtension,
        onProgress: onProgress,
      );

      // Добавляем файл в список для отслеживания
      if (trackForCleanup) {
        _trackDecryptedFile(output.path);
      }

      logInfo('Файл успешно расшифрован: ${output.path}', tag: _tag);
      return extension;
    } catch (e, stackTrace) {
      logError(
        'Ошибка дешифрования файла',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return null;
    }
  }

  /// Добавить путь к файлу в список отслеживаемых
  void _trackDecryptedFile(String filePath) {
    if (!state.decryptedFiles.contains(filePath)) {
      state = state.copyWith(
        decryptedFiles: [...state.decryptedFiles, filePath],
      );
      logDebug('Файл добавлен для отслеживания: $filePath', tag: _tag);
    }
  }

  /// Удалить конкретный расшифрованный файл
  ///
  /// **Параметры:**
  /// - `filePath`: Путь к файлу для удаления
  ///
  /// **Возвращает:** `true` если файл успешно удален
  Future<bool> removeDecryptedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logInfo('Файл удален: $filePath', tag: _tag);
      }

      // Удаляем из списка отслеживания
      state = state.copyWith(
        decryptedFiles: state.decryptedFiles
            .where((f) => f != filePath)
            .toList(),
      );

      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления файла: $filePath',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return false;
    }
  }

  /// Очистка всех отслеживаемых расшифрованных файлов
  ///
  /// Удаляет все временные расшифрованные файлы из файловой системы
  ///
  /// **Возвращает:** Количество успешно удаленных файлов
  Future<int> cleanup() async {
    logInfo(
      'Начало очистки расшифрованных файлов (${state.decryptedFiles.length})',
      tag: _tag,
    );

    int deletedCount = 0;
    final List<String> remainingFiles = [];

    for (final filePath in state.decryptedFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
          logDebug('Удален: $filePath', tag: _tag);
        } else {
          logDebug('Файл уже не существует: $filePath', tag: _tag);
        }
      } catch (e, stackTrace) {
        logError(
          'Не удалось удалить файл: $filePath',
          error: e,
          stackTrace: stackTrace,
          tag: _tag,
        );
        // Оставляем файл в списке, если не удалось удалить
        remainingFiles.add(filePath);
      }
    }

    // Обновляем состояние только оставшимися файлами
    state = state.copyWith(decryptedFiles: remainingFiles);

    logInfo(
      'Очистка завершена. Удалено: $deletedCount, осталось: ${remainingFiles.length}',
      tag: _tag,
    );
    return deletedCount;
  }

  /// Получить список всех отслеживаемых файлов
  List<String> get decryptedFiles => state.decryptedFiles;

  /// Проверка инициализации
  bool get isInitialized => state.isInitialized;

  /// Получить сообщение об ошибке инициализации
  String? get errorMessage => state.errorMessage;
}
