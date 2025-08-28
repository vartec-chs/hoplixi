import 'dart:typed_data';
import 'services/crypto_service.dart';

/// Утилиты для криптографических операций
///
/// УСТАРЕЛ: Используйте CryptoService для новых проектов
/// Этот класс сохранен для обратной совместимости
@Deprecated('Используйте CryptoService вместо CryptoUtils')
class CryptoUtils {
  static final ICryptoService _service = CryptoService();

  /// Генерация криптографически стойкой соли
  static String generateSecureSalt() {
    return _service.generateSecureSalt();
  }

  /// PBKDF2-подобное хеширование с улучшенными параметрами
  static String hashPassword(String password, String salt) {
    return _service.hashPassword(password, salt);
  }

  /// Деривация ключа шифрования
  static Uint8List deriveKey(String password, String salt) {
    return _service.deriveKey(password, salt);
  }

  /// Безопасная проверка пароля с защитой от timing attacks
  static bool verifyPassword(String password, String hash, String salt) {
    return _service.verifyPassword(password, hash, salt);
  }

  /// Генерация данных пароля (хеш + соль)
  static Map<String, String> generatePasswordData(String password) {
    return _service.generatePasswordData(password);
  }

  /// Безопасная очистка чувствительных данных из памяти
  static void clearSensitiveData(Uint8List? data) {
    _service.clearSensitiveData(data);
  }
}
