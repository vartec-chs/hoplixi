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
    OAuth2Token mainToken,
  ) async {
    logInfo(
      'Getting or refreshing client for token',
      tag: _tag,
      data: {'token': mainToken.toJsonString()},
    );
    OAuth2Token token = mainToken;
    try {
      // timeToRefresh: access token истёк и нужен рефреш
      if (token.timeToRefresh) {
        logInfo(
          'Access token expired, attempting to refresh',
          tag: _tag,
          data: {'iss': token.iss, 'userName': token.userName},
        );
        final refreshed = await _account.refreshToken(token);
        logInfo(
          'Refresh token result',
          tag: _tag,
          data: {
            'refreshed': refreshed?.toJsonString(),
            'iss': token.iss,
            'userName': token.userName,
          },
        );
        if (refreshed == null) {
          // Refresh token тоже истёк - нужна переавторизация
          logInfo(
            'Refresh token expired, attempting to relogin',
            tag: _tag,
            data: {'iss': token.iss, 'userName': token.userName},
          );
          final relogin = await _account.forceRelogin(token);
          if (relogin == null) {
            return ServiceResult.failure('Failed to refresh or relogin');
          }
          token = relogin;
        } else {
          token = refreshed;
        }
      }

      final client = await _account.createClient(token);
      return ServiceResult.success(data: client);
    } catch (e, stack) {
      logError(
        'Failed to get or refresh client',
        error: e,
        stackTrace: stack,
        tag: _tag,
        data: {'tokenIss': token.iss, 'tokenUserName': token.userName},
      );
      return ServiceResult.failure(
        'Failed to get or refresh client: ${e.toString()}',
      );
    }
  }
}
