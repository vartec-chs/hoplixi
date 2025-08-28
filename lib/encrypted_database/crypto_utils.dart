import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Утилиты для криптографических операций
class CryptoUtils {
  static const int _saltLength = 32;
  static const int _iterations = 100000; // Увеличено с 10000 для безопасности

  /// Генерация криптографически стойкой соли
  static String generateSecureSalt() {
    final random = Random.secure();
    final bytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  /// PBKDF2-подобное хеширование с улучшенными параметрами
  static String hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < _iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64.encode(bytes);
  }

  /// Деривация ключа шифрования
  static Uint8List deriveKey(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    for (int i = 0; i < _iterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return Uint8List.fromList(bytes);
  }

  /// Безопасная проверка пароля с защитой от timing attacks
  static bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return _secureCompare(computedHash, hash);
  }

  /// Генерация данных пароля (хеш + соль)
  static Map<String, String> generatePasswordData(String password) {
    final salt = generateSecureSalt();
    final hash = hashPassword(password, salt);
    return {'hash': hash, 'salt': salt};
  }

  /// Защита от timing attacks при сравнении строк
  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Безопасная очистка чувствительных данных из памяти
  static void clearSensitiveData(Uint8List? data) {
    if (data != null) {
      data.fillRange(0, data.length, 0);
    }
  }
}
