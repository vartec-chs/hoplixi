import 'dart:convert';

import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/lib/oauth2restclient/src/token/oauth2_token_storage.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/token_oauth.dart';

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

    // Проверить, существует ли уже БД
    final boxExists = await _boxManager.hasBoxKey(_boxName);

    try {
      if (boxExists) {
        // Открыть существующую БД
        _db = await _boxManager.openBox<TokenOAuth>(
          name: _boxName,
          fromJson: (json) => TokenOAuth.fromJson(json),
          toJson: (data) => data.toJson(),
          getId: (data) => data.id,
        );
        logInfo('Token storage opened successfully', tag: _tag);
      } else {
        // Создать новую БД
        _db = await _boxManager.createBox<TokenOAuth>(
          name: _boxName,
          fromJson: (json) => TokenOAuth.fromJson(json),
          toJson: (data) => data.toJson(),
          getId: (data) => data.id,
        );
        logInfo('Token storage created successfully', tag: _tag);
      }
    } catch (e) {
      logError('Failed to initialize token storage: $e', tag: _tag);
      rethrow;
    }
  }

  // get all with suffix

  Future<List<String>> getAllWithSuffix(String suffix) async {
    try {
      await _ensureInitialized();

      final allIds = await _db!.getAllIndex();
      final filteredIds = allIds
          .where((id) => id.contains(suffix.toLowerCase()))
          .toList();

      logDebug(
        'Found ${filteredIds.length} tokens with suffix "$suffix"',
        tag: _tag,
      );
      return filteredIds;
    } catch (e) {
      logError('Failed to get tokens with suffix "$suffix": $e', tag: _tag);
      return [];
    }
  }

  // find one by suffix
  Future<TokenOAuth?> findOneBySuffix(String suffix) async {
    try {
      await _ensureInitialized();

      final allIds = await _db!.getAllIndex();
      final matchedId = allIds.firstWhere(
        (id) => id.contains(suffix.toLowerCase()),
        orElse: () => '',
      );

      if (matchedId.isEmpty) {
        logDebug('No token found with suffix "$suffix"', tag: _tag);
        return null;
      }
      final tokenData = await _db!.get(matchedId);
      if (tokenData == null) {
        logDebug('Token data not found for id: $matchedId', tag: _tag);
        return null;
      }
      return tokenData;
    } catch (e) {
      logError('Failed to find token with suffix "$suffix": $e', tag: _tag);
      return null;
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

      // Если tokenJson не содержит iss/user_name, обогащаем его
      final jsonMap = jsonDecode(tokenData.tokenJson) as Map<String, dynamic>;

      // Гарантируем наличие iss и user_name
      if ((jsonMap['iss'] == null || jsonMap['iss'] == '') &&
          tokenData.iss.isNotEmpty) {
        jsonMap['iss'] = tokenData.iss;
      }
      if ((jsonMap['user_name'] == null || jsonMap['user_name'] == '') &&
          tokenData.userName.isNotEmpty) {
        jsonMap['user_name'] = tokenData.userName;
      }

      final enrichedJson = jsonEncode(jsonMap);

      logDebug('Token loaded for key: $key', tag: _tag);
      return enrichedJson;
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

        // Обогащаем tokenJson, если нужно
        final jsonMap = jsonDecode(tokenData.tokenJson) as Map<String, dynamic>;

        if ((jsonMap['iss'] == null || jsonMap['iss'] == '') &&
            tokenData.iss.isNotEmpty) {
          jsonMap['iss'] = tokenData.iss;
        }
        if ((jsonMap['user_name'] == null || jsonMap['user_name'] == '') &&
            tokenData.userName.isNotEmpty) {
          jsonMap['user_name'] = tokenData.userName;
        }

        result[tokenData.id] = jsonEncode(jsonMap);
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

      // log o save new token and all data
      logInfo('Saving token for key: $key', tag: _tag, data: {'value': value});

      final OAuth2TokenF data = OAuth2TokenF.fromJsonString(value);

      // Извлекаем iss и userName из ключа, если они пустые в токене
      // Формат ключа: "Hoplixi-OAUTH2ACCOUNT107-{service}-{userName}"
      String iss = data.iss;
      String userName = data.userName;

      if (iss.isEmpty || userName.isEmpty) {
        final parts = key.split('-');
        if (parts.length >= 4) {
          if (iss.isEmpty) {
            iss = parts[2]; // service name (например, "yandex", "dropbox")
          }
          if (userName.isEmpty) {
            userName = parts[3]; // userName
          }
        }
      }

      // Гарантируем, что iss и userName сохранены в JSON
      final jsonMap = jsonDecode(value) as Map<String, dynamic>;
      jsonMap['iss'] = iss;
      jsonMap['user_name'] = userName;
      final enrichedJson = jsonEncode(jsonMap);

      final TokenOAuth tokenData = TokenOAuth(
        id: key,
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        userName: userName,
        iss: iss,
        timeToRefresh: data.timeToRefresh,
        canRefresh: data.canRefresh,
        timeToLogin: data.timeToLogin,
        tokenJson: enrichedJson, // Сохраняем обогащённый JSON
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

  // get all tokens
  Future<List<TokenOAuth>> getAllTokens() async {
    try {
      await _ensureInitialized();
      final allTokens = await _db!.getAll();
      logDebug('Retrieved ${allTokens.length} tokens', tag: _tag);
      return allTokens;
    } catch (e) {
      logError('Failed to retrieve all tokens: $e', tag: _tag);
      return [];
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
