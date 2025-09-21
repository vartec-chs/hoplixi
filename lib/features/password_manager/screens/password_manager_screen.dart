import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/universal_filter_section.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/passwords_list.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/expandable_fab.dart';
import 'package:hoplixi/features/password_manager/universal_filter/controllers/password_list_controller.dart';
import 'package:hoplixi/features/password_manager/universal_filter/providers/entity_type_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';

/// Полноценный экран управления паролями с фильтрацией и пагинацией
class PasswordManagerScreen extends ConsumerStatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  ConsumerState<PasswordManagerScreen> createState() =>
      _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends ConsumerState<PasswordManagerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Устанавливаем тип сущности на пароли
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(entityTypeControllerProvider.notifier)
          .changeEntityType(UniversalEntityType.password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: UniversalFilterSection()),
          SliverFillRemaining(
            child: PasswordsList(
              onPasswordTap: () => _onPasswordTap(),
              onPasswordLongPress: _onPasswordLongPress,
              onPasswordEdit: _onPasswordEdit,
              onPasswordDelete: _onPasswordDelete,
              onPasswordFavoriteToggle: _onPasswordFavoriteToggle,
            ),
          ),
        ],
      ),
      floatingActionButton: ExpandableFAB(
        onCreatePassword: _onCreatePassword,
        onCreateCategory: _onCreateCategory,
        onCreateTag: _onCreateTag,
        onIconCreate: _onCreateIcon,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(passwordListControllerProvider);

    return SliverAppBar(
      title: Text('Менеджер паролей'),
      centerTitle: false,
      floating: true,
      snap: true,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        // Кнопка поиска
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Поиск',
        ),
        // Кнопка сортировки
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortDialog,
          tooltip: 'Сортировка',
        ),
        // Кнопка обновления
        IconButton(
          icon: state.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onSurface,
                  ),
                )
              : const Icon(Icons.refresh),
          onPressed: state.isLoading ? null : _refreshPasswords,
          tooltip: 'Обновить',
        ),
        // Меню действий
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Экспорт'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Настройки'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('О программе'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoplixi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Менеджер паролей',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(
                      0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Пароли'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Заметки'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('Заметки');
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Карты'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('Карты');
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Генератор паролей'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('Генератор паролей');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Категории'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('Управление категориями');
            },
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Теги'),
            onTap: () {
              Navigator.pop(context);
              _showNotImplementedSnackBar('Управление тегами');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Справка'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  // ==================== ОБРАБОТЧИКИ СОБЫТИЙ ====================

  void _onPasswordTap() {
    logDebug('Клик по паролю');
  }

  void _onPasswordLongPress(CardPasswordDto password) {
    _showPasswordContextMenu(password);
  }

  void _onPasswordEdit(CardPasswordDto password) {
    logDebug('Редактирование пароля: ${password.name}');
    _showNotImplementedSnackBar('Редактирование пароля');
  }

  void _onPasswordDelete(CardPasswordDto password) {
    _showDeleteConfirmationDialog(password);
  }

  void _onPasswordFavoriteToggle(CardPasswordDto password) {
    logDebug('Переключение избранного для пароля: ${password.name}');
    _showNotImplementedSnackBar('Переключение избранного');
  }

  void _onCreatePassword() {
    logDebug('Создание нового пароля');
    _showNotImplementedSnackBar('Создание пароля');
  }

  void _onCreateCategory() {
    logDebug('Создание новой категории');
    _showNotImplementedSnackBar('Создание категории');
  }

  void _onCreateTag() {
    logDebug('Создание нового тега');
    _showNotImplementedSnackBar('Создание тега');
  }

  void _onCreateIcon() {
    logDebug('Создание новой иконки');
    _showNotImplementedSnackBar('Создание иконки');
  }

  void _refreshPasswords() {
    ref.read(passwordListControllerProvider.notifier).refresh();
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'export':
        _showNotImplementedSnackBar('Экспорт данных');
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  // ==================== ДИАЛОГИ ====================

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Поисковый запрос',
            hintText: 'Введите название, URL или логин...',
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              ref
                  .read(passwordListControllerProvider.notifier)
                  .updateSearch(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(passwordListControllerProvider.notifier).clearFilters();
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сортировка'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('По названию'),
              leading: Radio(
                value: 'name',
                groupValue: 'name',
                onChanged: null,
              ),
            ),
            ListTile(
              title: Text('По дате создания'),
              leading: Radio(
                value: 'created',
                groupValue: 'name',
                onChanged: null,
              ),
            ),
            ListTile(
              title: Text('По дате изменения'),
              leading: Radio(
                value: 'modified',
                groupValue: 'name',
                onChanged: null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _showPasswordContextMenu(CardPasswordDto password) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _onPasswordEdit(password);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Копировать пароль'),
              onTap: () {
                Navigator.pop(context);
                _showNotImplementedSnackBar('Копирование пароля');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _showNotImplementedSnackBar('Общий доступ');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Удалить',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _onPasswordDelete(password);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(CardPasswordDto password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить пароль "${password.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePassword(password);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки'),
        content: const Text('Настройки приложения'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Hoplixi',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.lock, size: 48),
      children: [
        const Text('Безопасный менеджер паролей с локальным шифрованием.'),
      ],
    );
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  void _deletePassword(CardPasswordDto password) {
    try {
      ref
          .read(passwordListControllerProvider.notifier)
          .removePassword(password.id);
      ToastHelper.success(
        title: 'Успешно',
        description: 'Пароль "${password.name}" удален',
      );
      logDebug('Пароль удален: ${password.name}');
    } catch (e, stackTrace) {
      logError('Ошибка удаления пароля', error: e, stackTrace: stackTrace);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось удалить пароль',
      );
    }
  }

  void _showNotImplementedSnackBar(String feature) {
    ToastHelper.info(
      title: 'В разработке',
      description: '$feature будет доступно в следующих версиях',
    );
  }
}
