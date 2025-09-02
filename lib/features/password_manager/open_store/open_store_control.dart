import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/dto/database_file_info.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/state.dart';
import 'package:file_picker/file_picker.dart';

/// Состояние формы открытия хранилища
class OpenStoreFormState {
  final String databasePath;
  final String masterPassword;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, String?> fieldErrors;

  const OpenStoreFormState({
    this.databasePath = '',
    this.masterPassword = '',
    this.isLoading = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  OpenStoreFormState copyWith({
    String? databasePath,
    String? masterPassword,
    bool? isLoading,
    String? errorMessage,
    Map<String, String?>? fieldErrors,
  }) {
    return OpenStoreFormState(
      databasePath: databasePath ?? this.databasePath,
      masterPassword: masterPassword ?? this.masterPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  bool get isValid {
    return databasePath.isNotEmpty &&
        masterPassword.isNotEmpty &&
        fieldErrors.isEmpty;
  }
}

/// Контроллер для управления состоянием формы открытия хранилища
class OpenStoreController extends StateNotifier<OpenStoreFormState> {
  final Ref _ref;

  OpenStoreController(this._ref) : super(const OpenStoreFormState());

  /// Обновление пути к базе данных
  void updateDatabasePath(String path) {
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (path.isEmpty) {
      errors['databasePath'] = 'Путь к хранилищу обязателен';
    } else if (!File(path).existsSync()) {
      errors['databasePath'] = 'Файл хранилища не существует';
    } else if (!path.toLowerCase().endsWith(".${MainConstants.dbExtension}")) {
      errors['databasePath'] = 'Неверный формат файла хранилища';
    } else {
      errors.remove('databasePath');
    }

    state = state.copyWith(databasePath: path, fieldErrors: errors);
  }

  /// Обновление мастер-пароля
  void updateMasterPassword(String password) {
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (password.isEmpty) {
      errors['masterPassword'] = 'Мастер-пароль обязателен';
    } else {
      errors.remove('masterPassword');
    }

    state = state.copyWith(masterPassword: password, fieldErrors: errors);
  }

  /// Выбор файла базы данных
  Future<void> selectDatabaseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [MainConstants.dbExtension],
        dialogTitle: 'Выберите файл хранилища',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        updateDatabasePath(path);
        logDebug(
          'Выбран файл хранилища',
          tag: 'OpenStoreController',
          data: {'path': path},
        );
      }
    } catch (e) {
      logError(
        'Ошибка выбора файла хранилища',
        error: e,
        tag: 'OpenStoreController',
      );

      final errors = Map<String, String?>.from(state.fieldErrors);
      errors['databasePath'] = 'Ошибка при выборе файла';
      state = state.copyWith(fieldErrors: errors);
    }
  }

  /// Быстрый выбор файла БД из найденных
  void selectDatabaseFromInfo(DatabaseFileInfo fileInfo) {
    updateDatabasePath(fileInfo.path);
    logDebug(
      'Выбран файл БД из списка',
      tag: 'OpenStoreController',
      data: {'path': fileInfo.path, 'name': fileInfo.name},
    );
  }

  /// Открытие хранилища
  Future<void> openStore() async {
    if (!state.isValid) {
      logWarning(
        'Попытка открыть хранилище с невалидными данными',
        tag: 'OpenStoreController',
        data: {'isValid': state.isValid},
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dto = OpenDatabaseDto(
        path: state.databasePath,
        masterPassword: state.masterPassword,
      );

      await _ref.read(databaseStateProvider.notifier).openDatabase(dto);

      // Отложенное логирование после завершения операции
      scheduleMicrotask(() {
        logInfo(
          'Хранилище успешно открыто',
          tag: 'OpenStoreController',
          data: {'path': state.databasePath},
        );
      });

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      // Отложенное логирование для избежания проблем с build cycle
      scheduleMicrotask(() {
        logError(
          'Ошибка открытия хранилища',
          error: e,
          tag: 'OpenStoreController',
          data: {'path': state.databasePath},
          stackTrace: stackTrace,
        );
      });

      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e, stackTrace),
      );
    }
  }

