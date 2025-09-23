import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tabs_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';

/// Демонстрационный экран для DashboardSliverAppBar
/// Показывает полнофункциональный SliverAppBar с фильтрацией и поиском
class DashboardSliverAppBarExampleScreen extends ConsumerWidget {
  const DashboardSliverAppBarExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final baseFilter = ref.watch(baseFilterProvider);
    final currentTab = ref.watch(filterTabsControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Полнофункциональный SliverAppBar
          DashboardSliverAppBar(
            onMenuPressed: () {
              logInfo('DashboardSliverAppBarExample: Открытие drawer');
              // Scaffold.of(context).openDrawer();
            },
            onFilterApplied: () {
              logInfo('DashboardSliverAppBarExample: Фильтры применены');
            },
            expandedHeight: 180.0,
            collapsedHeight: 60.0,
            pinned: true,
            floating: false,
            snap: false,
            showEntityTypeSelector: true,
            // additionalActions: [
            //   IconButton(
            //     icon: const Icon(Icons.settings),
            //     onPressed: () {
            //       logInfo('DashboardSliverAppBarExample: Открытие настроек');
            //     },
            //     tooltip: 'Настройки',
            //   ),
            //   IconButton(
            //     icon: const Icon(Icons.help_outline),
            //     onPressed: () {
            //       logInfo('DashboardSliverAppBarExample: Открытие справки');
            //     },
            //     tooltip: 'Справка',
            //   ),
            // ],
          ),

          // Заголовок контента
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Демонстрация DashboardSliverAppBar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Полнофункциональный SliverAppBar с поиском, фильтрами и вкладками',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Информация о текущем состоянии
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Текущее состояние',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoSection(
                        context,
                        'Тип сущности',
                        currentEntityType.label,
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoSection(
                        context,
                        'Активная вкладка',
                        currentTab.label,
                        icon: currentTab.icon,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoSection(
                        context,
                        'Поисковый запрос',
                        baseFilter.query.isNotEmpty
                            ? baseFilter.query
                            : 'Не задан',
                        icon: Icons.search,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoSection(
                        context,
                        'Активные фильтры',
                        _getActiveFiltersCount(baseFilter).toString(),
                        icon: Icons.filter_list,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Контент страницы - список элементов для демонстрации скроллинга
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text('Элемент ${index + 1}'),
                    subtitle: Text(
                      'Описание элемента ${index + 1} для демонстрации',
                    ),
                    trailing: Icon(
                      _getEntityIcon(currentEntityType),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      logInfo(
                        'DashboardSliverAppBarExample: Нажат элемент ${index + 1}',
                      );
                    },
                  ),
                );
              },
              childCount: 50, // Много элементов для демонстрации скроллинга
            ),
          ),

          // Нижний отступ
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // Drawer для демонстрации интеграции
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hoplixi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Менеджер паролей',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Дашборд'),
              onTap: () {
                Navigator.pop(context);
                logInfo('DashboardSliverAppBarExample: Переход в дашборд');
              },
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Пароли'),
              onTap: () {
                Navigator.pop(context);
                final currentType = ref.read(currentEntityTypeProvider);
                final newType = currentType == EntityType.password
                    ? EntityType.note
                    : EntityType.password;
                ref
                    .read(entityTypeControllerProvider.notifier)
                    .changeEntityType(newType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('Заметки'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(entityTypeControllerProvider.notifier)
                    .changeEntityType(EntityType.note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('OTP'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(entityTypeControllerProvider.notifier)
                    .changeEntityType(EntityType.otp);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
                logInfo('DashboardSliverAppBarExample: Открытие настроек');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Помощь'),
              onTap: () {
                Navigator.pop(context);
                logInfo('DashboardSliverAppBarExample: Открытие помощи');
              },
            ),
          ],
        ),
      ),

      // Floating Action Button для дополнительных действий
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Демонстрация программного сброса фильтров
          ref.read(baseFilterProvider.notifier).reset();
          logInfo('DashboardSliverAppBarExample: Сброс всех фильтров');
        },
        tooltip: 'Сбросить фильтры',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getActiveFiltersCount(dynamic baseFilter) {
    int count = 0;
    if (baseFilter.query.isNotEmpty) count++;
    if (baseFilter.categoryIds.isNotEmpty) count++;
    if (baseFilter.tagIds.isNotEmpty) count++;
    if (baseFilter.isFavorite != null) count++;
    if (baseFilter.isArchived != null) count++;
    if (baseFilter.hasNotes != null) count++;
    if (baseFilter.createdAfter != null || baseFilter.createdBefore != null)
      count++;
    if (baseFilter.modifiedAfter != null || baseFilter.modifiedBefore != null)
      count++;
    if (baseFilter.lastAccessedAfter != null ||
        baseFilter.lastAccessedBefore != null)
      count++;
    return count;
  }

  IconData _getEntityIcon(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return Icons.password;
      case EntityType.note:
        return Icons.note;
      case EntityType.otp:
        return Icons.security;
    }
  }
}

/// Компактная версия примера для демонстрации CompactDashboardSliverAppBar
class CompactDashboardSliverAppBarExampleScreen extends ConsumerWidget {
  const CompactDashboardSliverAppBarExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Компактный SliverAppBar
          CompactDashboardSliverAppBar(
            title: 'Компактный дашборд',
            showFilterButton: true,
            onMenuPressed: () {
              logInfo('CompactDashboardSliverAppBarExample: Открытие drawer');
              Scaffold.of(context).openDrawer();
            },
            onFilterPressed: () {
              logInfo('CompactDashboardSliverAppBarExample: Открытие фильтров');
            },
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  logInfo(
                    'CompactDashboardSliverAppBarExample: Добавление элемента',
                  );
                },
                tooltip: 'Добавить',
              ),
            ],
          ),

          // Контент
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Компактный дашборд',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Упрощенная версия SliverAppBar\nдля использования в других экранах',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: const Drawer(
        child: Center(child: Text('Drawer для компактного дашборда')),
      ),
    );
  }
}
