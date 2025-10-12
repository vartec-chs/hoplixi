import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/lib/oauth2restclient/src/token/oauth2_token_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/models/token_oauth.dart';

class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  ServiceResult({required this.success, this.message, this.data});

  factory ServiceResult.success({T? data, String? message}) {
    return ServiceResult(success: true, data: data, message: message);
  }

  factory ServiceResult.failure(String message) {
    return ServiceResult(success: false, message: message);
  }
}

class TokenServices implements OAuth2TokenStorage {
  static const String _boxName = 'oauth2_tokens';
  static const String _tag = 'TokenServices';

  final BoxManager _boxManager;
  BoxDB<TokenOAuth>? _db;

  TokenServices(this._boxManager);

  /// Публичный доступ к базе данных токенов
  BoxDB<TokenOAuth>? get db => _db;

  /// Инициализация базы данных
  Future<void> _ensureInitialized() async {
    if (_db != null) return;

    try {
      // Попробовать открыть существующую БД
      _db = await _boxManager.openBox<TokenOAuth>(
        name: _boxName,
        fromJson: (json) => TokenOAuth.fromJson(json),
        toJson: (data) => data.toJson(),
        getId: (data) => data.id,
      );
      logInfo('Token storage opened successfully', tag: _tag);
    } catch (e) {
      // Если БД не существует, создать новую
      try {
        _db = await _boxManager.createBox<TokenOAuth>(
          name: _boxName,
          fromJson: (json) => TokenOAuth.fromJson(json),
          toJson: (data) => data.toJson(),
          getId: (data) => data.id,
        );
        logInfo('Token storage created successfully', tag: _tag);
      } catch (createError) {
        logError('Failed to create token storage: $createError', tag: _tag);
        rethrow;
      }
    }
  }

  @override
  Future<String?> load(String key) async {
    try {
      await _ensureInitialized();

      final tokenData = await _db!.get(key);
      if (tokenData == null) {
        logDebug('Token not found for key: $key', tag: _tag);
        return null;
      }

      // Преобразуем TokenOAuth обратно в OAuth2TokenF JSON строку
      final token = OAuth2TokenF({
        'access_token': tokenData.accessToken,
        'refresh_token': tokenData.refreshToken,
        'id_token':
            '', // OAuth2TokenF попытается декодировать, но для userName/iss используем прямые значения
        'expiry': '9999-12-31T23:59:59.999Z', // Значения по умолчанию
        'refresh_token_expiry': '9999-12-31T23:59:59.999Z',
      });

      logDebug('Token loaded for key: $key', tag: _tag);
      return token.toJsonString();
    } catch (e) {
      logError('Failed to load token for key "$key": $e', tag: _tag);
      return null;
    }
  }

  @override
  Future<Map<String, String>> loadAll({String? keyPrefix}) async {
    try {
      await _ensureInitialized();

      final allTokens = await _db!.getAll();
      final Map<String, String> result = {};

      for (final tokenData in allTokens) {
        // Если указан префикс, фильтруем по нему
        if (keyPrefix != null && !tokenData.id.startsWith(keyPrefix)) {
          continue;
        }

        // Преобразуем TokenOAuth обратно в OAuth2TokenF JSON строку
        final token = OAuth2TokenF({
          'access_token': tokenData.accessToken,
          'refresh_token': tokenData.refreshToken,
          'id_token': '',
          'expiry': '9999-12-31T23:59:59.999Z',
          'refresh_token_expiry': '9999-12-31T23:59:59.999Z',
        });

        result[tokenData.id] = token.toJsonString();
      }

      logDebug(
        'Loaded ${result.length} tokens${keyPrefix != null ? ' with prefix "$keyPrefix"' : ''}',
        tag: _tag,
      );
      return result;
    } catch (e) {
      logError('Failed to load all tokens: $e', tag: _tag);
      return {};
    }
  }

  @override
  Future<void> save(String key, String value) async {
    try {
      await _ensureInitialized();

      final OAuth2TokenF data = OAuth2TokenF.fromJsonString(value);
      final TokenOAuth tokenData = TokenOAuth(
        id: key,
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        userName: data.userName,
        iss: data.iss,
        timeToRefresh: data.timeToRefresh,
        canRefresh: data.canRefresh,
        timeToLogin: data.timeToLogin,
      );

      final exists = await _db!.exists(key);
      if (exists) {
        await _db!.update(tokenData);
        logDebug('Token updated for key: $key', tag: _tag);
      } else {
        await _db!.insert(tokenData);
        logDebug('Token saved for key: $key', tag: _tag);
      }
    } catch (e) {
      logError('Failed to save token for key "$key": $e', tag: _tag);
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _ensureInitialized();

      await _db!.delete(key);
      logDebug('Token deleted for key: $key', tag: _tag);
    } catch (e) {
      logError('Failed to delete token for key "$key": $e', tag: _tag);
      rethrow;
    }
  }

  /// Закрыть хранилище токенов
  Future<void> close() async {
    if (_db != null) {
      await _boxManager.closeBox(_boxName);
      _db = null;
      logInfo('Token storage closed', tag: _tag);
    }
  }

  /// Очистить все токены
  Future<void> clear() async {
    try {
      await _ensureInitialized();
      await _db!.clear();
      logInfo('All tokens cleared', tag: _tag);
    } catch (e) {
      logError('Failed to clear tokens: $e', tag: _tag);
      rethrow;
    }
  }

  /// Получить количество сохранённых токенов
  Future<int> count() async {
    try {
      await _ensureInitialized();
      final count = await _db!.count();
      return count;
    } catch (e) {
      logError('Failed to count tokens: $e', tag: _tag);
      return 0;
    }
  }
}
