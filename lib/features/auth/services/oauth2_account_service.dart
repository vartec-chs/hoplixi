import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/features/auth/models/token_oauth.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';

const List<String> _dropboxScopes = <String>[
  'account_info.read',
  'files.content.read',
  'files.content.write',
  'files.metadata.write',
  'files.metadata.read',
];

const List<String> _yandexScopes = <String>[
  'login:email',
  'login:info',
  'login:avatar',
  'cloud_api:disk.read',
  'cloud_api:disk.write',
  'cloud_api:disk.app_folder',
  'cloud_api:disk.info',
];

class OAuth2AccountService {
  static const String _tag = 'OAuth2AccountService';

  late OAuth2Account _account;
  final TokenServices _tokenServices;

  final Map<String, OAuth2RestClient> _clients = {}; // key - provider_key
  Map<String, OAuth2RestClient> get clients => _clients;

  OAuth2AccountService(TokenServices tokenStorage)
    : _tokenServices = tokenStorage {
    _account = OAuth2Account(
      appPrefix: MainConstants.appName,
      tokenStorage: _tokenServices,
    );
  }

  OAuth2Account get account => _account;

  // общий метод авторизации
  Future<ServiceResult<String>> authorize(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    switch (credential.type) {
      case AuthClientType.dropbox:
        final token = await _tokenServices.findOneBySuffix(
          ProviderType.dropbox.name.toLowerCase(),
        );

        try {
          if (token != null) {
            logInfo(
              'Found existing Dropbox token, attempting to use it',
              tag: _tag,
            );
            final tokenInfo = TokenInfo(key: token.id, token: token);
            return await authorizeWithToken(tokenInfo);
          }
        } catch (e, stack) {
          logError(
            'Failed to authorize with existing Dropbox token',
            error: e,
            stackTrace: stack,
            tag: _tag,
          );
        }

        return await authorizeWithDropbox(credential, onError: onError);
      case AuthClientType.yandex:
        final token = await _tokenServices.findOneBySuffix(
          ProviderType.yandex.name.toLowerCase(),
        );

        try {
          if (token != null) {
            logInfo(
              'Found existing Yandex token, attempting to use it',
              tag: _tag,
            );
            final tokenInfo = TokenInfo(key: token.id, token: token);
            return await authorizeWithToken(tokenInfo);
          }
        } catch (e, stack) {
          logError(
            'Failed to authorize with existing Yandex token',
            error: e,
            stackTrace: stack,
            tag: _tag,
          );
        }
        return await authorizeWithYandex(credential, onError: onError);
      case AuthClientType.google:
      case AuthClientType.onedrive:
      case AuthClientType.icloud:
      case AuthClientType.other:
        return ServiceResult.failure(
          'Авторизация для ${credential.type.name} не реализована',
        );
    }
  }

  // authroize with token TokenInfo

