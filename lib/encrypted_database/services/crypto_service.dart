import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Интерфейс для криптографического сервиса
abstract class ICryptoService {
  /// Генерирует криптографически стойкую соль
  String generateSecureSalt();

  /// Хеширует пароль с использованием соли
  String hashPassword(String password, String salt);

  /// Выводит ключ шифрования из пароля и соли
  Uint8List deriveKey(String password, String salt);

  /// Проверяет пароль с защитой от timing attacks
  bool verifyPassword(String password, String hash, String salt);

  /// Генерирует данные пароля (хеш + соль)
  Map<String, String> generatePasswordData(String password);

  /// Безопасно очищает чувствительные данные из памяти
  void clearSensitiveData(Uint8List? data);
}

/// Реализация криптографического сервиса
class CryptoService implements ICryptoService {
  static const int _saltLength = 32;
  static const int _iterations = 100000; // Увеличено для безопасности

  @override
  String generateSecureSalt() {
    final random = Random.secure();
    final bytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  @override
  String hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < _iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64.encode(bytes);
  }

  @override
  Uint8List deriveKey(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < _iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return _secureCompare(computedHash, hash);
  }

  @override
  Map<String, String> generatePasswordData(String password) {
    final salt = generateSecureSalt();
    final hash = hashPassword(password, salt);
    return {'hash': hash, 'salt': salt};
  }

  @override
  void clearSensitiveData(Uint8List? data) {
    if (data != null) {
      data.fillRange(0, data.length, 0);
    }
  }

  /// Защита от timing attacks при сравнении строк
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
