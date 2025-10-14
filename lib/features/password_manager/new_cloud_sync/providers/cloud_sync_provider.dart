import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/sync_providers.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/export_dropbox_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

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

  /// Сброс состояния в idle
  void reset() {
    state = const CloudSyncState.idle();
    logDebug('Cloud sync state reset to idle', tag: _tag);
  }
}

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncState>(
  CloudSyncNotifier.new,
);
