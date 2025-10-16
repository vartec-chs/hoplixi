import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/config/oauth2_provider_config.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Google
class GoogleAuthService extends BaseOAuthProviderService {
  static const String _tag = 'GoogleAuthService';

  GoogleAuthService(OAuth2Account account) : super(account: account, tag: _tag);

  /// Выполнить авторизацию через Google
  Future<ServiceResult<String>> authorizeWithGoogle(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    if (credential.type != AuthClientType.google) {
      return ServiceResult.failure('Указан неверный тип учётных данных');
    }

    if (!credential.type.isActive) {
      return ServiceResult.failure('Поддержка Google сейчас недоступна');
    }

    final redirectUri = _resolveRedirectUri(disabledMobile: true);

    late Google googleProvider;

    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      googleProvider = Google(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.googleScopes,
      );
    } else {
      googleProvider = Google(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.googleScopes,
      );
    }

    account.addProvider(googleProvider);

    return await authorize(googleProvider, onError);
  }

  String _resolveRedirectUri({bool disabledMobile = false}) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !disabledMobile) {
      return AuthConstants.redirectUriMobile;
    }
    return AuthConstants.redirectUriDesktop;
  }
}
