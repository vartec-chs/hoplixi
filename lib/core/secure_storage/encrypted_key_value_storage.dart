import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pointycastle/export.dart';

import '../flutter_secure_storageo_impl.dart';
import 'secure_key_value_storage.dart';
import 'secure_storage_models.dart';
import 'key_verification_service.dart';
import 'secure_storage_errors.dart';
import 'secure_storage_error_handler.dart';

/// Реализация безопасного key-value хранилища с шифрованием AES-GCM
/// Предназначена для хранения критически важных данных, включая пароли
///
/// СТРАТЕГИЯ ШИФРОВАНИЯ v3.0:
/// - Файлы хранятся в формате JSON с читаемыми ключами
/// - Шифруются только значения, ключи остаются в открытом виде
/// - Это позволяет эффективно работать с индексами и поиском по ключам
/// - Каждое значение шифруется индивидуально с использованием AES-256-GCM
/// - Метаданные (версия, временные метки, HMAC) остаются незашифрованными
class EncryptedKeyValueStorage implements SecureKeyValueStorage {
  final SecureStorage _secureStorage;
  late final Directory _storageDirectory;
  late final KeyVerificationService _keyVerificationService;

  // Кэш для ключей шифрования
  final Map<String, Uint8List> _encryptionKeysCache = {};

  // Кэш для данных (опционально) - автоматически очищается
  final Map<String, Map<String, dynamic>> _dataCache = {};
  final bool _enableCache;

  // Константы для криптографии
  static const int _keyLength = 32; // AES-256
  static const int _ivLength = 12; // GCM IV
  static const int _tagLength = 16; // GCM Tag

  // Таймер для автоматической очистки кэша
  Timer? _cacheCleanupTimer;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  EncryptedKeyValueStorage({
    required SecureStorage secureStorage,
    required String appName,
    bool enableCache = true,
  }) : _secureStorage = secureStorage,
       _enableCache = enableCache {
    // Инициализируем сервис проверки ключей
    _keyVerificationService = KeyVerificationService(
      secureStorage: _secureStorage,
    );

    // Автоматическая очистка кэша каждые 5 минут
    if (_enableCache) {
      _cacheCleanupTimer = Timer.periodic(_cacheTimeout, (_) {
        _secureMemoryClear();
      });
    }
  }

