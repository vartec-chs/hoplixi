import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';

import 'package:responsive_framework/responsive_framework.dart';

import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

import 'widgets/icon_card.dart';
import 'widgets/icon_form.dart';
import 'widgets/icon_filters.dart';
import 'widgets/pagination_controls.dart';

/// Экран управления иконками с пагинацией и адаптивным дизайном
class IconsManagementScreen extends ConsumerStatefulWidget {
  const IconsManagementScreen({super.key});

  @override
  ConsumerState<IconsManagementScreen> createState() =>
      _IconsManagementScreenState();
}

class _IconsManagementScreenState extends ConsumerState<IconsManagementScreen> {
  // Контроллеры состояния
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Фильтры и пагинация
  IconType? _selectedType;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1; // Сброс на первую страницу при поиске
    });
  }

  void _onTypeFilterChanged(IconType? type) {
    setState(() {
      _selectedType = type;
      _currentPage = 1;
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  Future<void> _showAddIconDialog() async {
    final bool isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      await _showMobileBottomSheet();
    } else {
      await _showDesktopDialog();
    }
  }

  Future<void> _showMobileBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const IconFormWidget(),
      ),
    );
  }

  Future<void> _showDesktopDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const IconFormWidget(),
        ),
      ),
    );
  }

  Future<void> _showEditIconDialog(store.IconData icon) async {
    final bool isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: true,
        // showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: IconFormWidget(existingIcon: icon),
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: IconFormWidget(existingIcon: icon),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteIcon(store.IconData icon) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить иконку'),
        content: Text('Вы уверены, что хотите удалить иконку "${icon.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteIcon(icon.id);
    }
  }

  Future<void> _deleteIcon(String iconId) async {
    try {
      final iconsService = ref.read(iconsServiceProvider);
      final result = await iconsService.deleteIcon(iconId);

      if (result.success) {
        if (mounted) {
          ToastHelper.success(
            title: 'Иконка удалена',
            description: result.message ?? 'Иконка успешно удалена',
          
          );
          // ref.invalidate(allIconsStreamProvider);
        }
      } else {
        if (mounted) {
          ToastHelper.error(
            title: 'Ошибка',
            description: 'Ошибка удаления иконки: ${result.message}',
           
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Ошибка удаления иконки: $e',
         
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconsAsync = ref.watch(allIconsStreamProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление иконками'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleViewMode,
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'Список' : 'Сетка',
          ),
          IconButton(
            onPressed: _showAddIconDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Добавить иконку',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              // Фильтры и поиск
              _buildFiltersSection(),
              const SizedBox(height: 16),

              // Контент
              Expanded(
                child: iconsAsync.when(
                  data: (icons) => _buildIconsList(icons),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(error),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _showAddIconDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поиск
            PrimaryTextField(
              controller: _searchController,
              label: 'Поиск иконок',
              prefixIcon: const Icon(Icons.search),
              hintText: 'Введите название иконки...',
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Фильтры
            IconFiltersWidget(
              selectedType: _selectedType,
              onTypeChanged: _onTypeFilterChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconsList(List<store.IconData> allIcons) {
    // Фильтрация
    List<store.IconData> filteredIcons = allIcons;

    if (_searchQuery.isNotEmpty) {
      filteredIcons = filteredIcons
          .where(
            (icon) =>
                icon.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (_selectedType != null) {
      filteredIcons = filteredIcons
          .where((icon) => icon.type == _selectedType)
          .toList();
    }

    // Пагинация
    final totalItems = filteredIcons.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final currentPageIcons = filteredIcons.sublist(startIndex, endIndex);

    if (filteredIcons.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Информация о результатах
        _buildResultsInfo(totalItems, _currentPage, totalPages),
        const SizedBox(height: 16),

        // Список иконок
        Expanded(
          child: _isGridView
              ? _buildGridView(currentPageIcons)
              : _buildListView(currentPageIcons),
        ),

        // Пагинация
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          PaginationControls(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: _onPageChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildResultsInfo(int totalItems, int currentPage, int totalPages) {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Показано $startItem-$endItem из $totalItems иконок',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Страница $currentPage из $totalPages',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<store.IconData> icons) {
    final crossAxisCount = ResponsiveBreakpoints.of(context).isDesktop
        ? 4
        : ResponsiveBreakpoints.of(context).isTablet
        ? 3
        : 2;

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        return IconCard(
          icon: icon,
          onEdit: () => _showEditIconDialog(icon),
          onDelete: () => _confirmDeleteIcon(icon),
        );
      },
    );
  }

  Widget _buildListView(List<store.IconData> icons) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: icons.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final icon = icons[index];
        return IconCard(
          icon: icon,
          isListView: true,
          onEdit: () => _showEditIconDialog(icon),
          onDelete: () => _confirmDeleteIcon(icon),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedType != null
                ? 'Иконки не найдены'
                : 'Нет добавленных иконок',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedType != null
                ? 'Попробуйте изменить параметры поиска'
                : 'Добавьте первую иконку нажав на кнопку "+"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddIconDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить иконку'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки иконок',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.invalidate(allIconsStreamProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
