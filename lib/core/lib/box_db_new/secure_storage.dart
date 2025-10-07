import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/index.dart';

/// Заглушка для SecureStorage (для использования без Flutter)
/// В будущем можно заменить на FlutterSecureStorage
class MemorySecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_storage);
  }

  /// Получить количество сохранённых ключей (для отладки)
  int get length => _storage.length;

  /// Получить все ключи (для отладки)
  List<String> get keys => _storage.keys.toList();
}

// /// Реализация SecureStorage с использованием FlutterSecureStorage
// class FlutterSecureStorageImpl implements SecureStorage {
//   final FlutterSecureStorage _storage;

//   FlutterSecureStorageImpl({FlutterSecureStorage? storage})
//     : _storage = storage ?? const FlutterSecureStorage();

//   @override
//   Future<String?> read(String key) async {
//     return await _storage.read(key: key);
//   }

//   @override
//   Future<void> write(String key, String value) async {
//     await _storage.write(key: key, value: value);
//   }

//   @override
//   Future<void> delete(String key) async {
//     await _storage.delete(key: key);
//   }

//   @override
//   Future<bool> containsKey(String key) async {
//     return await _storage.containsKey(key: key);
//   }

//   @override
//   Future<void> deleteAll() async {
//     await _storage.deleteAll();
//   }

//   @override
//   Future<Map<String, String>> readAll() async {
//     return await _storage.readAll();
//   }
// }
