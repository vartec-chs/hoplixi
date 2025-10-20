import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Dropbox
class DropboxAuthService extends BaseOAuthProviderService {
  static const String _tag = 'DropboxAuthService';

  DropboxAuthService(
    OAuth2Account account,
    Map<String, OAuth2RestClient> clients,
  ) : super(account: account, tag: _tag, clients: clients);
}
