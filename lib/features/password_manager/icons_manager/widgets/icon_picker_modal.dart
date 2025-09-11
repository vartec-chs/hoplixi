import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/dao/icons_dao.dart';
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

  List<store.IconData> _currentPageIcons = [];
  PaginationInfo? _paginationInfo;
  IconType? _selectedType;
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 0;
  final IconSortBy _sortBy = IconSortBy.name;
  final bool _ascending = true;

  // Таймер для дебаунсинга поиска
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Откладываем загрузку данных до завершения построения виджета
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCurrentPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentPage() async {
    if (!mounted) return;

    // Безопасно устанавливаем состояние загрузки
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final iconsDao = ref.read(iconsDaoProvider);

      // Загружаем иконки для текущей страницы
      final icons = await iconsDao.getIconsPaginated(
        page: _currentPage,
        pageSize: widget.pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        typeFilter: _selectedType,
        sortBy: _sortBy,
        ascending: _ascending,
      );

      // Загружаем информацию о пагинации
      final paginationInfo = await iconsDao.getPaginationInfo(
        page: _currentPage,
        pageSize: widget.pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        typeFilter: _selectedType,
      );

      if (mounted) {
        setState(() {
          _currentPageIcons = icons;
          _paginationInfo = paginationInfo;
          _isLoading = false; // Устанавливаем загрузку в false здесь
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки иконок: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    // Отменяем предыдущий таймер если он есть
    _debounceTimer?.cancel();

    // Устанавливаем новый таймер с задержкой 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = query;
        _currentPage = 0;
      });

      _loadCurrentPage();

      // Переходим на первую страницу
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onTypeFilterChanged(IconType? type) {
    if (!mounted) return;

    // Используем post-frame callback для безопасного обновления состояния
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _selectedType = type;
        _currentPage = 0;
      });

      _loadCurrentPage();

      // Переходим на первую страницу
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToPage(int page) {
    if (!mounted) return;
    if (_paginationInfo != null &&
        page >= 0 &&
        page < _paginationInfo!.totalPages) {
      // Используем post-frame callback для безопасного обновления состояния
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() => _currentPage = page);
        _loadCurrentPage();

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
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
          if (_paginationInfo != null && _paginationInfo!.totalPages > 1) ...[
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
    if (_currentPageIcons.isEmpty && !_isLoading) {
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

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _currentPageIcons.length,
      itemBuilder: (context, index) {
        final icon = _currentPageIcons[index];
        return SelectableIconCard(
          icon: icon,
          isSelected: icon.id == widget.selectedIconId,
          onTap: () => widget.onIconSelected(icon.id, icon),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    if (_paginationInfo == null) return const SizedBox.shrink();

    final totalPages = _paginationInfo!.totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Предыдущая страница
        IconButton(
          onPressed: _paginationInfo!.hasPreviousPage
              ? () => _goToPage(_currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),

        // Номера страниц
        ...List.generate(
          totalPages.clamp(0, 5), // Показываем максимум 5 страниц
          (index) {
            int pageIndex;
            if (totalPages <= 5) {
              pageIndex = index;
            } else {
              // Умная пагинация для большого количества страниц
              if (_currentPage < 3) {
                pageIndex = index;
              } else if (_currentPage >= totalPages - 3) {
                pageIndex = totalPages - 5 + index;
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
          onPressed: _paginationInfo!.hasNextPage
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
