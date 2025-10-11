import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/services/biometric_service.dart';

/// Провайдер сервиса биометрической аутентификации
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
