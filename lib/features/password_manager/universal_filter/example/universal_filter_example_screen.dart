import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/universal_filter_section.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/universal_records_list.dart';

/// Экран-пример использования универсального фильтра
/// Демонстрирует интеграцию FilterSection и RecordsList с bottom navigation
class UniversalFilterExampleScreen extends ConsumerStatefulWidget {
  const UniversalFilterExampleScreen({super.key});

  @override
  ConsumerState<UniversalFilterExampleScreen> createState() =>
      _UniversalFilterExampleScreenState();
}

class _UniversalFilterExampleScreenState
    extends ConsumerState<UniversalFilterExampleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entityType = ref.watch(currentEntityTypeProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          // Универсальная секция фильтрации
          UniversalFilterSection(
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            showEntityTypeSelector: true,
            additionalActions: [
              IconButton(
                onPressed: () {
                  // Дополнительное действие (например, настройки)
                  _showSettingsDialog();
                },
                icon: const Icon(Icons.settings),
                tooltip: 'Настройки',
              ),
            ],
          ),

          // Список записей
          SliverFillRemaining(
            child: UniversalRecordsList(
              onRecordTap: (record) {
                _onRecordTap(context, record, entityType);
              },
              onRecordLongPress: (record) {
                _onRecordLongPress(context, record, entityType);
              },
              onRefresh: () async {
                // Обновление данных
                await Future.delayed(const Duration(seconds: 1));
              },
              emptyMessage: _getEmptyMessage(entityType),
            ),
          ),
        ],
      ),
      // в данный момент не нужен
      // bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final entityType = ref.watch(currentEntityTypeProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.security,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
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
                      0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...UniversalEntityType.values.map((type) {
            final isActive = entityType == type;
            return ListTile(
              leading: Icon(
                _getEntityTypeIcon(type),
                color: isActive ? theme.colorScheme.primary : null,
              ),
              title: Text(
                type.label,
                style: TextStyle(
                  color: isActive ? theme.colorScheme.primary : null,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
              selected: isActive,
              onTap: () {
                ref
                    .read(entityTypeControllerProvider.notifier)
                    .changeEntityType(type);
                Navigator.of(context).pop();
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.of(context).pop();
              _showSettingsDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final entityType = ref.watch(currentEntityTypeProvider);

    return BottomAppBar(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              _showQuickAddDialog(context, entityType);
            },
            icon: const Icon(Icons.add),
            tooltip:
                'Добавить ${_getEntityTypeLabel(entityType).toLowerCase()}',
          ),
          IconButton(
            onPressed: () {
              _showSearchDialog(context);
            },
            icon: const Icon(Icons.search),
            tooltip: 'Поиск',
          ),
          IconButton(
            onPressed: () {
              _showSortDialog(context);
            },
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
          ),
          IconButton(
            onPressed: () {
              _showExportDialog(context, entityType);
            },
            icon: const Icon(Icons.file_download),
            tooltip: 'Экспорт',
          ),
        ],
      ),
    );
  }

  void _onRecordTap(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Нажатие на ${_getEntityTypeLabel(entityType).toLowerCase()}: ${_getRecordDisplayName(record, entityType)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRecordLongPress(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _buildRecordActionsSheet(context, record, entityType),
    );
  }

  Widget _buildRecordActionsSheet(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _getRecordDisplayName(record, entityType),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать'),
            onTap: () {
              Navigator.of(context).pop();
              _editRecord(context, record, entityType);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Копировать'),
            onTap: () {
              Navigator.of(context).pop();
              _copyRecord(context, record, entityType);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Поделиться'),
            onTap: () {
              Navigator.of(context).pop();
              _shareRecord(context, record, entityType);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _deleteRecord(context, record, entityType);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showQuickAddDialog(
    BuildContext context,
    UniversalEntityType entityType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Добавить ${_getEntityTypeLabel(entityType).toLowerCase()}',
        ),
        content: Text(
          'Здесь будет форма для быстрого добавления нового элемента типа "${entityType.label}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Расширенный поиск'),
        content: const Text('Здесь будут дополнительные опции поиска'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сортировка'),
        content: const Text('Здесь будут опции сортировки'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, UniversalEntityType entityType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Экспорт ${_getEntityTypeLabel(entityType).toLowerCase()}'),
        content: const Text('Здесь будут опции экспорта данных'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Экспорт'),
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
        content: const Text('Здесь будут настройки приложения'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
      applicationLegalese: '© ${DateTime.now().year} Hoplixi Team',
      children: [
        const Text('Универсальный менеджер паролей с поддержкой фильтрации.'),
      ],
    );
  }

  void _editRecord(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование ${_getEntityTypeLabel(entityType).toLowerCase()}: ${_getRecordDisplayName(record, entityType)}',
        ),
      ),
    );
  }

  void _copyRecord(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Скопировано: ${_getRecordDisplayName(record, entityType)}',
        ),
      ),
    );
  }

  void _shareRecord(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Поделиться: ${_getRecordDisplayName(record, entityType)}',
        ),
      ),
    );
  }

  void _deleteRecord(
    BuildContext context,
    dynamic record,
    UniversalEntityType entityType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить "${_getRecordDisplayName(record, entityType)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Удалено: ${_getRecordDisplayName(record, entityType)}',
                  ),
                ),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  IconData _getEntityTypeIcon(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return Icons.lock;
      case UniversalEntityType.note:
        return Icons.note;
      case UniversalEntityType.otp:
        return Icons.security;
      case UniversalEntityType.attachment:
        return Icons.attachment;
    }
  }

  String _getEntityTypeLabel(UniversalEntityType entityType) {
    return entityType.label;
  }

  String _getRecordDisplayName(dynamic record, UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return record['name'] ?? 'Пароль';
      case UniversalEntityType.note:
        return record['title'] ?? 'Заметка';
      case UniversalEntityType.otp:
        return record['issuer'] ?? 'OTP';
      case UniversalEntityType.attachment:
        return record['name'] ?? 'Файл';
    }
  }

  String _getEmptyMessage(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Пароли не найдены.\nДобавьте новый пароль или измените фильтры.';
      case UniversalEntityType.note:
        return 'Заметки не найдены.\nСоздайте новую заметку или измените фильтры.';
      case UniversalEntityType.otp:
        return 'OTP коды не найдены.\nДобавьте новый OTP или измените фильтры.';
      case UniversalEntityType.attachment:
        return 'Вложения не найдены.\nДобавьте новое вложение или измените фильтры.';
    }
  }
}
