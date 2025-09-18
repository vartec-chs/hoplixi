import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/filter_section/filter_section_controller.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/filter_section/widgets/filter_modal.dart';

/// Виджет секции фильтрации для паролей использующий SliverAppBar
class FilterSection extends ConsumerStatefulWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Высота расширенного состояния (по умолчанию 120)
  final double? expandedHeight;

  /// Высота свернутого состояния (по умолчанию 60)
  final double? collapsedHeight;

  /// Должен ли AppBar быть закрепленным при прокрутке
  final bool pinned;

  /// Должен ли AppBar плавать при прокрутке
  final bool floating;

  /// Должен ли AppBar быстро появляться при прокрутке вверх
  final bool snap;

  const FilterSection({
    super.key,
    this.onMenuPressed,
    this.expandedHeight,
    this.collapsedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
  });

  @override
  ConsumerState<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends ConsumerState<FilterSection>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();

    // Слушаем изменения в табах
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tab = FilterTab.values[_tabController.index];
        ref.read(filterSectionControllerProvider.notifier).switchTab(tab);
      }
    });

    // Синхронизируем начальное состояние поискового поля
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQuery = ref
          .read(filterSectionControllerProvider)
          .searchQuery;
      if (_searchController.text != initialQuery) {
        _searchController.text = initialQuery;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() async {
    final currentFilter = ref.read(filterSectionControllerProvider).filter;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FilterModal(
        initialFilter: currentFilter,
        onApply: (filter) {
          ref
              .read(filterSectionControllerProvider.notifier)
              .applyFilter(filter);
          Navigator.of(context).pop(true);
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    // Результат не используется, но сохраняем для будущих улучшений
    if (result == true) {
      // Фильтр применен
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(filterSectionControllerProvider);
    final controller = ref.read(filterSectionControllerProvider.notifier);

    // Синхронизируем TabController с состоянием
    final targetIndex = FilterTab.values.indexOf(filterState.activeTab);
    if (_tabController.index != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController.index != targetIndex) {
          _tabController.animateTo(targetIndex);
        }
      });
    }

    // Синхронизируем текст поиска
    if (_searchController.text != filterState.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchController.text != filterState.searchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: filterState.searchQuery,
            selection: TextSelection.collapsed(
              offset: filterState.searchQuery.length,
            ),
          );
        }
      });
    }

    return SliverAppBar(
      expandedHeight: widget.expandedHeight ?? 120.0,
      collapsedHeight: widget.collapsedHeight ?? 60.0,
      floating: widget.floating,
      pinned: widget.pinned,
      snap: widget.snap,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      leading: widget.onMenuPressed != null
          ? Builder(
              builder: (context) => IconButton(
                onPressed: widget.onMenuPressed,
                icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                tooltip: 'Меню',
              ),
            )
          : null,
      actions: [
        // Кнопка фильтров
        Container(
          margin: const EdgeInsets.only(right: 16.0),
          decoration: BoxDecoration(
            color: filterState.hasActiveFilters
                ? theme.colorScheme.primary
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _showFilterModal,
            icon: Stack(
              children: [
                Icon(
                  Icons.tune,
                  color: filterState.hasActiveFilters
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimaryContainer,
                ),
                if (filterState.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Фильтры',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 60.0,
            bottom: 0.0,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.secondary,

                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondaryContainer,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: theme.colorScheme.onSecondary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                    0.7,
                  ),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  indicatorColor: theme.colorScheme.onSecondary,
                  // isScrollable: true,
                  indicatorWeight: 3,
                  overlayColor: WidgetStateProperty.all(
                    theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                  splashBorderRadius: BorderRadius.circular(10),

                  unselectedLabelStyle: theme.textTheme.bodyMedium,
                  padding: const EdgeInsets.all(4),
                  splashFactory: InkRipple.splashFactory,
                  tabAlignment: TabAlignment.fill,
                  automaticIndicatorColorAdjustment: true,
                  tabs: FilterTab.values.map((tab) {
                    return Tab(
                      text: tab.label,
                      // icon: Icon(tab.icon),
                      height: 30,
                    );
                  }).toList(),
                ),
              ),

              // Поле поиска
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PrimaryTextField(
            controller: _searchController,
            onChanged: (value) {
              controller.updateSearchQuery(value);
            },
            hintText: 'Поиск паролей...',
            prefixIcon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
