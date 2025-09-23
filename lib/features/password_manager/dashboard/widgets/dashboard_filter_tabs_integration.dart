import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/filter_tabs.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tabs_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Пример интеграции FilterTabs в дашборд
/// Показывает, как использовать компонент вкладок фильтров
class DashboardFilterTabsIntegration extends ConsumerWidget {
  const DashboardFilterTabsIntegration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения типа сущности
    ref.listen(currentEntityTypeProvider, (previous, next) {
      if (previous != next) {
        logDebug(
          'DashboardFilterTabsIntegration: Изменение типа сущности',
          data: {'previousType': previous?.id, 'newType': next.id},
        );

        // Синхронизируем вкладки с новым типом сущности
        ref.read(filterTabsControllerProvider.notifier).syncWithEntityType();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Фильтры',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),

        // Компонент вкладок фильтров
        const FilterTabs(),

        // Разделитель
        const Divider(height: 1),

        // Контент в зависимости от выбранной вкладки
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final currentTab = ref.watch(filterTabsControllerProvider);
              final entityType = ref.watch(currentEntityTypeProvider);

              return _buildTabContent(context, currentTab, entityType);
            },
          ),
        ),
      ],
    );
  }

  /// Строит контент для текущей вкладки
  Widget _buildTabContent(
    BuildContext context,
    dynamic currentTab,
    dynamic entityType,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Выбрана вкладка: ${currentTab.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Тип сущности: ${entityType.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Здесь будет отображаться\nотфильтрованный контент',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пример простой интеграции только компонента вкладок
class SimpleFilterTabsExample extends ConsumerWidget {
  const SimpleFilterTabsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пример FilterTabs'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Column(
        children: [
          // Компонент вкладок
          FilterTabs(),

          // Основной контент
          Expanded(child: Center(child: Text('Основной контент дашборда'))),
        ],
      ),
    );
  }
}

/// Пример кастомной интеграции с дополнительными элементами управления
class AdvancedFilterTabsExample extends ConsumerWidget {
  const AdvancedFilterTabsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с действиями
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фильтры и поиск',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Сброс фильтров
                    ref
                        .read(filterTabsControllerProvider.notifier)
                        .syncWithEntityType();

                    logDebug('AdvancedFilterTabsExample: Сброс фильтров');
                  },
                  tooltip: 'Сбросить фильтры',
                ),
              ],
            ),
          ),

          // Компонент вкладок
          const FilterTabs(),

          // Дополнительные элементы управления
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    // Открытие расширенных фильтров
                    logDebug(
                      'AdvancedFilterTabsExample: Открытие расширенных фильтров',
                    );
                  },
                  tooltip: 'Расширенные фильтры',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
