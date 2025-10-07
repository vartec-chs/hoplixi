import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

abstract class SecureStorage {
  /// Прочитать значение по ключу
  Future<String?> read(String key);

  /// Записать значение
  Future<void> write(String key, String value);

  /// Удалить значение
  Future<void> delete(String key);

  /// Проверить существование ключа
  Future<bool> containsKey(String key);

  /// Очистить все значения
  Future<void> deleteAll();

  // read all keys (for debugging)
  Future<Map<String, String>> readAll();
}

class FlutterSecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _store;

  FlutterSecureStorageImpl({FlutterSecureStorage? underlying})
    : _store =
          underlying ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
            lOptions: LinuxOptions(),
            wOptions: WindowsOptions(useBackwardCompatibility: true),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  @override
  Future<void> write(String key, String value) =>
      _store.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _store.read(key: key);

  @override
  Future<void> delete(String key) => _store.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _store.containsKey(key: key);

  @override
  Future<void> deleteAll() => _store.deleteAll();

  @override
  Future<Map<String, String>> readAll() => _store.readAll();
}

