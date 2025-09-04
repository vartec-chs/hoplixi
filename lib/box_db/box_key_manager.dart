import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils.dart';
import 'errors.dart';

/// Manager for box encryption keys using secure storage.
class BoxKeyManager {
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'box_key:';

  BoxKeyManager([FlutterSecureStorage? secureStorage])
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get or create a raw key for the box.
  Future<Uint8List> getOrCreateKey(String boxName, {int keyLen = 32}) async {
    final existingKey = await readKey(boxName);
    if (existingKey != null) {
      return existingKey;
    }

    // Generate new key
    final newKey = _generateRandomKey(keyLen);
    await setKey(boxName, newKey);
    return newKey;
  }

  /// Read existing key for the box.
  Future<Uint8List?> readKey(String boxName) async {
    try {
      final keyStr = await _secureStorage.read(key: _keyPrefix + boxName);
      if (keyStr == null) {
        return null;
      }
      return BoxUtils.base64ToBytes(keyStr);
    } catch (e) {
      throw KeyMissingError('Failed to read key for box: $boxName', e);
    }
  }

  /// Set key for the box.
  Future<void> setKey(String boxName, List<int> rawKey) async {
    try {
      final keyStr = BoxUtils.bytesToBase64(rawKey);
      await _secureStorage.write(key: _keyPrefix + boxName, value: keyStr);
    } catch (e) {
      throw KeyMissingError('Failed to set key for box: $boxName', e);
    }
  }

  /// Delete key for the box.
  Future<void> deleteKey(String boxName) async {
    try {
      await _secureStorage.delete(key: _keyPrefix + boxName);
    } catch (e) {
      throw KeyMissingError('Failed to delete key for box: $boxName', e);
    }
  }

  /// Generate cryptographically secure random key.
  Uint8List _generateRandomKey(int length) {
    final random = Random.secure();
    final key = Uint8List(length);
    for (int i = 0; i < length; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }
}
