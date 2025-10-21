import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';
import 'package:hoplixi/features/auth/models/sync_providers.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_import_state.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/providers/local_meta_crud_provider.dart';
import 'package:hoplixi/features/cloud_sync/services/dropbox/import_service.dart';
import 'package:hoplixi/features/cloud_sync/services/local_meta_crud_service.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

final cloudImportProvider =
    AsyncNotifierProvider<CloudImportProvider, ImportState>(
      CloudImportProvider.new,
    );

final cloudImportStateProvider = Provider<AsyncValue<ImportState>>((ref) {
  final importState = ref.watch(cloudImportProvider);
  return importState;
});

class CloudImportProvider extends AsyncNotifier<ImportState> {
  late final OAuth2AccountService _oauth2AccountService;
  late final ImportDropboxService _dropboxImportService;
  late final TokenServices _tokenServices;
  late final LocalMetaCrudService _localMetaCrudService;

  @override
  Future<ImportState> build() async {
    _tokenServices = await ref.read(tokenServicesProvider.future);
    _oauth2AccountService = await ref.read(oauth2AccountProvider.future);
    _localMetaCrudService = await ref.read(localMetaCrudProvider.future);

    _dropboxImportService = ImportDropboxService(
      _oauth2AccountService,
      _localMetaCrudService,
    );
    return const ImportState.idle();
  }

