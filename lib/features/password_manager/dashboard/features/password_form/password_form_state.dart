import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/core/utils/toastification.dart';

/// Состояние формы пароля - безопасная модель с автоочисткой
class PasswordFormState {
  // Контроллеры для полей ввода
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController passwordController;
  late final TextEditingController urlController;
  late final TextEditingController notesController;
  late final TextEditingController loginController;
  late final TextEditingController emailController;

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
    return PasswordFormState(
      editingPasswordId: editingPasswordId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      isFavorite: isFavorite ?? this.isFavorite,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFormValid: isFormValid ?? this.isFormValid,
    );
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
      _clearSensitiveData(initialState);
      _disposeControllers(initialState);
    });

    // Загружаем данные для редактирования, если нужно
    if (passwordId != null) {
      _loadPasswordForEditing(initialState);
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
    }
  }

  /// Загрузка пароля для редактирования
  Future<void> _loadPasswordForEditing(PasswordFormState currentState) async {
    if (passwordId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final passwordsDao = ref.read(passwordsDaoProvider);
      final password = await passwordsDao.getPasswordById(passwordId!);

      if (password != null) {
        currentState.nameController.text = password.name;
        currentState.descriptionController.text = password.description ?? '';
        currentState.passwordController.text = password.password;
        currentState.urlController.text = password.url ?? '';
        currentState.notesController.text = password.notes ?? '';
        currentState.loginController.text = password.login ?? '';
        currentState.emailController.text = password.email ?? '';

        // Загрузить связанные теги
        await _loadAssociatedTags();

        // Обновить состояние с загруженными данными
        state = state.copyWith(
          selectedCategoryId: password.categoryId,
          isFavorite: password.isFavorite,
          isLoading: false,
        );

        // Проверить валидность формы после загрузки
        _validateForm();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error, stackTrace) {
      state = state.copyWith(error: error.toString(), isLoading: false);
      logError(
        'Ошибка загрузки пароля для редактирования: $error',
        stackTrace: stackTrace,
      );
    }
  }

  /// Загрузка тегов, связанных с паролем
  Future<void> _loadAssociatedTags() async {
    if (passwordId == null) return;

    try {
      final passwordTagsDao = ref.read(passwordTagsDaoProvider);
      final tags = await passwordTagsDao.getTagsForPassword(passwordId!);
      state = state.copyWith(
        selectedTagIds: tags.map((tag) => tag.id).toList(),
      );
    } catch (error, stackTrace) {
      logError(
        'Ошибка загрузки связанных тегов: $error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Создание связей пароля с тегами (для нового пароля)
  Future<void> _createPasswordTags(String passwordId) async {
    if (state.selectedTagIds.isEmpty) return;

    try {
      final passwordTagsDao = ref.read(passwordTagsDaoProvider);

      for (final tagId in state.selectedTagIds) {
        await passwordTagsDao.addTagToPassword(passwordId, tagId);
      }
    } catch (error, stackTrace) {
      logError(
        'Ошибка создания связей с тегами: $error',
        stackTrace: stackTrace,
      );
      // Не блокируем сохранение пароля из-за ошибки тегов
      throw Exception('Пароль создан, но не удалось связать с тегами: $error');
    }
  }

  /// Обновление связей пароля с тегами (для существующего пароля)
  Future<void> _updatePasswordTags(String passwordId) async {
    try {
      final passwordTagsDao = ref.read(passwordTagsDaoProvider);

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
  }

  /// Обновление выбранных тегов
  void updateSelectedTags(List<String> tagIds) {
    state = state.copyWith(selectedTagIds: List.from(tagIds));
  }

  /// Переключение избранного
  void toggleFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
  }

  /// Переключение видимости пароля
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
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

    try {
      state = state.copyWith(isLoading: true, error: null);

      final passwordsDao = ref.read(passwordsDaoProvider);

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

        if (success) {
          // Обновить связи с тегами
          await _updatePasswordTags(passwordId!);
          ToastHelper.success(title: 'Успешно', description: 'Пароль обновлен');
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

        // Создать связи с тегами
        await _createPasswordTags(newPasswordId);
        ToastHelper.success(title: 'Успешно', description: 'Пароль создан');
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (error, _) {
      state = state.copyWith(error: error.toString(), isLoading: false);

      print('Ошибка сохранения пароля: $error');

      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось сохранить пароль: ${error.toString()}',
      );

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

    print('Чувствительные данные формы пароля очищены');
  }

  /// Безопасная очистка TextController
  void _clearTextControllerSecurely(TextEditingController controller) {
    try {
      // Заполняем случайными символами для затирания данных из памяти
      final originalLength = controller.text.length;
      if (originalLength > 0) {
        final randomData = List.generate(
          originalLength,
          (index) => String.fromCharCode(
            48 + (DateTime.now().millisecondsSinceEpoch + index) % 75,
          ),
        );
        controller.text = randomData.join();
        controller.clear();
      }
    } catch (e) {
      // Если не удается безопасно очистить, просто очищаем обычным способом
      controller.clear();
    }
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
