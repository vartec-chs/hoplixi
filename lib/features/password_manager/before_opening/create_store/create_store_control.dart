import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/errors/error.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:file_picker/file_picker.dart';

/// Состояние формы создания хранилища
class CreateStoreFormState {
  final String storeName;
  final String storeDescription;
  final String masterPassword;
  final String confirmPassword;
  final bool isDefaultPath;
  final String customPath;
  final String finalPath;
  final bool saveMasterPassword;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, String?> fieldErrors;

  const CreateStoreFormState({
    this.storeName = '',
    this.storeDescription = '',
    this.masterPassword = '',
    this.confirmPassword = '',
    this.isDefaultPath = true,
    this.customPath = '',
    this.finalPath = '',
    this.saveMasterPassword = false,
    this.isLoading = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  CreateStoreFormState copyWith({
    String? storeName,
    String? storeDescription,
    String? masterPassword,
    String? confirmPassword,
    bool? isDefaultPath,
    String? customPath,
    String? finalPath,
    bool? saveMasterPassword,
    bool? isLoading,
    String? errorMessage,
    Map<String, String?>? fieldErrors,
  }) {
    return CreateStoreFormState(
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      masterPassword: masterPassword ?? this.masterPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isDefaultPath: isDefaultPath ?? this.isDefaultPath,
      customPath: customPath ?? this.customPath,
      finalPath: finalPath ?? this.finalPath,
      saveMasterPassword: saveMasterPassword ?? this.saveMasterPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  bool get isValid {
    return storeName.isNotEmpty &&
        masterPassword.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        masterPassword == confirmPassword &&
        finalPath.isNotEmpty &&
        fieldErrors.isEmpty;
  }
}

/// Контроллер для управления состоянием формы создания хранилища
class CreateStoreController extends StateNotifier<CreateStoreFormState> {
  final Ref _ref;

  CreateStoreController(this._ref) : super(const CreateStoreFormState()) {
    _initializeDefaultPath();
  }

  /// Инициализация пути по умолчанию
  Future<void> _initializeDefaultPath() async {
    try {
      final defaultPath = await _getDefaultStoragePath();
      state = state.copyWith(finalPath: defaultPath);
    } catch (e) {
      logError(
        'Ошибка инициализации пути по умолчанию',
        error: e,
        tag: 'CreateStoreController',
      );
    }
  }

  /// Получение пути для хранения по умолчанию
  Future<String> _getDefaultStoragePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final basePath = p.join(
      appDir.path,
      MainConstants.appFolderName,
      'storages',
    );

    // Создаем директорию если её нет
    final directory = Directory(basePath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = state.storeName.isNotEmpty
        ? '${state.storeName}.${MainConstants.dbExtension}'
        : 'new_store.${MainConstants.dbExtension}';

    return p.join(basePath, fileName);
  }

  /// Обновление названия хранилища
  void updateStoreName(String name) {
    // Валидация названия
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (name.isEmpty) {
      errors['storeName'] = 'Название хранилища обязательно';
    } else if (name.length < 3) {
      errors['storeName'] = 'Название должно содержать минимум 3 символа';
    } else if (name.length > 50) {
      errors['storeName'] = 'Название не должно превышать 50 символов';
    } else if (!RegExp(r'^[a-zA-Zа-яА-Я0-9\s_-]+$').hasMatch(name)) {
      errors['storeName'] = 'Название содержит недопустимые символы';
    } else {
      errors.remove('storeName');
    }

    state = state.copyWith(storeName: name, fieldErrors: errors);

    // Обновляем путь если используется путь по умолчанию
    if (state.isDefaultPath) {
      _updateDefaultPath();
    }
  }

  /// Обновление описания хранилища
  void updateStoreDescription(String description) {
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (description.length > 200) {
      errors['storeDescription'] = 'Описание не должно превышать 200 символов';
    } else {
      errors.remove('storeDescription');
    }

    state = state.copyWith(storeDescription: description, fieldErrors: errors);
  }

  /// Обновление мастер-пароля
  void updateMasterPassword(String password) {
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (password.isEmpty) {
      errors['masterPassword'] = 'Мастер-пароль обязателен';
    }
    // } else if (password.length < 1) {
    //   errors['masterPassword'] = 'Пароль должен содержать минимум 1 символ';
    // } else if (password.length > 256) {
    //   errors['masterPassword'] = 'Пароль не должен превышать 256 символов';
    // } else if (!_isPasswordStrong(password)) {
    //   errors['masterPassword'] =
    //       'Пароль должен содержать буквы, цифры и спецсимволы';
    // } else {
    else {
      errors.remove('masterPassword');
    }

    // Проверяем совпадение паролей если подтверждение уже введено
    if (state.confirmPassword.isNotEmpty) {
      if (password != state.confirmPassword) {
        errors['confirmPassword'] = 'Пароли не совпадают';
      } else {
        errors.remove('confirmPassword');
      }
    }

    state = state.copyWith(masterPassword: password, fieldErrors: errors);
  }

  /// Обновление подтверждения пароля
  void updateConfirmPassword(String password) {
    final errors = Map<String, String?>.from(state.fieldErrors);

    if (password.isEmpty) {
      errors['confirmPassword'] = 'Подтверждение пароля обязательно';
    } else if (password != state.masterPassword) {
      errors['confirmPassword'] = 'Пароли не совпадают';
    } else {
      errors.remove('confirmPassword');
    }

    state = state.copyWith(confirmPassword: password, fieldErrors: errors);
  }

  /// Переключение между путем по умолчанию и пользовательским
  void togglePathType(bool isDefault) {
    state = state.copyWith(isDefaultPath: isDefault);

    if (isDefault) {
      _updateDefaultPath();
    }
  }

  /// Переключение сохранения мастер-пароля
  void toggleSaveMasterPassword(bool saveMasterPassword) {
    state = state.copyWith(saveMasterPassword: saveMasterPassword);
  }

  /// Выбор пользовательского пути
  Future<void> selectCustomPath() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Выберите место для сохранения хранилища',
        fileName:
            '${state.storeName.isNotEmpty ? state.storeName : 'new_store'}.${MainConstants.dbExtension}',
        allowedExtensions: [MainConstants.dbExtension],
        type: FileType.custom,
      );

      if (result != null) {
        state = state.copyWith(customPath: result, finalPath: result);
      }
    } catch (e) {
      logError(
        'Ошибка выбора пользовательского пути',
        error: e,
        tag: 'CreateStoreController',
      );

      state = state.copyWith(
        errorMessage: 'Не удалось выбрать путь для сохранения',
      );
    }
  }

  /// Обновление пути по умолчанию
  Future<void> _updateDefaultPath() async {
    try {
      final defaultPath = await _getDefaultStoragePath();
      state = state.copyWith(finalPath: defaultPath);
    } catch (e) {
      logError(
        'Ошибка обновления пути по умолчанию',
        error: e,
        tag: 'CreateStoreController',
      );
    }
  }

  /// Проверка надежности пароля
  // bool _isPasswordStrong(String password) {
  //   // Проверяем наличие букв, цифр и спецсимволов
  //   final hasLetter = RegExp(r'[a-zA-Zа-яА-Я]').hasMatch(password);
  //   final hasDigit = RegExp(r'[0-9]').hasMatch(password);
  //   final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  //   return hasLetter && hasDigit && hasSpecial;
  // }

  /// Создание хранилища
  Future<void> createStore() async {
    if (!state.isValid) {
      logWarning(
        'Попытка создания хранилища с невалидными данными',
        tag: 'CreateStoreController',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Создаем DTO для создания базы данных
      final dto = CreateDatabaseDto(
        name: state.storeName,
        description: state.storeDescription.isNotEmpty
            ? state.storeDescription
            : null,
        masterPassword: state.masterPassword,
        customPath: state.isDefaultPath ? null : p.dirname(state.finalPath),
        saveMasterPassword: state.saveMasterPassword,
      );

      // Вызываем создание через провайдер базы данных
      final databaseNotifier = _ref.read(hoplixiStoreProvider.notifier);
      await databaseNotifier.createDatabase(dto);

      logInfo(
        'Хранилище успешно создано',
        tag: 'CreateStoreController',
        data: {'name': state.storeName, 'path': state.finalPath},
      );

      // Сбрасываем состояние загрузки
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания хранилища',
        error: e,
        stackTrace: stackTrace,
        tag: 'CreateStoreController',
        data: {'name': state.storeName, 'path': state.finalPath},
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e, stackTrace),
      );
    }
  }

