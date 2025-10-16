import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/config/oauth2_provider_config.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Dropbox
class DropboxAuthService extends BaseOAuthProviderService {
  static const String _tag = 'DropboxAuthService';

  DropboxAuthService(
    OAuth2Account account,
    Map<String, OAuth2RestClient> clients,
  ) : super(account: account, tag: _tag, clients: clients);

  /// Выполнить авторизацию через Dropbox
  Future<ServiceResult<String>> authorizeWithDropbox(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    if (credential.type != AuthClientType.dropbox) {
      return ServiceResult.failure('Указан неверный тип учётных данных');
    }

    if (!credential.type.isActive) {
      return ServiceResult.failure('Поддержка Dropbox сейчас недоступна');
    }

    final redirectUri = _resolveRedirectUri();

    late Dropbox dropboxProvider;

    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      dropboxProvider = Dropbox(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.dropboxScopes,
      );
    } else {
      dropboxProvider = Dropbox(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.dropboxScopes,
      );
    }

    account.addProvider(dropboxProvider);

    return await authorize(dropboxProvider, onError);
  }

  String _resolveRedirectUri({bool disabledMobile = false}) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !disabledMobile) {
      return AuthConstants.redirectUriMobile;
    }
    return AuthConstants.redirectUriDesktop;
  }
}
