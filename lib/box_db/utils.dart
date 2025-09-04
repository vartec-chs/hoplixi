import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Utility functions for the box storage.
class BoxUtils {
  /// Convert 32-bit integer to big-endian bytes.
  static Uint8List int32ToBytes(int value) {
    final bytes = Uint8List(4);
    bytes[0] = (value >> 24) & 0xFF;
    bytes[1] = (value >> 16) & 0xFF;
    bytes[2] = (value >> 8) & 0xFF;
    bytes[3] = value & 0xFF;
    return bytes;
  }

  /// Read 32-bit integer from big-endian bytes.
  static int readInt32BE(List<int> bytes, [int offset = 0]) {
    if (bytes.length < offset + 4) {
      throw ArgumentError('Not enough bytes to read int32');
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  /// Calculate SHA-256 hash synchronously.
  static Uint8List sha256Sync(List<int> data) {
    final digest = sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Generate deterministic nonce from writer ID and counter.
  static Uint8List generateNonce(String writerId, int counter) {
    final writerHash = sha256Sync(utf8.encode(writerId));
    final nonce = Uint8List(12);

    // First 8 bytes from writer hash
    nonce.setRange(0, 8, writerHash);

    // Last 4 bytes from counter (big-endian)
    final counterBytes = int32ToBytes(counter);
    nonce.setRange(8, 12, counterBytes);

    return nonce;
  }

  /// Encode string to UTF-8 bytes.
  static Uint8List stringToBytes(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  /// Decode UTF-8 bytes to string.
  static String bytesToString(List<int> bytes) {
    return utf8.decode(bytes);
  }

  /// Convert bytes to base64 string.
  static String bytesToBase64(List<int> bytes) {
    return base64.encode(bytes);
  }

  /// Convert base64 string to bytes.
  static Uint8List base64ToBytes(String base64Str) {
    return Uint8List.fromList(base64.decode(base64Str));
  }

  /// Generate timestamp in ISO 8601 format.
  static String getCurrentTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Parse JSON safely.
  static Map<String, dynamic>? tryParseJson(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      return null;
    }
  }

  /// Encode JSON safely.
  static String encodeJson(Map<String, dynamic> data) {
    return json.encode(data);
  }
}
