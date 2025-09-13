import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/filter_section/filter_section_controller.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/filter_section/widgets/filter_modal.dart';

/// Виджет секции фильтрации для паролей
class FilterSection extends ConsumerStatefulWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Высота секции (по умолчанию 160)
  final double? height;

  const FilterSection({super.key, this.onMenuPressed, this.height});

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

    return Container(
      height: widget.height ?? 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header с поиском и кнопками
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Кнопка меню
                IconButton(
                  onPressed: widget.onMenuPressed,
                  icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                  tooltip: 'Меню',
                ),
                const SizedBox(width: 8),

                // Поле поиска
                Expanded(
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

                const SizedBox(width: 8),

                // Кнопка фильтров
                Container(
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
            ),
          ),

          // TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.secondary,
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
              unselectedLabelStyle: theme.textTheme.bodyMedium,
              padding: const EdgeInsets.all(4),
              tabs: FilterTab.values.map((tab) {
                return Tab(text: tab.label, height: 40);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
