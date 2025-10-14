import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/credential_app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

/// Результат операции сервиса
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

/// Сервис для управления credential приложениями
class CredentialService {
  static const String _boxName = 'credential_apps';
  final BoxManager _boxManager;
  BoxDB<CredentialApp>? _db;

  CredentialService(this._boxManager);

  /// Инициализация бокса
  Future<ServiceResult<void>> _ensureInitialized() async {
    try {
      if (_db != null) {
        return ServiceResult.success();
      }

      // Пытаемся открыть существующий бокс
      try {
        _db = await _boxManager.openBox<CredentialApp>(
          name: _boxName,
          fromJson: CredentialApp.fromJson,
          toJson: (credential) => credential.toJson(),
          getId: (credential) => credential.id,
        );
      } catch (e) {
        // Если не удалось открыть, создаём новый
        final key = await EncryptionService.generate();
        logInfo('Creating new credentials box');
        _db = await _boxManager.createBox<CredentialApp>(
          name: _boxName,
          fromJson: CredentialApp.fromJson,
          toJson: (credential) => credential.toJson(),
          getId: (credential) => credential.id,
          password: await key.exportKey(),
        );
      }

      return ServiceResult.success();
    } catch (e, stack) {
      logError(
        'Failed to initialize credentials box',
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure(
        'Не удалось инициализировать хранилище учётных данных',
      );
    }
  }

  /// Создать новый credential
  Future<ServiceResult<CredentialApp>> createCredential({
    required CredentialOAuthType type,
    required String clientId,
    required String name,
    required String clientSecret,
  }) async {
    try {
      // Валидация входных данных
      final validationResult = await _validateCredentialData(
        type: type,
        clientId: clientId,
        clientSecret: clientSecret,

        isUpdate: false,
      );

      if (!validationResult.success) {
        return ServiceResult.failure(validationResult.message!);
      }

      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final credential = CredentialApp(
        id: const Uuid().v4(),
        type: type,
        name: name,
        clientId: clientId,
        clientSecret: clientSecret,
      );

      await _db!.insert(credential);
      logInfo('Created credential: ${credential.id} (${type.name})');

      return ServiceResult.success(
        data: credential,
        message: 'Учётные данные успешно созданы',
      );
    } catch (e, stack) {
      logError('Failed to create credential', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось создать учётные данные');
    }
  }

  /// Получить credential по ID
  Future<ServiceResult<CredentialApp>> getCredential(String id) async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final credential = await _db!.get(id);

      if (credential == null) {
        return ServiceResult.failure('Учётные данные не найдены');
      }

      return ServiceResult.success(data: credential);
    } catch (e, stack) {
      logError('Failed to get credential', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось получить учётные данные');
    }
  }

  /// Получить все credentials
  Future<ServiceResult<List<CredentialApp>>> getAllCredentials() async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final credentials = await _db!.getAll();

      // Добавляем встроенные credentials из env, если включено
      if (dotenv.env['USED_BUILTIN_AUTH_APPS'] == 'true') {
        final builtinCredentials = await _getBuiltinCredentials();
        for (final builtin in builtinCredentials) {
          if (!credentials.any((c) => c.id == builtin.id)) {
            credentials.add(builtin);
          }
        }
      }

      return ServiceResult.success(data: credentials);
    } catch (e, stack) {
      logError('Failed to get all credentials', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось получить список учётных данных');
    }
  }