  /// Основной метод импорта базы данных из облака
  Future<void> import(DatabaseMetaForSync databaseMeta) async {
    state = const AsyncValue.loading();
    final startedAt = DateTime.now();

    try {
      final providerType = ProviderType.dropbox;

      // Step 1: Get client key
      state = AsyncData(
        const ImportState.checking('Получение ключа клиента...'),
      );
      final clientKeyResult = await _getClientKey(providerType);
      if (clientKeyResult.isFailure) {
        state = AsyncData(ImportState.failure(clientKeyResult.errorOrNull!));
        return;
      }
      final clientKey = clientKeyResult.dataOrNull!;

      // Step 2: Initialize Dropbox connection
      state = AsyncData(
        const ImportState.checking('Инициализация подключения к Dropbox...'),
      );
      final initResult = await _dropboxImportService
          .initializeDropboxConnection(
            clientKey,
            (error) => logError(
              'Ошибка подключения к Dropbox: $error',
              tag: 'CloudImportProvider',
            ),
          );
      if (initResult.isFailure) {
        state = AsyncData(
          ImportState.failure(
            ImportException.network(
              'Не удалось подключиться к Dropbox',
              details: initResult.errorOrNull,
            ),
          ),
        );
        return;
      }

      // Step 3: Check for new version
      state = AsyncData(
        const ImportState.checking('Проверка наличия новой версии...'),
      );
      final versionCheckResult = await _dropboxImportService.checkForNewVersion(
        metadata: databaseMeta,
        clientKey: clientKey,
      );
      if (versionCheckResult.isFailure) {
        state = AsyncData(
          ImportState.failure(
            ImportException.network(
              'Не удалось проверить версию',
              details: versionCheckResult.errorOrNull,
            ),
          ),
        );
        return;
      }

      final versionInfo = versionCheckResult.dataOrNull;

      // Если новой версии нет - выход
      if (versionInfo == null) {
        logInfo(
          'Новая версия в облаке не найдена',
          tag: 'CloudImportProvider',
          data: {'storageId': databaseMeta.id},
        );
        state = const AsyncData(
          ImportState.info('Новая версия в облаке отсутствует'),
        );
        return;
      }

      logInfo(
        'Найдена новая версия в облаке',
        tag: 'CloudImportProvider',
        data: {
          'storageId': databaseMeta.id,
          'fileName': versionInfo.fileName,
          'timestamp': versionInfo.timestamp.toIso8601String(),
        },
      );

      final exportCloudPath = _dropboxImportService.getImportCloudPath(
        databaseMeta,
      );

      // Step 4: Check lock file existence
      state = AsyncData(
        const ImportState.checking('Проверка блокировки хранилища...'),
      );
      final lockCheckResult = await _dropboxImportService.checkLockFileExists(
        exportCloudPath: exportCloudPath,
      );
      if (lockCheckResult.isFailure) {
        state = AsyncData(
          ImportState.failure(
            ImportException.network(
              'Не удалось проверить блокировку',
              details: lockCheckResult.errorOrNull,
            ),
          ),
        );
        return;
      }

      final lockExists = lockCheckResult.dataOrNull!;
      bool editingEnabled = false;

      if (!lockExists) {
        // Step 5a: Lock file doesn't exist - try to create it
        state = AsyncData(
          const ImportState.checking('Создание блокировки хранилища...'),
        );

        final deviceInfo = _getDeviceInfo();
        final lockCreateResult = await _dropboxImportService.createLockFile(
          exportCloudPath: exportCloudPath,
          deviceInfo: deviceInfo,
        );

        if (lockCreateResult.isSuccess) {
          logInfo(
            'Блокировка успешно создана',
            tag: 'CloudImportProvider',
            data: {
              'storageId': databaseMeta.id,
              'lockPath': lockCreateResult.dataOrNull,
            },
          );
          editingEnabled = true;
        } else {
          logWarning(
            'Не удалось создать блокировку',
            tag: 'CloudImportProvider',
            data: {'error': lockCreateResult.errorOrNull},
          );
          editingEnabled = false;
        }
      } else {
        // Step 5b: Lock file exists
        logInfo(
          'Блокировка уже существует',
          tag: 'CloudImportProvider',
          data: {'storageId': databaseMeta.id},
        );
        editingEnabled = false;
      }

      // Step 6: Update editingEnabled flag in LocalMeta
      final updateResult = await _updateEditingEnabled(
        databaseMeta.id,
        editingEnabled,
      );
      if (updateResult.isFailure) {
        logWarning(
          'Не удалось обновить флаг editingEnabled',
          tag: 'CloudImportProvider',
          data: {
            'storageId': databaseMeta.id,
            'editingEnabled': editingEnabled,
            'error': updateResult.errorOrNull,
          },
        );
      }

      // Step 7: Download archive
      state = AsyncData(
        ImportState.importing(
          progress: 0.1,
          message: 'Скачивание архива из облака...',
          startedAt: startedAt,
        ),
      );

      final downloadResult = await _dropboxImportService.downloadArchive(
        versionInfo: versionInfo,
        metadata: databaseMeta,
        onFileProgress: (progress, message) {
          state = AsyncData(
            ImportState.fileProgress(progress: progress, message: message),
          );
        },
      );

      if (downloadResult.isFailure) {
        state = AsyncData(
          ImportState.failure(
            ImportException.storage(
              'Не удалось скачать архив: ${downloadResult.errorOrNull}',
            ),
          ),
        );
        return;
      }

      final downloadPath = downloadResult.dataOrNull!;

      // Step 8a: Delete current database before replacement
      state = AsyncData(
        ImportState.importing(
          progress: 0.65,
          message: 'Удаление текущей базы данных...',
          startedAt: startedAt,
        ),
      );

      try {
        await ref.read(hoplixiStoreProvider.notifier).deleteCurrentDatabase();
        logInfo(
          'Текущая база данных удалена перед импортом',
          tag: 'CloudImportProvider',
          data: {'storageId': databaseMeta.id},
        );
      } catch (e, st) {
        logError(
          'Ошибка удаления текущей БД перед импортом',
          tag: 'CloudImportProvider',
          error: e,
          stackTrace: st,
        );
        state = AsyncData(
          ImportState.failure(
            ImportException.storage(
              'Не удалось удалить текущую базу данных: $e',
            ),
          ),
        );
        return;
      }

      // Step 8b: Replace database
      state = AsyncData(
        ImportState.importing(
          progress: 0.7,
          message: 'Замена базы данных...',
          startedAt: startedAt,
        ),
      );

      final replaceResult = await _dropboxImportService.replaceDatabase(
        downloadPath: downloadPath,
        metadata: databaseMeta,
        onProgress: (message) {
          logInfo(message, tag: 'CloudImportProvider');
        },
      );

      if (replaceResult.isFailure) {
        state = AsyncData(
          ImportState.failure(
            ImportException.storage(
              'Не удалось заменить базу данных: ${replaceResult.errorOrNull}',
            ),
          ),
        );
        return;
      }

      // Step 9: Success
      final importTime = DateTime.now().difference(startedAt).inSeconds;
      state = AsyncData(
        ImportState.success(
          fileName: versionInfo.fileName,
          importTime: importTime,
        ),
      );

      logInfo(
        'Импорт успешно завершён',
        tag: 'CloudImportProvider',
        data: {
          'storageId': databaseMeta.id,
          'fileName': versionInfo.fileName,
          'importTime': importTime,
          'editingEnabled': editingEnabled,
        },
      );
    } catch (e, st) {
      logError(
        'Неожиданная ошибка при импорте',
        tag: 'CloudImportProvider',
        error: e,
        stackTrace: st,
      );
      state = AsyncData(
        ImportState.failure(
          ImportException.unknown('Неожиданная ошибка: $e', cause: e),
        ),
      );
    }
  }

