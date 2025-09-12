import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/core/utils/toastification.dart';

/// Состояние формы пароля - безопасная модель с автоочисткой
class PasswordFormState extends ChangeNotifier {
  final Ref _ref;

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
  String? _selectedCategoryId;
  List<String> _selectedTagIds = [];
  bool _isFavorite = false;
  bool _isPasswordVisible = false;

  // ID редактируемого пароля (null для создания нового)
  final String? _editingPasswordId;

  // Состояние загрузки
  bool _isLoading = false;
  String? _error;

  // Геттеры для состояния
  bool get isLoading => _isLoading;
  String? get error => _error;

  PasswordFormState(this._ref, [this._editingPasswordId]) {
    _initializeControllers();
    if (_editingPasswordId != null) {
      _loadPasswordForEditing();
    }
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

  /// Загрузка пароля для редактирования
  Future<void> _loadPasswordForEditing() async {
    if (_editingPasswordId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final passwordsDao = _ref.read(passwordsDaoProvider);
      final password = await passwordsDao.getPasswordById(_editingPasswordId);

      if (password != null) {
        nameController.text = password.name;
        descriptionController.text = password.description ?? '';
        passwordController.text = password.password;
        urlController.text = password.url ?? '';
        notesController.text = password.notes ?? '';
        loginController.text = password.login ?? '';
        emailController.text = password.email ?? '';
        _selectedCategoryId = password.categoryId;
        _isFavorite = password.isFavorite;

        // Загрузить связанные теги
        await _loadAssociatedTags();
      }

      _isLoading = false;
      notifyListeners();
    } catch (error, stackTrace) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      logError(
        'Ошибка загрузки пароля для редактирования: $error',
        stackTrace: stackTrace,
      );
    }
  }

  /// Загрузка тегов, связанных с паролем
  Future<void> _loadAssociatedTags() async {
    if (_editingPasswordId == null) return;

    try {
      final passwordTagsDao = _ref.read(passwordTagsDaoProvider);
      final tags = await passwordTagsDao.getTagsForPassword(_editingPasswordId);
      _selectedTagIds = tags.map((tag) => tag.id).toList();
      notifyListeners(); // Обновляем UI после загрузки тегов
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
    if (_selectedTagIds.isEmpty) return;

    try {
      final passwordTagsDao = _ref.read(passwordTagsDaoProvider);

      for (final tagId in _selectedTagIds) {
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
      final passwordTagsDao = _ref.read(passwordTagsDaoProvider);

      // Заменяем все теги новыми
      await passwordTagsDao.replacePasswordTags(passwordId, _selectedTagIds);
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
  bool get isEditing => _editingPasswordId != null;

  /// Текст для кнопки сохранения
  String get saveButtonText => isEditing ? 'Обновить' : 'Создать';

  /// Заголовок экрана
  String get screenTitle =>
      isEditing ? 'Редактирование пароля' : 'Новый пароль';

  // Геттеры для состояния
  String? get selectedCategoryId => _selectedCategoryId;
  List<String> get selectedTagIds => List.unmodifiable(_selectedTagIds);
  bool get isFavorite => _isFavorite;
  bool get isPasswordVisible => _isPasswordVisible;

  /// Обновление выбранной категории
  void updateSelectedCategory(List<String> categoryIds) {
    _selectedCategoryId = categoryIds.isNotEmpty ? categoryIds.first : null;
    notifyListeners();
  }

  /// Обновление выбранных тегов
  void updateSelectedTags(List<String> tagIds) {
    _selectedTagIds = List.from(tagIds);
    notifyListeners();
  }

  /// Переключение избранного
  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
  }

  /// Переключение видимости пароля
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  /// Валидация формы
  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;

    // Дополнительная проверка: должен быть указан логин ИЛИ email
    if (isValid) {
      final hasLogin = loginController.text.trim().isNotEmpty;
      final hasEmail = emailController.text.trim().isNotEmpty;

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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final passwordsDao = _ref.read(passwordsDaoProvider);

      if (isEditing) {
        // Обновление существующего пароля
        final updateDto = UpdatePasswordDto(
          id: _editingPasswordId!,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          password: passwordController.text,
          url: urlController.text.trim().isEmpty
              ? null
              : urlController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          login: loginController.text.trim().isEmpty
              ? null
              : loginController.text.trim(),
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          categoryId: _selectedCategoryId,
          isFavorite: _isFavorite,
        );

        final success = await passwordsDao.updatePassword(updateDto);

        if (success) {
          // Обновить связи с тегами
          await _updatePasswordTags(_editingPasswordId);
          ToastHelper.success(title: 'Успешно', description: 'Пароль обновлен');
        } else {
          throw Exception('Не удалось обновить пароль');
        }
      } else {
        // Создание нового пароля
        final createDto = CreatePasswordDto(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          password: passwordController.text,
          url: urlController.text.trim().isEmpty
              ? null
              : urlController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          login: loginController.text.trim().isEmpty
              ? null
              : loginController.text.trim(),
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          categoryId: _selectedCategoryId,
          isFavorite: _isFavorite,
        );

        final passwordId = await passwordsDao.createPassword(createDto);

        // Создать связи с тегами
        await _createPasswordTags(passwordId);
        ToastHelper.success(title: 'Успешно', description: 'Пароль создан');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error, _) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();

      print('Ошибка сохранения пароля: $error');

      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось сохранить пароль: ${error.toString()}',
      );

      return false;
    }
  }

  /// Безопасная очистка всех чувствительных данных
  void clearSensitiveData() {
    // Очистка паролей из памяти
    _clearTextControllerSecurely(passwordController);
    _clearTextControllerSecurely(nameController);
    _clearTextControllerSecurely(descriptionController);
    _clearTextControllerSecurely(urlController);
    _clearTextControllerSecurely(notesController);
    _clearTextControllerSecurely(loginController);
    _clearTextControllerSecurely(emailController);

    // Очистка состояния
    _selectedCategoryId = null;
    _selectedTagIds.clear();
    _isFavorite = false;
    _isPasswordVisible = false;

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

  @override
  void dispose() {
    clearSensitiveData();

    nameController.dispose();
    descriptionController.dispose();
    passwordController.dispose();
    urlController.dispose();
    notesController.dispose();
    loginController.dispose();
    emailController.dispose();

    super.dispose();
  }
}

/// Провайдер для состояния формы пароля
final passwordFormStateProvider = Provider.autoDispose
    .family<PasswordFormState, String?>((ref, passwordId) {
      final state = PasswordFormState(ref, passwordId);
      ref.onDispose(() {
        state.dispose();
      });
      return state;
    });
