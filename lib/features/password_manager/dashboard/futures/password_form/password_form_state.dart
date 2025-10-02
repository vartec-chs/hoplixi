import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/dao_providers.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/dao/password_tags_dao.dart';

/// Состояние формы пароля - чистая логическая модель
class PasswordFormState {
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
  });

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

    // Настраиваем очистку ресурсов
    ref.onDispose(() {
      // Ресурсы теперь управляются в UI слое
    });

    return initialState;
  }

  /// Загрузка данных пароля для редактирования
  /// Вызывается из UI слоя с переданными контроллерами
  Future<void> loadPasswordForEditing(
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController passwordController,
    TextEditingController urlController,
    TextEditingController notesController,
    TextEditingController loginController,
    TextEditingController emailController,
  ) async {
    if (passwordId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final passwordsDao = ref.read(passwordsDaoProvider);
      final passwordTagsDao = ref.read(passwordTagsDaoProvider);

      final password = await passwordsDao.getPasswordById(passwordId!);

      if (password != null) {
        // Заполняем контроллеры данными
        nameController.text = password.name;
        descriptionController.text = password.description ?? '';
        passwordController.text = password.password;
        urlController.text = password.url ?? '';
        notesController.text = password.notes ?? '';
        loginController.text = password.login ?? '';
        emailController.text = password.email ?? '';

        // Загружаем связанные теги
        final tags = await passwordTagsDao.getTagsForPassword(passwordId!);

        // Обновляем состояние с загруженными данными
        state = state.copyWith(
          selectedCategoryId: password.categoryId,
          selectedTagIds: tags.map((tag) => tag.id).toList(),
          isFavorite: password.isFavorite,
          isLoading: false,
        );
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

  /// Проверка валидности формы
  /// Теперь принимает данные от UI слоя
  bool checkFormValidity({
    required String name,
    required String password,
    required String login,
    required String email,
  }) {
    final hasName = name.trim().isNotEmpty;
    final hasPassword = password.trim().isNotEmpty;
    final hasLogin = login.trim().isNotEmpty;
    final hasEmail = email.trim().isNotEmpty;
    final hasLoginOrEmail = hasLogin || hasEmail;

    final newIsValid = hasName && hasPassword && hasLoginOrEmail;

    if (state.isFormValid != newIsValid) {
      state = state.copyWith(isFormValid: newIsValid);
    }

    return newIsValid;
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
  /// Принимает данные от контроллеров из UI
  bool validateForm({
    required GlobalKey<FormState> formKey,
    required String login,
    required String email,
  }) {
    final isValid = formKey.currentState?.validate() ?? false;

    // Дополнительная проверка: должен быть указан логин ИЛИ email
    if (isValid) {
      final hasLogin = login.trim().isNotEmpty;
      final hasEmail = email.trim().isNotEmpty;

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
  /// Принимает данные от контроллеров из UI
  Future<bool> savePassword({
    required GlobalKey<FormState> formKey,
    required String name,
    required String description,
    required String password,
    required String url,
    required String notes,
    required String login,
    required String email,
  }) async {
    if (!validateForm(formKey: formKey, login: login, email: email)) {
      return false;
    }

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
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
          password: password,
          url: url.trim().isEmpty ? null : url.trim(),
          notes: notes.trim().isEmpty ? null : notes.trim(),
          login: login.trim().isEmpty ? null : login.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
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
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
          password: password,
          url: url.trim().isEmpty ? null : url.trim(),
          notes: notes.trim().isEmpty ? null : notes.trim(),
          login: login.trim().isEmpty ? null : login.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
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
}

/// Провайдер для состояния формы пароля с новым API Riverpod v3
final passwordFormStateProvider = NotifierProvider.autoDispose
    .family<PasswordFormNotifier, PasswordFormState, String?>(
      PasswordFormNotifier.new,
    );
