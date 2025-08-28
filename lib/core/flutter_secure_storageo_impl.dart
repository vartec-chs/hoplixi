import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

abstract class SecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<Map<String, String>> readAll();
  Future<void> deleteAll();
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
  Future<void> write({required String key, required String value}) =>
      _store.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _store.read(key: key);

  @override
  Future<void> delete({required String key}) => _store.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => _store.readAll();

  @override
  Future<void> deleteAll() => _store.deleteAll();
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageImpl(); // или с опциями
});
