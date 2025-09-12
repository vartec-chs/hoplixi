import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/dao/password_tags_dao.dart';

/// Состояние формы пароля - безопасная модель с автоочисткой
class PasswordFormState {
  // Контроллеры для полей ввода
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController passwordController;
  late TextEditingController urlController;
  late TextEditingController notesController;
  late TextEditingController loginController;
  late TextEditingController emailController;

  // Глобальный ключ для формы
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Состояние формы
  String? selectedCategoryId;
  List<String> selectedTagIds = [];
  bool isFavorite = false;
  bool isPasswordVisible = false;

  // ID редактируемого пароля (null для создания нового)
  final String? editingPasswordId;

  // Состояние загрузки
  bool isLoading = false;
  String? error;
  bool isFormValid = false;

  PasswordFormState({
    required this.editingPasswordId,
    this.selectedCategoryId,
    this.selectedTagIds = const [],
    this.isFavorite = false,
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.error,
    this.isFormValid = false,
  }) {
    _initializeControllers();
  }

  PasswordFormState copyWith({
    String? selectedCategoryId,
    List<String>? selectedTagIds,
    bool? isFavorite,
    bool? isPasswordVisible,
    bool? isLoading,
    String? error,
    bool? isFormValid,
  }) {
    // Создаем новое состояние, НО сохраняем существующие контроллеры
    final newState = PasswordFormState(
      editingPasswordId: editingPasswordId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      isFavorite: isFavorite ?? this.isFavorite,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFormValid: isFormValid ?? this.isFormValid,
    );

    // Заменяем новые контроллеры на существующие
    newState.nameController.dispose();
    newState.descriptionController.dispose();
    newState.passwordController.dispose();
    newState.urlController.dispose();
    newState.notesController.dispose();
    newState.loginController.dispose();
    newState.emailController.dispose();

    newState.nameController = nameController;
    newState.descriptionController = descriptionController;
    newState.passwordController = passwordController;
    newState.urlController = urlController;
    newState.notesController = notesController;
    newState.loginController = loginController;
    newState.emailController = emailController;

    return newState;
  }

  /// Инициализация контроллеров
  void _initializeControllers() {
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    passwordController = TextEditingController();
    urlController = TextEditingController();
    notesController = TextEditingController();
    loginController = TextEditingController();
    emailController = TextEditingController();
  }
}

/// Notifier для управления состоянием формы пароля в Riverpod v3
class PasswordFormNotifier extends Notifier<PasswordFormState> {
  // Family параметр - ID редактируемого пароля
  final String? passwordId;

  PasswordFormNotifier(this.passwordId);

  @override
  PasswordFormState build() {
    // Создаем начальное состояние
    final initialState = PasswordFormState(editingPasswordId: passwordId);

    // Добавляем слушатели для валидации
    _addListenersToControllers(initialState);

    // Настраиваем очистку ресурсов
    ref.onDispose(() {
      // _clearSensitiveData(initialState);
      _disposeControllers(initialState);
    });

    // Загружаем данные для редактирования асинхронно, если нужно
    if (passwordId != null) {
      // Отложим загрузку данных, чтобы не блокировать build()
      Future.microtask(() async {
        // Проверяем, что провайдер еще не disposed
        try {
          if (ref.mounted) {
            // Получаем зависимости синхронно
            final passwordsDao = ref.read(passwordsDaoProvider);
            final passwordTagsDao = ref.read(passwordTagsDaoProvider);
            await _loadPasswordForEditing(
              initialState,
              passwordsDao,
              passwordTagsDao,
            );
          }
        } catch (e) {
          // Провайдер мог быть disposed во время загрузки
          logError('Провайдер был disposed во время загрузки: $e');
        }
      });
    }

    return initialState;
  }

