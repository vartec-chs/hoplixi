import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'selectable_icon_card.dart';

/// Модальное окно для выбора иконки
class IconPickerModal extends ConsumerStatefulWidget {
  /// ID текущей выбранной иконки
  final String? selectedIconId;

  /// Callback при выборе иконки
  final void Function(String iconId, store.IconData iconData) onIconSelected;

  /// Отображается ли как bottom sheet
  final bool isBottomSheet;

  /// Заголовок модального окна
  final String title;

  /// Размер страницы для пагинации
  final int pageSize;

  const IconPickerModal({
    super.key,
    this.selectedIconId,
    required this.onIconSelected,
    this.isBottomSheet = false,
    this.title = 'Выбрать иконку',
    this.pageSize = 20,
  });

  @override
  ConsumerState<IconPickerModal> createState() => _IconPickerModalState();
}

class _IconPickerModalState extends ConsumerState<IconPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  List<store.IconData> _allIcons = [];
  List<store.IconData> _filteredIcons = [];
  IconType? _selectedType;
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    setState(() => _isLoading = true);

    try {
      final iconsService = ref.read(iconsServiceProvider);
      _allIcons = await iconsService.getAllIcons();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки иконок: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<store.IconData> filtered = _allIcons;

    // Фильтр по типу
    if (_selectedType != null) {
      filtered = filtered.where((icon) => icon.type == _selectedType).toList();
    }

    // Поиск по имени
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (icon) =>
                icon.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      _filteredIcons = filtered;
      _totalPages = (_filteredIcons.length / widget.pageSize).ceil();
      _currentPage = 0;
    });

    // Переходим на первую страницу
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onTypeFilterChanged(IconType? type) {
    setState(() => _selectedType = type);
    _applyFilters();
  }

  List<store.IconData> _getCurrentPageIcons() {
    final startIndex = _currentPage * widget.pageSize;
    final endIndex = (startIndex + widget.pageSize).clamp(
      0,
      _filteredIcons.length,
    );

    if (startIndex >= _filteredIcons.length) return [];

    return _filteredIcons.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() => _currentPage = page);
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final isMobile = breakpoints.isMobile;

    return Container(
      padding: widget.isBottomSheet
          ? EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            )
          : const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: widget.isBottomSheet
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          // Заголовок и закрытие
          _buildHeader(context),

          const SizedBox(height: 16),

          // Поиск и фильтры
          _buildSearchAndFilters(context),

          const SizedBox(height: 16),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildIconGrid(context, isMobile),
          ),

          // Пагинация
          if (_totalPages > 1) ...[
            const SizedBox(height: 16),
            _buildPagination(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Индикатор для bottom sheet
        if (widget.isBottomSheet) ...[
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ] else ...[
          // Заголовок для диалога
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Column(
      children: [
        // Поле поиска
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск иконок...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _onSearchChanged,
        ),

        const SizedBox(height: 12),

        // Фильтр по типу
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Все'),
                selected: _selectedType == null,
                onSelected: (_) => _onTypeFilterChanged(null),
              ),
              const SizedBox(width: 8),
              ...IconType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: _selectedType == type,
                    onSelected: (_) => _onTypeFilterChanged(type),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconGrid(BuildContext context, bool isMobile) {
    if (_filteredIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Иконки не найдены',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = _getCrossAxisCount(context);
    final currentPageIcons = _getCurrentPageIcons();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: currentPageIcons.length,
      itemBuilder: (context, index) {
        final icon = currentPageIcons[index];
        return SelectableIconCard(
          icon: icon,
          isSelected: icon.id == widget.selectedIconId,
          onTap: () => widget.onIconSelected(icon.id, icon),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Предыдущая страница
        IconButton(
          onPressed: _currentPage > 0
              ? () => _goToPage(_currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),

        // Номера страниц
        ...List.generate(
          _totalPages.clamp(0, 5), // Показываем максимум 5 страниц
          (index) {
            int pageIndex;
            if (_totalPages <= 5) {
              pageIndex = index;
            } else {
              // Умная пагинация для большого количества страниц
              if (_currentPage < 3) {
                pageIndex = index;
              } else if (_currentPage >= _totalPages - 3) {
                pageIndex = _totalPages - 5 + index;
              } else {
                pageIndex = _currentPage - 2 + index;
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () => _goToPage(pageIndex),
                style: TextButton.styleFrom(
                  backgroundColor: pageIndex == _currentPage
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor: pageIndex == _currentPage
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  minimumSize: const Size(40, 40),
                ),
                child: Text('${pageIndex + 1}'),
              ),
            );
          },
        ),

        // Следующая страница
        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () => _goToPage(_currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final width = MediaQuery.of(context).size.width;

    if (breakpoints.isMobile) {
      return widget.isBottomSheet ? 4 : 3;
    } else if (breakpoints.isTablet) {
      return 6;
    } else {
      // Для десктопа вычисляем на основе ширины
      return (width / 100).floor().clamp(4, 10);
    }
  }
}
