import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:hoplixi/core/lib/oauth2restclient/src/provider/oauth2_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/models/auth_state.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';

/// Notifier для управления процессом авторизации
class AuthorizationNotifier extends Notifier<AuthState> {
  static const String _tag = 'AuthorizationNotifier';

  OAuth2AccountService? _accountService;

  @override
  AuthState build() {
    // Слушаем изменения сервиса
    ref.listen(oauth2AccountProvider, (previous, next) {
      next.whenData((service) {
        _accountService = service;
      });
    });

    return const AuthState.idle();
  }

  /// Запуск процесса авторизации
  Future<void> startAuthorization({
    required AuthClientConfig credential,
    required String returnPath,
  }) async {
    logInfo(
      'Starting authorization for ${credential.type.name}',
      tag: _tag,
      data: {'returnPath': returnPath},
    );

    // Сначала валидируем существующий токен
    state = AuthState.validatingToken(
      credential: credential,
      returnPath: returnPath,
    );

    try {
      final validationResult = await _validateExistingToken(credential);

      if (validationResult != null) {
        // Токен валиден, используем его
        logInfo('Valid token found for ${credential.type.name}', tag: _tag);

        state = AuthState.success(
          clientKey: validationResult,
          returnPath: returnPath,
        );
        return;
      }

      // Токена нет или он невалиден, запускаем авторизацию
      await _performAuthorization(credential, returnPath);
    } catch (e, stack) {
      logError(
        'Authorization failed for ${credential.type.name}',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );

      state = AuthState.failure(
        error: e.toString(),
        credential: credential,
        returnPath: returnPath,
      );
    }
  }

  /// Проверка существующего токена
  Future<String?> _validateExistingToken(AuthClientConfig credential) async {
    try {
      final service = _accountService ?? await _getAccountService();
      if (service == null) {
        logError('Account service is not available', tag: _tag);
        return null;
      }

      // Пытаемся найти существующий токен
      final result = await service.validateAndUseExistingToken(credential);

      if (result.success && result.data != null) {
        return result.data;
      }

      return null;
    } catch (e, stack) {
      logError(
        'Token validation failed',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      return null;
    }
  }

  /// Выполнение авторизации
  Future<void> _performAuthorization(
    AuthClientConfig credential,
    String returnPath,
  ) async {
    state = AuthState.authorizing(
      credential: credential,
      returnPath: returnPath,
      message: 'Авторизация ${credential.type.name}...',
    );

    try {
      final service = _accountService ?? await _getAccountService();
      if (service == null) {
        throw Exception('Account service is not available');
      }

      final result = await service.authorize(
        credential,
        onError: (error) {
          logError('Authorization error: $error', tag: _tag);
        },
      );

      if (result.success && result.data != null) {
        logInfo(
          'Authorization successful for ${credential.type.name}',
          tag: _tag,
        );

        state = AuthState.success(
          clientKey: result.data!,
          returnPath: returnPath,
        );
      } else {
        throw Exception(result.message ?? 'Неизвестная ошибка авторизации');
      }
    } catch (e, stack) {
      logError('Authorization failed', error: e, stackTrace: stack, tag: _tag);

      state = AuthState.failure(
        error: e.toString(),
        credential: credential,
        returnPath: returnPath,
      );
    }
  }

  /// Отмена авторизации
  Future<void> cancel() async {
    logInfo('Authorization cancelled', tag: _tag);

    final currentReturnPath = state.returnPath ?? '/';

    // Отменяем OAuth2 авторизацию (закрываем сервер)
    await OAuth2ProviderF.cancelAuthorization();

    state = AuthState.cancelled(returnPath: currentReturnPath);

    // Сбрасываем состояние после небольшой задержки
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state is AuthStateCancelled) {
        state = const AuthState.idle();
      }
    });
  }

  /// Сброс состояния в idle
  void reset() {
    logInfo('Resetting authorization state', tag: _tag);
    state = const AuthState.idle();
  }

  /// Повторная попытка авторизации
  Future<void> retry() async {
    final currentState = state;

    if (currentState is AuthStateFailure) {
      logInfo('Retrying authorization', tag: _tag);

      await startAuthorization(
        credential: currentState.credential,
        returnPath: currentState.returnPath,
      );
    }
  }

  /// Получение сервиса аккаунта
  Future<OAuth2AccountService?> _getAccountService() async {
    final asyncService = ref.read(oauth2AccountProvider);

    return asyncService.whenOrNull(data: (service) => service);
  }
}

/// Провайдер для управления авторизацией
final authorizationProvider =
    NotifierProvider<AuthorizationNotifier, AuthState>(
      AuthorizationNotifier.new,
    );
