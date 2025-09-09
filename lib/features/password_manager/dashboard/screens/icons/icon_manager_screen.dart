import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/category/category_manager_screen.dart';
import 'widgets/icon_picker_modal.dart';

class IconManagerScreen extends ConsumerStatefulWidget {
  const IconManagerScreen({super.key});

  @override
  ConsumerState<IconManagerScreen> createState() => _IconManagerScreenState();
}

class _IconManagerScreenState extends ConsumerState<IconManagerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: IconType.values.length, vsync: this);
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
        title: const Text('Менеджер иконок'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddIconDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Добавить иконку',
          ),
          IconButton(
            onPressed: _showCleanupDialog,
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Очистить неиспользуемые',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: IconType.values.map((type) {
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
                hintText: 'Поиск иконок...',
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
              children: IconType.values.map((type) {
                return _buildIconsGrid(type, isDesktop);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconsGrid(IconType type, bool isDesktop) {
    return Consumer(
      builder: (context, ref, child) {
        final iconsAsync = ref.watch(iconsByTypeStreamProvider(type));

        return iconsAsync.when(
          data: (icons) {
            final filteredIcons = _searchQuery.isEmpty
                ? icons
                : icons
                      .where(
                        (icon) => icon.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            if (filteredIcons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Нет иконок типа ${_getTypeDisplayName(type)}'
                          : 'Иконки не найдены',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 6 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: filteredIcons.length,
              itemBuilder: (context, index) {
                final icon = filteredIcons[index];
                return _buildIconCard(icon);
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
                  'Ошибка загрузки иконок',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.refresh(iconsByTypeStreamProvider(type)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconCard(store.IconData iconData) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showIconDetails(iconData),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Image.memory(
                  iconData.data,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      size: 32,
                      color: theme.colorScheme.error,
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Text(
                iconData.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIconDialog() {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    if (isDesktop) {
      // Show modal dialog on desktop
      showDialog(
        context: context,
        builder: (context) => const IconPickerModal(),
      );
    } else {
      // Show bottom sheet on mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
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
              child: const IconPickerModal(isBottomSheet: true),
            );
          },
        ),
      );
    }
  }

  void _showIconDetails(store.IconData iconData) {
    showDialog(
      context: context,
      builder: (context) => _IconDetailsDialog(icon: iconData),
    );
  }

  void _showCleanupDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистка неиспользуемых иконок'),
        content: const Text(
          'Удалить все иконки, которые не используются в категориях? '
          'Это действие нельзя отменить.',
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
      _performCleanup();
    }
  }

  void _performCleanup() async {
    try {
      final iconsService = ref.read(iconsServiceProvider);
      final deletedCount = await iconsService.cleanupUnusedIcons();

      if (mounted) {
        ScaffoldMessengerManager.instance.showSuccess(
          'Удалено $deletedCount неиспользуемых иконок',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessengerManager.instance.showError('Ошибка при очистке: $e');
      }
    }
  }

  String _getTypeDisplayName(IconType type) {
    switch (type) {
      case IconType.png:
        return 'PNG';
      case IconType.jpg:
        return 'JPG';
      case IconType.svg:
        return 'SVG';
      case IconType.gif:
        return 'GIF';
      case IconType.bmp:
        return 'BMP';
      case IconType.webp:
        return 'WebP';
    }
  }

  IconData _getTypeIcon(IconType type) {
    switch (type) {
      case IconType.png:
      case IconType.jpg:
      case IconType.bmp:
      case IconType.webp:
        return Icons.image;
      case IconType.svg:
        return Icons.image;
      case IconType.gif:
        return Icons.gif;
    }
  }
}

class _IconDetailsDialog extends StatelessWidget {
  final store.IconData icon;

  const _IconDetailsDialog({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(icon.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(icon.data, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Тип', icon.type.name.toUpperCase()),
          _buildInfoRow(
            'Размер',
            '${(icon.data.length / 1024).toStringAsFixed(1)} KB',
          ),
          _buildInfoRow('Создано', _formatDate(icon.createdAt)),
          _buildInfoRow('Изменено', _formatDate(icon.modifiedAt)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () => _deleteIcon(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Удалить'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _deleteIcon(BuildContext context, WidgetRef ref) async {
    try {
      final iconsService = ref.read(iconsServiceProvider);
      await iconsService.deleteIcon(icon.id);

      if (context.mounted) {
        Navigator.of(context).pop();
        ToastHelper.success(
          title: 'Иконка удалена',
          context: context,
          description: 'Иконка успешно удалена',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.error(
          title: 'Ошибка при удалении',
          context: context,
          description: e.toString(),
        );
      }
    }
  }
}
