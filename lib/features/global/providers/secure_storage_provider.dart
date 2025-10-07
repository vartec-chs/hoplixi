import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageImpl(); // или с опциями
});