  @override
  Future<void> initialize() async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'initialize_storage',
      function: () async {
        SecureStorageErrorHandler.logOperationStart(
          operation: 'initialize_storage',
          additionalData: {'appName': MainConstants.appFolderName},
        );

        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          _storageDirectory = Directory(
            path.join(
              documentsDir.path,
              MainConstants.appFolderName,
              'secure_storage',
            ),
          );

          if (!await _storageDirectory.exists()) {
            await _storageDirectory.create(recursive: true);
          }

          SecureStorageErrorHandler.logSuccess(
            operation: 'initialize_storage',
            additionalData: {'storageDirectory': _storageDirectory.path},
          );
        } catch (e, stackTrace) {
          throw SecureStorageErrorHandler.handleInitializationError(
            error: e,
            context: 'storage_directory_creation',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Безопасная очистка памяти от чувствительных данных
  void _secureMemoryClear() {
    // Очищаем кэш ключей шифрования
    for (final key in _encryptionKeysCache.keys.toList()) {
      final keyData = _encryptionKeysCache[key]!;
      keyData.fillRange(0, keyData.length, 0); // Обнуляем данные
      _encryptionKeysCache.remove(key);
    }

    // Очищаем кэш данных
    _dataCache.clear();
  }

  /// Генерирует новый ключ шифрования с использованием криптографически стойкого ГСЧ
  Uint8List _generateEncryptionKey() {
    return SecureStorageErrorHandler.safeExecuteSync(
      operation: 'generate_encryption_key',
      function: () {
        logDebug(
          'Генерация нового ключа шифрования',
          tag: 'EncryptedKeyValueStorage',
        );

        try {
          final random = SecureRandom('Fortuna');
          final seed = Uint8List(32);
          final secureRandom = Random.secure();
          for (int i = 0; i < seed.length; i++) {
            seed[i] = secureRandom.nextInt(256);
          }
          random.seed(KeyParameter(seed));

          final keyBytes = Uint8List(_keyLength);
          for (int i = 0; i < _keyLength; i++) {
            keyBytes[i] = random.nextUint8();
          }

          logDebug(
            'Ключ шифрования успешно сгенерирован',
            tag: 'EncryptedKeyValueStorage',
            data: {'keyLength': keyBytes.length},
          );

          return keyBytes;
        } catch (e, stackTrace) {
          throw SecureStorageErrorHandler.handleKeyError(
            operation: 'generate_encryption_key',
            error: e,
            context: 'key_generation',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Получает ключ шифрования для файла хранилища
  Future<Uint8List> _getEncryptionKey(String storageKey) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'get_encryption_key',
      function: () async {
        logDebug(
          'Получение ключа шифрования для хранилища',
          tag: 'EncryptedKeyValueStorage',
          data: {'storageKey': storageKey},
        );

        // Проверяем кэш
        if (_encryptionKeysCache.containsKey(storageKey)) {
          final cachedKey = _encryptionKeysCache[storageKey]!;

          // Проверяем правильность ключа из кэша
          try {
            await _keyVerificationService.validateEncryptionKey(
              storageKey,
              cachedKey,
            );

            logDebug(
              'Ключ шифрования получен из кэша',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey},
            );
          } catch (e) {
            // Если ключ из кэша неправильный, удаляем его и загружаем заново
            _encryptionKeysCache.remove(storageKey);
            logWarning(
              'Ключ из кэша недействителен, перезагрузка',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey},
            );
          }

          if (_encryptionKeysCache.containsKey(storageKey)) {
            return Uint8List.fromList(cachedKey);
          }
        }

        final keyName = '${MainConstants.appName}_storage_key_$storageKey';

        try {
          String? encryptionKeyBase64 = await _secureStorage.read(key: keyName);

          if (encryptionKeyBase64 == null) {
            // Генерируем новый ключ, если его нет
            logInfo(
              'Генерация нового ключа для хранилища',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey},
            );

            final newKey = _generateEncryptionKey();
            encryptionKeyBase64 = base64.encode(newKey);
            await _secureStorage.write(
              key: keyName,
              value: encryptionKeyBase64,
            );

            // Регистрируем новый ключ в сервисе проверки
            await _keyVerificationService.registerEncryptionKey(
              storageKey,
              newKey,
            );

            // Кэшируем ключ
            _encryptionKeysCache[storageKey] = Uint8List.fromList(newKey);

            logInfo(
              'Новый ключ шифрования создан и зарегистрирован',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey},
            );

            return newKey;
          }

          final keyBytes = Uint8List.fromList(
            base64.decode(encryptionKeyBase64),
          );

          // Проверяем правильность загруженного ключа
          try {
            await _keyVerificationService.validateEncryptionKey(
              storageKey,
              keyBytes,
            );
          } catch (e) {
            // Если ключ неправильный, но это существующее хранилище,
            // возможно это первый запуск после добавления системы проверки ключей
            final verificationStatus = await _keyVerificationService
                .getVerificationStatus(storageKey);
            if (!verificationStatus.hasSignature) {
              // Это существующее хранилище без подписи - регистрируем ключ
              logInfo(
                'Регистрация существующего ключа для проверки',
                tag: 'EncryptedKeyValueStorage',
                data: {'storageKey': storageKey},
              );
              await _keyVerificationService.registerEncryptionKey(
                storageKey,
                keyBytes,
              );
            } else {
              // Ключ действительно неправильный
              throw SecureStorageErrorHandler.handleKeyError(
                operation: 'validate_encryption_key',
                error: e,
                storageKey: storageKey,
                context: 'key_validation_failed',
              );
            }
          }

          // Кэшируем ключ
          _encryptionKeysCache[storageKey] = Uint8List.fromList(keyBytes);

          logDebug(
            'Ключ шифрования успешно загружен',
            tag: 'EncryptedKeyValueStorage',
            data: {'storageKey': storageKey},
          );

          return keyBytes;
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleKeyError(
            operation: 'get_encryption_key',
            error: e,
            storageKey: storageKey,
            context: 'key_retrieval',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Шифрует данные с использованием AES-256-GCM
  String _encryptData(String data, Uint8List key) {
    return SecureStorageErrorHandler.safeExecuteSync(
      operation: 'encrypt_data',
      function: () {
        try {
          final cipher = GCMBlockCipher(AESEngine());
          final random = SecureRandom('Fortuna');

          // Инициализируем генератор случайных чисел
          final seed = Uint8List(32);
          final secureRandom = Random.secure();
          for (int i = 0; i < seed.length; i++) {
            seed[i] = secureRandom.nextInt(256);
          }
          random.seed(KeyParameter(seed));

          // Генерируем случайный IV
          final iv = Uint8List(_ivLength);
          for (int i = 0; i < _ivLength; i++) {
            iv[i] = random.nextUint8();
          }

          // Инициализируем шифр
          final params = AEADParameters(
            KeyParameter(key),
            _tagLength * 8,
            iv,
            Uint8List(0),
          );
          cipher.init(true, params);

          // Шифруем данные
          final dataBytes = Uint8List.fromList(utf8.encode(data));
          final encrypted = cipher.process(dataBytes);

          // Объединяем IV и зашифрованные данные с тегом
          final result = Uint8List(iv.length + encrypted.length);
          result.setRange(0, iv.length, iv);
          result.setRange(iv.length, result.length, encrypted);

          logDebug(
            'Данные успешно зашифрованы',
            tag: 'EncryptedKeyValueStorage',
            data: {'dataSize': data.length, 'encryptedSize': result.length},
          );

          return base64.encode(result);
        } catch (e, stackTrace) {
          throw SecureStorageErrorHandler.handleEncryptionError(
            operation: 'encrypt_data',
            error: e,
            context: 'aes_gcm_encryption',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Расшифровывает данные с использованием AES-256-GCM
  String _decryptData(String encryptedData, Uint8List key) {
    return SecureStorageErrorHandler.safeExecuteSync(
      operation: 'decrypt_data',
      function: () {
        try {
          final encryptedBytes = base64.decode(encryptedData);

          // Извлекаем IV (первые 12 байт для GCM)
          final iv = encryptedBytes.sublist(0, _ivLength);
          final encrypted = encryptedBytes.sublist(_ivLength);

          // Инициализируем шифр для дешифрования
          final cipher = GCMBlockCipher(AESEngine());
          final params = AEADParameters(
            KeyParameter(key),
            _tagLength * 8,
            iv,
            Uint8List(0),
          );
          cipher.init(false, params);

          // Расшифровываем
          final decrypted = cipher.process(encrypted);

          logDebug(
            'Данные успешно расшифрованы',
            tag: 'EncryptedKeyValueStorage',
            data: {
              'encryptedSize': encryptedBytes.length,
              'decryptedSize': decrypted.length,
            },
          );

          return utf8.decode(decrypted);
        } catch (e, stackTrace) {
          throw SecureStorageErrorHandler.handleDecryptionError(
            operation: 'decrypt_data',
            error: e,
            context: 'aes_gcm_decryption',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Шифрует только значения в Map, оставляя ключи в открытом виде
  Future<Map<String, dynamic>> _encryptValues(
    Map<String, dynamic> data,
    String storageKey,
  ) async {
    final encryptionKey = await _getEncryptionKey(storageKey);
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.key.startsWith('_')) {
        // Метаданные не шифруем
        result[entry.key] = entry.value;
      } else {
        // Шифруем значение
        final valueJson = jsonEncode(entry.value);
        final encryptedValue = _encryptData(valueJson, encryptionKey);
        result[entry.key] = {'_encrypted': true, '_value': encryptedValue};
      }
    }

    return result;
  }

  /// Расшифровывает только значения в Map, оставляя ключи в открытом виде
  Future<Map<String, dynamic>> _decryptValues(
    Map<String, dynamic> data,
    String storageKey,
  ) async {
    final encryptionKey = await _getEncryptionKey(storageKey);
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.key.startsWith('_')) {
        // Метаданные не расшифровываем
        result[entry.key] = entry.value;
      } else {
        // Проверяем, зашифровано ли значение
        if (entry.value is Map<String, dynamic>) {
          final valueMap = entry.value as Map<String, dynamic>;
          if (valueMap.containsKey('_encrypted') &&
              valueMap['_encrypted'] == true &&
              valueMap.containsKey('_value')) {
            // Расшифровываем значение
            final encryptedValue = valueMap['_value'] as String;
            final decryptedValue = _decryptData(encryptedValue, encryptionKey);
            result[entry.key] = jsonDecode(decryptedValue);
          } else {
            // Значение не зашифровано (старый формат)
            result[entry.key] = entry.value;
          }
        } else {
          // Значение не зашифровано (старый формат)
          result[entry.key] = entry.value;
        }
      }
    }

    return result;
  }

  /// Получает путь к файлу хранилища
  String _getStorageFilePath(String storageKey) {
    return path.join(_storageDirectory.path, '$storageKey.secure.json');
  }

  /// Вычисляет HMAC для защиты от модификации данных
  String _calculateHMAC(String data, Uint8List key) {
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Генерирует временную метку для защиты от replay-атак
  int _generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Проверяет, что временная метка не слишком старая (защита от replay)
  bool _isTimestampValid(
    int timestamp, {
    Duration maxAge = const Duration(hours: 24),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    return age >= 0 && age <= maxAge.inMilliseconds;
  }

  /// Вычисляет контрольную сумму данных
  String _calculateChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Загружает данные из файла с проверкой целостности и временных меток
  /// Новая стратегия: файл хранится в открытом виде JSON, шифруются только значения
  Future<Map<String, dynamic>> _loadStorageFile(String storageKey) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'load_storage_file',
      function: () async {
        final filePath = _getStorageFilePath(storageKey);
        final file = File(filePath);

        if (!await file.exists()) {
          logDebug(
            'Файл хранилища не существует, возвращаем пустые данные',
            tag: 'EncryptedKeyValueStorage',
            data: {'storageKey': storageKey, 'filePath': filePath},
          );
          return <String, dynamic>{};
        }

        try {
          final jsonContent = await file.readAsString();
          if (jsonContent.isEmpty) {
            logDebug(
              'Файл хранилища пуст, возвращаем пустые данные',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey, 'filePath': filePath},
            );
            return <String, dynamic>{};
          }

          final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;

          // Проверяем метаданные и целостность
          if (jsonData.containsKey('_metadata')) {
            final metadata = FileMetadata.fromJson(jsonData['_metadata']);
            final dataWithoutMetadata = Map<String, dynamic>.from(jsonData);
            dataWithoutMetadata.remove('_metadata');

            // Проверяем временную метку
            if (jsonData.containsKey('_timestamp')) {
              final timestamp = jsonData['_timestamp'] as int;
              if (!_isTimestampValid(timestamp)) {
                throw SecureStorageErrorHandler.handleValidationError(
                  operation: 'validate_timestamp',
                  error: 'File timestamp is too old',
                  context: 'storageKey: $storageKey',
                );
              }
              dataWithoutMetadata.remove('_timestamp');
            }

            // Проверяем HMAC (вычисляется для зашифрованных значений)
            if (jsonData.containsKey('_hmac')) {
              final storedHmac = jsonData['_hmac'] as String;
              final encryptionKey = await _getEncryptionKey(storageKey);
              final calculatedHmac = _calculateHMAC(
                jsonEncode(dataWithoutMetadata),
                encryptionKey,
              );
              if (storedHmac != calculatedHmac) {
                throw SecureStorageErrorHandler.handleValidationError(
                  operation: 'validate_hmac',
                  error: 'File HMAC mismatch',
                  context: 'storageKey: $storageKey',
                );
              }
              dataWithoutMetadata.remove('_hmac');
            }

            // Проверяем контрольную сумму
            final currentChecksum = _calculateChecksum(
              jsonEncode(dataWithoutMetadata),
            );
            if (currentChecksum != metadata.checksum) {
              throw SecureStorageErrorHandler.handleValidationError(
                operation: 'validate_checksum',
                error: 'File checksum mismatch',
                context: 'storageKey: $storageKey',
              );
            }

            // Расшифровываем значения (ключи остаются в открытом виде)
            final decryptedData = await _decryptValues(
              dataWithoutMetadata,
              storageKey,
            );

            logDebug(
              'Файл хранилища успешно загружен и проверен',
              tag: 'EncryptedKeyValueStorage',
              data: {
                'storageKey': storageKey,
                'itemCount': decryptedData.length,
                'hasMetadata': true,
              },
            );

            return decryptedData;
          }

          // Для старых файлов без метаданных просто возвращаем как есть
          logWarning(
            'Загружен файл хранилища без метаданных (старый формат)',
            tag: 'EncryptedKeyValueStorage',
            data: {'storageKey': storageKey},
          );

          return await _decryptValues(jsonData, storageKey);
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleFileError(
            operation: 'load_storage_file',
            error: e,
            filePath: filePath,
            context: 'storageKey: $storageKey',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Сохраняет данные в файл с метаданными безопасности
  /// Новая стратегия: файл сохраняется как обычный JSON, шифруются только значения
  Future<void> _saveStorageFile(
    String storageKey,
    Map<String, dynamic> data,
  ) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'save_storage_file',
      function: () async {
        try {
          final now = DateTime.now();
          final timestamp = _generateTimestamp();

          // Шифруем значения, оставляя ключи в открытом виде
          final encryptedData = await _encryptValues(data, storageKey);

          final checksum = _calculateChecksum(jsonEncode(data));
          final encryptionKey = await _getEncryptionKey(storageKey);

          // Создаем HMAC для зашифрованных данных
          final hmac = _calculateHMAC(jsonEncode(encryptedData), encryptionKey);

          // Добавляем метаданные безопасности
          final dataWithMetadata = Map<String, dynamic>.from(encryptedData);
          dataWithMetadata['_metadata'] = FileMetadata(
            version: '1.0', // Увеличиваем версию для новой стратегии шифрования
            createdAt: now,
            updatedAt: now,
            checksum: checksum,
          ).toJson();
          dataWithMetadata['_timestamp'] = timestamp;
          dataWithMetadata['_hmac'] = hmac;

          final jsonContent = jsonEncode(dataWithMetadata);

          final filePath = _getStorageFilePath(storageKey);

          // Атомарная запись файла (сначала во временный файл)
          final tempFile = File('$filePath.tmp');
          await tempFile.writeAsString(jsonContent);
          await tempFile.rename(filePath);

          // Обновляем кэш (сохраняем расшифрованные данные)
          if (_enableCache) {
            _dataCache[storageKey] = Map<String, dynamic>.from(data);
          }

          logDebug(
            'Файл хранилища успешно сохранен',
            tag: 'EncryptedKeyValueStorage',
            data: {
              'storageKey': storageKey,
              'itemCount': data.length,
              'fileSize': jsonContent.length,
            },
          );
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleFileError(
            operation: 'save_storage_file',
            error: e,
            filePath: _getStorageFilePath(storageKey),
            context: 'storageKey: $storageKey',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  /// Получает данные из кэша или загружает из файла
  Future<Map<String, dynamic>> _getStorageData(String storageKey) async {
    if (_enableCache && _dataCache.containsKey(storageKey)) {
      return Map<String, dynamic>.from(_dataCache[storageKey]!);
    }

    final data = await _loadStorageFile(storageKey);

    if (_enableCache) {
      _dataCache[storageKey] = Map<String, dynamic>.from(data);
    }

    return data;
  }

  @override
  Future<void> write<T>({
    required String storageKey,
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'write_data',
      function: () async {
        SecureStorageErrorHandler.logOperationStart(
          operation: 'write_data',
          context: storageKey,
          additionalData: {'key': key},
        );

        try {
          final storageData = await _getStorageData(storageKey);
          storageData[key] = toJson(data);
          await _saveStorageFile(storageKey, storageData);

          SecureStorageErrorHandler.logSuccess(
            operation: 'write_data',
            context: storageKey,
            additionalData: {'key': key},
          );
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleOperationError(
            operation: 'write_data',
            error: e,
            context: 'storageKey: $storageKey, key: $key',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  @override
  Future<T?> read<T>({
    required String storageKey,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'read_data',
      function: () async {
        logDebug(
          'Чтение данных из хранилища',
          tag: 'EncryptedKeyValueStorage',
          data: {'storageKey': storageKey, 'key': key},
        );

        try {
          final storageData = await _getStorageData(storageKey);

          if (!storageData.containsKey(key)) {
            logDebug(
              'Ключ не найден в хранилище',
              tag: 'EncryptedKeyValueStorage',
              data: {'storageKey': storageKey, 'key': key},
            );
            return null;
          }

          final jsonData = storageData[key] as Map<String, dynamic>;
          final result = fromJson(jsonData);

          logDebug(
            'Данные успешно прочитаны из хранилища',
            tag: 'EncryptedKeyValueStorage',
            data: {'storageKey': storageKey, 'key': key},
          );

          return result;
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleSerializationError(
            operation: 'read_data',
            error: e,
            context: 'storageKey: $storageKey, key: $key',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  @override
  Future<Map<String, T>> readAll<T>({
    required String storageKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    return SecureStorageErrorHandler.safeExecute(
      operation: 'read_all_data',
      function: () async {
        logDebug(
          'Чтение всех данных из хранилища',
          tag: 'EncryptedKeyValueStorage',
          data: {'storageKey': storageKey},
        );

        try {
          final storageData = await _getStorageData(storageKey);
          final result = <String, T>{};
          int successCount = 0;
          int errorCount = 0;

          for (final entry in storageData.entries) {
            if (entry.key.startsWith('_')) continue; // Пропускаем метаданные

            try {
              final jsonData = entry.value as Map<String, dynamic>;
              result[entry.key] = fromJson(jsonData);
              successCount++;
            } catch (e) {
              errorCount++;
              logWarning(
                'Ошибка десериализации элемента',
                tag: 'EncryptedKeyValueStorage',
                data: {
                  'storageKey': storageKey,
                  'itemKey': entry.key,
                  'error': e.toString(),
                },
              );
            }
          }

          logInfo(
            'Чтение всех данных завершено',
            tag: 'EncryptedKeyValueStorage',
            data: {
              'storageKey': storageKey,
              'successCount': successCount,
              'errorCount': errorCount,
              'totalItems': result.length,
            },
          );

          return result;
        } catch (e, stackTrace) {
          if (e is SecureStorageError) rethrow;
          throw SecureStorageErrorHandler.handleOperationError(
            operation: 'read_all_data',
            error: e,
            context: 'storageKey: $storageKey',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  @override
  Future<void> delete({required String storageKey, required String key}) async {
    try {
      final storageData = await _getStorageData(storageKey);
      storageData.remove(key);
      await _saveStorageFile(storageKey, storageData);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to delete data from storage: $storageKey, key: $key',
        e,
      );
    }
  }

  @override
  Future<void> deleteAll({required String storageKey}) async {
    try {
      await _saveStorageFile(storageKey, {});
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to delete all data from storage: $storageKey',
        e,
      );
    }
  }

  @override
  Future<void> deleteStorage({required String storageKey}) async {
    try {
      final filePath = _getStorageFilePath(storageKey);
      final file = File(filePath);

      if (await file.exists()) {
        // Безопасно перезаписываем файл случайными данными перед удалением
        await _secureFileDelete(file);
      }

      // Удаляем ключ шифрования
      final keyName = '${MainConstants.appName}_storage_key_$storageKey';
      await _secureStorage.delete(key: keyName);

      // Удаляем подпись ключа из сервиса проверки
      await _keyVerificationService.removeKeySignature(storageKey);

      // Очищаем кэш
      if (_encryptionKeysCache.containsKey(storageKey)) {
        final keyData = _encryptionKeysCache[storageKey]!;
        keyData.fillRange(0, keyData.length, 0); // Обнуляем ключ
        _encryptionKeysCache.remove(storageKey);
      }
      _dataCache.remove(storageKey);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException('Failed to delete storage: $storageKey', e);
    }
  }

  /// Безопасно удаляет файл (перезаписывает случайными данными)
  Future<void> _secureFileDelete(File file) async {
    try {
      final fileSize = await file.length();
      final random = Random.secure();

      // Перезаписываем файл случайными данными 3 раза (DOD 5220.22-M standard)
      for (int pass = 0; pass < 3; pass++) {
        final randomData = Uint8List(fileSize);
        for (int i = 0; i < fileSize; i++) {
          randomData[i] = random.nextInt(256);
        }
        await file.writeAsBytes(randomData);
        // Принудительная синхронизация с диском
        final raf = await file.open(mode: FileMode.append);
        await raf.flush();
        await raf.close();
      }

      // Затем удаляем файл
      await file.delete();
    } catch (e) {
      // Если безопасное удаление не удалось, просто удаляем файл
      await file.delete();
    }
  }

  @override
  Future<bool> containsKey({
    required String storageKey,
    required String key,
  }) async {
    try {
      final storageData = await _getStorageData(storageKey);
      return storageData.containsKey(key);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to check key existence in storage: $storageKey, key: $key',
        e,
      );
    }
  }

  @override
  Future<List<String>> getKeys({required String storageKey}) async {
    try {
      final storageData = await _getStorageData(storageKey);
      return storageData.keys
          .where((key) => !key.startsWith('_')) // Исключаем метаданные
          .toList();
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to get keys from storage: $storageKey',
        e,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    _secureMemoryClear();
  }

  /// Финализатор для очистки ресурсов
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _secureMemoryClear();
  }

  /// Проверяет целостность всех файлов хранилища
  Future<Map<String, bool>> verifyAllStoragesIntegrity() async {
    final results = <String, bool>{};

    try {
      final storageFiles = _storageDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.secure.json'))
          .toList();

      for (final file in storageFiles) {
        final fileName = path.basenameWithoutExtension(file.path);
        final storageKey = fileName.replaceAll('.secure', '');
        results[storageKey] = await verifyStorageIntegrity(storageKey);
      }
    } catch (e) {
      // Логируем ошибку, но не прерываем проверку
      print('Warning: Failed to verify some storage files: $e');
    }

    return results;
  }

  /// Получает размер хранилища в байтах
  Future<int> getStorageSize(String storageKey) async {
    try {
      final filePath = _getStorageFilePath(storageKey);
      final file = File(filePath);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Экспортирует зашифрованные данные для резервного копирования
  Future<Map<String, dynamic>> exportEncryptedData(String storageKey) async {
    try {
      final filePath = _getStorageFilePath(storageKey);
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileAccessException('Storage file does not exist: $storageKey');
      }

      final jsonContent = await file.readAsString();
      final metadata = await getStorageMetadata(storageKey);

      return {
        'storageKey': storageKey,
        'encryptedData':
            jsonContent, // Теперь это JSON с зашифрованными значениями
        'metadata': metadata?.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '3.0', // Новая версия стратегии
      };
    } catch (e) {
      throw SecureStorageException(
        'Failed to export encrypted data for storage: $storageKey',
        e,
      );
    }
  }

  /// Получает информацию о файле хранилища
  Future<FileMetadata?> getStorageMetadata(String storageKey) async {
    try {
      final data = await _loadStorageFile(storageKey);
      if (data.containsKey('_metadata')) {
        return FileMetadata.fromJson(data['_metadata']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверяет целостность файла хранилища
  Future<bool> verifyStorageIntegrity(String storageKey) async {
    try {
      await _loadStorageFile(storageKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// НОВЫЕ МЕТОДЫ ДЛЯ ПРОВЕРКИ КЛЮЧЕЙ

  /// Проверяет правильность ключа шифрования для хранилища
  Future<bool> verifyStorageKey(String storageKey) async {
    try {
      final encryptionKey = await _getEncryptionKey(storageKey);
      return await _keyVerificationService.verifyEncryptionKey(
        storageKey,
        encryptionKey,
      );
    } catch (e) {
      return false;
    }
  }

  /// Получает статус верификации ключа для хранилища
  Future<KeyVerificationStatus> getKeyVerificationStatus(
    String storageKey,
  ) async {
    try {
      return await _keyVerificationService.getVerificationStatus(storageKey);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to get key verification status for storage: $storageKey',
        e,
      );
    }
  }

  /// Принудительно перерегистрирует ключ для хранилища
  ///
  /// ВНИМАНИЕ: Используйте этот метод только если вы уверены, что текущий ключ правильный!
  /// Этот метод перезаписывает существующую подпись новой.
  Future<void> reregisterStorageKey(String storageKey) async {
    try {
      final encryptionKey = await _getEncryptionKey(storageKey);

      // Удаляем старую подпись
      await _keyVerificationService.removeKeySignature(storageKey);

      // Создаем новую подпись
      await _keyVerificationService.registerEncryptionKey(
        storageKey,
        encryptionKey,
      );
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to reregister storage key: $storageKey',
        e,
      );
    }
  }

  /// Проверяет правильность ключей для всех зарегистрированных хранилищ
  Future<Map<String, bool>> verifyAllStorageKeys() async {
    try {
      final registeredStorages = await _keyVerificationService
          .getRegisteredStorages();
      final results = <String, bool>{};

      for (final storageKey in registeredStorages) {
        results[storageKey] = await verifyStorageKey(storageKey);
      }

      return results;
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException('Failed to verify all storage keys', e);
    }
  }

  /// Получает список всех хранилищ с зарегистрированными ключами
  Future<List<String>> getRegisteredStorages() async {
    try {
      return await _keyVerificationService.getRegisteredStorages();
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException('Failed to get registered storages list', e);
    }
  }

  /// Выполняет полную диагностику безопасности всех хранилищ
  Future<SecurityDiagnostics> performSecurityDiagnostics() async {
    try {
      final registeredStorages = await getRegisteredStorages();
      final keyVerificationResults = await verifyAllStorageKeys();
      final storageIntegrityResults = await verifyAllStoragesIntegrity();
      final signatureIntegrityResults = await _keyVerificationService
          .verifyAllSignatures();

      final issues = <SecurityIssue>[];

      // Проверяем проблемы с ключами
      for (final entry in keyVerificationResults.entries) {
        if (!entry.value) {
          issues.add(
            SecurityIssue(
              type: SecurityIssueType.invalidKey,
              storageKey: entry.key,
              description:
                  'Invalid encryption key detected for storage: ${entry.key}',
              severity: SecurityIssueSeverity.critical,
            ),
          );
        }
      }

      // Проверяем проблемы с файлами
      for (final entry in storageIntegrityResults.entries) {
        if (!entry.value) {
          issues.add(
            SecurityIssue(
              type: SecurityIssueType.corruptedFile,
              storageKey: entry.key,
              description:
                  'Storage file integrity check failed for: ${entry.key}',
              severity: SecurityIssueSeverity.high,
            ),
          );
        }
      }

      // Проверяем проблемы с подписями
      for (final entry in signatureIntegrityResults.entries) {
        if (!entry.value) {
          issues.add(
            SecurityIssue(
              type: SecurityIssueType.corruptedSignature,
              storageKey: entry.key,
              description:
                  'Key signature is corrupted for storage: ${entry.key}',
              severity: SecurityIssueSeverity.medium,
            ),
          );
        }
      }

      return SecurityDiagnostics(
        totalStorages: registeredStorages.length,
        validKeys: keyVerificationResults.values.where((v) => v).length,
        invalidKeys: keyVerificationResults.values.where((v) => !v).length,
        intactFiles: storageIntegrityResults.values.where((v) => v).length,
        corruptedFiles: storageIntegrityResults.values.where((v) => !v).length,
        issues: issues,
        scanTime: DateTime.now(),
      );
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException('Failed to perform security diagnostics', e);
    }
  }
}
