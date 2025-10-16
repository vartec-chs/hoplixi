import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/models/token_oauth.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';

/// Сервис для работы с существующими OAuth2 токенами
class TokenAuthService {
  static const String _tag = 'TokenAuthService';

  final OAuth2Account _account;
  final Map<String, OAuth2RestClient> _clients;

  TokenAuthService({
    required OAuth2Account account,
    required Map<String, OAuth2RestClient> clients,
  }) : _account = account,
       _clients = clients;

  /// Авторизация с использованием существующего токена
  Future<ServiceResult<String>> authorizeWithToken(TokenInfo tokenInfo) async {
    logInfo('Authorizing with existing token', tag: _tag);
    final TokenOAuth tokenOAuth = tokenInfo.token;
    OAuth2Token token = OAuth2TokenF.fromJsonString(tokenOAuth.tokenJson);

    final key = tokenInfo.key;
    final clientResult = await _getOrRefreshClient(token);

    if (!clientResult.success) {
      return ServiceResult.failure(clientResult.message ?? 'Unknown error');
    }

    _clients[key] = clientResult.data!;
    return ServiceResult.success(data: key);
  }

  /// Получить или обновить токен и создать клиент
  Future<ServiceResult<OAuth2RestClient>> _getOrRefreshClient(
    OAuth2Token token,
  ) async {
    try {
      if (token.timeToLogin) {
        logInfo('Token expired, attempting to relogin', tag: _tag);
        token = await _account.forceRelogin(token) as OAuth2Token;
      }

      final client = await _account.createClient(token);
      return ServiceResult.success(data: client);
    } catch (e, stack) {
      logError(
        'Failed to create client, attempting token refresh',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );

      try {
        final newToken = await _account.refreshToken(token);
        if (newToken == null) {
          return ServiceResult.failure('Failed to refresh expired token');
        }

        final client = await _account.createClient(newToken);
        return ServiceResult.success(data: client);
      } catch (e, stack) {
        logError(
          'Failed to create client after token refresh',
          error: e,
          stackTrace: stack,
          tag: _tag,
        );
        return ServiceResult.failure(
          'Failed to create client after token refresh',
        );
      }
    }
  }
}
