import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_preferences.dart';
import 'preference_definition.dart';
import 'preferences_registry.dart';
import 'preference_editors.dart';

/// Динамический экран настроек приложения
class DynamicSettingsScreen extends StatefulWidget {
  const DynamicSettingsScreen({super.key});

  @override
  State<DynamicSettingsScreen> createState() => _DynamicSettingsScreenState();
}

class _DynamicSettingsScreenState extends State<DynamicSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AppPreferences _prefs = AppPreferences.instance;
  List<PreferenceCategory> _categories = [];
  String _searchQuery = '';
  bool _showDeprecated = false;
  bool _showReadOnly = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    _categories = PreferencesRegistry.getAllCategories();
  }

  void _refreshSettings() {
    setState(() {
      _loadCategories();
    });
  }

  List<PreferenceDefinition> _getFilteredPreferences() {
    final allPrefs = PreferencesRegistry.getAllPreferences();
    return allPrefs.where((pref) {
      // Фильтр по поиску
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!pref.title.toLowerCase().contains(query) &&
            !pref.key.toLowerCase().contains(query) &&
            !(pref.subtitle?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Фильтр устаревших настроек
      if (!_showDeprecated && pref.isDeprecated) {
        return false;
      }

      // Фильтр read-only настроек
      if (!_showReadOnly && pref.isReadOnly) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки приложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSettings,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugInfo,
            tooltip: 'Информация',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'show_all',
                child: Text('Показать все настройки'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Экспорт настроек'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Импорт настроек'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Сбросить настройки'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'show_all':
                  _showAllSettingsDialog();
                  break;
                case 'export':
                  _exportSettings();
                  break;
                case 'import':
                  _importSettings();
                  break;
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            // Вкладка поиска
            const Tab(icon: Icon(Icons.search), text: 'Поиск'),
            // Вкладки категорий
            ..._categories.map(
              (category) =>
                  Tab(icon: Icon(category.icon), text: category.title),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка поиска
          _buildSearchTab(),
          // Вкладки категорий
          ..._categories.map((category) => _buildCategoryTab(category)),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final filteredPrefs = _getFilteredPreferences();

    return Column(
      children: [
        // Строка поиска и фильтры
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Поиск настроек...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Устаревшие'),
                    selected: _showDeprecated,
                    onSelected: (selected) {
                      setState(() {
                        _showDeprecated = selected;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Только чтение'),
                    selected: _showReadOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showReadOnly = selected;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Результаты поиска
        Expanded(
          child: filteredPrefs.isEmpty
              ? const Center(child: Text('Настройки не найдены'))
              : ListView.builder(
                  itemCount: filteredPrefs.length,
                  itemBuilder: (context, index) {
                    final pref = filteredPrefs[index];
                    return _buildPreferenceCard(pref);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(PreferenceCategory category) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Заголовок категории
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (category.icon != null) ...[
                      Icon(category.icon, size: 24),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Настройки категории
        ...category.preferences.map((pref) => _buildPreferenceCard(pref)),
      ],
    );
  }

  Widget _buildPreferenceCard(PreferenceDefinition preference) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          PreferenceEditor.create(preference, onChanged: _refreshSettings),
          if (preference.isDeprecated || preference.isReadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (preference.isDeprecated) ...[
                    const Chip(
                      label: Text('Устарело', style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (preference.isReadOnly) ...[
                    const Chip(
                      label: Text(
                        'Только чтение',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    final allSettings = _prefs.getAllSettings();
    final categories = PreferencesRegistry.getAllCategories();
    final allPrefs = PreferencesRegistry.getAllPreferences();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о настройках'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Категорий настроек: ${categories.length}'),
              Text('Определений настроек: ${allPrefs.length}'),
              Text('Сохраненных настроек: ${allSettings.length}'),
              const SizedBox(height: 16),
              Text(
                'Deprecated настроек: ${allPrefs.where((p) => p.isDeprecated).length}',
              ),
              Text(
                'Read-only настроек: ${allPrefs.where((p) => p.isReadOnly).length}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAllSettingsDialog() {
    final allSettings = _prefs.getAllSettings();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Все настройки'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: allSettings.length,
            itemBuilder: (context, index) {
              final entry = allSettings.entries.elementAt(index);
              return ListTile(
                title: Text(entry.key),
                subtitle: Text(
                  entry.value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: '${entry.key}: ${entry.value}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скопировано')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    final allSettings = _prefs.getAllSettings();
    final json = allSettings.entries
        .map((e) => '"${e.key}": "${e.value}"')
        .join(',\n');
    final export = '{\n$json\n}';

    Clipboard.setData(ClipboardData(text: export));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки скопированы в буфер обмена')),
    );
  }

  void _importSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт настроек'),
        content: const Text(
          'Функция импорта настроек будет доступна в следующих версиях. '
          'Пока что можно использовать только экспорт настроек.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс настроек'),
        content: const Text(
          'Вы уверены, что хотите сбросить все пользовательские настройки? '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _prefs.clearUserSettings();
              _refreshSettings();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Настройки сброшены')),
                );
              }
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
