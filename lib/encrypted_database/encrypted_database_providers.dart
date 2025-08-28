import 'package:hoplixi/encrypted_database/dto/db_dto.dart';

import 'db_state.dart';
import 'encrypted_database_manager.dart';
import 'package:riverpod/riverpod.dart';

final databaseManagerProvider = Provider<EncryptedDatabaseManager>((ref) {
  final manager = EncryptedDatabaseManager();
  // Cleanup on dispose
  ref.onDispose(() {
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> openDatabase(OpenDatabaseDto dto) async {
    try {
      state = state.copyWith(error: null);
      final newState = await _manager.openDatabase(dto);
      state = newState;
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> closeDatabase() async {
    try {
      state = state.copyWith(error: null);
      final newState = await _manager.closeDatabase();
      state = newState;
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Future<void> lockDatabase() async {
  //   try {
  //     state = state.copyWith(error: null);
  //     final newState = await _manager.lockDatabase();
  //     state = newState;
  //   } catch (e) {
  //     state = state.copyWith(error: e.toString());
  //   }
  // }

  // Future<void> unlockDatabase(String password) async {
  //   try {
  //     state = state.copyWith(error: null);
  //     final newState = await _manager.unlockDatabase(password);
  //     state = newState;
  //   } catch (e) {
  //     state = state.copyWith(error: e.toString());
  //   }
  // }

  Future<String?> pickDatabaseFile() async {
    return await _manager.pickDatabaseFile();
  }

  // Future<Map<String, dynamic>> getHealthInfo() async {
  //   return await _manager.getHealthInfo();
  // }

  // Future<List<String>> repairStorage() async {
  //   try {
  //     state = state.copyWith(error: null);
  //     return await _manager.repairStorage();
  //   } catch (e) {
  //     state = state.copyWith(error: e.toString());
  //     return ['Repair failed: $e'];
  //   }
  // }
}
