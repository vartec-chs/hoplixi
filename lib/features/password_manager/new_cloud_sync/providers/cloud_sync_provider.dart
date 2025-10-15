import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/sync_providers.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/export_dropbox_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/import_dropbox_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/import_session_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

class CloudSyncNotifier extends Notifier<CloudSyncState> {
  static const String _tag = 'CloudSyncProvider';

  @override
  CloudSyncState build() {
    return const CloudSyncState.idle();
  }

  /// Экспорт хранилища в Dropbox
  ///
  /// [metadata] - метаданные базы данных для синхронизации
  /// [pathToDbFolder] - путь к папке с БД
  /// [encryptionKeyArchive] - опциональный ключ шифрования архива
  Future<void> exportToDropbox({
    required DatabaseMetaForSync metadata,
    required String pathToDbFolder,
    String? encryptionKeyArchive,
  }) async {
    try {
      // Инициализация состояния
      state = const CloudSyncState.exporting(
        progress: CloudSyncProgress(
          progress: 0.0,
          message: 'Инициализация экспорта...',
        ),
      );

      logInfo(
        'Starting export to Dropbox',
        tag: _tag,
        data: {'storageId': metadata.id, 'storageName': metadata.name},
      );

      // Получаем сервисы
      final tokenServices = await ref.read(tokenServicesProvider.future);
      final accountService = await ref.read(oauth2AccountProvider.future);
      final exportService = await ref.read(exportDropboxProvider.future);

      // Обновление прогресса
      state = const CloudSyncState.exporting(
        progress: CloudSyncProgress(
          progress: 0.1,
          message: 'Получение токена Dropbox...',
        ),
      );

      // Находим токен Dropbox
      final token = await tokenServices.findOneBySuffix(
        ProviderType.dropbox.name.toLowerCase(),
      );

      if (token == null) {
        final errorMsg = 'Токен Dropbox не найден. Необходима авторизация.';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      logDebug('Dropbox token found', tag: _tag, data: {'tokenId': token.id});

      // Обновление прогресса
      state = const CloudSyncState.exporting(
        progress: CloudSyncProgress(
          progress: 0.2,
          message: 'Авторизация в Dropbox...',
        ),
      );

      // Авторизуемся с найденным токеном
      final tokenInfo = TokenInfo(key: token.id, token: token);
      final authResult = await accountService.authorizeWithToken(tokenInfo);

      if (!authResult.success || authResult.data == null) {
        final errorMsg =
            authResult.message ?? 'Не удалось авторизоваться в Dropbox';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      final clientKey = authResult.data!;

      logInfo(
        'Successfully authorized in Dropbox',
        tag: _tag,
        data: {'clientKey': clientKey},
      );

      // Обновление прогресса
      state = const CloudSyncState.exporting(
        progress: CloudSyncProgress(
          progress: 0.3,
          message: 'Подготовка к экспорту...',
        ),
      );

      // Экспортируем в Dropbox
      final result = await exportService.exportToDropbox(
        metadata,
        clientKey,
        pathToDbFolder,
        encryptionKeyArchive,
        onProgress: (progress, message) {
          state = CloudSyncState.exporting(
            progress: CloudSyncProgress(progress: progress, message: message),
          );
          logDebug(
            'Export progress',
            tag: _tag,
            data: {
              'progress': '${(progress * 100).toStringAsFixed(1)}%',
              'message': message,
            },
          );
        },
        onFileProgress: (fileProgress, message) {
          state.whenOrNull(
            exporting: (progress) {
              state = CloudSyncState.exporting(
                progress: CloudSyncProgress(
                  progress: progress.progress,
                  message: progress.message,
                  fileProgress: fileProgress,
                ),
              );
            },
          );
        },
        onError: (error) {
          logError('Export error callback', tag: _tag, data: {'error': error});
        },
      );

      if (result.success) {
        final successMsg = result.message ?? 'Экспорт успешно завершён';
        logInfo(
          'Export to Dropbox completed successfully',
          tag: _tag,
          data: {'storageId': metadata.id, 'cloudFileName': result.data},
        );
        state = CloudSyncState.success(message: successMsg);
      } else {
        final errorMsg = result.message ?? 'Неизвестная ошибка при экспорте';
        logError(
          'Export to Dropbox failed',
          tag: _tag,
          data: {'error': errorMsg},
        );
        state = CloudSyncState.error(message: errorMsg);
      }
    } catch (e, st) {
      final errorMsg = 'Критическая ошибка при экспорте: ${e.toString()}';
      logError(
        'Critical error during export',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      state = CloudSyncState.error(message: errorMsg);
    }
  }

  /// Проверяет наличие новой версии хранилища в Dropbox
  ///
  /// [metadata] - метаданные базы данных для синхронизации
  /// [encryptionKeyArchive] - опциональный ключ шифрования архива
  ///
  /// Возвращает clientKey если найдена новая версия, иначе null
  Future<String?> checkForNewVersion({
    required DatabaseMetaForSync metadata,
    String? encryptionKeyArchive,
  }) async {
    try {
      // Инициализация состояния - используем checking вместо importing
      state = const CloudSyncState.checking(
        progress: CloudSyncProgress(
          progress: 0.0,
          message: 'Проверка обновлений...',
        ),
      );

      logInfo(
        'Checking for new version in Dropbox',
        tag: _tag,
        data: {'storageId': metadata.id, 'storageName': metadata.name},
      );

      // Получаем сервисы
      final tokenServices = await ref.read(tokenServicesProvider.future);
      final accountService = await ref.read(oauth2AccountProvider.future);
      final importService = await ref.read(importDropboxProvider.future);

      // Находим токен Dropbox
      final token = await tokenServices.findOneBySuffix(
        ProviderType.dropbox.name.toLowerCase(),
      );

      if (token == null) {
        final errorMsg = 'Токен Dropbox не найден. Необходима авторизация.';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return null;
      }

      logDebug('Dropbox token found', tag: _tag, data: {'tokenId': token.id});

      // Авторизуемся с найденным токеном
      final tokenInfo = TokenInfo(key: token.id, token: token);
      final authResult = await accountService.authorizeWithToken(tokenInfo);

      if (!authResult.success || authResult.data == null) {
        final errorMsg =
            authResult.message ?? 'Не удалось авторизоваться в Dropbox';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return null;
      }

      final clientKey = authResult.data!;

      logInfo(
        'Successfully authorized in Dropbox',
        tag: _tag,
        data: {'clientKey': clientKey},
      );

      // Проверяем наличие новой версии
      state = const CloudSyncState.checking(
        progress: CloudSyncProgress(
          progress: 0.2,
          message: 'Проверка новой версии...',
        ),
      );

      final versionResult = await importService.checkForNewVersion(
        metadata: metadata,
        clientKey: clientKey,
      );

      if (!versionResult.success) {
        final errorMsg = versionResult.message ?? 'Ошибка проверки версии';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return null;
      }

      if (versionResult.data == null) {
        // Нет новой версии
        logInfo('No new version found in cloud', tag: _tag);
        state = const CloudSyncState.idle();
        return null;
      }

      // Найдена новая версия
      logInfo(
        'New version found in cloud',
        tag: _tag,
        data: {
          'timestamp': versionResult.data!.timestamp.toString(),
          'fileName': versionResult.data!.fileName,
        },
      );

      // Инициализируем сессию импорта
      ref
          .read(importSessionProvider.notifier)
          .startSession(
            metadata: metadata,
            clientKey: clientKey,
            encryptionKeyArchive: encryptionKeyArchive,
          );

      state = CloudSyncState.success(message: 'Найдена новая версия хранилища');

      return clientKey;
    } catch (e, st) {
      final errorMsg =
          'Критическая ошибка при проверке версии: ${e.toString()}';
      logError(
        'Critical error during version check',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      state = CloudSyncState.error(message: errorMsg);
      return null;
    }
  }

  /// Импорт хранилища из Dropbox (DEPRECATED - использовать checkForNewVersion)
  ///
  /// [metadata] - метаданные базы данных для синхронизации
  /// [encryptionKeyArchive] - опциональный ключ шифрования архива
  @Deprecated('Используйте checkForNewVersion и navigate к процессу импорта')
  Future<void> importFromDropbox({
    required DatabaseMetaForSync metadata,
    String? encryptionKeyArchive,
  }) async {
    try {
      // Инициализация состояния
      state = const CloudSyncState.importing(
        progress: CloudSyncProgress(
          progress: 0.0,
          message: 'Инициализация импорта...',
        ),
      );

      logInfo(
        'Starting import from Dropbox',
        tag: _tag,
        data: {'storageId': metadata.id, 'storageName': metadata.name},
      );

      // Получаем сервисы
      final tokenServices = await ref.read(tokenServicesProvider.future);
      final accountService = await ref.read(oauth2AccountProvider.future);
      final importService = await ref.read(importDropboxProvider.future);

      // Обновление прогресса
      state = const CloudSyncState.importing(
        progress: CloudSyncProgress(
          progress: 0.05,
          message: 'Получение токена Dropbox...',
        ),
      );

      // Находим токен Dropbox
      final token = await tokenServices.findOneBySuffix(
        ProviderType.dropbox.name.toLowerCase(),
      );

      if (token == null) {
        final errorMsg = 'Токен Dropbox не найден. Необходима авторизация.';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      logDebug('Dropbox token found', tag: _tag, data: {'tokenId': token.id});

      // Обновление прогресса
      state = const CloudSyncState.importing(
        progress: CloudSyncProgress(
          progress: 0.1,
          message: 'Авторизация в Dropbox...',
        ),
      );

      // Авторизуемся с найденным токеном
      final tokenInfo = TokenInfo(key: token.id, token: token);
      final authResult = await accountService.authorizeWithToken(tokenInfo);

      if (!authResult.success || authResult.data == null) {
        final errorMsg =
            authResult.message ?? 'Не удалось авторизоваться в Dropbox';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      final clientKey = authResult.data!;

      logInfo(
        'Successfully authorized in Dropbox',
        tag: _tag,
        data: {'clientKey': clientKey},
      );

      // Получаем путь к БД
      final manager = await ref.read(hoplixiStoreManagerProvider.future);

      if (!manager.hasOpenDatabase) {
        final errorMsg = 'База данных не открыта';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      final dbPath = ref.read(hoplixiStoreProvider.notifier).databaseDir;

      if (dbPath == null) {
        final errorMsg = 'Путь к директории базы данных не определён';
        logError(errorMsg, tag: _tag);
        state = CloudSyncState.error(message: errorMsg);
        return;
      }

      // Обновление прогресса
      state = const CloudSyncState.importing(
        progress: CloudSyncProgress(
          progress: 0.15,
          message: 'Подготовка к импорту...',
        ),
      );

      // Импортируем из Dropbox
      final result = await importService.importFromDropbox(
        metadata: metadata,
        pathToDbFolder: dbPath,
        clientKey: clientKey,
        encryptionKeyArchive: encryptionKeyArchive,
        onProgress: (progress, message) {
          state = CloudSyncState.importing(
            progress: CloudSyncProgress(progress: progress, message: message),
          );
          logDebug(
            'Import progress',
            tag: _tag,
            data: {
              'progress': '${(progress * 100).toStringAsFixed(1)}%',
              'message': message,
            },
          );
        },
        onFileProgress: (fileProgress, message) {
          state.whenOrNull(
            importing: (progress) {
              state = CloudSyncState.importing(
                progress: CloudSyncProgress(
                  progress: progress.progress,
                  message: progress.message,
                  fileProgress: message,
                ),
              );
            },
          );
        },
        onError: (error) {
          logError('Import error callback', tag: _tag, data: {'error': error});
        },
      );

      if (result.success) {
        final successMsg = result.message ?? 'Импорт успешно завершён';
        logInfo(
          'Import from Dropbox completed successfully',
          tag: _tag,
          data: {'storageId': metadata.id},
        );
        state = CloudSyncState.success(message: successMsg);
      } else {
        final errorMsg = result.message ?? 'Неизвестная ошибка при импорте';
        logError(
          'Import from Dropbox failed',
          tag: _tag,
          data: {'error': errorMsg},
        );
        state = CloudSyncState.error(message: errorMsg);
      }
    } catch (e, st) {
      final errorMsg = 'Критическая ошибка при импорте: ${e.toString()}';
      logError(
        'Critical error during import',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      state = CloudSyncState.error(message: errorMsg);
    }
  }

  /// Сброс состояния в idle
  void reset() {
    state = const CloudSyncState.idle();
    logDebug('Cloud sync state reset to idle', tag: _tag);
  }
}

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncState>(
  CloudSyncNotifier.new,
);
