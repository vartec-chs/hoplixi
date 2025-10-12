import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/services/token_services.dart';

const List<String> _dropboxScopes = <String>[
  'account_info.read',
  'files.content.read',
  'files.content.write',
  'files.metadata.write',
  'files.metadata.read',
];

enum ProviderType { dropbox, google, microsoft, unknown }

extension ProviderTypeX on ProviderType {
  String get name {
    switch (this) {
      case ProviderType.dropbox:
        return 'dropbox';
      case ProviderType.google:
        return 'google';
      case ProviderType.microsoft:
        return 'microsoft';
      case ProviderType.unknown:
        return 'unknown';
    }
  }

  static ProviderType fromName(String name) {
    switch (name.toLowerCase()) {
      case 'dropbox':
        return ProviderType.dropbox;
      case 'google':
        return ProviderType.google;
      case 'microsoft':
        return ProviderType.microsoft;
      default:
        throw ArgumentError('Unknown provider name: $name');
    }
  }

  static ProviderType fromKey(String key) {
    if (key.toLowerCase().contains('dropbox')) {
      return ProviderType.dropbox;
    } else if (key.toLowerCase().contains('google')) {
      return ProviderType.google;
    } else if (key.toLowerCase().contains('microsoft')) {
      return ProviderType.microsoft;
    } else {
      return ProviderType.unknown;
    }
  }
}

class OAuth2AccountService {
  static const String _tag = 'OAuth2AccountService';

  late OAuth2Account _account;
  final TokenServices _tokenServices;

  final Map<String, OAuth2RestClient> _clients = {};
  Map<String, OAuth2RestClient> get clients => _clients;

  OAuth2AccountService(TokenServices tokenStorage)
    : _tokenServices = tokenStorage {
    _account = OAuth2Account(
      appPrefix: MainConstants.appName,
      tokenStorage: _tokenServices,
    );
  }

  OAuth2Account get account => _account;

  Future<ServiceResult<String>> authorizeWithDropbox(
    CredentialApp credential, {
    void Function(String error)? onError,
  }) async {
    try {
      if (credential.type != CredentialOAuthType.dropbox) {
        return ServiceResult.failure('Указан неверный тип учётных данных');
      }

      if (!credential.type.isActive) {
        return ServiceResult.failure('Поддержка Dropbox сейчас недоступна');
      }

      if (credential.expiresAt.isBefore(DateTime.now())) {
        return ServiceResult.failure('Срок действия учётных данных истёк');
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
