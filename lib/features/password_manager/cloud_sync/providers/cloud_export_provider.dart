import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/dropbox_export_service_provider.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/local_meta_crud_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

class CloudExportNotifier extends Notifier<ExportState> {
  static const String _tag = 'CloudExportProvider';

  // Сохраняем параметры последней операции для retry
  String? _lastClientKey;
  String? _lastEncryptionKeyArchive;

  @override
  ExportState build() {
    return const ExportState.idle();
  }

  /// Экспортирует текущее открытое хранилище в Dropbox
  Future<void> exportCurrentStorage({
    required String clientKey,
    String? encryptionKeyArchive,
  }) async {
    // Сохраняем параметры для возможности повтора
    _lastClientKey = clientKey;
    _lastEncryptionKeyArchive = encryptionKeyArchive;
    try {
      state = const ExportState.inProgress(
        progress: 0.0,
        message: 'Начало экспорта...',
      );

      // Получаем метаданные БД
      final dbManager = await ref.read(hoplixiStoreManagerProvider.future);
      final metadata = await dbManager.getDatabaseMetaForSync();

      // Получаем путь к БД
      final dbState = ref.read(hoplixiStoreProvider).value;
      if (dbState == null || dbState.path == null) {
        state = const ExportState.failure('База данных не открыта');
        return;
      }

      final pathToDbFolder = dbState.path!.substring(
        0,
        dbState.path!.lastIndexOf('\\'),
      );

      logInfo(
        'Начало экспорта хранилища',
        tag: _tag,
        data: {
          'storageName': metadata.name,
          'storageId': metadata.id,
          'path': pathToDbFolder,
        },
      );

      // Получаем сервис экспорта
      final exportService = await ref.read(dropboxExportServiceProvider.future);

      // Выполняем экспорт
      final result = await exportService.exportToDropbox(
        metadata,
        clientKey,
        pathToDbFolder,
        encryptionKeyArchive,
        onProgress: (progress, message) {
          state = ExportState.inProgress(progress: progress, message: message);
        },
        onFileProgress: (progress, message) {
          logDebug('File progress: $progress - $message', tag: _tag);
        },
        onError: (error) {
          logError('Export error', tag: _tag, data: {'error': error});
        },
      );

      result.fold(
        onSuccess: (data) async {
          // Обновляем LocalMeta
          final localMetaService = await ref.read(localMetaCrudProvider.future);
          final localMetaResult = localMetaService.getByDbId(metadata.id);

          localMetaResult.fold(
            onSuccess: (localMeta) async {
              final updated = localMeta.copyWith(lastExportAt: DateTime.now());
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
              // Если LocalMeta не найдена, логируем предупреждение
              logWarning(
                'LocalMeta не найдена для обновления',
                tag: _tag,
                data: {'storageId': metadata.id, 'error': err.toString()},
              );
            },
          );

          state = ExportState.success(
            fileName: data.fileName,
            exportTime: data.exportTime,
          );

          logInfo(
            'Экспорт успешно завершён',
            tag: _tag,
            data: {'fileName': data.fileName, 'exportTime': data.exportTime},
          );
        },
        onFailure: (error) {
          state = ExportState.failure(error);
          logError('Ошибка при экспорте', tag: _tag, data: {'error': error});
        },
      );
    } catch (e, st) {
      state = ExportState.failure('Непредвиденная ошибка: ${e.toString()}');
      logError(
        'Непредвиденная ошибка при экспорте',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Сбрасывает состояние в idle
  void reset() {
    state = const ExportState.idle();
  }

  /// Повторяет последнюю операцию экспорта
  Future<void> retry() async {
    if (_lastClientKey != null) {
      await exportCurrentStorage(
        clientKey: _lastClientKey!,
        encryptionKeyArchive: _lastEncryptionKeyArchive,
      );
    } else {
      logWarning('Нет сохранённых параметров для retry', tag: _tag);
    }
  }
}

final cloudExportProvider = NotifierProvider<CloudExportNotifier, ExportState>(
  CloudExportNotifier.new,
);
