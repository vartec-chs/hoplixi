import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/logger/app_logger.dart';
import 'service_results.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Сервис для работы с биометрической аутентификацией
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Проверяет, поддерживает ли устройство биометрическую аутентификацию
  Future<ServiceResult<bool>> isDeviceSupported() async {
    try {
      logDebug(
        'Проверка поддержки биометрии устройством',
        tag: 'BiometricService',
      );

      final isSupported = await _auth.isDeviceSupported();

      logInfo('Поддержка биометрии: $isSupported', tag: 'BiometricService');

      return ServiceResult.success(
        data: isSupported,
        message: isSupported
            ? 'Устройство поддерживает биометрию'
            : 'Устройство не поддерживает биометрию',
      );
    } on PlatformException catch (e) {
      logError(
        'Ошибка проверки поддержки биометрии',
        error: e,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Ошибка проверки поддержки: ${e.message}');
    } catch (e, stackTrace) {
      logError(
        'Неизвестная ошибка проверки поддержки биометрии',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Проверяет, может ли устройство проверять биометрию
  Future<ServiceResult<bool>> canCheckBiometrics() async {
    try {
      logDebug(
        'Проверка возможности проверки биометрии',
        tag: 'BiometricService',
      );

      final canCheck = await _auth.canCheckBiometrics;

      logInfo(
        'Возможность проверки биометрии: $canCheck',
        tag: 'BiometricService',
      );

      return ServiceResult.success(
        data: canCheck,
        message: canCheck
            ? 'Биометрия доступна для проверки'
            : 'Биометрия недоступна для проверки',
      );
    } on PlatformException catch (e) {
      logError(
        'Ошибка проверки возможности биометрии',
        error: e,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Ошибка проверки возможности: ${e.message}');
    } catch (e, stackTrace) {
      logError(
        'Неизвестная ошибка проверки возможности биометрии',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Получает список доступных биометрических типов
  Future<ServiceResult<List<BiometricType>>> getAvailableBiometrics() async {
    try {
      logDebug(
        'Получение доступных биометрических типов',
        tag: 'BiometricService',
      );

      final availableBiometrics = await _auth.getAvailableBiometrics();

      logInfo(
        'Доступные биометрические типы: ${availableBiometrics.map((e) => e.name).join(', ')}',
        tag: 'BiometricService',
      );

      return ServiceResult.success(
        data: availableBiometrics,
        message: 'Найдено типов биометрии: ${availableBiometrics.length}',
      );
    } on PlatformException catch (e) {
      logError(
        'Ошибка получения доступных биометрий',
        error: e,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Ошибка получения биометрий: ${e.message}');
    } catch (e, stackTrace) {
      logError(
        'Неизвестная ошибка получения доступных биометрий',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Выполняет биометрическую аутентификацию
  Future<ServiceResult<BiometricAuthResult>> authenticate({
    String localizedReason = 'Подтвердите свою личность',
    bool biometricOnly = false,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      logInfo('Начало биометрической аутентификации', tag: 'BiometricService');

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
        ),
      );

      logInfo(
        'Результат аутентификации: ${authenticated ? 'успешно' : 'неудачно'}',
        tag: 'BiometricService',
      );

      return ServiceResult.success(
        data: authenticated
            ? BiometricAuthResult.authenticated
            : BiometricAuthResult.failed,
        message: authenticated
            ? 'Аутентификация успешна'
            : 'Аутентификация отменена или неудачна',
      );
    } on PlatformException catch (e) {
      logError(
        'Ошибка биометрической аутентификации',
        error: e,
        tag: 'BiometricService',
      );
      if (e.code == auth_error.lockedOut) {
        return ServiceResult.success(
          data: BiometricAuthResult.lockedOut,
          message:
              'Биометрическая аутентификация временно заблокирована из-за слишком многих неудачных попыток. Попробуйте позже.',
        );
      }
      return ServiceResult.error('Ошибка аутентификации: ${e.message}');
    } catch (e, stackTrace) {
      logError(
        'Неизвестная ошибка биометрической аутентификации',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Выполняет аутентификацию только с биометрией (без PIN/пароля)
  Future<ServiceResult<BiometricAuthResult>> authenticateWithBiometrics({
    String localizedReason = 'Используйте биометрию для подтверждения',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    return authenticate(
      localizedReason: localizedReason,
      biometricOnly: true,
      useErrorDialogs: useErrorDialogs,
      stickyAuth: stickyAuth,
    );
  }

  /// Останавливает текущую аутентификацию
  Future<ServiceResult<bool>> stopAuthentication() async {
    try {
      logDebug('Остановка аутентификации', tag: 'BiometricService');

      await _auth.stopAuthentication();

      logInfo('Аутентификация остановлена', tag: 'BiometricService');

      return ServiceResult.success(
        data: true,
        message: 'Аутентификация остановлена',
      );
    } on PlatformException catch (e) {
      logError(
        'Ошибка остановки аутентификации',
        error: e,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Ошибка остановки: ${e.message}');
    } catch (e, stackTrace) {
      logError(
        'Неизвестная ошибка остановки аутентификации',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Комплексная проверка готовности к биометрической аутентификации
  Future<ServiceResult<BiometricStatus>> checkBiometricStatus() async {
    try {
      logDebug(
        'Комплексная проверка статуса биометрии',
        tag: 'BiometricService',
      );

      final isSupported = await isDeviceSupported();
      if (!isSupported.success || !isSupported.data!) {
        return ServiceResult.success(
          data: BiometricStatus.notSupported,
          message: 'Биометрия не поддерживается устройством',
        );
      }

      final canCheck = await canCheckBiometrics();
      if (!canCheck.success || !canCheck.data!) {
        return ServiceResult.success(
          data: BiometricStatus.notAvailable,
          message: 'Биометрия недоступна для проверки',
        );
      }

      final availableTypes = await getAvailableBiometrics();
      if (!availableTypes.success || availableTypes.data!.isEmpty) {
        return ServiceResult.success(
          data: BiometricStatus.noBiometricsEnrolled,
          message: 'Нет зарегистрированных биометрических данных',
        );
      }

      return ServiceResult.success(
        data: BiometricStatus.ready,
        message: 'Биометрия готова к использованию',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка комплексной проверки биометрии',
        error: e,
        stackTrace: stackTrace,
        tag: 'BiometricService',
      );
      return ServiceResult.error('Ошибка проверки статуса: ${e.toString()}');
    }
  }
}

/// Статус биометрической аутентификации
enum BiometricStatus {
  /// Биометрия не поддерживается устройством
  notSupported,

  /// Биометрия поддерживается, но недоступна для проверки
  notAvailable,

  /// Биометрия поддерживается, но нет зарегистрированных данных
  noBiometricsEnrolled,

  /// Биометрия готова к использованию
  ready,

  /// Биометрия временно заблокирована из-за слишком многих неудачных попыток
  lockedOut,
}

/// Результат биометрической аутентификации
enum BiometricAuthResult {
  /// Аутентификация успешна
  authenticated,

  /// Аутентификация неудачна
  failed,

  /// Биометрия заблокирована
  lockedOut,
}