  /// Добавление слушателей к контроллерам для валидации в реальном времени
  void _addListenersToControllers(PasswordFormState currentState) {
    currentState.nameController.addListener(() => _validateForm());
    currentState.passwordController.addListener(() => _validateForm());
    currentState.loginController.addListener(() => _validateForm());
    currentState.emailController.addListener(() => _validateForm());
  }

  /// Повторное добавление слушателей (если они были потеряны)
  void _ensureListenersAreActive() {
    final currentState = state;
    // Удаляем старые слушатели (если есть)
    try {
      currentState.nameController.removeListener(_validateForm);
      currentState.passwordController.removeListener(_validateForm);
      currentState.loginController.removeListener(_validateForm);
      currentState.emailController.removeListener(_validateForm);
    } catch (e) {
      // Игнорируем ошибки если слушателей не было
    }

    // Добавляем новые слушатели
    currentState.nameController.addListener(() => _validateForm());
    currentState.passwordController.addListener(() => _validateForm());
    currentState.loginController.addListener(() => _validateForm());
    currentState.emailController.addListener(() => _validateForm());
  }

  /// Проверка валидности формы в реальном времени
  void _validateForm() {
    final currentState = state;
    final hasName = currentState.nameController.text.trim().isNotEmpty;
    final hasPassword = currentState.passwordController.text.trim().isNotEmpty;
    final hasLogin = currentState.loginController.text.trim().isNotEmpty;
    final hasEmail = currentState.emailController.text.trim().isNotEmpty;
    final hasLoginOrEmail = hasLogin || hasEmail;

    final wasValid = currentState.isFormValid;
    final newIsValid = hasName && hasPassword && hasLoginOrEmail;

    // Обновляем состояние только если валидность изменилась
    if (wasValid != newIsValid) {
      state = state.copyWith(isFormValid: newIsValid);
      _ensureListenersAreActive(); // Восстанавливаем слушатели после обновления
    }
  }