  /// Получить credentials по типу
  Future<ServiceResult<List<CredentialApp>>> getCredentialsByType(
    CredentialOAuthType type,
  ) async {
    try {
      final result = await getAllCredentials();
      if (!result.success) {
        return result;
      }

      final filtered = result.data!
          .where((credential) => credential.type == type)
          .toList();

      return ServiceResult.success(data: filtered);
    } catch (e, stack) {
      logError(
        'Failed to get credentials by type',
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure(
        'Не удалось получить учётные данные по типу',
      );
    }
  }

  /// Обновить credential
  Future<ServiceResult<CredentialApp>> updateCredential(
    CredentialApp credential,
  ) async {
    try {
      // Валидация входных данных
      final validationResult = await _validateCredentialData(
        type: credential.type,
        clientId: credential.clientId,
        clientSecret: credential.clientSecret,
        isUpdate: true,
        existingId: credential.id,
      );

      if (!validationResult.success) {
        return ServiceResult.failure(validationResult.message!);
      }

      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final exists = await _db!.exists(credential.id);
      if (!exists) {
        return ServiceResult.failure('Учётные данные не найдены');
      }

      await _db!.update(credential);
      logInfo('Updated credential: ${credential.id}');

      return ServiceResult.success(
        data: credential,
        message: 'Учётные данные успешно обновлены',
      );
    } catch (e, stack) {
      logError('Failed to update credential', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось обновить учётные данные');
    }
  }

  /// Удалить credential
  Future<ServiceResult<void>> deleteCredential(String id) async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final exists = await _db!.exists(id);
      if (!exists) {
        return ServiceResult.failure('Учётные данные не найдены');
      }

      await _db!.delete(id);
      logInfo('Deleted credential: $id');

      return ServiceResult.success(message: 'Учётные данные успешно удалены');
    } catch (e, stack) {
      logError('Failed to delete credential', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось удалить учётные данные');
    }
  }

  /// Очистить все credentials
  Future<ServiceResult<void>> clearAll() async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      await _db!.clear();
      logInfo('Cleared all credentials');

      return ServiceResult.success(message: 'Все учётные данные удалены');
    } catch (e, stack) {
      logError('Failed to clear credentials', error: e, stackTrace: stack);
      return ServiceResult.failure('Не удалось очистить учётные данные');
    }
  }

  /// Получить количество credentials
  Future<ServiceResult<int>> getCount() async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final count = await _db!.count();
      return ServiceResult.success(data: count);
    } catch (e, stack) {
      logError('Failed to get credentials count', error: e, stackTrace: stack);
      return ServiceResult.failure(
        'Не удалось получить количество учётных данных',
      );
    }
  }

  /// Закрыть сервис
  Future<void> dispose() async {
    if (_boxManager.isBoxOpen(_boxName)) {
      await _boxManager.closeBox(_boxName);
      _db = null;
    }
  }

  /// Получить встроенные credentials из env
  Future<List<CredentialApp>> _getBuiltinCredentials() async {
    final builtinCredentials = <CredentialApp>[];

    for (final type in CredentialOAuthType.values) {
      if (type == CredentialOAuthType.other) continue;

      final enabledKey = '${type.identifier.toUpperCase()}_BUILTIN_ENABLED';
      if (dotenv.env[enabledKey] == 'true') {
        final appNameKey = '${type.identifier.toUpperCase()}_APP_NAME';
        final clientIdKey = '${type.identifier.toUpperCase()}_CLIENT_ID';
        final clientSecretKey =
            '${type.identifier.toUpperCase()}_CLIENT_SECRET';

        final appName = dotenv.env[appNameKey];
        final clientId = dotenv.env[clientIdKey];
        final clientSecret = dotenv.env[clientSecretKey];

        if (appName != null && clientId != null && clientSecret != null) {
          final builtinCredential = CredentialApp(
            id: 'builtin_${type.identifier}',
            name: appName,
            type: type,
            clientId: clientId,
            clientSecret: clientSecret,
          );
          builtinCredentials.add(builtinCredential);
        }
      }
    }

    return builtinCredentials;
  }

  /// Валидация данных учетных данных
  Future<ServiceResult<void>> _validateCredentialData({
    required CredentialOAuthType type,
    required String clientId,
    required String clientSecret,

    bool isUpdate = false,
    String? existingId,
  }) async {
    // Проверка обязательных полей
    if (clientId.trim().isEmpty) {
      return ServiceResult.failure('Client ID не может быть пустым');
    }

    if (clientSecret.trim().isEmpty) {
      return ServiceResult.failure('Client Secret не может быть пустым');
    }

    // Проверка уникальности clientId (только для новых записей или при изменении)
    if (!isUpdate || existingId == null) {
      final initResult = await _ensureInitialized();
      if (initResult.success) {
        final allCredentials = await _db!.getAll();
        final duplicate = allCredentials.any(
          (cred) => cred.clientId.trim() == clientId.trim(),
        );
        if (duplicate) {
          return ServiceResult.failure(
            'Учётные данные с таким Client ID уже существуют',
          );
        }
      }
    }

    // Специфическая валидация для разных типов
    switch (type) {
      case CredentialOAuthType.dropbox:
        // Для Dropbox clientId должен быть в определенном формате
        if (clientId.length < 10) {
          return ServiceResult.failure(
            'Client ID Dropbox должен содержать минимум 10 символов',
          );
        }
        if (clientSecret.length < 10) {
          return ServiceResult.failure(
            'Client Secret Dropbox должен содержать минимум 10 символов',
          );
        }
        break;

      case CredentialOAuthType.google:
        // Для Google проверяем что redirectUri содержит google
        // if (!redirectUri.contains('google')) {
        //   logInfo('Предупреждение: Redirect URI не содержит "google"');
        // }
        break;

      case CredentialOAuthType.onedrive:
        // Для OneDrive проверяем что redirectUri содержит microsoft
        // if (!redirectUri.contains('microsoft') &&
        //     !redirectUri.contains('live.com')) {
        //   logInfo(
        //     'Предупреждение: Redirect URI не содержит "microsoft" или "live.com"',
        //   );
        // }
        break;

      default:
        // Для других типов базовая валидация достаточна
        break;
    }

    return ServiceResult.success();
  }
}
