import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/config/oauth2_provider_config.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/services/base_oauth_provider_service.dart';

/// Сервис авторизации Yandex
class YandexAuthService extends BaseOAuthProviderService {
  static const String _tag = 'YandexAuthService';

  YandexAuthService(OAuth2Account account) : super(account: account, tag: _tag);

  /// Выполнить авторизацию через Yandex
  Future<ServiceResult<String>> authorizeWithYandex(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    if (credential.type != AuthClientType.yandex) {
      return ServiceResult.failure('Указан неверный тип учётных данных');
    }

    if (!credential.type.isActive) {
      return ServiceResult.failure('Поддержка Yandex сейчас недоступна');
    }

    final redirectUri = _resolveRedirectUri();

    late Yandex yandexProvider;

    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      yandexProvider = Yandex(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.yandexScopes,
      );
    } else {
      yandexProvider = Yandex(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.yandexScopes,
      );
    }

    account.addProvider(yandexProvider);

    return await authorize(yandexProvider, onError);
  }

  String _resolveRedirectUri({bool disabledMobile = false}) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !disabledMobile) {
      return AuthConstants.redirectUriMobile;
    }
    return AuthConstants.redirectUriDesktop;
  }
}
