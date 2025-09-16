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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _showPasswordGenerator = false;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Контроллеры для полей ввода
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _passwordController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;
  late final TextEditingController _loginController;
  late final TextEditingController _emailController;

  // Глобальный ключ для формы
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Инициализация анимаций
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Инициализация контроллеров
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _passwordController = TextEditingController();
    _urlController = TextEditingController();
    _notesController = TextEditingController();
    _loginController = TextEditingController();
    _emailController = TextEditingController();

    // Добавляем слушатели для валидации
    _nameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _loginController.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // Загрузка данных для редактирования после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.passwordId != null) {
        _loadPasswordForEditing();
      }
      // Запускаем анимации появления
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Остановка и освобождение анимаций
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    // Удаляем слушатели
    _nameController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _loginController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);

    // Безопасная очистка контроллеров
    _clearControllerSecurely(_nameController);
    _clearControllerSecurely(_descriptionController);
    _clearControllerSecurely(_passwordController);
    _clearControllerSecurely(_urlController);
    _clearControllerSecurely(_notesController);
    _clearControllerSecurely(_loginController);
    _clearControllerSecurely(_emailController);

    // Освобождение ресурсов
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _loginController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  /// Безопасная очистка контроллера
  void _clearControllerSecurely(TextEditingController controller) {
    controller.clear();
  }

  /// Загрузка данных для редактирования
  Future<void> _loadPasswordForEditing() async {
    final notifier = ref.read(
      passwordFormStateProvider(widget.passwordId).notifier,
    );

    await notifier.loadPasswordForEditing(
      _nameController,
      _descriptionController,
      _passwordController,
      _urlController,
      _notesController,
      _loginController,
      _emailController,
    );
  }

  /// Валидация формы в реальном времени
  void _validateForm() {
    final notifier = ref.read(
      passwordFormStateProvider(widget.passwordId).notifier,
    );

    notifier.checkFormValidity(
      name: _nameController.text,
      password: _passwordController.text,
      login: _loginController.text,
      email: _emailController.text,
    );
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
    final success = await notifier.savePassword(
      formKey: _formKey,
      name: _nameController.text,
      description: _descriptionController.text,
      password: _passwordController.text,
      url: _urlController.text,
      notes: _notesController.text,
      login: _loginController.text,
      email: _emailController.text,
    );
    if (success && mounted) {
      context.pop(true); // Возвращаем true для обновления списка
    }
  }

  /// Отмена и возврат
  void _cancel() {
    context.pop(false);
  }

  /// Создает красивую карточку для секции формы с анимацией
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
    int delay = 0,
  }) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + delay),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок секции с анимацией
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + delay),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Содержимое секции с задержкой анимации
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 500 + delay),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(children: children),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            // backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              notifier.screenTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _cancel,
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              // Кнопка избранного
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: formState.isFavorite
                      ? Colors.amber.withOpacity(0.2)
                      : theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    formState.isFavorite ? Icons.star : Icons.star_border,
                    color: formState.isFavorite
                        ? Colors.amber
                        : theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () {
                    notifier.toggleFavorite();
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Основная скроллируемая область с полями
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    8,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Карточка основной информации
                      _buildSectionCard(
                        context: context,
                        title: 'Основная информация',
                        icon: Icons.info_outline,
                        delay: 0,
                        children: [
                          // Название
                          PrimaryTextFormField(
                            controller: _nameController,
                            label: 'Название',
                            hintText: 'Введите название пароля',
                            validator: _requiredValidator,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          // Описание
                          PrimaryTextFormField(
                            controller: _descriptionController,
                            label: 'Описание',
                            hintText: 'Дополнительное описание (необязательно)',
                            textInputAction: TextInputAction.next,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // URL
                          PrimaryTextFormField(
                            controller: _urlController,
                            label: 'URL сайта',
                            hintText: 'https://example.com',
                            validator: _urlValidator,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Карточка данных для входа
                      _buildSectionCard(
                        context: context,
                        title: 'Данные для входа',
                        icon: Icons.account_circle_outlined,
                        delay: 100,
                        children: [
                          // Логин
                          PrimaryTextFormField(
                            controller: _loginController,
                            label: 'Логин',
                            hintText: 'Имя пользователя',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          // Email
                          PrimaryTextFormField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'user@example.com',
                            validator: _emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          // Пароль
                          PrimaryTextFormField(
                            controller: _passwordController,
                            label: 'Пароль',
                            hintText: 'Введите пароль',
                            validator: _requiredValidator,
                            obscureText: !formState.isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Кнопка генератора паролей
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.auto_awesome),
                                    tooltip: 'Генератор паролей',
                                    onPressed: () {
                                      setState(() {
                                        _showPasswordGenerator =
                                            !_showPasswordGenerator;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Кнопка видимости пароля
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
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
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Генератор паролей (показывается при нажатии на кнопку)
                      if (_showPasswordGenerator) ...[
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _buildSectionCard(
                            context: context,
                            title: 'Генератор паролей',
                            icon: Icons.security,
                            delay: 200,
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withOpacity(0.3),
                            children: [
                              PasswordGenerator(
                                onPasswordGenerated: (password) {
                                  _passwordController.text = password;
                                  setState(() {
                                    _showPasswordGenerator = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Карточка дополнительной информации
                      _buildSectionCard(
                        context: context,
                        title: 'Дополнительно',
                        icon: Icons.notes_outlined,
                        delay: 300,
                        children: [
                          // Заметки
                          PrimaryTextFormField(
                            controller: _notesController,
                            label: 'Заметки',
                            hintText: 'Дополнительные заметки (необязательно)',
                            textInputAction: TextInputAction.done,
                            maxLines: 3,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Карточка категоризации
                      _buildSectionCard(
                        context: context,
                        title: 'Категория и теги',
                        icon: Icons.label_outline,
                        delay: 400,
                        children: [
                          // Выбор категории
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

                          const SizedBox(height: 16),

                          // Выбор тегов
                          TagsPicker(
                            tagType: TagType.password,
                            maxSelection: 5,
                            selectedTagIds: formState.selectedTagIds,
                            onSelect: notifier.updateSelectedTags,
                            labelText: 'Теги пароля',
                            hintText: 'Выберите теги',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Нижняя панель с кнопкой сохранения
              Container(
                padding: EdgeInsets.fromLTRB(
                  8,
                  8,
                  8,
                  MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Индикатор требований для валидации
                    if (!formState.isFormValid && !formState.isLoading)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Заполните обязательные поля: название, пароль и логин или email',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Стилизованная кнопка сохранения
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: formState.isLoading || !formState.isFormValid
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                        boxShadow: formState.isLoading || !formState.isFormValid
                            ? null
                            : [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: SmoothButton(
                        label: notifier.saveButtonText,
                        onPressed: formState.isLoading || !formState.isFormValid
                            ? null
                            : _savePassword,
                        loading: formState.isLoading,
                        type: SmoothButtonType.filled,
                        size: SmoothButtonSize.medium,
                        isFullWidth: true,
                        bold: true,
                      ),
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
