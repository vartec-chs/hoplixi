import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
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
        return await _authorizeWithExistingOrNew(
          ProviderType.dropbox,
          () => _dropboxService.authorizeWithDropbox(
            credential,
            onError: onError,
          ),
        );
      case AuthClientType.yandex:
        return await _authorizeWithExistingOrNew(
          ProviderType.yandex,
          () =>
              _yandexService.authorizeWithYandex(credential, onError: onError),
        );
      case AuthClientType.google:
        return await _authorizeWithExistingOrNew(
          ProviderType.google,
          () =>
              _googleService.authorizeWithGoogle(credential, onError: onError),
        );
      case AuthClientType.onedrive:
        return await _authorizeWithExistingOrNew(
          ProviderType.microsoft,
          () => _microsoftService.authorizeWithMicrosoft(
            credential,
            onError: onError,
          ),
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
