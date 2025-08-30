import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
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

final databaseStateProvider =
    StateNotifierProvider<DatabaseStateNotifier, DatabaseState>((ref) {
      final manager = ref.read(hoplixiStoreManagerProvider);
      return DatabaseStateNotifier(manager);
    });

/// Нотификатор состояния базы данных (новая версия)
class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  final HoplixiStoreManager _manager;

  DatabaseStateNotifier(this._manager) : super(const DatabaseState());

  /// Создает новую базу данных
  Future<void> createDatabase(CreateDatabaseDto dto) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final newState = await _manager.createDatabase(dto);
      state = newState;
      logInfo(
        'База данных создана успешно',
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
        stackTrace: stackTrace,
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError
            ? e
            : DatabaseError.unknown(
                message: 'Unknown database error',
                stackTrace: stackTrace,
                details: e.toString(),
              ),
      );
      rethrow;
    }
  }

  /// Открывает существующую базу данных
  Future<void> openDatabase(OpenDatabaseDto dto) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final newState = await _manager.openDatabase(dto);
      state = newState;
      logInfo(
        'База данных открыта успешно',
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
        stackTrace: stackTrace,
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError
            ? e
            : DatabaseError.unknown(
                message: 'Unknown database error',
                stackTrace: stackTrace,
                details: e.toString(),
              ),
      );
      rethrow;
    }
  }

  /// Закрывает текущую базу данных
  Future<void> closeDatabase() async {
    try {
      final newState = await _manager.closeDatabase();
      state = newState;
      logInfo('База данных закрыта успешно', tag: 'DatabaseStateNotifier');
    } catch (e) {
      logError(
        'Ошибка закрытия базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
      );
      // В случае ошибки закрытия, все равно считаем БД закрытой
      state = const DatabaseState(status: DatabaseStatus.closed);
    }
  }

  // /// Попытка автологина
  // Future<bool> tryAutoLogin(String path) async {
  //   try {
  //     state = state.copyWith(status: DatabaseStatus.loading);
  //     final result = await _manager.openWithAutoLogin(path);
  //     if (result != null) {
  //       state = result;
  //       logInfo(
  //         'Автологин успешен',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return true;
  //     } else {
  //       state = const DatabaseState(status: DatabaseStatus.closed);
  //       logDebug(
  //         'Автологин не удался',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     logError(
  //       'Ошибка автологина',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     state = DatabaseState(
  //       status: DatabaseStatus.error,
  //       error: e is DatabaseError ? e.toString() : e.toString(),
  //     );
  //     return false;
  //   }
  // }

  // /// Умное открытие базы данных
  // Future<bool> smartOpen(String path, [String? providedPassword]) async {
  //   try {
  //     state = state.copyWith(status: DatabaseStatus.loading);
  //     final result = await _manager.smartOpen(path, providedPassword);
  //     if (result != null) {
  //       state = result;
  //       logInfo(
  //         'Умное открытие успешно',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return true;
  //     } else {
  //       state = const DatabaseState(status: DatabaseStatus.closed);
  //       logDebug(
  //         'Умное открытие не удалось',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     logError(
  //       'Ошибка умного открытия',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     state = DatabaseState(
  //       status: DatabaseStatus.error,
  //       error: e is DatabaseError ? e.toString() : e.toString(),
  //     );
  //     return false;
  //   }
  // }

  // /// Проверка возможности автологина
  // Future<bool> canAutoLogin(String path) async {
  //   try {
  //     return await _manager.canAutoLogin(path);
  //   } catch (e) {
  //     logError(
  //       'Ошибка проверки возможности автологина',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     return false;
  //   }
  // }

  /// Выбор файла базы данных
  // Future<String?> pickDatabaseFile() async {
  //   try {
  //     return await _manager.pickDatabaseFile();
  //   } catch (e) {
  //     logError(
  //       'Ошибка выбора файла базы данных',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //     );
  //     return null;
  //   }
  // }

  /// Сброс состояния в начальное
  void reset() {
    state = const DatabaseState();
  }

  /// Установка состояния ошибки
  void setError(DatabaseError error) {
    state = DatabaseState(status: DatabaseStatus.error, error: error);
  }
}
