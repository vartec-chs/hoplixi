library;

import 'dart:async';

import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/cloud_sync_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/box_db_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/models/db_state.dart';

final hoplixiStoreManagerProvider = FutureProvider<HoplixiStoreManager>((
  ref,
) async {
  final boxManager = await ref.watch(boxDbProvider.future);
  final manager = HoplixiStoreManager(boxManager: boxManager);

  // Cleanup on dispose
  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов databaseManagerProvider',
      tag: 'DatabaseProviders',
    );
    manager.dispose();
    boxManager.closeAll();
  });

  return manager;
});

final hoplixiStoreProvider =
    AsyncNotifierProvider<DatabaseAsyncNotifier, DatabaseState>(
      DatabaseAsyncNotifier.new,
    );

final isDatabaseOpenProvider = Provider<bool>((ref) {
  return ref.watch(
    hoplixiStoreProvider.select((async) => async.asData?.value.isOpen ?? false),
  );
});

final stateProvider = Provider<DatabaseState?>((ref) {
  return ref.watch(hoplixiStoreProvider).asData?.value;
});

/// Нотификатор состояния базы данных (новая версия)
class DatabaseAsyncNotifier extends AsyncNotifier<DatabaseState> {
  late final HoplixiStoreManager _manager;

  @override
  Future<DatabaseState> build() async {
    _manager = await ref.read(hoplixiStoreManagerProvider.future);
    return const DatabaseState();
  }

  /// Создать новую базу
  Future<void> createDatabase(CreateDatabaseDto dto) async {
    try {
      state = const AsyncValue.loading();
      final newState = await _manager.createDatabase(dto);
      // final manager = ref.read(fileEncryptorProvider.notifier);
      // await manager.initialize();
      state = AsyncValue.data(newState);
      logInfo(
        'База данных создана успешно',
        tag: 'DatabaseAsyncNotifier',
        data: {'name': dto.name},
      );
    } catch (e, st) {
      logError(
        'Ошибка создания базы данных',
        error: e,
        stackTrace: st,
        tag: 'DatabaseAsyncNotifier',
        data: {'name': dto.name},
      );
      final dbError = e is DatabaseError
          ? e
          : DatabaseError.unknown(
              message: 'Unknown database error',
              stackTrace: st,
              details: e.toString(),
            );
      state = AsyncValue.error(dbError, st);
      rethrow;
    }
  }

