import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'utils.dart';
import 'errors.dart';

/// Encryption wrapper for AEAD encryption/decryption using AES-GCM.
class CryptoBox {
  final SecretKey _secretKey;
  final AesGcm _algorithm;

  CryptoBox._(this._secretKey) : _algorithm = AesGcm.with256bits();

  /// Create CryptoBox from raw key bytes.
  static CryptoBox fromRawKey(List<int> rawKey) {
    if (rawKey.length != 32) {
      throw ArgumentError('Raw key must be 32 bytes for AES-256');
    }
    final secretKey = SecretKey(rawKey);
    return CryptoBox._(secretKey);
  }

  /// Create CryptoBox from password using PBKDF2.
  static Future<CryptoBox> fromPassword(
    String password,
    List<int> salt, {
    int iterations = 120000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    return CryptoBox._(secretKey);
  }

  /// Encrypt UTF-8 plaintext with given nonce.
  // Future<Map<String, String>> encryptUtf8WithNonce(
  //   List<int> nonce,
  //   String plaintext,
  // ) async {
  //   try {
  //     final plaintextBytes = utf8.encode(plaintext);

  //     final secretBox = await _algorithm.encrypt(
  //       plaintextBytes,
  //       secretKey: _secretKey,
  //       nonce: nonce,
  //     );

  //     return {
  //       'payload': BoxUtils.bytesToBase64(secretBox.cipherText),
  //       'nonce': BoxUtils.bytesToBase64(nonce),
  //       'mac': BoxUtils.bytesToBase64(secretBox.mac.bytes),
  //     };
  //   } catch (e) {
  //     throw DecryptionError('Failed to encrypt data', e);
  //   }
  // }

  Future<Map<String, String>> encryptUtf8WithAutoNonce(String plaintext) async {
    try {
      final plaintextBytes = utf8.encode(plaintext);
      final nonce = _algorithm.newNonce();

      final secretBox = await _algorithm.encrypt(
        plaintextBytes,
        secretKey: _secretKey,
        nonce: nonce,
      );

      return {
        'payload': BoxUtils.bytesToBase64(secretBox.cipherText),
        'nonce': BoxUtils.bytesToBase64(nonce),
        'mac': BoxUtils.bytesToBase64(secretBox.mac.bytes),
      };
    } catch (e) {
      throw DecryptionError('Failed to encrypt data', e);
    }
  }

  /// Decrypt from container with payload, nonce, and MAC.
  Future<String> decryptFromContainer(Map<String, dynamic> container) async {
    try {
      final payload = container['payload'] as String?;
      final nonceStr = container['nonce'] as String?;
      final macStr = container['mac'] as String?;

      if (payload == null || nonceStr == null || macStr == null) {
        throw DecryptionError('Missing encryption fields in container');
      }

      final cipherText = BoxUtils.base64ToBytes(payload);
      final nonce = BoxUtils.base64ToBytes(nonceStr);
      final mac = Mac(BoxUtils.base64ToBytes(macStr));

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: _secretKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw DecryptionError('Failed to decrypt data', e);
    }
  }
}
