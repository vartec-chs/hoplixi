import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/config/oauth2_provider_config.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Microsoft
class MicrosoftAuthService extends BaseOAuthProviderService {
  static const String _tag = 'MicrosoftAuthService';

  MicrosoftAuthService(
    OAuth2Account account,
    Map<String, OAuth2RestClient> clients,
  ) : super(account: account, tag: _tag, clients: clients);

  /// Выполнить авторизацию через Microsoft
  Future<ServiceResult<String>> authorizeWithMicrosoft(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    if (credential.type != AuthClientType.onedrive) {
      return ServiceResult.failure('Указан неверный тип учётных данных');
    }

    if (!credential.type.isActive) {
      return ServiceResult.failure('Поддержка OneDrive сейчас недоступна');
    }

    final redirectUri = _resolveRedirectUri(disabledMobile: true);

    late Microsoft microsoftProvider;

    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      microsoftProvider = Microsoft(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.microsoftScopes,
      );
    } else {
      microsoftProvider = Microsoft(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.microsoftScopes,
      );
    }

    account.addProvider(microsoftProvider);

    return await authorize(microsoftProvider, onError);
  }

  String _resolveRedirectUri({bool disabledMobile = false}) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !disabledMobile) {
      return AuthConstants.redirectUriMobile;
    }
    return AuthConstants.redirectUriDesktop;
  }
}