  /// Открыть существующую базу
  Future<void> openDatabase(OpenDatabaseDto dto) async {
    try {
      state = const AsyncValue.loading();
      final isCloudSyncEnabled = Prefs.get(Keys.autoSyncCloud);

      final newState = await _manager.openDatabase(dto);

      final metaDataForSync = await _manager.getDatabaseMetaForSync();

      if (isCloudSyncEnabled == true &&
          metaDataForSync != null &&
          newState.isOpen) {
        logInfo(
          'База данных открыта с включённой облачной синхронизацией',
          tag: 'DatabaseAsyncNotifier',
          data: {
            'storageId': metaDataForSync.id,
            'storageName': metaDataForSync.name,
            'path': dto.path,
          },
        );
        // Запускаем синхронизацию в фоне
        unawaited(
          ref
              .read(cloudSyncProvider.notifier)
              .importFromDropbox(metadata: metaDataForSync),
        );
      }

      // final manager = ref.read(fileEncryptorProvider.notifier);
      // await manager.initialize();

      state = AsyncValue.data(newState);
      logInfo(
        'База данных открыта успешно',
        tag: 'DatabaseAsyncNotifier',
        data: {'path': dto.path},
      );
    } catch (e, st) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        stackTrace: st,
        tag: 'DatabaseAsyncNotifier',
        data: {'path': dto.path},
      );
      final dbError = e is DatabaseError
          ? e
          : DatabaseError.unknown(
              message: 'Unknown database error',
              stackTrace: st,
              details: e.toString(),
            );
      state = AsyncValue.error(dbError, st);
      rethrow;
    }
  }

  /// Закрыть текущую базу
  Future<void> closeDatabase({bool? imported}) async {
    try {
      final path = state.asData?.value.path;
      final modifiedAtBeforeOpen =
          state.asData?.value.modifiedAt ?? DateTime.now();
      state = const AsyncValue.loading();

      final modifiedAtCurrent = DateTime.fromMillisecondsSinceEpoch(
        await currentDatabase.getModifiedAt(),
      );
      final isModified = modifiedAtCurrent.isAfter(modifiedAtBeforeOpen);
      logDebug(
        'Database modified check: isModified=$isModified, modifiedAtBeforeOpen=$modifiedAtBeforeOpen, modifiedAtCurrent=$modifiedAtCurrent',
        tag: 'DatabaseAsyncNotifier',
      );
      final metaDataForSync = await _manager.getDatabaseMetaForSync();

      final isCloudSyncEnabled = Prefs.get(Keys.autoSyncCloud);
      await _manager.closeDatabase();

      if (isModified &&
          isCloudSyncEnabled! &&
          metaDataForSync != null &&
          (imported == null || imported == false)) {
        logInfo(
          'Database modified at $modifiedAtCurrent, before open at $modifiedAtBeforeOpen. Starting cloud sync...',
          tag: 'DatabaseAsyncNotifier',
          data: {
            'storageId': metaDataForSync.id,
            'storageName': metaDataForSync.name,
            'path': path,
          },
        );
        // Запускаем синхронизацию в фоне
        unawaited(
          ref
              .read(cloudSyncProvider.notifier)
              .exportToDropbox(
                metadata: metaDataForSync,
                pathToDbFolder: p.dirname(path ?? ''),
              ),
        );
      }
      // final manager = ref.read(fileEncryptorProvider.notifier);
      // await manager.cleanup();
      state = AsyncValue.data(DatabaseState(status: DatabaseStatus.closed));
      logInfo('База данных закрыта успешно', tag: 'DatabaseAsyncNotifier');
    } catch (e, st) {
      logError(
        'Ошибка закрытия базы данных',
        error: e,
        stackTrace: st,
        tag: 'DatabaseAsyncNotifier',
      );
      // В любом случае считаем базу закрытой
      state = const AsyncValue.data(
        DatabaseState(status: DatabaseStatus.closed),
      );
    }
  }

  /// Удалить текущую базу данных вместе с папкой и записью из истории
  Future<void> deleteCurrentDatabase() async {
    try {
      state = const AsyncValue.loading();
      await _manager.deleteCurrentDatabase();
      state = AsyncValue.data(DatabaseState(status: DatabaseStatus.closed));
      logInfo('База данных удалена успешно', tag: 'DatabaseAsyncNotifier');
    } catch (e, st) {
      logError(
        'Ошибка удаления базы данных',
        error: e,
        stackTrace: st,
        tag: 'DatabaseAsyncNotifier',
      );
      final dbError = e is DatabaseError
          ? e
          : DatabaseError.unknown(
              message: 'Unknown database error',
              stackTrace: st,
              details: e.toString(),
            );
      state = AsyncValue.error(dbError, st);
      rethrow;
    }
  }

  // Утилиты
  DatabaseState? get currentState => state.asData?.value;
  bool get isDatabaseOpen => state.asData?.value.isOpen ?? false;
  String? get databaseFilePath => state.asData?.value.path;

  String? get databaseDir => p.dirname(databaseFilePath ?? '');

  HoplixiStore get currentDatabase {
    final db = _manager.database;
    if (db == null) {
      logError(
        'Попытка доступа к базе данных, когда она не открыта',
        tag: 'DatabaseAsyncNotifier',
        data: {'state': state.toString()},
      );
      throw DatabaseError.operationFailed(
        operation: 'getCurrentDatabase',
        details:
            'Database is not open or not initialized. Current Async state: $state',
        message: 'Database must be opened before accessing it',
        stackTrace: StackTrace.current,
      );
    }
    return db;
  }
}
