import 'package:dropbox_api/dropbox_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/providers/credential_provider.dart';
import 'package:hoplixi/features/cloud_sync/services/dropbox_service.dart';

/// Состояние Dropbox сервиса
class DropboxServiceState {
  final bool isInitialized;
  final bool isChecking;
  final String? error;
  final CredentialApp? credential;

  DropboxServiceState({
    this.isInitialized = false,
    this.isChecking = false,
    this.error,
    this.credential,
  });

  DropboxServiceState copyWith({
    bool? isInitialized,
    bool? isChecking,
    String? error,
    CredentialApp? credential,
  }) {
    return DropboxServiceState(
      isInitialized: isInitialized ?? this.isInitialized,
      isChecking: isChecking ?? this.isChecking,
      error: error ?? this.error,
      credential: credential ?? this.credential,
    );
  }
}

/// Провайдер сервиса Dropbox
final dropboxServiceProvider = Provider<DropboxService>((ref) {
  // final credentialServiceAsync = await ref.watch(credentialServiceProvider.future);
  // Для синхронного провайдера мы не можем использовать async,
  // поэтому создаем сервис без зависимостей или используем другой подход

  final service = DropboxService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Провайдер состояния Dropbox сервиса для конкретного credential
final dropboxServiceStateProvider =
    AsyncNotifierProvider<DropboxServiceNotifier, DropboxServiceState>(
      DropboxServiceNotifier.new,
    );

/// Notifier для управления Dropbox сервисом
class DropboxServiceNotifier extends AsyncNotifier<DropboxServiceState> {
  String? _credentialId;
  late DropboxService _service;

  @override
  Future<DropboxServiceState> build() async {
    _service = ref.watch(dropboxServiceProvider);
    return DropboxServiceState();
  }

  /// Установить credential ID для этого notifier
  void setCredentialId(String credentialId) {
    _credentialId = credentialId;
  }

  /// Инициализация сервиса с credential
  Future<bool> init(String credentialId) async {
    _credentialId = credentialId;
    state = const AsyncValue.loading();

    try {
      // Получаем credential
      final credentialService = await ref.read(
        credentialServiceProvider.future,
      );
      final credentialResult = await credentialService.getCredential(
        _credentialId!,
      );

      if (!credentialResult.success) {
        state = AsyncValue.error(
          credentialResult.message ?? 'Не удалось получить учетные данные',
          StackTrace.current,
        );
        return false;
      }

      final credential = credentialResult.data!;
      if (credential.type != CredentialOAuthType.dropbox) {
        state = AsyncValue.error(
          'Неверный тип учетных данных',
          StackTrace.current,
        );
        return false;
      }

      // Инициализируем сервис
      final initResult = await _service.init(credential);
      if (!initResult.success) {
        state = AsyncValue.error(
          initResult.message ?? 'Не удалось инициализировать сервис',
          StackTrace.current,
        );
        return false;
      }

      state = AsyncValue.data(
        DropboxServiceState(isInitialized: true, credential: credential),
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Проверка подключения
  Future<bool> check() async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      final initialized = await init(_credentialId!);
      if (!initialized) return false;
    }

    state = AsyncValue.data(
      state.value!.copyWith(isChecking: true, error: null),
    );

    try {
      final checkResult = await _service.check();
      state = AsyncValue.data(
        state.value!.copyWith(
          isChecking: false,
          error: checkResult.success ? null : checkResult.message,
        ),
      );
      return checkResult.success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Получить информацию об аккаунте
  Future<DropboxResult<DropboxAccount>> getAccountInfo() async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.getAccountInfo();
  }

  /// Загрузить файл
  Future<DropboxResult<DropboxFile>> uploadFile(
    String path,
    Stream<List<int>> content,
  ) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.uploadFile(path, content);
  }

  /// Скачать файл
  Future<DropboxResult<Stream<List<int>>>> downloadFile(String path) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.downloadFile(path);
  }

  /// Получить список файлов
  Future<DropboxResult<List<DropboxFile>>> listFiles({
    String path = '',
    int limit = 100,
  }) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.listFiles(path: path, limit: limit);
  }

  /// Создать папку
  Future<DropboxResult<DropboxFile>> createFolder(String path) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.createFolder(path);
  }

  /// Удалить файл/папку
  Future<DropboxResult<void>> delete(String path) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.delete(path);
  }

  /// Проверить существование
  Future<DropboxResult<bool>> exists(String path) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.exists(path);
  }

  /// Получить метаданные
  Future<DropboxResult<DropboxFile>> getMetadata(String path) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.getMetadata(path);
  }

  /// Убедиться, что папка Hoplixi существует
  Future<DropboxResult<void>> ensureHoplixiFolder() async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.ensureHoplixiFolder();
  }

  /// Загрузить хранилище в облако
  Future<DropboxResult<String>> uploadStorage({
    required String localPath,
    required String storageName,
  }) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.uploadStorage(
      localPath: localPath,
      storageName: storageName,
    );
  }

  /// Скачать хранилище из облака
  Future<DropboxResult<String>> downloadStorage({
    required String storageName,
    required String localDir,
  }) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.downloadStorage(
      storageName: storageName,
      localDir: localDir,
    );
  }

  /// Получить список хранилищ в облаке
  Future<DropboxResult<List<DropboxFile>>> listStorages() async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.listStorages();
  }

  /// Удалить хранилище из облака
  Future<DropboxResult<void>> deleteStorage(String storageName) async {
    if (_credentialId == null) {
      throw Exception('Credential ID not set. Call init() first.');
    }

    final currentState = state.value;
    if (currentState == null || !currentState.isInitialized) {
      await init(_credentialId!);
    }
    return _service.deleteStorage(storageName);
  }
}
