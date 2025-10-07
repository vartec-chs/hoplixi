import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';

/// Сервис для шифрования и расшифровки данных
class EncryptionService {
  final SecretKey _key;
  final AesGcm _algorithm = AesGcm.with256bits();

  EncryptionService(this._key);

  /// Создать сервис из пароля
  static Future<EncryptionService> fromPassword(String password) async {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    final key = SecretKey(hash.bytes);
    return EncryptionService(key);
  }

  /// Создать сервис с новым случайным ключом
  static Future<EncryptionService> generate() async {
    final algorithm = AesGcm.with256bits();
    final key = await algorithm.newSecretKey();
    return EncryptionService(key);
  }

  /// Получить ключ в виде строки для сохранения
  Future<String> exportKey() async {
    final keyBytes = await _key.extractBytes();
    return base64Url.encode(keyBytes);
  }

  /// Восстановить сервис из сохраненного ключа
  static EncryptionService fromExportedKey(String exportedKey) {
    final keyBytes = base64Url.decode(exportedKey);
    final key = SecretKey(keyBytes);
    return EncryptionService(key);
  }

  /// Зашифровать данные
  Future<EncryptedData> encrypt(String plaintext) async {
    final bytes = utf8.encode(plaintext);
    final secretBox = await _algorithm.encrypt(bytes, secretKey: _key);

    return EncryptedData(
      ciphertext: base64Url.encode(secretBox.cipherText),
      nonce: base64Url.encode(secretBox.nonce),
      mac: base64Url.encode(secretBox.mac.bytes),
    );
  }

  /// Расшифровать данные
  Future<String> decrypt(EncryptedData encrypted) async {
    final cipherText = base64Url.decode(encrypted.ciphertext);
    final nonce = base64Url.decode(encrypted.nonce);
    final mac = Mac(base64Url.decode(encrypted.mac));

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    try {
      final decrypted = await _algorithm.decrypt(secretBox, secretKey: _key);
      return utf8.decode(decrypted);
    } catch (e) {
      throw EncryptionException('Не удалось расшифровать данные: $e');
    }
  }
}

/// Зашифрованные данные
class EncryptedData {
  final String ciphertext;
  final String nonce;
  final String mac;

  EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'nonce': nonce,
    'mac': mac,
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
    );
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
