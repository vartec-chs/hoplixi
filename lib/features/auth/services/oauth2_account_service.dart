import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/config/oauth2_provider_config.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/services/providers/dropbox_auth_service.dart';
import 'package:hoplixi/features/auth/services/providers/google_auth_service.dart';
import 'package:hoplixi/features/auth/services/providers/microsoft_auth_service.dart';
import 'package:hoplixi/features/auth/services/providers/yandex_auth_service.dart';
import 'package:hoplixi/features/auth/services/token_auth_service.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';

class OAuth2AccountService {
  static const String _tag = 'OAuth2AccountService';

  late OAuth2Account _account;
  final TokenServices _tokenServices;

  final Map<String, OAuth2RestClient> _clients = {}; // key - provider_key
  Map<String, OAuth2RestClient> get clients => _clients;

  // Специализированные сервисы для каждого провайдера
  late final DropboxAuthService _dropboxService;
  late final YandexAuthService _yandexService;
  late final GoogleAuthService _googleService;
  late final MicrosoftAuthService _microsoftService;
  late final TokenAuthService _tokenAuthService;

  OAuth2AccountService(TokenServices tokenStorage)
    : _tokenServices = tokenStorage {
    _account = OAuth2Account(
      appPrefix: MainConstants.appName,
      tokenStorage: _tokenServices,
    );

    // Инициализация специализированных сервисов
    _dropboxService = DropboxAuthService(_account, _clients);
    _yandexService = YandexAuthService(_account, _clients);
    _googleService = GoogleAuthService(_account, _clients);
    _microsoftService = MicrosoftAuthService(_account, _clients);
    _tokenAuthService = TokenAuthService(account: _account, clients: _clients);
  }

  OAuth2Account get account => _account;

  OAuth2RestClient? getClient(String key) {
    return _clients[key];
  }

  // общий метод авторизации
  Future<ServiceResult<String>> authorize(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    switch (credential.type) {
      case AuthClientType.dropbox:
        final redirectUri = _resolveRedirectUri();
        final dropboxProvider = _createDropboxProvider(credential, redirectUri);
        _account.addProvider(dropboxProvider);
        return await _authorizeWithExistingOrNew(
          ProviderType.dropbox,
          () => _dropboxService.authorize(dropboxProvider, onError),
        );
      case AuthClientType.yandex:
        final redirectUri = _resolveRedirectUri();
        final yandexProvider = _createYandexProvider(credential, redirectUri);
        _account.addProvider(yandexProvider);
        return await _authorizeWithExistingOrNew(
          ProviderType.yandex,
          () => _yandexService.authorize(yandexProvider, onError),
        );
      case AuthClientType.google:
        final redirectUri = _resolveRedirectUri(disabledMobile: true);
        final googleProvider = _createGoogleProvider(credential, redirectUri);
        _account.addProvider(googleProvider);
        return await _authorizeWithExistingOrNew(
          ProviderType.google,
          () => _googleService.authorize(googleProvider, onError),
        );
      case AuthClientType.onedrive:
        final redirectUri = _resolveRedirectUri();
        final microsoftProvider = _createMicrosoftProvider(
          credential,
          redirectUri,
        );
        _account.addProvider(microsoftProvider);
        return await _authorizeWithExistingOrNew(
          ProviderType.microsoft,
          () => _microsoftService.authorize(microsoftProvider, onError),
        );
      case AuthClientType.icloud:
        return ServiceResult.failure(
          'Авторизация для ${credential.type.name} не реализована',
        );
      case AuthClientType.other:
        return ServiceResult.failure(
          'Авторизация для ${credential.type.name} не реализована',
        );
    }
  }