  /// Получение понятного сообщения об ошибке
  String _getErrorMessage(Object error, [StackTrace? stackTrace]) {
    if (error is DatabaseError) {
      return error.when(
        invalidPassword: (code, message, data, stackTrace, timestamp) =>
            'Неверный мастер-пароль',
        databaseNotFound: (path, code, message, data, stackTrace, timestamp) =>
            'Файл хранилища не найден',
        databaseAlreadyExists:
            (path, code, message, data, stackTrace, timestamp) =>
                'Хранилище уже существует',
        connectionFailed:
            (details, code, message, data, stackTrace, timestamp) =>
                'Ошибка подключения к хранилищу',
        operationFailed:
            (operation, details, code, message, data, stackTrace, timestamp) =>
                'Ошибка выполнения операции: $operation',
        pathNotAccessible: (path, code, message, data, stackTrace, timestamp) =>
            'Нет доступа к файлу хранилища',
        unknown: (details, code, message, data, stackTrace, timestamp) =>
            'Неизвестная ошибка: $details',
        keyError: (details, code, message, data, stackTrace, timestamp) =>
            'Ошибка работы с ключами',
        secureStorageError:
            (details, code, message, data, stackTrace, timestamp) =>
                'Ошибка безопасного хранилища',
        closeError: (details, code, message, data, stackTrace, timestamp) =>
            'Ошибка закрытия хранилища',
      );
    }

    if (error is Exception) {
      final errorString = error.toString();

      if (errorString.contains('password')) {
        return 'Неверный мастер-пароль';
      }

      if (errorString.contains('file') || errorString.contains('path')) {
        return 'Ошибка доступа к файлу хранилища';
      }

      return 'Неизвестная ошибка: $errorString';
    }

    return error.toString();
  }

  /// Сброс ошибки
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сброс формы
  void resetForm() {
    state = const OpenStoreFormState();
  }

  /// Полная очистка всех данных
  void clearAllData() {
    // Очищаем состояние
    state = const OpenStoreFormState();

    // Логируем очистку данных
    logDebug(
      'Выполнена полная очистка данных формы открытия хранилища',
      tag: 'OpenStoreController',
    );
  }

  /// Безопасная очистка всех чувствительных данных
  void clearSensitiveData() {
    // Очищаем только чувствительные данные (пароль)
    state = state.copyWith(
      masterPassword: '',
      errorMessage: null,
      fieldErrors: {},
    );

    logDebug(
      'Выполнена очистка чувствительных данных формы открытия хранилища',
      tag: 'OpenStoreController',
    );
  }
}

/// Провайдер контроллера открытия хранилища
final openStoreControllerProvider =
    StateNotifierProvider<OpenStoreController, OpenStoreFormState>((ref) {
      return OpenStoreController(ref);
    });

/// Провайдер для получения состояния базы данных
final openStoreDatabaseStateProvider = Provider<DatabaseState>((ref) {
  return ref.watch(databaseStateProvider);
});

/// Провайдер для проверки готовности к открытию
final openStoreReadyProvider = Provider<bool>((ref) {
  final formState = ref.watch(openStoreControllerProvider);
  return formState.isValid && !formState.isLoading;
});

/// Провайдер для поиска файлов БД в папке по умолчанию
final databaseFilesProvider = FutureProvider<DatabaseFilesResult>((ref) async {
  final manager = ref.read(hoplixiStoreManagerProvider);
  return await manager.findDatabaseFiles();
});

/// Провайдер для получения самого недавнего файла БД
final mostRecentDatabaseFileProvider = FutureProvider<DatabaseFileInfo?>((
  ref,
) async {
  final manager = ref.read(hoplixiStoreManagerProvider);
  return await manager.getMostRecentDatabaseFile();
});
