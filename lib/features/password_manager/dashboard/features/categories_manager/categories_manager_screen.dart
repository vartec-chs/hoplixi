import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/categories_manager/widgets/category_icon.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'categories_manager_control.dart';
import 'widgets/category_form_modal.dart';

/// Экран управления категориями
class CategoriesManagerScreen extends ConsumerStatefulWidget {
  const CategoriesManagerScreen({super.key});

  @override
  ConsumerState<CategoriesManagerScreen> createState() =>
      _CategoriesManagerScreenState();
}

class _CategoriesManagerScreenState
    extends ConsumerState<CategoriesManagerScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final categories = ref.watch(categoriesListProvider);
    final isLoading = ref.watch(categoriesLoadingProvider);
    final error = ref.watch(categoriesErrorProvider);
    final selectedType = ref.watch(categoriesSelectedTypeProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          _buildFilters(selectedType),
          if (error != null) _buildErrorBanner(error),
          Expanded(child: _buildContent(categories, isLoading, breakpoints)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Управление категориями'),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchController.clear();
              ref
                  .read(categoriesManagerControllerProvider.notifier)
                  .searchCategories('');
            }
          },
          icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          tooltip: _showSearch ? 'Скрыть поиск' : 'Поиск',
        ),
        IconButton(
          onPressed: () =>
              ref.read(categoriesManagerControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Обновить',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_filters',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 12),
                  Text('Очистить фильтры'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 12),
                  Text('Экспорт'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: PrimaryTextField(
        controller: _searchController,
        decoration:
            primaryInputDecoration(
              context,
              hintText: 'Поиск категорий...',
            ).copyWith(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(categoriesManagerControllerProvider.notifier)
                            .searchCategories('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
        onChanged: (value) {
          ref
              .read(categoriesManagerControllerProvider.notifier)
              .searchCategories(value);
        },
      ),
    );
  }

  Widget _buildFilters(CategoryType? selectedType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Все'),
              selected: selectedType == null,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(categoriesManagerControllerProvider.notifier)
                      .filterByType(null);
                }
              },
            ),
            const SizedBox(width: 8),
            ...CategoryType.values.map((type) {
              final isSelected = selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getCategoryTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref
                        .read(categoriesManagerControllerProvider.notifier)
                        .filterByType(selected ? type : null);
                  },
                  avatar: CategoryIconWithData(
                    category: store.Category(
                      id: '', // Временный ID для виджета фильтра
                      name: '',
                      type: type,
                      color: 'FFFFFF',
                      createdAt: DateTime.now(),
                      modifiedAt: DateTime.now(),
                    ),
                    size: 18,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(categoriesManagerControllerProvider.notifier)
                .clearError(),
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<store.Category> categories,
    bool isLoading,
    ResponsiveBreakpointsData breakpoints,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    final isMobile = breakpoints.isMobile;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(categoriesManagerControllerProvider.notifier).refresh();
      },
      child: isMobile ? _buildListView(categories) : _buildGridView(categories),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Категории не найдены',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте свою первую категорию',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateCategoryModal(),
            icon: const Icon(Icons.add),
            label: const Text('Создать категорию'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<store.Category> categories) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryListTile(category);
      },
    );
  }

  Widget _buildGridView(List<store.Category> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryListTile(store.Category category) {
    final color = _parseColor(category.color);

    return Card(
      child: ListTile(
        leading: CategoryIconWithData(
          category: category,
          size: 48,
          backgroundColor: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          showBorder: true,
          borderColor: color.withOpacity(0.3),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description?.isNotEmpty == true)
              Text(
                category.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                CategoryIconWithData(
                  category: category,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _getCategoryTypeLabel(category.type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleCategoryAction(action, category),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 12),
                  Text('Редактировать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Удалить', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showEditCategoryModal(category),
      ),
    );
  }

  Widget _buildCategoryCard(store.Category category) {
    final color = _parseColor(category.color);

    return Card(
      child: InkWell(
        onTap: () => _showEditCategoryModal(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIconWithData(
                    category: category,
                    size: 40,
                    backgroundColor: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleCategoryAction(action, category),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 12),
                            Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (category.description?.isNotEmpty == true) ...[
                Text(
                  category.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              Row(
                children: [
                  CategoryIconWithData(
                    category: category,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCategoryTypeLabel(category.type),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateCategoryModal,
      tooltip: 'Создать категорию',
      child: const Icon(Icons.add),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_filters':
        ref.read(categoriesManagerControllerProvider.notifier).clearFilters();
        setState(() {
          _showSearch = false;
          _searchController.clear();
        });
        break;
      case 'export':
        // TODO: Реализовать экспорт
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Экспорт будет добавлен в следующих версиях'),
          ),
        );
        break;
    }
  }

  void _handleCategoryAction(String action, store.Category category) {
    switch (action) {
      case 'edit':
        _showEditCategoryModal(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  void _showCreateCategoryModal() {
    showCategoryFormModal(
      context: context,
      onSaved: () {
        // Обновление происходит автоматически через контроллер
      },
    );
  }

  void _showEditCategoryModal(store.Category category) {
    showCategoryFormModal(
      context: context,
      category: category,
      onSaved: () {
        // Обновление происходит автоматически через контроллер
      },
    );
  }

  Future<void> _showDeleteConfirmation(store.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          'Категория "${category.name}" будет удалена безвозвратно. '
          'Все элементы в этой категории останутся, но будут без категории.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(categoriesManagerControllerProvider.notifier)
          .deleteCategory(category.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Категория "${category.name}" удалена'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  String _getCategoryTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP коды';
      case CategoryType.mixed:
        return 'Смешанная';
    }
  }

  Color _parseColor(String colorHex) {
    try {
      final colorValue = int.parse(colorHex, radix: 16);
      return Color(0xFF000000 | colorValue);
    } catch (e) {
      return Colors.blue; // Цвет по умолчанию
    }
  }
}
