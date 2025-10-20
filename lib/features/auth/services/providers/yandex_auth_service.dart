import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Yandex
class YandexAuthService extends BaseOAuthProviderService {
  static const String _tag = 'YandexAuthService';

  YandexAuthService(
    OAuth2Account account,
    Map<String, OAuth2RestClient> clients,
  ) : super(account: account, tag: _tag, clients: clients);
}
