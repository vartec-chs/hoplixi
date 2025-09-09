import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'widgets/category_form_modal.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CategoryType.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер категорий'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Добавить категорию',
          ),
          IconButton(
            onPressed: _showStatsDialog,
            icon: const Icon(Icons.analytics),
            tooltip: 'Статистика',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: CategoryType.values.map((type) {
            return Tab(
              text: _getTypeDisplayName(type),
              icon: Icon(_getTypeIcon(type)),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск категорий...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: CategoryType.values.map((type) {
                return _buildCategoriesGrid(type, isDesktop);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(CategoryType type, bool isDesktop) {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(categoriesByTypeStreamProvider(type));

        return categoriesAsync.when(
          data: (categories) {
            final filteredCategories = _searchQuery.isEmpty
                ? categories
                : categories
                      .where(
                        (category) =>
                            category.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (category.description?.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ??
                                false),
                      )
                      .toList();

            if (filteredCategories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Нет категорий типа ${_getTypeDisplayName(type)}'
                          : 'Категории не найдены',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddCategoryDialog(initialType: type),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Создать ${_getTypeDisplayName(type).toLowerCase()}',
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return _buildCategoryCard(category);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки категорий',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.refresh(categoriesByTypeStreamProvider(type)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(store.Category category) {
    final theme = Theme.of(context);
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _showCategoryDetails(category),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor.withOpacity(0.1),
                categoryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header with color strip
              Container(
                width: double.infinity,
                height: 4,
                color: categoryColor,
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and title row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: categoryColor.withOpacity(0.2),
                            child: Icon(
                              _getTypeIcon(category.type),
                              size: 18,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Редактировать'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('Удалить'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) =>
                                _handleCategoryAction(value, category),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Description
                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        Expanded(
                          child: Text(
                            category.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            'Без описания',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Type badge
                      Chip(
                        label: Text(
                          _getTypeDisplayName(category.type),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: categoryColor.withOpacity(0.1),
                        side: BorderSide(color: categoryColor.withOpacity(0.3)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog({CategoryType? initialType}) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    if (isDesktop) {
      // Show modal dialog on desktop
      showDialog(
        context: context,
        builder: (context) => CategoryFormModal(initialType: initialType),
      );
    } else {
      // Show bottom sheet on mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: CategoryFormModal(
                isBottomSheet: true,
                initialType: initialType,
              ),
            );
          },
        ),
      );
    }
  }

  void _showCategoryDetails(store.Category category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDetailsDialog(category: category),
    );
  }

  void _handleCategoryAction(String action, store.Category category) {
    switch (action) {
      case 'edit':
        _editCategory(category);
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _editCategory(store.Category category) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => CategoryFormModal(category: category),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: CategoryFormModal(isBottomSheet: true, category: category),
            );
          },
        ),
      );
    }
  }

  void _deleteCategory(store.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление категории'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите удалить категорию "${category.name}"?',
            ),
            const SizedBox(height: 8),
            Text(
              'Это действие нельзя отменить.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final categoriesService = ref.read(categoriesServiceProvider);
        final result = await categoriesService.deleteCategory(category.id);

        if (mounted) {
          if (result.success) {
            
            ToastHelper.success(
              title: 'Категория удалена',
              context: context,
              description: 'Категория "${category.name}" успешно удалена',
            );
          } else {
            ToastHelper.error(
              title: 'Ошибка при удалении категории',
              context: context,
              description: result.message ?? 'Ошибка при удалении категории',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.error(
            title: 'Ошибка при удалении',
            context: context,
            description: 'Ошибка при удалении: $e',
          );
        }
      }
    }
  }

  void _showStatsDialog() async {
    try {
      final categoriesService = ref.read(categoriesServiceProvider);
      final stats = await categoriesService.getCategoriesStats();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _StatsDialog(stats: stats),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка получения статистики',
          context: context,
          description: e.toString(),
        );
      }
    }
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанные';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.key;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.category;
    }
  }
}

class _CategoryDetailsDialog extends StatelessWidget {
  final store.Category category;

  const _CategoryDetailsDialog({required this.category});

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: categoryColor.withOpacity(0.2),
            child: Icon(_getTypeIcon(category.type), color: categoryColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Тип', _getTypeDisplayName(category.type)),
          if (category.description != null && category.description!.isNotEmpty)
            _buildInfoRow('Описание', category.description!),
          _buildInfoRow('Цвет', category.color),
          _buildInfoRow('Создана', _formatDate(category.createdAt)),
          _buildInfoRow('Изменена', _formatDate(category.modifiedAt)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанные';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.key;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.category;
    }
  }
}

class _StatsDialog extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsDialog({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Статистика категорий'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow('Всего категорий', '${stats['totalCategories'] ?? 0}'),
          _buildStatRow(
            'Категорий паролей',
            '${stats['passwordCategories'] ?? 0}',
          ),
          _buildStatRow(
            'Категорий заметок',
            '${stats['notesCategories'] ?? 0}',
          ),
          _buildStatRow('TOTP категорий', '${stats['totpCategories'] ?? 0}'),
          _buildStatRow(
            'Смешанных категорий',
            '${stats['mixedCategories'] ?? 0}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