  /// Получить ключ клиента для провайдера
  Future<Result<String, ImportException>> _getClientKey(
    ProviderType providerType,
  ) async {
    try {
      final token = await _tokenServices.findOneBySuffix(providerType.name);
      if (token == null) {
        return Result.failure(
          const ImportException.auth(
            'Токен авторизации не найден. Необходимо войти в аккаунт.',
          ),
        );
      }
      final tokenInfo = TokenInfo(key: token.id, token: token);
      final result = await _oauth2AccountService.authorizeWithToken(tokenInfo);
      if (result.success && result.data != null) {
        return Result.success(result.data!);
      } else {
        return Result.failure(
          const ImportException.auth('Не удалось авторизоваться с токеном'),
        );
      }
    } catch (e) {
      return Result.failure(
        ImportException.unknown('Ошибка получения ключа клиента: $e', cause: e),
      );
    }
  }

  /// Получить информацию об устройстве
  String _getDeviceInfo() {
    final platform = Platform.operatingSystem;
    final hostname = Platform.localHostname;
    return '$hostname ($platform)';
  }

  /// Обновить флаг editingEnabled в LocalMeta
  Future<Result<void, String>> _updateEditingEnabled(
    String dbId,
    bool editingEnabled,
  ) async {
    try {
      // Получить существующую запись
      final getResult = _localMetaCrudService.getByDbId(dbId);

      if (getResult.isFailure) {
        // Если записи нет - это не критично для импорта
        logWarning(
          'LocalMeta запись не найдена для dbId: $dbId',
          tag: 'CloudImportProvider',
        );
        return Result.success(null);
      }

      final existingMeta = getResult.dataOrNull!;

      // Обновить запись с новым значением editingEnabled
      final updatedMeta = existingMeta.copyWith(
        editingEnabled: editingEnabled,
        lastImportedAt: DateTime.now(),
      );

      final updateResult = await _localMetaCrudService.update(updatedMeta);

      if (updateResult.isFailure) {
        return Result.failure(
          'Не удалось обновить LocalMeta: ${updateResult.errorOrNull}',
        );
      }

      logInfo(
        'Флаг editingEnabled обновлён',
        tag: 'CloudImportProvider',
        data: {'dbId': dbId, 'editingEnabled': editingEnabled},
      );

      return Result.success(null);
    } catch (e, st) {
      logError(
        'Ошибка при обновлении editingEnabled',
        tag: 'CloudImportProvider',
        error: e,
        stackTrace: st,
      );
      return Result.failure('Неожиданная ошибка: $e');
    }
  }
}
