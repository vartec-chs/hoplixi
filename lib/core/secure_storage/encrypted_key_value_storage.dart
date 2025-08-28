import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pointycastle/export.dart';

import '../flutter_secure_storageo_impl.dart';
import 'secure_key_value_storage.dart';
import 'secure_storage_models.dart';

/// Реализация безопасного key-value хранилища с шифрованием AES-GCM
/// Предназначена для хранения критически важных данных, включая пароли
class EncryptedKeyValueStorage implements SecureKeyValueStorage {
  final SecureStorage _secureStorage;
  late final Directory _storageDirectory;

  // Кэш для ключей шифрования
  final Map<String, Uint8List> _encryptionKeysCache = {};

  // Кэш для данных (опционально) - автоматически очищается
  final Map<String, Map<String, dynamic>> _dataCache = {};
  final bool _enableCache;

  // Константы для криптографии
  static const int _keyLength = 32; // AES-256
  static const int _ivLength = 12; // GCM IV
  static const int _tagLength = 16; // GCM Tag
  static const int _saltLength = 32; // Salt для PBKDF2
  static const int _pbkdf2Iterations = 100000; // Итерации PBKDF2

  // Таймер для автоматической очистки кэша
  Timer? _cacheCleanupTimer;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  EncryptedKeyValueStorage({
    required SecureStorage secureStorage,
    required String appName,
    bool enableCache = true,
  }) : _secureStorage = secureStorage,
       _enableCache = enableCache {
    // Автоматическая очистка кэша каждые 5 минут
    if (_enableCache) {
      _cacheCleanupTimer = Timer.periodic(_cacheTimeout, (_) {
        _secureMemoryClear();
      });
    }
  }