  /// Загрузка пароля для редактирования
  Future<void> _loadPasswordForEditing(
    PasswordFormState currentState,
    dynamic passwordsDao,
    PasswordTagsDao passwordTagsDao,
  ) async {
    if (passwordId == null) return;

    try {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: true, error: null);

      final password = await passwordsDao.getPasswordById(passwordId!);

      // Проверяем, что провайдер еще смонтирован после await
      if (!ref.mounted) return;

      if (password != null) {
        currentState.nameController.text = password.name;
        currentState.descriptionController.text = password.description ?? '';
        currentState.passwordController.text = password.password;
        currentState.urlController.text = password.url ?? '';
        currentState.notesController.text = password.notes ?? '';
        currentState.loginController.text = password.login ?? '';
        currentState.emailController.text = password.email ?? '';

        // Загрузить связанные теги
        await _loadAssociatedTags(passwordTagsDao);

        // Проверяем, что провайдер еще смонтирован после await
        if (!ref.mounted) return;

        // Обновить состояние с загруженными данными
        state = state.copyWith(
          selectedCategoryId: password.categoryId,
          isFavorite: password.isFavorite,
          isLoading: false,
        );

        // Восстанавливаем слушатели после обновления состояния
        _ensureListenersAreActive();

        // Проверить валидность формы после загрузки
        _validateForm();
      } else {
        if (ref.mounted) {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString(), isLoading: false);
        logError(
          'Ошибка загрузки пароля для редактирования: $error',
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Загрузка тегов, связанных с паролем
  Future<void> _loadAssociatedTags(PasswordTagsDao passwordTagsDao) async {
    if (passwordId == null) return;

    try {
      final tags = await passwordTagsDao.getTagsForPassword(passwordId!);
      state = state.copyWith(
        selectedTagIds: tags.map((tag) => tag.id).toList(),
      );
      _ensureListenersAreActive(); // Восстанавливаем слушатели
    } catch (error, stackTrace) {
      logError(
        'Ошибка загрузки связанных тегов: $error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Создание связей пароля с тегами (для нового пароля)
  Future<void> _createPasswordTags(
    String passwordId,
    PasswordTagsDao passwordTagsDao,
  ) async {
    if (state.selectedTagIds.isEmpty) return;

    try {
      for (final tagId in state.selectedTagIds) {
        await passwordTagsDao.addTagToPassword(passwordId, tagId);
      }
    } catch (error, stackTrace) {
      logError(
        'Ошибка создания связей с тегами: $error',
        stackTrace: stackTrace,
      );
      // Не блокируем сохранение пароля из-за ошибки тегов
    }
  }

  /// Обновление связей пароля с тегами (для существующего пароля)
  Future<void> _updatePasswordTags(
    String passwordId,
    PasswordTagsDao passwordTagsDao,
  ) async {
    try {
      // Заменяем все теги новыми
      await passwordTagsDao.replacePasswordTags(
        passwordId,
        state.selectedTagIds,
      );
    } catch (error, stackTrace) {
      logError(
        'Ошибка обновления связей с тегами: $error',
        stackTrace: stackTrace,
      );
      // Не блокируем сохранение пароля из-за ошибки тегов
      throw Exception('Пароль обновлен, но не удалось обновить теги: $error');
    }
  }

  /// Проверяет, является ли форма редактированием существующего пароля
  bool get isEditing => passwordId != null;

  /// Текст для кнопки сохранения
  String get saveButtonText => isEditing ? 'Обновить' : 'Создать';

  /// Заголовок экрана
  String get screenTitle =>
      isEditing ? 'Редактирование пароля' : 'Новый пароль';

  /// Обновление выбранной категории
  void updateSelectedCategory(List<String> categoryIds) {
    state = state.copyWith(
      selectedCategoryId: categoryIds.isNotEmpty ? categoryIds.first : null,
    );
    _ensureListenersAreActive(); // Восстанавливаем слушатели
  }

  /// Обновление выбранных тегов
  void updateSelectedTags(List<String> tagIds) {
    state = state.copyWith(selectedTagIds: List.from(tagIds));
    _ensureListenersAreActive(); // Восстанавливаем слушатели
  }

  /// Переключение избранного
  void toggleFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
    _ensureListenersAreActive(); // Восстанавливаем слушатели
  }

  /// Переключение видимости пароля
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
    _ensureListenersAreActive(); // Восстанавливаем слушатели
  }

  /// Валидация формы
  bool validateForm() {
    final formKey = state.formKey;
    final isValid = formKey.currentState?.validate() ?? false;

    // Дополнительная проверка: должен быть указан логин ИЛИ email
    if (isValid) {
      final hasLogin = state.loginController.text.trim().isNotEmpty;
      final hasEmail = state.emailController.text.trim().isNotEmpty;

      if (!hasLogin && !hasEmail) {
        ToastHelper.error(
          title: 'Ошибка валидации',
          description: 'Необходимо указать логин или email (или оба)',
        );
        return false;
      }
    }

    return isValid;
  }

  /// Сохранение пароля
  Future<bool> savePassword() async {
    if (!validateForm()) return false;

    // Получаем зависимости синхронно ПЕРЕД началом асинхронных операций
    final passwordsDao = ref.read(passwordsDaoProvider);
    final passwordTagsDao = ref.read(passwordTagsDaoProvider);

    try {
      // Проверяем, что провайдер еще смонтирован
      if (!ref.mounted) return false;

      state = state.copyWith(isLoading: true, error: null);

      if (isEditing) {
        // Обновление существующего пароля
        final updateDto = UpdatePasswordDto(
          id: passwordId!,
          name: state.nameController.text.trim(),
          description: state.descriptionController.text.trim().isEmpty
              ? null
              : state.descriptionController.text.trim(),
          password: state.passwordController.text,
          url: state.urlController.text.trim().isEmpty
              ? null
              : state.urlController.text.trim(),
          notes: state.notesController.text.trim().isEmpty
              ? null
              : state.notesController.text.trim(),
          login: state.loginController.text.trim().isEmpty
              ? null
              : state.loginController.text.trim(),
          email: state.emailController.text.trim().isEmpty
              ? null
              : state.emailController.text.trim(),
          categoryId: state.selectedCategoryId,
          isFavorite: state.isFavorite,
        );

        final success = await passwordsDao.updatePassword(updateDto);

        // Проверяем, что провайдер еще смонтирован после await
        if (!ref.mounted) return false;

        if (success) {
          // Обновить связи с тегами
          await _updatePasswordTags(passwordId!, passwordTagsDao);

          if (ref.mounted) {
            ToastHelper.success(
              title: 'Успешно',
              description: 'Пароль обновлен',
            );
          }
        } else {
          throw Exception('Не удалось обновить пароль');
        }
      } else {
        // Создание нового пароля
        final createDto = CreatePasswordDto(
          name: state.nameController.text.trim(),
          description: state.descriptionController.text.trim().isEmpty
              ? null
              : state.descriptionController.text.trim(),
          password: state.passwordController.text,
          url: state.urlController.text.trim().isEmpty
              ? null
              : state.urlController.text.trim(),
          notes: state.notesController.text.trim().isEmpty
              ? null
              : state.notesController.text.trim(),
          login: state.loginController.text.trim().isEmpty
              ? null
              : state.loginController.text.trim(),
          email: state.emailController.text.trim().isEmpty
              ? null
              : state.emailController.text.trim(),
          categoryId: state.selectedCategoryId,
          isFavorite: state.isFavorite,
        );

        final newPasswordId = await passwordsDao.createPassword(createDto);

        // Проверяем, что провайдер еще смонтирован после await
        if (!ref.mounted) return false;

        // Создать связи с тегами
        await _createPasswordTags(newPasswordId, passwordTagsDao);

        if (ref.mounted) {
          ToastHelper.success(title: 'Успешно', description: 'Пароль создан');
        }
      }

      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (error, _) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString(), isLoading: false);

        logError('Ошибка сохранения пароля: $error');

        ToastHelper.error(
          title: 'Ошибка',
          description: 'Не удалось сохранить пароль: ${error.toString()}',
        );
      }

      return false;
    }
  }

  /// Безопасная очистка всех чувствительных данных
  void _clearSensitiveData(PasswordFormState currentState) {
    // Очистка паролей из памяти
    _clearTextControllerSecurely(currentState.passwordController);
    _clearTextControllerSecurely(currentState.nameController);
    _clearTextControllerSecurely(currentState.descriptionController);
    _clearTextControllerSecurely(currentState.urlController);
    _clearTextControllerSecurely(currentState.notesController);
    _clearTextControllerSecurely(currentState.loginController);
    _clearTextControllerSecurely(currentState.emailController);

    logDebug('Чувствительные данные формы пароля очищены');
  }

  /// Безопасная очистка TextController
  void _clearTextControllerSecurely(TextEditingController controller) {
    controller.clear();
  }

  /// Освобождение контроллеров
  void _disposeControllers(PasswordFormState currentState) {
    // Удаляем слушатели перед очисткой
    currentState.nameController.removeListener(_validateForm);
    currentState.passwordController.removeListener(_validateForm);
    currentState.loginController.removeListener(_validateForm);
    currentState.emailController.removeListener(_validateForm);

    currentState.nameController.dispose();
    currentState.descriptionController.dispose();
    currentState.passwordController.dispose();
    currentState.urlController.dispose();
    currentState.notesController.dispose();
    currentState.loginController.dispose();
    currentState.emailController.dispose();
  }
}

/// Провайдер для состояния формы пароля с новым API Riverpod v3
final passwordFormStateProvider = NotifierProvider.autoDispose
    .family<PasswordFormNotifier, PasswordFormState, String?>(
      PasswordFormNotifier.new,
    );
