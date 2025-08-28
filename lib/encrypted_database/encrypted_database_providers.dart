import 'package:hoplixi/encrypted_database/dto/db_dto.dart';
import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

import 'db_state.dart';
import 'encrypted_database_manager.dart';
import 'package:riverpod/riverpod.dart';

final databaseManagerProvider = Provider<EncryptedDatabaseManager>((ref) {
  final manager = EncryptedDatabaseManager();

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
      final manager = ref.read(databaseManagerProvider);
      return DatabaseStateNotifier(manager);
    });

class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  final EncryptedDatabaseManager _manager;

  DatabaseStateNotifier(this._manager) : super(const DatabaseState());

  Future<void> createDatabase(CreateDatabaseDto dto) async {
    try {
      state = state.copyWith(error: null);
      final newState = await _manager.createDatabase(dto);
      state = newState;
      logInfo(
        'База данных успешно создана через провайдер',
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name, 'path': newState.path},
      );
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      logError(
        'Ошибка создания базы данных через провайдер',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
      );
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<void> openDatabase(OpenDatabaseDto dto) async {
    try {
      state = state.copyWith(error: null);
      final newState = await _manager.openDatabase(dto);
      state = newState;
      logInfo(
        'База данных успешно открыта через провайдер',
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path, 'name': newState.name},
      );
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      logError(
        'Ошибка открытия базы данных через провайдер',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
      );
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<void> closeDatabase() async {
    try {
      state = state.copyWith(error: null);
      final newState = await _manager.closeDatabase();
      state = newState;
      logInfo(
        'База данных успешно закрыта через провайдер',
        tag: 'DatabaseStateNotifier',
      );
    } catch (e) {
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      logError(
        'Ошибка закрытия базы данных через провайдер',
        error: e,
        tag: 'DatabaseStateNotifier',
      );
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<String?> pickDatabaseFile() async {
    try {
      final result = await _manager.pickDatabaseFile();
      logInfo(
        'Файл базы данных выбран через провайдер',
        tag: 'DatabaseStateNotifier',
        data: {'selected': result != null, 'path': result},
      );
      return result;
    } catch (e) {
      logError(
        'Ошибка выбора файла базы данных через провайдер',
        error: e,
        tag: 'DatabaseStateNotifier',
      );
      return null;
    }
  }
}
