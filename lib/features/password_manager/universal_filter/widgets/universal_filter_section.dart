import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/universal_filter_modal.dart';

/// Универсальный виджет секции фильтрации для любых типов записей
/// Использует SliverAppBar для создания коллапсирующегося интерфейса
class UniversalFilterSection extends ConsumerStatefulWidget {
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

  /// Показывать ли selector типа сущности
  final bool showEntityTypeSelector;

  /// Дополнительные actions в AppBar
  final List<Widget>? additionalActions;

  const UniversalFilterSection({
    super.key,
    this.onMenuPressed,
    this.expandedHeight,
    this.collapsedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.showEntityTypeSelector = true,
    this.additionalActions,
  });

  @override
  ConsumerState<UniversalFilterSection> createState() =>
      _UniversalFilterSectionState();
}

class _UniversalFilterSectionState extends ConsumerState<UniversalFilterSection>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late final TextEditingController _searchController;
  List<UniversalFilterTab> _currentTabs = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Инициализируем TabController после первого build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTabController();

      // Синхронизируем начальное состояние поискового поля
      final initialQuery = ref
          .read(universalFilterControllerProvider)
          .searchQuery;
      if (_searchController.text != initialQuery) {
        _searchController.text = initialQuery;
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeTabController() {
    final availableTabs = ref.read(availableFilterTabsProvider);

    // Проверяем, нужно ли пересоздавать контроллер
    if (_tabController?.length != availableTabs.length ||
        !_tabsEqual(_currentTabs, availableTabs)) {
      _tabController?.dispose();
      _currentTabs = List.from(availableTabs);
      _tabController = TabController(length: _currentTabs.length, vsync: this);

      // Устанавливаем правильный индекс для активной вкладки
      final filterState = ref.read(universalFilterControllerProvider);
      final targetIndex = _currentTabs.indexOf(filterState.activeTab);
      if (targetIndex >= 0 && targetIndex < _currentTabs.length) {
        _tabController!.index = targetIndex;
      }

      // Слушаем изменения в табах
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging && mounted) {
          if (_tabController!.index < _currentTabs.length) {
            final tab = _currentTabs[_tabController!.index];
            ref.read(universalFilterControllerProvider.notifier).switchTab(tab);
          }
        }
      });

      // Обновляем состояние
      if (mounted) {
        setState(() {});
      }
    }
  }

  bool _tabsEqual(List<UniversalFilterTab> a, List<UniversalFilterTab> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showFilterModal() async {
    final currentFilter = ref.read(universalFilterControllerProvider).filter;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UniversalFilterModal(
        initialFilter: currentFilter,
        onFilterApplied: (filter) {
          ref
              .read(universalFilterControllerProvider.notifier)
              .applyFilter(filter);
          logDebug('Applied filter: $filter');
          // Navigator.of(context).pop(true);
        },
        // onCancel: () => Navigator.of(context).pop(false),
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
    final filterState = ref.watch(universalFilterControllerProvider);
    final controller = ref.read(universalFilterControllerProvider.notifier);
    final entityType = ref.watch(currentEntityTypeProvider);
    final availableTabs = ref.watch(availableFilterTabsProvider);

    // Синхронизируем TabController с доступными вкладками
    if (_tabController?.length != availableTabs.length ||
        !_tabsEqual(_currentTabs, availableTabs)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeTabController();
      });
    }

    // Синхронизируем TabController с состоянием только если контроллер готов
    if (_tabController != null && _currentTabs.isNotEmpty) {
      final targetIndex = _currentTabs.indexOf(filterState.activeTab);
      if (targetIndex >= 0 &&
          targetIndex < _currentTabs.length &&
          _tabController!.index != targetIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabController != null &&
              targetIndex >= 0 &&
              targetIndex < _tabController!.length) {
            _tabController!.animateTo(targetIndex);
          }
        });
      }
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
      expandedHeight: widget.expandedHeight ?? 180.0,
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
        // Селектор типа сущности
        if (widget.showEntityTypeSelector)
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<UniversalEntityType>(
              value: entityType,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),

              items: UniversalEntityType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label, style: theme.textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: (newType) {
                if (newType != null) {
                  ref
                      .read(entityTypeControllerProvider.notifier)
                      .changeEntityType(newType);
                }
              },
            ),
          ),

        // Дополнительные actions
        if (widget.additionalActions != null) ...widget.additionalActions!,

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
                  Icons.filter_list,
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
            bottom: 58.0,
          ),
          child: Column(
            children: [
              // Поле поиска
              Expanded(
                child: Center(
                  child: PrimaryTextField(
                    controller: _searchController,
                    hintText: _getSearchHint(entityType),
                    onChanged: (value) {
                      controller.updateSearchQuery(value);
                    },
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              controller.updateSearchQuery('');
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: 'Очистить поиск',
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: (_tabController != null && _currentTabs.isNotEmpty)
              ? TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurface,
                  dividerColor: Colors.transparent,
                  tabs: _currentTabs.map((tab) {
                    return Tab(
                      icon: Icon(tab.icon, size: 20),
                      text: tab.label,
                      height: 44,
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  String _getSearchHint(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Поиск по паролям, логинам, URL...';
      case UniversalEntityType.note:
        return 'Поиск по заметкам, заголовкам...';
      case UniversalEntityType.otp:
        return 'Поиск по OTP, аккаунтам...';
      case UniversalEntityType.attachment:
        return 'Поиск по вложениям, именам файлов...';
    }
  }
}
