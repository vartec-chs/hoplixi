import 'dart:convert';
import 'dart:typed_data';

/// Класс для управления криптографическими ключами
/// Обрабатывает конвертацию между base64 и Uint8List
class CryptoKeys {
  final Uint8List _aesKey;
  final Uint8List _hmacKey;

  /// Приватный конструктор
  CryptoKeys._(this._aesKey, this._hmacKey);

  /// Создание из base64 строк
  /// Декодирует ключи из base64 в Uint8List
  factory CryptoKeys.fromBase64({
    required String aesKeyBase64,
    required String hmacKeyBase64,
  }) {
    try {
      final aesKey = base64.decode(aesKeyBase64);
      final hmacKey = base64.decode(hmacKeyBase64);

      // Проверяем размер ключей
      if (aesKey.length != 32) {
        throw ArgumentError(
          'AES ключ должен быть 32 байта (256 бит), получено: ${aesKey.length}',
        );
      }

      if (hmacKey.length != 32) {
        throw ArgumentError(
          'HMAC ключ должен быть 32 байта, получено: ${hmacKey.length}',
        );
      }

      return CryptoKeys._(
        Uint8List.fromList(aesKey),
        Uint8List.fromList(hmacKey),
      );
    } on FormatException catch (e) {
      throw ArgumentError('Ошибка декодирования base64: $e');
    }
  }

  /// Создание из Uint8List
  factory CryptoKeys.fromBytes({
    required Uint8List aesKey,
    required Uint8List hmacKey,
  }) {
    // Проверяем размер ключей
    if (aesKey.length != 32) {
      throw ArgumentError(
        'AES ключ должен быть 32 байта (256 бит), получено: ${aesKey.length}',
      );
    }

    if (hmacKey.length != 32) {
      throw ArgumentError(
        'HMAC ключ должен быть 32 байта, получено: ${hmacKey.length}',
      );
    }

    return CryptoKeys._(aesKey, hmacKey);
  }

  /// Получить AES ключ в виде Uint8List (для шифрования/дешифрования)
  Uint8List get aesKey => _aesKey;

  /// Получить HMAC ключ в виде Uint8List (для шифрования/дешифрования)
  Uint8List get hmacKey => _hmacKey;

  /// Получить AES ключ в виде base64 строки (для сохранения/передачи)
  String get aesKeyBase64 => base64.encode(_aesKey);

  /// Получить HMAC ключ в виде base64 строки (для сохранения/передачи)
  String get hmacKeyBase64 => base64.encode(_hmacKey);

  /// Получить оба ключа в виде Map для удобного сохранения в JSON
  Map<String, String> toJson() {
    return {'aesKey': aesKeyBase64, 'hmacKey': hmacKeyBase64};
  }

  /// Создать из JSON Map
  factory CryptoKeys.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('aesKey') || !json.containsKey('hmacKey')) {
      throw ArgumentError('JSON должен содержать поля "aesKey" и "hmacKey"');
    }

    return CryptoKeys.fromBase64(
      aesKeyBase64: json['aesKey'] as String,
      hmacKeyBase64: json['hmacKey'] as String,
    );
  }

  /// Вывести ключи в читаемом формате (для отладки)
  @override
  String toString() {
    return 'CryptoKeys(\n'
        '  AES-256 Key: $aesKeyBase64\n'
        '  HMAC Key: $hmacKeyBase64\n'
        ')';
  }
}