  Future<ServiceResult<String>> authorizeWithToken(TokenInfo tokenInfo) async {
    logInfo('Authorizing with existing token', tag: _tag);
    final provider = ProviderTypeX.fromKey(tokenInfo.key);
    final TokenOAuth tokenOAuth = tokenInfo.token;
    OAuth2Token token = OAuth2TokenF.fromJsonString(tokenOAuth.tokenJson);

    switch (provider) {
      case ProviderType.dropbox:
        final key = tokenInfo.key;
        late OAuth2RestClient client;
        try {
          if (token?.timeToLogin ?? false) {
            token = await _account.forceRelogin(token) as OAuth2Token;
          }
          client = await _account.createClient(token);
        } catch (e, stack) {
          final newToken = await _account.refreshToken(token);
          if (newToken == null) {
            return ServiceResult.failure('Failed to refresh expired token');
          }
          try {
            client = await _account.createClient(newToken);
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
          logError(
            'Failed to create client for existing token',
            error: e,
            stackTrace: stack,
            tag: _tag,
          );
        }

        _clients[key] = client;
        return ServiceResult.success(data: key);

      case ProviderType.google:
        return ServiceResult.failure('Not implemented');

      case ProviderType.microsoft:
        return ServiceResult.failure('Not implemented');

      case ProviderType.yandex:
        final key = tokenInfo.key;
        final client = await _account.createClient(token);
        _clients[key] = client;
        return ServiceResult.success(data: key);

      case ProviderType.unknown:
        return ServiceResult.failure('Not implemented');
    }
  }

  Future<ServiceResult<String>> authorizeWithDropbox(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    try {
      if (credential.type != AuthClientType.dropbox) {
        return ServiceResult.failure('Указан неверный тип учётных данных');
      }

      if (!credential.type.isActive) {
        return ServiceResult.failure('Поддержка Dropbox сейчас недоступна');
      }

      final redirectUri = _resolveRedirectUri();

      late Dropbox dropboxProvider;

      if (credential.clientSecret.isNotEmpty) {
        dropboxProvider = Dropbox(
          clientId: credential.clientId,
          clientSecret: credential.clientSecret,
          redirectUri: redirectUri,
          scopes: _dropboxScopes,
        );
      } else {
        dropboxProvider = Dropbox(
          clientId: credential.clientId,
          redirectUri: redirectUri,
          scopes: _dropboxScopes,
        );
      }

      _account.addProvider(dropboxProvider);

      final token = await _account.newLogin(
        dropboxProvider.name,
        errorCallback: onError,
      );

      if (token == null) {
        return ServiceResult.failure('Авторизация Dropbox не завершена');
      }

      final key = _account.keyFor(dropboxProvider.name, token.userName);

      final client = await _account.createClient(token);

      _clients[key] = client;

      return ServiceResult.success(data: key);
    } catch (e, stack) {
      logError(
        'Не удалось выполнить авторизацию Dropbox',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      return ServiceResult.failure('Ошибка авторизации Dropbox');
    }
  }

  // with Yandex
  Future<ServiceResult<String>> authorizeWithYandex(
    AuthClientConfig credential, {
    void Function(String error)? onError,
  }) async {
    try {
      if (credential.type != AuthClientType.yandex) {
        return ServiceResult.failure('Указан неверный тип учётных данных');
      }

      if (!credential.type.isActive) {
        return ServiceResult.failure('Поддержка Yandex сейчас недоступна');
      }

      final redirectUri = _resolveRedirectUri();

      late Yandex yandexProvider;

      if (credential.clientSecret.isNotEmpty) {
        yandexProvider = Yandex(
          clientId: credential.clientId,
          clientSecret: credential.clientSecret,

          redirectUri: redirectUri,
          scopes: _yandexScopes,
        );
      } else {
        yandexProvider = Yandex(
          clientId: credential.clientId,
          redirectUri: redirectUri,
          scopes: _yandexScopes,
        );
      }

      _account.addProvider(yandexProvider);

      final token = await _account.newLogin(
        yandexProvider.name,
        errorCallback: onError,
      );
      if (token == null) {
        return ServiceResult.failure('Авторизация Yandex не завершена');
      }

      final key = _account.keyFor(yandexProvider.name, token.userName);

      final client = await _account.createClient(token);

      _clients[key] = client;

      return ServiceResult.success(data: key);
    } catch (e, stack) {
      logError(
        'Не удалось выполнить авторизацию Yandex',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      return ServiceResult.failure('Ошибка авторизации Yandex');
    }
  }

  String _resolveRedirectUri() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return AuthConstants.redirectUriMobile;
    }

    return AuthConstants.redirectUriDesktop;
  }
}

//  var dropbox = Dropbox(
//       clientId: dotenv.env["DROPBOX_CLIENT_ID"]!,
//       redirectUri: "aircomix://${dotenv.env["DROPBOX_CLIENT_ID"]!}/",
//       scopes: [
//         "account_info.read",
//         "files.content.read",
//         "files.content.write",
//         "files.metadata.write",
//         "files.metadata.read",
//       ],
//     );

//  Future<String> getEmail(OAuth2RestClient client, String service) async {
//     if (service == "dropbox") {
//       var response = await client.postJson(
//         "https://api.dropboxapi.com/2/users/get_current_account",
//       );
//       return response["email"] as String;
//     }

//     if (service == "microsoft") {
//       var response = await client.getJson(
//         "https://graph.microsoft.com/v1.0/me",
//       );
//       return response["mail"] as String;
//     }

//     // Google
//     var response = await client.getJson(
//       "https://www.googleapis.com/oauth2/v3/userinfo",
//     );
//     return response["email"] as String;
//   }

//   void _incrementCounter() async {
//     //var token = await account.any(service: service);
//     //token ??= await account.newLogin(service);
//     var token = await account.newLogin(service);
//     if (token?.timeToLogin ?? false) {
//       token = await account.forceRelogin(token!);
//     }

//     if (token == null) throw Exception("login first");
//     var client = await account.createClient(token);

//     // PUT 메서드 테스트
//     //await testPutMethods(client);

//     var email = await getEmail(client, service);
//     debugPrint(email);

//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
