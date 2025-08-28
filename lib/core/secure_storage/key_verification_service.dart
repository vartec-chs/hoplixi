import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import '../flutter_secure_storageo_impl.dart';
import 'secure_key_value_storage.dart';

/// Сервис для проверки правильности ключей шифрования хранилища
///
/// Этот сервис создает и проверяет криптографические подписи ключей,
/// чтобы убедиться, что правильный ключ используется для каждого хранилища.
///
/// ПРИНЦИП РАБОТЫ:
/// 1. При создании нового ключа создается подпись на основе ключа и известного текста
/// 2. Подпись сохраняется в отдельном безопасном хранилище
/// 3. При каждом доступе к хранилищу подпись проверяется
/// 4. Если подпись не совпадает - ключ неправильный или поврежден
class KeyVerificationService {
  final SecureStorage _secureStorage;

  // Константы для проверки ключей
  static const String _verificationPrefix = 'hoplixi_key_verification_';
  static const String _signaturePrefix = 'hoplixi_key_signature_';
  static const String _testMessage =
      'HOPLIXI_KEY_VERIFICATION_TEST_MESSAGE_v1.0';

  KeyVerificationService({required SecureStorage secureStorage})
    : _secureStorage = secureStorage;

  /// Создает подпись для ключа шифрования
  ///
  /// Подпись создается путем шифрования известного тестового сообщения
  /// с использованием ключа и последующего хеширования результата
  String _createKeySignature(Uint8List encryptionKey) {
    try {
      // Создаем уникальную подпись на основе ключа
      final hmac = Hmac(sha256, encryptionKey);
      final digest = hmac.convert(utf8.encode(_testMessage));

      // Дополнительно шифруем тестовое сообщение для создания более сложной подписи
      final encryptedTest = _encryptTestMessage(encryptionKey);
      final combinedData = digest.bytes + encryptedTest;

      // Создаем итоговую подпись
      final finalDigest = sha256.convert(combinedData);
      return finalDigest.toString();
    } catch (e) {
      throw EncryptionException('Failed to create key signature', e);
    }
  }

  /// Шифрует тестовое сообщение с использованием AES-GCM
  Uint8List _encryptTestMessage(Uint8List key) {
    try {
      final cipher = GCMBlockCipher(AESEngine());

      // Используем детерминированный IV для создания воспроизводимой подписи
      // IV создается из хеша ключа для обеспечения уникальности
      final keyHash = sha256.convert(key);
      final iv = Uint8List.fromList(keyHash.bytes.take(12).toList());

      final params = AEADParameters(
        KeyParameter(key),
        128, // 16 bytes * 8 = 128 bits
        iv,
        Uint8List(0),
      );

      cipher.init(true, params);
      final testBytes = Uint8List.fromList(utf8.encode(_testMessage));
      return cipher.process(testBytes);
    } catch (e) {
      throw EncryptionException('Failed to encrypt test message', e);
    }
  }

  /// Сохраняет подпись ключа в безопасном хранилище
  Future<void> _saveKeySignature(String storageKey, String signature) async {
    try {
      final signatureKey = '$_signaturePrefix$storageKey';
      await _secureStorage.write(key: signatureKey, value: signature);
    } catch (e) {
      throw SecureStorageException(
        'Failed to save key signature for storage: $storageKey',
        e,
      );
    }
  }

  /// Получает сохраненную подпись ключа
  Future<String?> _getKeySignature(String storageKey) async {
    try {
      final signatureKey = '$_signaturePrefix$storageKey';
      return await _secureStorage.read(key: signatureKey);
    } catch (e) {
      throw SecureStorageException(
        'Failed to get key signature for storage: $storageKey',
        e,
      );
    }
  }

  /// Регистрирует новый ключ шифрования для хранилища
  ///
  /// Этот метод должен вызываться при создании нового ключа шифрования
  Future<void> registerEncryptionKey(
    String storageKey,
    Uint8List encryptionKey,
  ) async {
    try {
      // Проверяем, есть ли уже подпись для этого хранилища
      final existingSignature = await _getKeySignature(storageKey);
      if (existingSignature != null) {
        // Если подпись уже существует, проверяем, что ключ правильный
        final isValid = await _verifyKeyInternal(storageKey, encryptionKey);
        if (!isValid) {
          throw ValidationException(
            'Key registration failed: provided key does not match existing signature for storage: $storageKey',
          );
        }
        return; // Ключ уже зарегистрирован и правильный
      }

      // Создаем новую подпись для ключа
      final signature = _createKeySignature(encryptionKey);
      await _saveKeySignature(storageKey, signature);

      // Сохраняем информацию о времени регистрации
      final registrationKey = '$_verificationPrefix${storageKey}_registered_at';
      await _secureStorage.write(
        key: registrationKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to register encryption key for storage: $storageKey',
        e,
      );
    }
  }

