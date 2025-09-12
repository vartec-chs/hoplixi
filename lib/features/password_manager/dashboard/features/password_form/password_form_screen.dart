import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_picker/tags_picker.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'password_form_state.dart';
import 'password_generator.dart';

/// Экран добавления/редактирования пароля
class PasswordFormScreen extends ConsumerStatefulWidget {
  /// ID пароля для редактирования (null для создания нового)
  final String? passwordId;

  const PasswordFormScreen({super.key, this.passwordId});

  @override
  ConsumerState<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen>
    with WidgetsBindingObserver {
  bool _showPasswordGenerator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Очистка ресурсов теперь управляется через Notifier автоматически
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Очистка данных при сворачивании/закрытии приложения управляется через Notifier
  }

  /// Валидатор для обязательных полей
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Это поле обязательно для заполнения';
    }
    return null;
  }

  /// Валидатор для URL
  String? _urlValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL не обязательный
    }

    final urlPattern = RegExp(r'^https?:\/\/.+\..+');
    if (!urlPattern.hasMatch(value.trim())) {
      return 'Введите корректный URL (например: https://example.com)';
    }
    return null;
  }

  /// Валидатор для email
  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email не обязательный если есть логин
    }

    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    return null;
  }

  /// Сохранение пароля
  Future<void> _savePassword() async {
    final notifier = ref.read(
      passwordFormStateProvider(widget.passwordId).notifier,
    );
    final success = await notifier.savePassword();
    if (success && mounted) {
      context.pop(true); // Возвращаем true для обновления списка
    }
  }

  /// Отмена и возврат
  void _cancel() {
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(passwordFormStateProvider(widget.passwordId));
    final notifier = ref.read(
      passwordFormStateProvider(widget.passwordId).notifier,
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(notifier.screenTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
          actions: [
            // Кнопка избранного
            IconButton(
              icon: Icon(
                formState.isFavorite ? Icons.star : Icons.star_border,
                color: formState.isFavorite ? Colors.amber : null,
              ),
              onPressed: () {
                notifier.toggleFavorite();
              },
            ),
          ],
        ),
        body: Form(
          key: formState.formKey,
          child: Column(
            children: [
              // Основная скроллируемая область с полями
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Название
                      PrimaryTextFormField(
                        controller: formState.nameController,
                        label: 'Название',
                        hintText: 'Введите название пароля',
                        validator: _requiredValidator,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Описание
                      PrimaryTextFormField(
                        controller: formState.descriptionController,
                        label: 'Описание',
                        hintText: 'Дополнительное описание (необязательно)',
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // URL
                      PrimaryTextFormField(
                        controller: formState.urlController,
                        label: 'URL сайта',
                        hintText: 'https://example.com',
                        validator: _urlValidator,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Логин
                      PrimaryTextFormField(
                        controller: formState.loginController,
                        label: 'Логин',
                        hintText: 'Имя пользователя',
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      PrimaryTextFormField(
                        controller: formState.emailController,
                        label: 'Email',
                        hintText: 'user@example.com',
                        validator: _emailValidator,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Пароль
                      PrimaryTextFormField(
                        controller: formState.passwordController,
                        label: 'Пароль',
                        hintText: 'Введите пароль',
                        validator: _requiredValidator,
                        obscureText: !formState.isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Кнопка генератора паролей
                            IconButton(
                              icon: const Icon(Icons.auto_awesome),
                              tooltip: 'Генератор паролей',
                              onPressed: () {
                                setState(() {
                                  _showPasswordGenerator =
                                      !_showPasswordGenerator;
                                });
                              },
                            ),
                            // Кнопка видимости пароля
                            IconButton(
                              icon: Icon(
                                formState.isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              tooltip: formState.isPasswordVisible
                                  ? 'Скрыть пароль'
                                  : 'Показать пароль',
                              onPressed: () {
                                notifier.togglePasswordVisibility();
                              },
                            ),
                          ],
                        ),
                      ),

                      // Генератор паролей (показывается при нажатии на кнопку)
                      if (_showPasswordGenerator) ...[
                        const SizedBox(height: 16),
                        PasswordGenerator(
                          onPasswordGenerated: (password) {
                            formState.passwordController.text = password;
                            setState(() {
                              _showPasswordGenerator = false;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Заметки
                      PrimaryTextFormField(
                        controller: formState.notesController,
                        label: 'Заметки',
                        hintText: 'Дополнительные заметки (необязательно)',
                        textInputAction: TextInputAction.done,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Выбор категории
                      Text(
                        'Категория',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CategoriesPicker(
                        categoryType: CategoryType.password,
                        maxSelection: 1,
                        selectedCategoryIds:
                            formState.selectedCategoryId != null
                            ? [formState.selectedCategoryId!]
                            : [],
                        onSelect: notifier.updateSelectedCategory,
                        labelText: 'Категория пароля',
                        hintText: 'Выберите категорию',
                      ),

                      const SizedBox(height: 24),

                      // Выбор тегов
                      Text(
                        'Теги',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TagsPicker(
                        tagType: TagType.password,
                        maxSelection: 5,
                        selectedTagIds: formState.selectedTagIds,
                        onSelect: notifier.updateSelectedTags,
                        labelText: 'Теги пароля',
                        hintText: 'Выберите теги',
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Нижняя панель с кнопкой сохранения
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Индикатор требований для валидации
                    if (!formState.isFormValid && !formState.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Заполните обязательные поля: название, пароль и логин или email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SmoothButton(
                      label: notifier.saveButtonText,
                      onPressed: formState.isLoading || !formState.isFormValid
                          ? null
                          : _savePassword,
                      loading: formState.isLoading,
                      type: SmoothButtonType.filled,
                      size: SmoothButtonSize.large,
                      isFullWidth: true,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