  /// Получение понятного сообщения об ошибке
  String _getErrorMessage(Object error, [StackTrace? stackTrace]) {
    final errorString = error.toString();

    if (error is DatabaseError) {
      return error.displayMessage;
    }

    if (error is Exception) {
      return OtherError(
        message: error.toString(),
        stackTrace: stackTrace,
      ).toString();
    }

    return errorString;
  }

  /// Сброс ошибки
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сброс формы
  void resetForm() {
    state = const CreateStoreFormState();
    _initializeDefaultPath();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Полная очистка всех данных
  void clearAllData() {
    // Очищаем состояние
    state = const CreateStoreFormState();

    // Логируем очистку данных
    logDebug(
      'Выполнена полная очистка данных формы создания хранилища',
      tag: 'CreateStoreController',
    );
  }

  /// Безопасная очистка всех чувствительных данных
  void clearSensitiveData() {
    // Очищаем только чувствительные данные (пароли)
    // Сохраняем настройку saveMasterPassword для удобства пользователя
    state = state.copyWith(
      masterPassword: '',
      confirmPassword: '',
      errorMessage: null,
      fieldErrors: {},
    );

    logDebug(
      'Выполнена очистка чувствительных данных формы создания хранилища',
      tag: 'CreateStoreController',
    );
  }
}

/// Провайдер контроллера создания хранилища
final createStoreControllerProvider =
    StateNotifierProvider<CreateStoreController, CreateStoreFormState>((ref) {
      return CreateStoreController(ref);
    });

/// Провайдер для проверки готовности к созданию
final createStoreReadyProvider = Provider<bool>((ref) {
  final formState = ref.watch(createStoreControllerProvider);
  return formState.isValid && !formState.isLoading;
});
