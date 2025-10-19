import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/core/utils/result_pattern/common_errors.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_setup_state.dart';
import 'package:hoplixi/features/cloud_sync/models/local_meta.dart';
import 'package:hoplixi/features/cloud_sync/providers/local_meta_crud_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

final cloudSyncSetupProvider =
    AsyncNotifierProvider<CloudSyncSetupNotifier, CloudSyncSetupState>(
      CloudSyncSetupNotifier.new,
    );

class CloudSyncSetupNotifier extends AsyncNotifier<CloudSyncSetupState> {
  static const String _tag = 'CloudSyncSetupNotifier';

  // Временное хранилище для данных настройки
  String? _pendingDbId;
  String? _pendingDbName;

  @override
  Future<CloudSyncSetupState> build() async {
    // Начальная проверка при открытии экрана
    return await _checkSyncStatus();
  }

  /// Начать процесс настройки (вызывается перед авторизацией)
  void startSetup({required String dbId, required String dbName}) {
    _pendingDbId = dbId;
    _pendingDbName = dbName;
    logInfo(
      'Сохранены данные для настройки синхронизации',
      tag: _tag,
      data: {'dbId': dbId, 'dbName': dbName},
    );
  }

  /// Проверить и завершить отложенную настройку (вызывается после возврата)
  Future<void> checkAndCompletePendingSetup(String? providerKey) async {
    if (providerKey == null) {
      logInfo('Авторизация отменена', tag: _tag);
      _clearPendingSetup();
      return;
    }

    if (_pendingDbId == null || _pendingDbName == null) {
      logWarning('Нет сохраненных данных для завершения настройки', tag: _tag);
      return;
    }

    await completeSetup(
      providerKey: providerKey,
      dbId: _pendingDbId!,
      dbName: _pendingDbName!,
    );

    _clearPendingSetup();
  }

  /// Очистить временные данные
  void _clearPendingSetup() {
    _pendingDbId = null;
    _pendingDbName = null;
  }

  /// Проверить текущий статус синхронизации
  Future<CloudSyncSetupState> _checkSyncStatus() async {
    try {
      // Получаем информацию о текущей открытой БД
      final dbState = ref.read(hoplixiStoreProvider).asData?.value;

      if (dbState == null || !dbState.isOpen) {
        return const CloudSyncSetupState.error(
          message: 'База данных не открыта',
        );
      }

      // Получаем метаданные БД для синхронизации
      final manager = await ref.read(hoplixiStoreManagerProvider.future);
      final DatabaseMetaForSync dbMeta;

      try {
        dbMeta = await manager.getDatabaseMetaForSync();
      } catch (e) {
        logError('Ошибка получения метаданных БД', error: e, tag: _tag);
        return const CloudSyncSetupState.error(
          message: 'Не удалось получить метаданные базы данных',
        );
      }

      // Проверяем, есть ли запись в LocalMeta
      final localMetaService = await ref.read(localMetaCrudProvider.future);
      final result = localMetaService.getByDbId(dbMeta.id);

      return result.fold(
        onSuccess: (meta) {
          // Запись найдена - синхронизация уже настроена
          logInfo(
            'Синхронизация уже настроена для БД: ${dbMeta.name}',
            tag: _tag,
            data: {
              'dbId': dbMeta.id,
              'providerType': meta.providerType.name,
              'enabled': meta.enabled,
            },
          );
          return CloudSyncSetupState.alreadyConfigured(meta: meta);
        },
        onFailure: (error) {
          // Запись не найдена - синхронизация не настроена
          if (error is NotFoundError) {
            logInfo(
              'Синхронизация не настроена для БД: ${dbMeta.name}',
              tag: _tag,
              data: {'dbId': dbMeta.id},
            );
            return CloudSyncSetupState.notConfigured(
              dbId: dbMeta.id,
              dbName: dbMeta.name,
            );
          }

          // Другая ошибка
          logError('Ошибка проверки LocalMeta', error: error, tag: _tag);
          return CloudSyncSetupState.error(
            message:
                'Ошибка проверки статуса синхронизации: ${error.toUserMessage()}',
            dbId: dbMeta.id,
          );
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Неожиданная ошибка при проверке статуса синхронизации',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return CloudSyncSetupState.error(
        message: 'Неожиданная ошибка: ${e.toString()}',
      );
    }
  }

  /// Начать настройку синхронизации после успешной авторизации
  Future<void> completeSetup({
    required String providerKey,
    required String dbId,
    required String dbName,
  }) async {
    try {
      state = const AsyncValue.loading();
      state = const AsyncValue.data(CloudSyncSetupState.setupInProgress());

      // Извлекаем тип провайдера из ключа
      final providerType = ProviderTypeX.fromKey(providerKey);

      if (providerType == ProviderType.unknown) {
        throw Exception(
          'Не удалось определить тип провайдера из ключа: $providerKey',
        );
      }

      logInfo(
        'Завершение настройки синхронизации',
        tag: _tag,
        data: {
          'dbId': dbId,
          'dbName': dbName,
          'providerType': providerType.name,
          'providerKey': providerKey,
        },
      );

      // Получаем deviceId
      final deviceInfo = await DeviceInfo.collect();
      final deviceId = deviceInfo.deviceId;

      // Создаём запись в LocalMeta
      final localMetaService = await ref.read(localMetaCrudProvider.future);
      final localMeta = LocalMeta(
        dbId: dbId,
        enabled: true,
        dbName: dbName,
        deviceId: deviceId,
        providerType: providerType,
        lastExportAt: null,
        lastImportedAt: null,
      );

      final createResult = await localMetaService.create(localMeta);

      await createResult.fold(
        onSuccess: (createdMeta) async {
          logInfo(
            'LocalMeta успешно создан',
            tag: _tag,
            data: {
              'dbId': createdMeta.dbId,
              'providerType': createdMeta.providerType.name,
            },
          );

          // Переходим в состояние завершения
          state = AsyncValue.data(
            CloudSyncSetupState.setupCompleted(
              providerType: providerType,
              dbName: dbName,
            ),
          );
        },
        onFailure: (error) async {
          logError('Ошибка создания LocalMeta', error: error, tag: _tag);
          state = AsyncValue.data(
            CloudSyncSetupState.error(
              message:
                  'Не удалось сохранить настройки: ${error.toUserMessage()}',
              dbId: dbId,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка завершения настройки синхронизации',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      state = AsyncValue.data(
        CloudSyncSetupState.error(message: 'Ошибка настройки: ${e.toString()}'),
      );
    }
  }

  /// Повторить проверку статуса
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _checkSyncStatus());
  }
}
