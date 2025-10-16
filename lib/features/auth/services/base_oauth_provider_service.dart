import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/models/token_oauth.dart';

/// Базовый класс для работы с OAuth2 провайдерами
/// Содержит общую логику refresh, relogin и создания клиента
abstract class BaseOAuthProviderService {
  final OAuth2Account account;
  final String tag;
  final Map<String, OAuth2RestClient> clients;

  BaseOAuthProviderService({
    required this.account,
    required this.tag,
    required this.clients,
  });

  /// Получить или обновить токен и создать клиент
  Future<ServiceResult<OAuth2RestClient>> getOrRefreshClient(
    TokenOAuth tokenOAuth,
  ) async {
    try {
      OAuth2Token token = OAuth2TokenF.fromJsonString(tokenOAuth.tokenJson);

      if (token.timeToLogin) {
        logInfo('Token expired, attempting to relogin', tag: tag);
        token = await account.forceRelogin(token) as OAuth2Token;
      }

      final client = await account.createClient(token);
      return ServiceResult.success(data: client);
    } catch (e, stack) {
      logError(
        'Failed to create client, attempting token refresh',
        error: e,
        stackTrace: stack,
        tag: tag,
      );

      try {
        final OAuth2Token token = OAuth2TokenF.fromJsonString(
          tokenOAuth.tokenJson,
        );
        final newToken = await account.refreshToken(token);

        if (newToken == null) {
          return ServiceResult.failure('Failed to refresh expired token');
        }

        final client = await account.createClient(newToken);
        return ServiceResult.success(data: client);
      } catch (e, stack) {
        logError(
          'Failed to create client after token refresh',
          error: e,
          stackTrace: stack,
          tag: tag,
        );
        return ServiceResult.failure(
          'Failed to create client after token refresh',
        );
      }
    }
  }

  /// Выполнить авторизацию через провайдера
  Future<ServiceResult<String>> authorize(
    dynamic provider,
    void Function(String error)? onError,
  ) async {
    try {
      logInfo('Starting authorization for ${provider.name}', tag: tag);

      final token = await account.newLogin(
        provider.name,
        errorCallback: onError,
      );

      if (token == null) {
        logInfo(
          'Authorization cancelled or failed for ${provider.name}',
          tag: tag,
        );
        return ServiceResult.failure(
          'Авторизация отменена или не удалась. Попробуйте еще раз.',
        );
      }

      final key = account.keyFor(provider.name, token.userName);

      // Создаём клиент
      final client = await account.createClient(token);

      // Сохраняем клиент в общий кэш
      clients[key] = client;

      logInfo(
        'Authorization successful for ${provider.name}, key: $key',
        tag: tag,
      );
      return ServiceResult.success(data: key);
    } catch (e, stack) {
      logError(
        'Failed to authorize ${provider.name}',
        error: e,
        stackTrace: stack,
        tag: tag,
      );

      // Более детальное сообщение об ошибке
      String errorMessage = 'Ошибка авторизации';
      if (e.toString().contains('cancelled')) {
        errorMessage = 'Авторизация отменена пользователем';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
      } else {
        errorMessage = 'Ошибка авторизации: ${e.toString()}';
      }

      return ServiceResult.failure(errorMessage);
    }
  }
}
