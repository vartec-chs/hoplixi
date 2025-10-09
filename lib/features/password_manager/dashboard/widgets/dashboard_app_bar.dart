import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/filter_tabs_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_type_dropdown.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/filter_modal.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/filter_tabs.dart';

/// Полноценный SliverAppBar для дашборда с фильтрацией и поиском
/// Включает drawer кнопку, выбор типа сущности, кнопку фильтров, поиск и вкладки
class DashboardSliverAppBar extends ConsumerStatefulWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Высота расширенного состояния
  final double expandedHeight;

  /// Высота свернутого состояния
  final double collapsedHeight;

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

  /// Callback при применении фильтров
  final VoidCallback? onFilterApplied;

  const DashboardSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.expandedHeight = 160.0,
    this.collapsedHeight = 60.0,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.showEntityTypeSelector = true,
    this.additionalActions,
    this.onFilterApplied,
  });

  @override
  ConsumerState<DashboardSliverAppBar> createState() =>
      _DashboardSliverAppBarState();
}

class _DashboardSliverAppBarState extends ConsumerState<DashboardSliverAppBar>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Инициализируем поисковое поле с текущим значением из фильтра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentQuery = ref.read(baseFilterProvider).query;
      if (currentQuery.isNotEmpty) {
        _searchController.text = currentQuery;
      }
    });

    logDebug('DashboardSliverAppBar: Инициализация');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Обновляем поисковый запрос в базовом фильтре с дебаунсом
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query) {
        ref.read(baseFilterProvider.notifier).updateQuery(query);
        logDebug('DashboardSliverAppBar: Обновлен поисковый запрос: $query');
      }
    });
  }

  void _openFilterModal() {
    logInfo('DashboardSliverAppBar: Открытие модального окна фильтров');

    showDialog(
      context: context,
      builder: (context) => FilterModal(
        onFilterApplied: () {
          logInfo('DashboardSliverAppBar: Фильтры применены');
          widget.onFilterApplied?.call();
        },
      ),
    );
  }

  String _getSearchHint(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return 'Поиск паролей по названию, URL, пользователю...';
      case EntityType.note:
        return 'Поиск заметок по заголовку, содержимому...';
      case EntityType.otp:
        return 'Поиск OTP по издателю, аккаунту...';
    }
  }

  bool _hasActiveConstraints(dynamic baseFilter) {
    return baseFilter.query.isNotEmpty ||
        baseFilter.categoryIds.isNotEmpty ||
        baseFilter.tagIds.isNotEmpty ||
        baseFilter.isFavorite != null ||
        baseFilter.isArchived != null ||
        baseFilter.hasNotes != null ||
        baseFilter.createdAfter != null ||
        baseFilter.createdBefore != null ||
        baseFilter.modifiedAfter != null ||
        baseFilter.modifiedBefore != null ||
        baseFilter.lastAccessedAfter != null ||
        baseFilter.lastAccessedBefore != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final baseFilter = ref.watch(baseFilterProvider);
    final availableTabs = ref.watch(availableFilterTabsProvider);

    // Синхронизируем поисковое поле с провайдером
    if (_searchController.text != baseFilter.query) {
      _searchController.text = baseFilter.query;
    }

    // Слушаем изменения типа сущности для синхронизации вкладок
    ref.listen(currentEntityTypeProvider, (previous, next) {
      if (previous != next) {
        ref.read(filterTabsControllerProvider.notifier).syncWithEntityType();
        logDebug(
          'DashboardSliverAppBar: Синхронизация с типом сущности: ${next.label}',
        );
      }
    });

    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.surface,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: theme.brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      expandedHeight: widget.expandedHeight,
      collapsedHeight: widget.collapsedHeight,
      pinned: widget.pinned,
      floating: widget.floating,
      snap: widget.snap,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,

      // Кнопка открытия drawer слева
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: widget.onMenuPressed,
        tooltip: 'Открыть меню',
      ),

      // Actions справа: выбор типа сущности и кнопка фильтров
      actions: [
        if (widget.showEntityTypeSelector) ...[
          // Компактный селектор типа сущности
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: EntityTypeCompactDropdown(
              onEntityTypeChanged: (entityType) {
                logInfo(
                  'DashboardSliverAppBar: Изменен тип сущности: ${entityType.label}',
                );
              },
            ),
          ),
        ],

        // Кнопка открытия модального окна фильтров
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              // Индикатор активных фильтров
              if (_hasActiveConstraints(baseFilter))
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openFilterModal,
          tooltip: 'Открыть фильтры',
        ),

        // Дополнительные actions
        if (widget.additionalActions != null) ...widget.additionalActions!,

        const SizedBox(width: 8),
      ],

      // Заголовок в свернутом состоянии
      title: Text(
        currentEntityType.label,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Расширенный контент
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Верхняя часть с заголовком (занимает место collapsed height)
                // SizedBox(
                //   height: widget.collapsedHeight,
                //   child: Center(
                //     child: Text(
                //       'Менеджер паролей Hoplixi',
                //       style: theme.textTheme.headlineSmall?.copyWith(
                //         fontWeight: FontWeight.w700,
                //         color: theme.colorScheme.onSurface,
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 50),

                // Нижняя часть с поиском и вкладками
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        // Поле поиска
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: PrimaryTextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            hintText: _getSearchHint(currentEntityType),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            decoration:
                                primaryInputDecoration(
                                  context,
                                  hintText: _getSearchHint(currentEntityType),
                                ).copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                          ),
                        ),

                        // Вкладки фильтров
                        if (availableTabs.isNotEmpty) ...[
                          FilterTabs(
                            height: 42,
                            borderRadius: 8,
                            // labelPadding: const EdgeInsets.symmetric(
                            //   horizontal: 12,
                            //   vertical: 6,
                            // ),
                            onTabChanged: (tab) {
                              logInfo(
                                'DashboardSliverAppBar: Изменена вкладка: ${tab.label}',
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
      ),
    );
  }
}

/// Компактная версия DashboardSliverAppBar для использования в различных экранах
class CompactDashboardSliverAppBar extends ConsumerWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Заголовок
  final String title;

  /// Дополнительные actions
  final List<Widget>? actions;

  /// Показывать ли кнопку фильтров
  final bool showFilterButton;

  /// Callback при открытии фильтров
  final VoidCallback? onFilterPressed;

  const CompactDashboardSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.title = 'Hoplixi',
    this.actions,
    this.showFilterButton = false,
    this.onFilterPressed,
  });

  bool _hasActiveConstraints(dynamic baseFilter) {
    return baseFilter.query.isNotEmpty ||
        baseFilter.categoryIds.isNotEmpty ||
        baseFilter.tagIds.isNotEmpty ||
        baseFilter.isFavorite != null ||
        baseFilter.isArchived != null ||
        baseFilter.hasNotes != null ||
        baseFilter.createdAfter != null ||
        baseFilter.createdBefore != null ||
        baseFilter.modifiedAfter != null ||
        baseFilter.modifiedBefore != null ||
        baseFilter.lastAccessedAfter != null ||
        baseFilter.lastAccessedBefore != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseFilter = ref.watch(baseFilterProvider);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,

      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
        tooltip: 'Открыть меню',
      ),

      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      actions: [
        if (showFilterButton) ...[
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveConstraints(baseFilter))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onFilterPressed,
            tooltip: 'Фильтры',
          ),
        ],
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}
