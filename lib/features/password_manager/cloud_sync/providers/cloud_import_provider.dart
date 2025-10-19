import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/services/dropbox/import_service.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/dropbox_import_service_provider.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/local_meta_crud_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

class CloudImportNotifier extends Notifier<ImportState> {
  static const String _tag = 'CloudImportProvider';

  // Сохраняем параметры последней операции для retry
  String? _lastClientKey;
  CloudVersionInfo? _lastVersionInfo;

  @override
  ImportState build() {
    return const ImportState.idle();
  }

  /// Проверяет наличие новой версии в облаке
  Future<void> checkForNewVersion({required String clientKey}) async {
    // Сохраняем параметры для возможности повтора
    _lastClientKey = clientKey;
    try {
      state = const ImportState.checking();

      // Получаем метаданные текущей БД
      final dbManager = await ref.read(hoplixiStoreManagerProvider.future);
      final metadata = await dbManager.getDatabaseMetaForSync();

      logInfo(
        'Проверка новой версии в облаке',
        tag: _tag,
        data: {'storageName': metadata.name, 'storageId': metadata.id},
      );

      // Получаем сервис импорта
      final importService = await ref.read(dropboxImportServiceProvider.future);

      // Проверяем наличие новой версии
      final result = await importService.checkForNewVersion(
        metadata: metadata,
        clientKey: clientKey,
      );

      result.fold(
        onSuccess: (versionInfo) {
          if (versionInfo != null && versionInfo.isNewer) {
            state = ImportState.newVersionAvailable(versionInfo: versionInfo);
            logInfo(
              'Обнаружена новая версия в облаке',
              tag: _tag,
              data: {
                'fileName': versionInfo.fileName,
                'timestamp': versionInfo.timestamp.toIso8601String(),
                'fileSize': versionInfo.fileSize,
              },
            );
          } else {
            state = const ImportState.noNewVersion();
            logInfo('Новых версий не обнаружено', tag: _tag);
          }
        },
        onFailure: (error) {
          state = ImportState.failure(error);
          logError(
            'Ошибка при проверке новой версии',
            tag: _tag,
            data: {'error': error},
          );
        },
      );
    } catch (e, st) {
      state = ImportState.failure('Непредвиденная ошибка: ${e.toString()}');
      logError(
        'Непредвиденная ошибка при проверке версии',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Скачивает и заменяет текущую БД новой версией из облака
  Future<void> downloadAndReplace({
    required String clientKey,
    required CloudVersionInfo versionInfo,
    DatabaseMetaForSync? metadata,
  }) async {
    // Сохраняем параметры для возможности повтора
    _lastClientKey = clientKey;
    _lastVersionInfo = versionInfo;
    try {
      // Получаем метаданные текущей БД
      final dbManager = await ref.read(hoplixiStoreManagerProvider.future);
      final dbMetadata = metadata ?? await dbManager.getDatabaseMetaForSync();

      logInfo(
        'Начало загрузки и замены БД',
        tag: _tag,
        data: {
          'storageName': dbMetadata.name,
          'storageId': dbMetadata.id,
          'cloudPath': versionInfo.cloudPath,
        },
      );

      // Получаем сервис импорта
      final importService = await ref.read(dropboxImportServiceProvider.future);

      // Скачиваем архив
      state = const ImportState.downloading(
        progress: 0.0,
        message: 'Начало загрузки...',
      );

      final downloadResult = await importService.downloadArchive(
        versionInfo: versionInfo,
        metadata: dbMetadata,
        onProgress: (progress, message) {
          state = ImportState.downloading(progress: progress, message: message);
        },
      );

      final downloadPath = await downloadResult.fold(
        onSuccess: (path) async {
          logInfo('Архив успешно загружен', tag: _tag, data: {'path': path});
          return path;
        },
        onFailure: (error) {
          state = ImportState.failure(error);
          logError(
            'Ошибка при загрузке архива',
            tag: _tag,
            data: {'error': error},
          );
          throw Exception(error);
        },
      );

      // Закрываем БД перед заменой
      state = const ImportState.extracting(
        progress: 0.0,
        message: 'Закрытие текущей БД...',
      );
      await dbManager.closeDatabase();

      logInfo('БД закрыта, начинается распаковка', tag: _tag);

      // Заменяем БД
      state = const ImportState.extracting(
        progress: 0.5,
        message: 'Распаковка архива...',
      );

      final replaceResult = await importService.replaceDatabase(
        downloadPath: downloadPath,
        metadata: dbMetadata,
        onProgress: (progress, message) {
          state = ImportState.extracting(progress: progress, message: message);
        },
      );

      replaceResult.fold(
        onSuccess: (importedFolderPath) async {
          // Обновляем LocalMeta
          final localMetaService = await ref.read(localMetaCrudProvider.future);
          final localMetaResult = localMetaService.getByDbId(dbMetadata.id);

          localMetaResult.fold(
            onSuccess: (localMeta) async {
              final updated = localMeta.copyWith(
                lastImportedAt: DateTime.now(),
              );
              final updateResult = await localMetaService.update(updated);
              updateResult.fold(
                onSuccess: (_) {
                  logDebug('LocalMeta обновлена', tag: _tag);
                },
                onFailure: (err) {
                  logWarning(
                    'Не удалось обновить LocalMeta',
                    tag: _tag,
                    data: {'error': err.toString()},
                  );
                },
              );
            },
            onFailure: (err) {
              logWarning(
                'LocalMeta не найдена для обновления',
                tag: _tag,
                data: {'storageId': dbMetadata.id, 'error': err.toString()},
              );
            },
          );

          state = ImportState.success(importedFolderPath: importedFolderPath);

          logInfo(
            'Импорт успешно завершён',
            tag: _tag,
            data: {'importedFolderPath': importedFolderPath},
          );
        },
        onFailure: (error) {
          state = ImportState.failure(error);
          logError('Ошибка при замене БД', tag: _tag, data: {'error': error});
        },
      );
    } catch (e, st) {
      state = ImportState.failure('Непредвиденная ошибка: ${e.toString()}');
      logError(
        'Непредвиденная ошибка при импорте',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Сбрасывает состояние в idle
  void reset() {
    state = const ImportState.idle();
  }

  /// Повторяет последнюю операцию проверки версии
  Future<void> retryCheckVersion() async {
    if (_lastClientKey != null) {
      await checkForNewVersion(clientKey: _lastClientKey!);
    } else {
      logWarning('Нет сохранённых параметров для retry', tag: _tag);
    }
  }

  /// Повторяет последнюю операцию загрузки и замены
  Future<void> retryDownloadAndReplace() async {
    if (_lastClientKey != null && _lastVersionInfo != null) {
      await downloadAndReplace(
        clientKey: _lastClientKey!,
        versionInfo: _lastVersionInfo!,
      );
    } else {
      logWarning('Нет сохранённых параметров для retry', tag: _tag);
    }
  }
}

final cloudImportProvider = NotifierProvider<CloudImportNotifier, ImportState>(
  CloudImportNotifier.new,
);