  /// Внутренний метод проверки ключа
  Future<bool> _verifyKeyInternal(
    String storageKey,
    Uint8List encryptionKey,
  ) async {
    try {
      final storedSignature = await _getKeySignature(storageKey);
      if (storedSignature == null) {
        return false; // Подпись не найдена
      }

      final currentSignature = _createKeySignature(encryptionKey);
      return storedSignature == currentSignature;
    } catch (e) {
      return false; // В случае ошибки считаем ключ неправильным
    }
  }

  /// Проверяет правильность ключа шифрования для хранилища
  ///
  /// Возвращает true, если ключ правильный, false - если нет
  /// Выбрасывает исключение в случае серьезных ошибок
  Future<bool> verifyEncryptionKey(
    String storageKey,
    Uint8List encryptionKey,
  ) async {
    try {
      return await _verifyKeyInternal(storageKey, encryptionKey);
    } catch (e) {
      throw SecureStorageException(
        'Failed to verify encryption key for storage: $storageKey',
        e,
      );
    }
  }

  /// Проверяет правильность ключа и выбрасывает исключение, если ключ неправильный
  ///
  /// Этот метод следует использовать перед выполнением операций с хранилищем
  Future<void> validateEncryptionKey(
    String storageKey,
    Uint8List encryptionKey,
  ) async {
    final isValid = await verifyEncryptionKey(storageKey, encryptionKey);
    if (!isValid) {
      throw ValidationException(
        'Invalid encryption key for storage: $storageKey. '
        'The key does not match the expected signature. '
        'This may indicate key corruption or wrong key usage.',
      );
    }
  }

  /// Получает статус верификации для хранилища
  Future<KeyVerificationStatus> getVerificationStatus(String storageKey) async {
    try {
      final signature = await _getKeySignature(storageKey);
      final registrationKey = '$_verificationPrefix${storageKey}_registered_at';
      final registrationTimeStr = await _secureStorage.read(
        key: registrationKey,
      );

      DateTime? registrationTime;
      if (registrationTimeStr != null) {
        try {
          registrationTime = DateTime.parse(registrationTimeStr);
        } catch (e) {
          // Игнорируем ошибки парсинга даты
        }
      }

      return KeyVerificationStatus(
        storageKey: storageKey,
        hasSignature: signature != null,
        registrationTime: registrationTime,
        signatureHash: signature != null
            ? sha256.convert(utf8.encode(signature)).toString()
            : null,
      );
    } catch (e) {
      throw SecureStorageException(
        'Failed to get verification status for storage: $storageKey',
        e,
      );
    }
  }

  /// Удаляет подпись ключа для хранилища
  ///
  /// Этот метод следует вызывать при удалении хранилища
  Future<void> removeKeySignature(String storageKey) async {
    try {
      final signatureKey = '$_signaturePrefix$storageKey';
      final registrationKey = '$_verificationPrefix${storageKey}_registered_at';

      await Future.wait([
        _secureStorage.delete(key: signatureKey),
        _secureStorage.delete(key: registrationKey),
      ]);
    } catch (e) {
      throw SecureStorageException(
        'Failed to remove key signature for storage: $storageKey',
        e,
      );
    }
  }

  /// Получает список всех зарегистрированных хранилищ
  Future<List<String>> getRegisteredStorages() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final storageKeys = <String>[];

      for (final key in allKeys.keys) {
        if (key.startsWith(_signaturePrefix)) {
          final storageKey = key.substring(_signaturePrefix.length);
          storageKeys.add(storageKey);
        }
      }

      return storageKeys;
    } catch (e) {
      throw SecureStorageException('Failed to get registered storages list', e);
    }
  }

  /// Проверяет целостность всех зарегистрированных подписей
  Future<Map<String, bool>> verifyAllSignatures() async {
    try {
      final registeredStorages = await getRegisteredStorages();
      final results = <String, bool>{};

      for (final storageKey in registeredStorages) {
        try {
          final signature = await _getKeySignature(storageKey);
          // Проверяем, что подпись существует и имеет правильный формат
          results[storageKey] =
              signature != null &&
              signature.length == 64; // SHA-256 hash length
        } catch (e) {
          results[storageKey] = false;
        }
      }

      return results;
    } catch (e) {
      throw SecureStorageException('Failed to verify all signatures', e);
    }
  }

  /// Очищает все данные верификации (использовать осторожно!)
  Future<void> clearAllVerificationData() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final keysToDelete = <String>[];

      for (final key in allKeys.keys) {
        if (key.startsWith(_signaturePrefix) ||
            key.startsWith(_verificationPrefix)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _secureStorage.delete(key: key);
      }
    } catch (e) {
      throw SecureStorageException('Failed to clear verification data', e);
    }
  }
}

/// Статус верификации ключа для хранилища
class KeyVerificationStatus {
  final String storageKey;
  final bool hasSignature;
  final DateTime? registrationTime;
  final String? signatureHash;

  const KeyVerificationStatus({
    required this.storageKey,
    required this.hasSignature,
    this.registrationTime,
    this.signatureHash,
  });

  bool get isRegistered => hasSignature;

  @override
  String toString() {
    return 'KeyVerificationStatus(storageKey: $storageKey, hasSignature: $hasSignature, '
        'registrationTime: $registrationTime, signatureHash: $signatureHash)';
  }
}
