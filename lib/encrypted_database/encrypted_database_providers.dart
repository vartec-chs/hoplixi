import 'package:hoplixi/encrypted_database/dto/db_dto.dart';
import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

import 'db_state.dart';
import 'encrypted_database_manager.dart';
import 'interfaces/database_interfaces.dart';
import 'services/crypto_service.dart';
import 'services/database_validation_service.dart';
import 'services/database_connection_service.dart';
import 'services/database_history_service.dart';
import 'package:riverpod/riverpod.dart';

// === ПРОВАЙДЕРЫ СЕРВИСОВ ===

/// Провайдер криптографического сервиса
final cryptoServiceProvider = Provider<ICryptoService>((ref) {
  return CryptoService();
});

/// Провайдер сервиса валидации
final validationServiceProvider = Provider<IDatabaseValidationService>((ref) {
  return DatabaseValidationService();
});

/// Провайдер сервиса подключения
final connectionServiceProvider = Provider<IDatabaseConnectionService>((ref) {
  final cryptoService = ref.read(cryptoServiceProvider);
  return DatabaseConnectionService(cryptoService: cryptoService);
});

/// Провайдер сервиса истории
final historyServiceProvider = Provider<IDatabaseHistoryService>((ref) {
  return DatabaseHistoryService();
});

// === ОСНОВНЫЕ ПРОВАЙДЕРЫ ===

/// Провайдер рефакторенного менеджера базы данных
final databaseManagerProvider = Provider<IEncryptedDatabaseManager>((ref) {
  final cryptoService = ref.read(cryptoServiceProvider);
  final validationService = ref.read(validationServiceProvider);
  final connectionService = ref.read(connectionServiceProvider);
  final historyService = ref.read(historyServiceProvider);

  final manager = EncryptedDatabaseManager(
    cryptoService: cryptoService,
    validationService: validationService,
    connectionService: connectionService,
    historyService: historyService,
  );

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

/// Провайдер состояния базы данных (новая версия)
final databaseStateProvider =
    StateNotifierProvider<DatabaseStateNotifier, DatabaseState>((ref) {
      final manager = ref.read(databaseManagerProvider);
      return DatabaseStateNotifier(manager);
    });

/// Нотификатор состояния базы данных (новая версия)
class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  final IEncryptedDatabaseManager _manager;

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
    } catch (e) {
      logError(
        'Ошибка создания базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError ? e.toString() : e.toString(),
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
    } catch (e) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError ? e.toString() : e.toString(),
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

  /// Попытка автологина
  Future<bool> tryAutoLogin(String path) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final result = await _manager.openWithAutoLogin(path);
      if (result != null) {
        state = result;
        logInfo(
          'Автологин успешен',
          tag: 'DatabaseStateNotifier',
          data: {'path': path},
        );
        return true;
      } else {
        state = const DatabaseState(status: DatabaseStatus.closed);
        logDebug(
          'Автологин не удался',
          tag: 'DatabaseStateNotifier',
          data: {'path': path},
        );
        return false;
      }
    } catch (e) {
      logError(
        'Ошибка автологина',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': path},
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError ? e.toString() : e.toString(),
      );
      return false;
    }
  }

  /// Умное открытие базы данных
  Future<bool> smartOpen(String path, [String? providedPassword]) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final result = await _manager.smartOpen(path, providedPassword);
      if (result != null) {
        state = result;
        logInfo(
          'Умное открытие успешно',
          tag: 'DatabaseStateNotifier',
          data: {'path': path},
        );
        return true;
      } else {
        state = const DatabaseState(status: DatabaseStatus.closed);
        logDebug(
          'Умное открытие не удалось',
          tag: 'DatabaseStateNotifier',
          data: {'path': path},
        );
        return false;
      }
    } catch (e) {
      logError(
        'Ошибка умного открытия',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': path},
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError ? e.toString() : e.toString(),
      );
      return false;
    }
  }

  /// Проверка возможности автологина
  Future<bool> canAutoLogin(String path) async {
    try {
      return await _manager.canAutoLogin(path);
    } catch (e) {
      logError(
        'Ошибка проверки возможности автологина',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': path},
      );
      return false;
    }
  }

  /// Выбор файла базы данных
  Future<String?> pickDatabaseFile() async {
    try {
      return await _manager.pickDatabaseFile();
    } catch (e) {
      logError(
        'Ошибка выбора файла базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
      );
      return null;
    }
  }

  /// Сброс состояния в начальное
  void reset() {
    state = const DatabaseState();
  }

  /// Установка состояния ошибки
  void setError(DatabaseError error) {
    state = DatabaseState(
      status: DatabaseStatus.error,
      error: error.toString(),
    );
  }
}