  /// Разрешить redirect URI в зависимости от платформы
  String _resolveRedirectUri({bool disabledMobile = false}) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !disabledMobile) {
      return AuthConstants.redirectUriMobile;
    }
    return AuthConstants.redirectUriDesktop;
  }

  /// Создать провайдер Dropbox
  Dropbox _createDropboxProvider(
    AuthClientConfig credential,
    String redirectUri,
  ) {
    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      return Dropbox(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.dropboxScopes,
      );
    } else {
      return Dropbox(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.dropboxScopes,
      );
    }
  }

  /// Создать провайдер Yandex
  Yandex _createYandexProvider(
    AuthClientConfig credential,
    String redirectUri,
  ) {
    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      return Yandex(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.yandexScopes,
      );
    } else {
      return Yandex(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.yandexScopes,
      );
    }
  }

  /// Создать провайдер Google
  Google _createGoogleProvider(
    AuthClientConfig credential,
    String redirectUri,
  ) {
    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      return Google(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.googleScopes,
      );
    } else {
      return Google(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.googleScopes,
      );
    }
  }

  /// Создать провайдер Microsoft
  Microsoft _createMicrosoftProvider(
    AuthClientConfig credential,
    String redirectUri,
  ) {
    if (credential.clientSecret != null &&
        credential.clientSecret!.isNotEmpty) {
      return Microsoft(
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.microsoftScopes,
      );
    } else {
      return Microsoft(
        clientId: credential.clientId,
        redirectUri: redirectUri,
        scopes: OAuth2ProviderConfig.microsoftScopes,
      );
    }
  }

  /// Попытка авторизации с существующим токеном или новая авторизация
  Future<ServiceResult<String>> _authorizeWithExistingOrNew(
    ProviderType providerType,
    Future<ServiceResult<String>> Function() newAuthCallback,
  ) async {
    final token = await _tokenServices.findOneBySuffix(
      providerType.name.toLowerCase(),
    );

    if (token != null) {
      try {
        logInfo(
          'Found existing ${providerType.name} token, attempting to use it',
          tag: _tag,
        );
        final tokenInfo = TokenInfo(key: token.id, token: token);
        return await _tokenAuthService.authorizeWithToken(tokenInfo);
      } catch (e, stack) {
        logError(
          'Failed to authorize with existing ${providerType.name} token',
          error: e,
          stackTrace: stack,
          tag: _tag,
        );
      }
    }

    return await newAuthCallback();
  }

  /// Авторизация с использованием существующего токена
  Future<ServiceResult<String>> authorizeWithToken(TokenInfo tokenInfo) async {
    return await _tokenAuthService.authorizeWithToken(tokenInfo);
  }

  /// Валидация и использование существующего токена для провайдера
  Future<ServiceResult<String>> validateAndUseExistingToken(
    AuthClientConfig credential,
  ) async {
    final providerType = _getProviderTypeFromCredential(credential);
    if (providerType == null) {
      return ServiceResult.failure(
        'Неподдерживаемый тип провайдера: ${credential.type.name}',
      );
    }

    final token = await _tokenServices.findOneBySuffix(
      providerType.name.toLowerCase(),
    );

    if (token == null) {
      return ServiceResult.failure('Токен не найден');
    }

    try {
      logInfo('Validating existing ${providerType.name} token', tag: _tag);
      final tokenInfo = TokenInfo(key: token.id, token: token);
      return await _tokenAuthService.authorizeWithToken(tokenInfo);
    } catch (e, stack) {
      logError(
        'Failed to validate existing ${providerType.name} token',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      return ServiceResult.failure('Токен невалиден: ${e.toString()}');
    }
  }

  /// Получение типа провайдера из credential
  ProviderType? _getProviderTypeFromCredential(AuthClientConfig credential) {
    switch (credential.type) {
      case AuthClientType.dropbox:
        return ProviderType.dropbox;
      case AuthClientType.yandex:
        return ProviderType.yandex;
      case AuthClientType.google:
        return ProviderType.google;
      case AuthClientType.onedrive:
        return ProviderType.microsoft;
      default:
        return null;
    }
  }
}
