import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/app_preferences/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/models/db_state.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

/// Состояние операции открытия БД
class DatabaseOpenState {
  final bool isOpening;
  final String? error;

  const DatabaseOpenState({this.isOpening = false, this.error});

  DatabaseOpenState copyWith({
    bool? isOpening,
    String? error,
    bool? clearError,
  }) {
    return DatabaseOpenState(
      isOpening: isOpening ?? this.isOpening,
      error: clearError == true ? null : (error ?? this.error),
    );
  }
}

/// Контроллер для операций открытия БД
class DatabaseOpenController extends Notifier<DatabaseOpenState> {
  @override
  DatabaseOpenState build() {
    return const DatabaseOpenState();
  }

  /// Автоматическое открытие базы данных
  Future<DatabaseState?> autoOpenDatabase(DatabaseEntry database) async {
    final canAutoOpen =
        database.saveMasterPassword == true &&
        database.masterPassword?.isNotEmpty == true;

    if (!canAutoOpen) {
      logWarning(
        'Автоматическое открытие недоступно: пароль не сохранен',
        tag: 'DatabaseOpenController',
        data: {'path': database.path},
      );
      return null;
    }

    try {
      state = state.copyWith(isOpening: true, clearError: true);

      logInfo(
        'Автоматическое открытие БД: ${database.name}',
        tag: 'DatabaseOpenController',
        data: {'path': database.path},
      );

      final openDto = OpenDatabaseDto(
        path: database.path,
        masterPassword: database.masterPassword!,
        saveMasterPassword: true,
      );

      final hoplixiStoreNotifier = ref.read(hoplixiStoreProvider.notifier);
      await hoplixiStoreNotifier.openDatabase(openDto);

      final hoplixiStoreState = ref.read(hoplixiStoreProvider);
      final result = hoplixiStoreState.hasValue
          ? hoplixiStoreState.value
          : null;

      if (result != null) {
        logInfo(
          'БД открыта успешно (автоматически)',
          tag: 'DatabaseOpenController',
          data: {'status': result.status.toString()},
        );
      }

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка автоматического открытия: ${e.toString()}';
      state = state.copyWith(isOpening: false, error: errorMessage);

      logError(
        'Ошибка автоматического открытия БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseOpenController',
        data: {'path': database.path},
      );

      return null;
    } finally {
      state = state.copyWith(isOpening: false);
    }
  }

  /// Открытие базы данных с паролем
  Future<DatabaseState?> openDatabaseWithPassword(
    DatabaseEntry database,
    String password, {
    bool savePassword = false,
  }) async {
    try {
      state = state.copyWith(isOpening: true, clearError: true);

      logInfo(
        'Открытие БД с паролем: ${database.name}',
        tag: 'DatabaseOpenController',
        data: {'path': database.path, 'savePassword': savePassword},
      );

      final openDto = OpenDatabaseDto(
        path: database.path,
        masterPassword: password,
        saveMasterPassword: savePassword,
      );

      final hoplixiStoreNotifier = ref.read(hoplixiStoreProvider.notifier);
      await hoplixiStoreNotifier.openDatabase(openDto);

      final hoplixiStoreState = ref.read(hoplixiStoreProvider);
      final result = hoplixiStoreState.hasValue
          ? hoplixiStoreState.value
          : null;

      if (result != null) {
        logInfo(
          'БД открыта успешно',
          tag: 'DatabaseOpenController',
          data: {
            'status': result.status.toString(),
            'savePassword': savePassword,
          },
        );
      }

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка открытия: ${e.toString()}';
      state = state.copyWith(isOpening: false, error: errorMessage);

      logError(
        'Ошибка открытия БД с паролем',
        error: e,
        stackTrace: stackTrace,
        tag: 'DatabaseOpenController',
        data: {'path': database.path},
      );

      return null;
    } finally {
      state = state.copyWith(isOpening: false);
    }
  }

  /// Проверка возможности автоматического открытия с учетом настроек
  static Future<bool> checkCanAutoOpenWithSettings(
    DatabaseEntry? database,
  ) async {
    if (database == null) return false;

    try {
      final autoOpenEnabled = Prefs.get<bool>(Keys.autoOpenLastStorage);
      if (autoOpenEnabled != true) return false;

      return database.saveMasterPassword == true &&
          database.masterPassword?.isNotEmpty == true;
    } catch (e) {
      logError(
        'Ошибка проверки настроек автооткрытия',
        error: e,
        tag: 'DatabaseOpenController.checkCanAutoOpenWithSettings',
      );
      return false;
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер контроллера открытия БД
final databaseOpenControllerProvider =
    NotifierProvider<DatabaseOpenController, DatabaseOpenState>(
      DatabaseOpenController.new,
    );

/// Провайдер для проверки возможности автооткрытия с настройками
final canAutoOpenWithSettingsProvider =
    FutureProvider.family<bool, DatabaseEntry?>((ref, database) async {
      return await DatabaseOpenController.checkCanAutoOpenWithSettings(
        database,
      );
    });
