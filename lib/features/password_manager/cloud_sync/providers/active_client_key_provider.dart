import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/local_meta_crud_provider.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

/// Провайдер для получения активного clientKey для текущей открытой БД
///
/// Возвращает clientKey, который используется для облачной синхронизации:
/// 1. Получает метаданные текущей БД
/// 2. Находит LocalMeta запись по dbId
/// 3. Определяет providerType (dropbox, yandex, google и т.д.)
/// 4. Возвращает clientKey для этого провайдера из OAuth2AccountService
final activeClientKeyProvider = FutureProvider<String?>((ref) async {
  const tag = 'ActiveClientKeyProvider';

  try {
    // Получаем метаданные текущей БД
    final dbManager = await ref.watch(hoplixiStoreManagerProvider.future);
    final dbMeta = await dbManager.getDatabaseMetaForSync();

    // Получаем LocalMeta для определения провайдера
    final localMetaService = await ref.watch(localMetaCrudProvider.future);
    final localMetaResult = localMetaService.getByDbId(dbMeta.id);

    return localMetaResult.fold(
      onSuccess: (localMeta) {
        if (!localMeta.enabled) {
          logWarning(
            'Облачная синхронизация отключена для БД',
            tag: tag,
            data: {'dbId': dbMeta.id, 'dbName': dbMeta.name},
          );
          return null;
        }

        // Формируем clientKey на основе providerType
        // Формат clientKey: provider_type (например, 'dropbox', 'yandex_disk')
        final clientKey = _getClientKeyFromProvider(localMeta.providerType);

        logDebug(
          'Определён активный clientKey',
          tag: tag,
          data: {
            'dbId': dbMeta.id,
            'providerType': localMeta.providerType.name,
            'clientKey': clientKey,
          },
        );

        return clientKey;
      },
      onFailure: (error) {
        logInfo(
          'LocalMeta не найдена, облачная синхронизация не настроена',
          tag: tag,
          data: {'dbId': dbMeta.id, 'error': error.toString()},
        );
        return null;
      },
    );
  } catch (e, st) {
    logError(
      'Ошибка при получении активного clientKey',
      error: e,
      stackTrace: st,
      tag: tag,
    );
    return null;
  }
});

/// Преобразует ProviderType в clientKey
String _getClientKeyFromProvider(ProviderType providerType) {
  switch (providerType) {
    case ProviderType.dropbox:
      return 'dropbox';
    case ProviderType.yandex:
      return 'yandex_disk';
    case ProviderType.google:
      return 'google_drive';
    case ProviderType.microsoft:
      return 'onedrive';
    case ProviderType.unknown:
      throw ArgumentError('Неподдерживаемый провайдер: unknown');
  }
}
