import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
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
  static const String _boxName = 'credentials';
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
        logInfo('Creating new credentials box');
        _db = await _boxManager.createBox<CredentialApp>(
          name: _boxName,
          fromJson: CredentialApp.fromJson,
          toJson: (credential) => credential.toJson(),
          getId: (credential) => credential.id,
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
    required String clientSecret,
    required String redirectUri,
    required DateTime expiresAt,
  }) async {
    try {
      final initResult = await _ensureInitialized();
      if (!initResult.success) {
        return ServiceResult.failure(initResult.message!);
      }

      final credential = CredentialApp(
        id: const Uuid().v4(),
        type: type,
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        expiresAt: expiresAt,
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

  /// Проверить истёкшие credentials
  Future<ServiceResult<List<CredentialApp>>> getExpiredCredentials() async {
    try {
      final result = await getAllCredentials();
      if (!result.success) {
        return result;
      }

      final now = DateTime.now();
      final expired = result.data!
          .where((credential) => credential.expiresAt.isBefore(now))
          .toList();

      return ServiceResult.success(data: expired);
    } catch (e, stack) {
      logError(
        'Failed to get expired credentials',
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure(
        'Не удалось получить истёкшие учётные данные',
      );
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
}
