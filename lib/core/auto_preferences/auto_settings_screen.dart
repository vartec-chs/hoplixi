import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auto_preferences_manager.dart';
import 'app_settings_definition.dart';
import 'setting_types.dart';
import 'setting_widgets.dart';

/// Автоматический экран настроек
class AutoSettingsScreen extends StatefulWidget {
  const AutoSettingsScreen({super.key});

  @override
  State<AutoSettingsScreen> createState() => _AutoSettingsScreenState();
}

class _AutoSettingsScreenState extends State<AutoSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController = TabController(length: 1, vsync: this);
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;

  List<String> _categories = [];
  String _searchQuery = '';
  bool _showOnlyModified = false;
  bool _groupBySubcategory = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _loadCategories();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSettings() {
    // Инициализируем все настройки из определения
    AppSettingsDefinition.initialize();
  }

  void _loadCategories() {
    _categories = _manager.getCategories();
    // Обновляем TabController если количество категорий изменилось
    if (_tabController.length != _categories.length + 1) {
      _tabController.dispose();
      _tabController = TabController(
        length: _categories.length + 1,
        vsync: this,
      );
    }
  }

  void _refreshSettings() {
    setState(() {
      _loadCategories();
    });
  }

  List<SettingDefinition> _getFilteredSettings() {
    final allSettings = _manager.getAllSettings();
    return allSettings.where((setting) {
      // Фильтр видимости
      if (!setting.isVisible) return false;

      // Фильтр по поиску
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!setting.title.toLowerCase().contains(query) &&
            !setting.key.toLowerCase().contains(query) &&
            !(setting.subtitle?.toLowerCase().contains(query) ?? false) &&
            !(setting.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Фильтр измененных настроек
      if (_showOnlyModified) {
        try {
          final currentValue = _manager.getValue(setting.key);
          if (currentValue == setting.defaultValue) {
            return false;
          }
        } catch (e) {
          // Игнорируем ошибки при получении значения
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Поиск',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтры',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Экспорт настроек'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Импорт настроек'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset_all',
                child: ListTile(
                  leading: Icon(Icons.restart_alt, color: Colors.red),
                  title: Text(
                    'Сбросить все',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Отладочная информация'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
        bottom: _categories.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                splashBorderRadius: BorderRadius.circular(12),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,

                tabs: [
                  const Tab(icon: Icon(Icons.search), text: 'Поиск'),
                  ..._categories.map(
                    (category) =>
                        Tab(icon: _getCategoryIcon(category), text: category),
                  ),
                ],
              )
            : null,
      ),
      body: _categories.isEmpty
          ? const Center(child: Text('Настройки не найдены'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                ..._categories.map((category) => _buildCategoryTab(category)),
              ],
            ),
    );
  }

  Widget _buildSearchTab() {
    final filteredSettings = _getFilteredSettings();

    return Column(
      children: [
        // Панель поиска
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск настроек...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
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
                    label: const Text('Только измененные'),
                    selected: _showOnlyModified,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyModified = selected;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Группировать'),
                    selected: _groupBySubcategory,
                    onSelected: (selected) {
                      setState(() {
                        _groupBySubcategory = selected;
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
          child: filteredSettings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Введите запрос для поиска'
                            : 'Настройки не найдены',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Попробуйте изменить запрос или фильтры',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                )
              : _buildSettingsList(filteredSettings),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(String category) {
    final categorySettings = _manager.getSettingsByCategory(category);
    final visibleSettings = categorySettings.where((s) => s.isVisible).toList();

    if (visibleSettings.isEmpty) {
      return const Center(
        child: Text('Настройки в этой категории отсутствуют'),
      );
    }

    return _buildSettingsList(visibleSettings, groupBySubcategory: true);
  }

  Widget _buildSettingsList(
    List<SettingDefinition> settings, {
    bool groupBySubcategory = false,
  }) {
    if (!groupBySubcategory || !_groupBySubcategory) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settings.length,
        itemBuilder: (context, index) {
          return _buildSettingCard(settings[index]);
        },
      );
    }

    // Группировка по подкатегориям
    final grouped = <String?, List<SettingDefinition>>{};
    for (final setting in settings) {
      grouped.putIfAbsent(setting.subcategory, () => []).add(setting);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        final subcategory = entry.key;
        final subcategorySettings = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subcategory != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  subcategory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ...subcategorySettings.map((setting) => _buildSettingCard(setting)),
            if (index < grouped.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSettingCard(SettingDefinition setting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SettingWidget.create(setting, onChanged: _refreshSettings),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    const categoryIcons = {
      'Общие': Icons.settings,
      'Безопасность': Icons.security,
      'Интерфейс': Icons.palette,
      'Генератор паролей': Icons.vpn_key,
      'Хранилище': Icons.storage,
      'Резервное копирование': Icons.backup,
      'Разработчик': Icons.code,
    };

    return Icon(categoryIcons[category] ?? Icons.category);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск настроек'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите название настройки...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _tabController.animateTo(0); // Переключиться на вкладку поиска
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tabController.animateTo(0);
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Только измененные настройки'),
              subtitle: const Text(
                'Показать только настройки, отличающиеся от значений по умолчанию',
              ),
              value: _showOnlyModified,
              onChanged: (value) {
                setState(() {
                  _showOnlyModified = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Группировать по подкатегориям'),
              subtitle: const Text('Разделять настройки по подкатегориям'),
              value: _groupBySubcategory,
              onChanged: (value) {
                setState(() {
                  _groupBySubcategory = value ?? false;
                });
              },
            ),
          ],
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
      case 'reset_all':
        _showResetAllDialog();
        break;
      case 'debug':
        _showDebugInfo();
        break;
    }
  }

  void _exportSettings() {
    final settings = _manager.exportSettings();
    final json = settings.entries
        .map((e) => '  "${e.key}": ${_formatJsonValue(e.value)}')
        .join(',\n');
    final export = '{\n$json\n}';

    Clipboard.setData(ClipboardData(text: export));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки скопированы в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatJsonValue(dynamic value) {
    if (value is String) {
      return '"$value"';
    } else if (value is List) {
      final items = value.map((item) => '"$item"').join(', ');
      return '[$items]';
    }
    return value.toString();
  }

  void _importSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт настроек'),
        content: const Text(
          'Функция импорта настроек будет доступна в следующих версиях. '
          'Пока доступен только экспорт настроек.',
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

  void _showResetAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс всех настроек'),
        content: const Text(
          'Вы действительно хотите сбросить все настройки к значениям по умолчанию? '
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
              try {
                await _manager.resetAllSettings();
                _refreshSettings();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Все настройки сброшены')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    final debugInfo = _manager.getDebugInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отладочная информация'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: debugInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.replaceAll('_', ' ')),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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
}
