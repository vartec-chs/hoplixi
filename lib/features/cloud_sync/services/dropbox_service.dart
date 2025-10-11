import 'package:dropbox_api/dropbox_api.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';

/// Результат операции Dropbox сервиса
class DropboxResult<T> {
  final bool success;
  final String? message;
  final T? data;

  DropboxResult({required this.success, this.message, this.data});

  factory DropboxResult.success({T? data, String? message}) {
    return DropboxResult(success: true, data: data, message: message);
  }

  factory DropboxResult.failure(String message) {
    return DropboxResult(success: false, message: message);
  }
}

/// Сервис для работы с Dropbox API
class DropboxService {
  final String _appPrefix = 'hoplixi_dropbox';

  OAuth2Account? _account;
  DropboxApi? _api;
  CredentialApp? _currentCredential;

  /// Инициализация сервиса с credential
  Future<DropboxResult<void>> init(CredentialApp credential) async {
    try {
      _currentCredential = credential;

      // Создаем аккаунт для OAuth
      _account = OAuth2Account(appPrefix: _appPrefix);

      logDebug(
        'Creating OAuth2Account with appPrefix: $_appPrefix',
        data: {
          'credentialId': credential.id,
          'clientId': credential.clientId,
          'redirectUri': credential.redirectUri,
        },
      );

      // Конфигурируем Dropbox провайдер
      final dropbox = Dropbox(
        clientId: credential.clientId,
        redirectUri: credential.redirectUri,
        scopes: [
          'account_info.read',
          'files.content.read',
          'files.content.write',
          'files.metadata.write',
          'files.metadata.read',
        ],
      );

      _account!.addProvider(dropbox);

      logInfo('Dropbox service initialized for credential: ${credential.id}');
      return DropboxResult.success(message: 'Сервис Dropbox инициализирован');
    } catch (e, stack) {
      logError(
        'Failed to initialize Dropbox service',
        error: e,
        stackTrace: stack,
      );
      return DropboxResult.failure(
        'Не удалось инициализировать сервис Dropbox',
      );
    }
  }

  /// Проверка валидности credentials и подключения
  Future<DropboxResult<bool>> check() async {
    try {
      if (_account == null || _currentCredential == null) {
        return DropboxResult.failure('Сервис не инициализирован');
      }

      // Проверяем токен
      var token = await _account!.any(service: 'dropbox');

      logDebug('Checking Dropbox token', data: {'hasToken': token != null});

      if (token == null) {
        // Пытаемся войти
        token = await _account!.newLogin('dropbox');
        if (token == null) {
          return DropboxResult.failure('Не удалось авторизоваться в Dropbox');
        }
      }

      // Проверяем время жизни токена
      if (token.timeToLogin) {
        token = await _account!.forceRelogin(token);
        if (token == null) {
          return DropboxResult.failure(
            'Токен истёк, требуется повторная авторизация',
          );
        }
      }

      // Создаем клиент и проверяем подключение
      final client = await _account!.createClient(token);
      _api = DropboxRestApi(client);

      logDebug('Created Dropbox API client', data: {'api': _api.toString()});

      // Проверяем аккаунт
      await _api!.listFolder('');
      return DropboxResult.success(
        data: true,
        message: 'Подключение к Dropbox проверено',
      );
    } catch (e, stack) {
      logError(
        'Failed to check Dropbox connection',
        error: e,
        stackTrace: stack,
      );
      return DropboxResult.failure(
        'Не удалось проверить подключение к Dropbox',
      );
    }
  }

  /// Получить информацию об аккаунте
  Future<DropboxResult<DropboxAccount>> getAccountInfo() async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      final account = await _api!.getCurrentAccount();
      return DropboxResult.success(data: account);
    } catch (e, stack) {
      logError('Failed to get account info', error: e, stackTrace: stack);
      return DropboxResult.failure(
        'Не удалось получить информацию об аккаунте',
      );
    }
  }

  /// Загрузить файл
  Future<DropboxResult<DropboxFile>> uploadFile(
    String path,
    Stream<List<int>> content,
  ) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      final result = await _api!.upload(path, content);

      logInfo('File uploaded to Dropbox: $path');
      return DropboxResult.success(
        data: result,
        message: 'Файл успешно загружен',
      );
    } catch (e, stack) {
      logError('Failed to upload file', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось загрузить файл');
    }
  }

  /// Скачать файл
  Future<DropboxResult<Stream<List<int>>>> downloadFile(String path) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      final stream = await _api!.download(path);
      return DropboxResult.success(
        data: stream,
        message: 'Файл готов к скачиванию',
      );
    } catch (e, stack) {
      logError('Failed to download file', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось скачать файл');
    }
  }

  /// Получить список файлов
  Future<DropboxResult<List<DropboxFile>>> listFiles({
    String path = '',
    int limit = 100,
  }) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      final response = await _api!.listFolder(path, limit: limit);
      final items = List<DropboxFile>.from(response.entries);

      // Загружаем дополнительные страницы если есть
      var cursor = response.cursor;
      while (cursor != null && response.hasMore) {
        final continueResponse = await _api!.listFolderContinue(cursor);
        items.addAll(continueResponse.entries);
        cursor = continueResponse.cursor;
      }

      return DropboxResult.success(data: items);
    } catch (e, stack) {
      logError('Failed to list files', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось получить список файлов');
    }
  }

  /// Создать папку
  Future<DropboxResult<DropboxFile>> createFolder(String path) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      final result = await _api!.createFolder(path);
      logInfo('Folder created in Dropbox: $path');
      return DropboxResult.success(
        data: result as DropboxFile,
        message: 'Папка успешно создана',
      );
    } catch (e, stack) {
      logError('Failed to create folder', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось создать папку');
    }
  }

  /// Удалить файл/папку
  Future<DropboxResult<void>> delete(String path) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      await _api!.delete(path);
      logInfo('Deleted from Dropbox: $path');
      return DropboxResult.success(message: 'Файл/папка успешно удалена');
    } catch (e, stack) {
      logError('Failed to delete', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось удалить файл/папку');
    }
  }

  /// Проверить существование файла/папки
  Future<DropboxResult<bool>> exists(String path) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      // Пытаемся получить список файлов в родительской папке
      final parentPath = path.contains('/')
          ? path.substring(0, path.lastIndexOf('/'))
          : '';
      final name = path.contains('/')
          ? path.substring(path.lastIndexOf('/') + 1)
          : path;

      final files = await listFiles(path: parentPath);
      if (!files.success) {
        return DropboxResult.success(data: false);
      }

      final exists = files.data!.any((file) => file.name == name);
      return DropboxResult.success(data: exists);
    } catch (e) {
      return DropboxResult.success(data: false);
    }
  }

  /// Получить метаданные файла/папки
  Future<DropboxResult<DropboxFile>> getMetadata(String path) async {
    try {
      if (_api == null) {
        return DropboxResult.failure('API не инициализировано');
      }

      // Используем listFolder для получения метаданных
      final response = await _api!.listFolder(path, limit: 1);
      if (response.entries.isNotEmpty) {
        return DropboxResult.success(data: response.entries.first);
      }

      return DropboxResult.failure('Файл/папка не найдена');
    } catch (e, stack) {
      logError('Failed to get metadata', error: e, stackTrace: stack);
      return DropboxResult.failure('Не удалось получить метаданные');
    }
  }

  /// Закрыть соединение
  Future<void> dispose() async {
    _api = null;
    _account = null;
    _currentCredential = null;
    logInfo('Dropbox service disposed');
  }

  /// Проверить инициализацию
  bool get isInitialized =>
      _api != null && _account != null && _currentCredential != null;
}
