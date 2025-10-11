import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/services/biometric_service.dart';

/// Провайдер сервиса биометрической аутентификации
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
