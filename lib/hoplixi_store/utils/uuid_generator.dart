import 'package:uuid/uuid.dart';

class UuidGenerator {
  static const _uuid = Uuid();

  /// Generates a new UUID v4
  static String generate() {
    return _uuid.v4();
  }
}
