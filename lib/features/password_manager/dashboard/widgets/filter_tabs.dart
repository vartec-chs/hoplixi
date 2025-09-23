import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/filter_tab.dart';
import '../providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tabs_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Виджет для отображения вкладок фильтров
/// Управляет состоянием активной вкладки через провайдер
class FilterTabs extends ConsumerStatefulWidget {
  /// Callback при изменении активной вкладки
  final ValueChanged<FilterTab>? onTabChanged;

  /// Пользовательский стиль для TabBar
  final TabBarTheme? tabBarTheme;

  /// Высота TabBar
  final double height;

  /// Отступы для лейблов
  final EdgeInsets labelPadding;

  /// Радиус скругления
  final double borderRadius;

  const FilterTabs({
    super.key,
    this.onTabChanged,
    this.tabBarTheme,
    this.height = 40,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    this.borderRadius = 12,
  });

  @override
  ConsumerState<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends ConsumerState<FilterTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<FilterTab> _currentTabs = [];

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер с минимальной длиной
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
  }

  void _updateTabController() {
    final currentEntityType = ref.read(currentEntityTypeProvider);
    final newTabs = FilterTab.getAvailableTabsForEntity(currentEntityType);
    final currentTab = ref.read(filterTabsControllerProvider);

    // Если вкладки изменились, обновляем контроллер
    if (!_areTabsEqual(_currentTabs, newTabs)) {
      _currentTabs = newTabs;

      // Создаем новый TabController
      final oldController = _tabController;
      _tabController = TabController(length: _currentTabs.length, vsync: this);

      // Устанавливаем индекс активной вкладки
      final currentTabIndex = _currentTabs.indexOf(currentTab);
      if (currentTabIndex != -1) {
        _tabController.index = currentTabIndex;
      } else {
        // Если текущая вкладка недоступна, выбираем первую
        _tabController.index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(filterTabsControllerProvider.notifier)
              .changeTab(_currentTabs.first);
        });
      }

      // Добавляем слушатель для отслеживания изменений
      _tabController.addListener(_onTabChanged);

      // Освобождаем старый контроллер
      oldController.removeListener(_onTabChanged);
      oldController.dispose();

      logDebug(
        'FilterTabs: Обновлены вкладки',
        data: {
          'entityType': currentEntityType.id,
          'tabsCount': _currentTabs.length,
          'currentTabIndex': _tabController.index,
        },
      );
    }
  }

  bool _areTabsEqual(List<FilterTab> tabs1, List<FilterTab> tabs2) {
    if (tabs1.length != tabs2.length) return false;
    for (int i = 0; i < tabs1.length; i++) {
      if (tabs1[i] != tabs2[i]) return false;
    }
    return true;
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging &&
        _tabController.index >= 0 &&
        _tabController.index < _currentTabs.length) {
      final selectedTab = _currentTabs[_tabController.index];

      logDebug(
        'FilterTabs: Изменена вкладка',
        data: {'tabIndex': _tabController.index, 'tabLabel': selectedTab.label},
      );

      // Обновляем провайдер
      ref.read(filterTabsControllerProvider.notifier).changeTab(selectedTab);

      // Вызываем callback
      widget.onTabChanged?.call(selectedTab);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Слушаем изменения типа сущности
    ref.listen<EntityType>(currentEntityTypeProvider, (previous, next) {
      if (previous != next) {
        _updateTabController();
        setState(() {}); // Перестраиваем UI
      }
    });

    // Слушаем изменения активной вкладки извне
    ref.listen<FilterTab>(filterTabsControllerProvider, (previous, next) {
      if (previous != next) {
        final newIndex = _currentTabs.indexOf(next);
        if (newIndex != -1 && _tabController.index != newIndex) {
          _tabController.animateTo(newIndex);
        }
      }
    });

    if (_currentTabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: theme.colorScheme.surface,
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: _currentTabs.length > 3,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.colorScheme.tertiary,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        labelColor: theme.colorScheme.onTertiary,
        indicatorColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurface,
        splashFactory: InkRipple.splashFactory,
        indicatorAnimation: TabIndicatorAnimation.elastic,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
          theme.colorScheme.secondary.withValues(alpha: 0.6),
        ),
        physics: const BouncingScrollPhysics(),
        indicatorWeight: 2,
        labelStyle: theme.textTheme.bodyMedium,
        tabAlignment: _currentTabs.length > 3 ? TabAlignment.center : null,
        labelPadding: widget.labelPadding,
        splashBorderRadius: BorderRadius.circular(widget.borderRadius),
        tabs: _currentTabs.map((tab) {
          return Tab(
            icon: Icon(tab.icon, size: 18),
            text: tab.label,
            height: widget.height,
          );
        }).toList(),
      ),
    );
  }
}