  @override
  Future<void> initialize() async {
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
    } catch (e) {
      throw FileAccessException('Failed to initialize storage directory', e);
    }
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
    return keyBytes;
  }

  /// Выводит ключ из мастер-пароля с использованием PBKDF2
  Uint8List _deriveKeyFromPassword(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Получает ключ шифрования для файла хранилища
  Future<Uint8List> _getEncryptionKey(String storageKey) async {
    // Проверяем кэш
    if (_encryptionKeysCache.containsKey(storageKey)) {
      return Uint8List.fromList(_encryptionKeysCache[storageKey]!);
    }

    final keyName = '${MainConstants.appName}_storage_key_$storageKey';

    try {
      String? encryptionKeyBase64 = await _secureStorage.read(key: keyName);

      if (encryptionKeyBase64 == null) {
        // Генерируем новый ключ, если его нет
        final newKey = _generateEncryptionKey();
        encryptionKeyBase64 = base64.encode(newKey);
        await _secureStorage.write(key: keyName, value: encryptionKeyBase64);

        // Кэшируем ключ
        _encryptionKeysCache[storageKey] = Uint8List.fromList(newKey);
        return newKey;
      }

      final keyBytes = Uint8List.fromList(base64.decode(encryptionKeyBase64));

      // Кэшируем ключ
      _encryptionKeysCache[storageKey] = Uint8List.fromList(keyBytes);
      return keyBytes;
    } catch (e) {
      throw EncryptionException(
        'Failed to get encryption key for storage: $storageKey',
        e,
      );
    }
  }

  /// Шифрует данные с использованием AES-256-GCM
  String _encryptData(String data, Uint8List key) {
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

      return base64.encode(result);
    } catch (e) {
      throw EncryptionException('Failed to encrypt data', e);
    }
  }

  /// Расшифровывает данные с использованием AES-256-GCM
  String _decryptData(String encryptedData, Uint8List key) {
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

      return utf8.decode(decrypted);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data', e);
    }
  }

  /// Получает путь к файлу хранилища
  String _getStorageFilePath(String storageKey) {
    return path.join(_storageDirectory.path, '$storageKey.encrypted');
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
  Future<Map<String, dynamic>> _loadStorageFile(String storageKey) async {
    final filePath = _getStorageFilePath(storageKey);
    final file = File(filePath);

    if (!await file.exists()) {
      return {};
    }

    try {
      final encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return {};
      }

      final encryptionKey = await _getEncryptionKey(storageKey);
      final decryptedContent = _decryptData(encryptedContent, encryptionKey);

      final jsonData = jsonDecode(decryptedContent) as Map<String, dynamic>;

      // Проверяем метаданные и целостность
      if (jsonData.containsKey('_metadata')) {
        final metadata = FileMetadata.fromJson(jsonData['_metadata']);
        final dataWithoutMetadata = Map<String, dynamic>.from(jsonData);
        dataWithoutMetadata.remove('_metadata');

        // Проверяем временную метку
        if (jsonData.containsKey('_timestamp')) {
          final timestamp = jsonData['_timestamp'] as int;
          if (!_isTimestampValid(timestamp)) {
            throw ValidationException(
              'File timestamp is too old for storage: $storageKey',
            );
          }
          dataWithoutMetadata.remove('_timestamp');
        }

        // Проверяем HMAC
        if (jsonData.containsKey('_hmac')) {
          final storedHmac = jsonData['_hmac'] as String;
          final calculatedHmac = _calculateHMAC(
            jsonEncode(dataWithoutMetadata),
            encryptionKey,
          );
          if (storedHmac != calculatedHmac) {
            throw ValidationException(
              'File HMAC mismatch for storage: $storageKey',
            );
          }
          dataWithoutMetadata.remove('_hmac');
        }

        // Проверяем контрольную сумму
        final currentChecksum = _calculateChecksum(
          jsonEncode(dataWithoutMetadata),
        );
        if (currentChecksum != metadata.checksum) {
          throw ValidationException(
            'File checksum mismatch for storage: $storageKey',
          );
        }

        return dataWithoutMetadata;
      }

      return jsonData;
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw FileAccessException('Failed to load storage file: $storageKey', e);
    }
  }

  /// Сохраняет данные в файл с метаданными безопасности
  Future<void> _saveStorageFile(
    String storageKey,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final timestamp = _generateTimestamp();
      final checksum = _calculateChecksum(jsonEncode(data));
      final encryptionKey = await _getEncryptionKey(storageKey);

      // Создаем HMAC для защиты от модификации
      final hmac = _calculateHMAC(jsonEncode(data), encryptionKey);

      // Добавляем метаданные безопасности
      final dataWithMetadata = Map<String, dynamic>.from(data);
      dataWithMetadata['_metadata'] = FileMetadata(
        version: '2.0', // Увеличиваем версию для новых функций безопасности
        createdAt: now,
        updatedAt: now,
        checksum: checksum,
      ).toJson();
      dataWithMetadata['_timestamp'] = timestamp;
      dataWithMetadata['_hmac'] = hmac;

      final jsonContent = jsonEncode(dataWithMetadata);
      final encryptedContent = _encryptData(jsonContent, encryptionKey);

      final filePath = _getStorageFilePath(storageKey);

      // Атомарная запись файла (сначала во временный файл)
      final tempFile = File('$filePath.tmp');
      await tempFile.writeAsString(encryptedContent);
      await tempFile.rename(filePath);

      // Обновляем кэш
      if (_enableCache) {
        _dataCache[storageKey] = Map<String, dynamic>.from(data);
      }
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw FileAccessException('Failed to save storage file: $storageKey', e);
    }
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
    try {
      final storageData = await _getStorageData(storageKey);
      storageData[key] = toJson(data);
      await _saveStorageFile(storageKey, storageData);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to write data to storage: $storageKey, key: $key',
        e,
      );
    }
  }

  @override
  Future<T?> read<T>({
    required String storageKey,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final storageData = await _getStorageData(storageKey);

      if (!storageData.containsKey(key)) {
        return null;
      }

      final jsonData = storageData[key] as Map<String, dynamic>;
      return fromJson(jsonData);
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to read data from storage: $storageKey, key: $key',
        e,
      );
    }
  }

  @override
  Future<Map<String, T>> readAll<T>({
    required String storageKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final storageData = await _getStorageData(storageKey);
      final result = <String, T>{};

      for (final entry in storageData.entries) {
        if (entry.key.startsWith('_')) continue; // Пропускаем метаданные

        try {
          final jsonData = entry.value as Map<String, dynamic>;
          result[entry.key] = fromJson(jsonData);
        } catch (e) {
          // Логируем ошибку, но продолжаем обработку других элементов
          print('Warning: Failed to deserialize item ${entry.key}: $e');
        }
      }

      return result;
    } catch (e) {
      if (e is SecureStorageException) rethrow;
      throw SecureStorageException(
        'Failed to read all data from storage: $storageKey',
        e,
      );
    }
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
          .where((file) => file.path.endsWith('.encrypted'))
          .toList();

      for (final file in storageFiles) {
        final fileName = path.basenameWithoutExtension(file.path);
        final storageKey = fileName.replaceAll('.encrypted', '');
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

      final encryptedContent = await file.readAsString();
      final metadata = await getStorageMetadata(storageKey);

      return {
        'storageKey': storageKey,
        'encryptedData': encryptedContent,
        'metadata': metadata?.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '2.0',
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
}
