library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/state.dart';

final hoplixiStoreManagerProvider = Provider<HoplixiStoreManager>((ref) {
  final manager = HoplixiStoreManager();

  // Cleanup on dispose
  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов databaseManagerProvider',
      tag: 'DatabaseProviders',
    );
    manager.dispose();
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
    _manager = ref.read(hoplixiStoreManagerProvider);
    return const DatabaseState();
  }

  /// Создать новую базу
  Future<void> createDatabase(CreateDatabaseDto dto) async {
    try {
      state = const AsyncValue.loading();
      final newState = await _manager.createDatabase(dto);
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
      final newState = await _manager.openDatabase(dto);
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
  Future<void> closeDatabase() async {
    try {
      state = const AsyncValue.loading();
      final closedState = await _manager.closeDatabase();
      state = AsyncValue.data(closedState);
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

  // Утилиты
  DatabaseState? get currentState => state.asData?.value;
  bool get isDatabaseOpen => state.asData?.value.isOpen ?? false;

  HoplixiStore get currentDatabase {
    final db = _manager.database;
    if (db == null) {
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
