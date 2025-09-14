import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../passwords_list_section/passwords_list.dart';
import '../filter_section/filter_section_controller.dart';
import '../passwords_list_section/passwords_list_controller.dart';

/// Пример интеграции компонентов списка паролей
/// Показывает, как использовать созданные контроллеры и виджеты
class PasswordsListIntegrationExample extends ConsumerWidget {
  const PasswordsListIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер паролей'),
        actions: [
          // Кнопка добавления нового пароля
          IconButton(
            onPressed: () => _navigateToAddPassword(context, ref),
            icon: const Icon(Icons.add),
            tooltip: 'Добавить пароль',
          ),
        ],
      ),
      body: Column(
        children: [
          // Секция поиска
          _buildSearchSection(ref),

          // Секция фильтров (tabs)
          _buildFilterTabs(ref),

          // Отображение активных фильтров
          _buildActiveFilters(ref),

          // Основной список паролей
          const Expanded(child: PasswordsList()),
        ],
      ),
      // FAB для быстрого добавления
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPassword(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Добавить пароль',
      ),
    );
  }

  /// Секция поиска
  Widget _buildSearchSection(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchBar(
        hintText: 'Поиск паролей...',
        leading: const Icon(Icons.search),
        onChanged: (query) {
          ref
              .read(filterSectionControllerProvider.notifier)
              .updateSearchQuery(query);
        },
        trailing: [
          IconButton(
            onPressed: () => _showFilterDialog(ref),
            icon: const Icon(Icons.tune),
            tooltip: 'Дополнительные фильтры',
          ),
        ],
      ),
    );
  }

  /// Секция вкладок фильтрации
  Widget _buildFilterTabs(WidgetRef ref) {
    final filterState = ref.watch(filterSectionControllerProvider);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: FilterTab.values.map((tab) {
          final isActive = filterState.activeTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(filterSectionControllerProvider.notifier)
                  .switchTab(tab),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(ref.context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(ref.context).colorScheme.primary
                        : Theme.of(
                            ref.context,
                          ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: isActive
                          ? Theme.of(ref.context).colorScheme.primary
                          : Theme.of(
                              ref.context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tab.label,
                      style: Theme.of(ref.context).textTheme.labelSmall
                          ?.copyWith(
                            color: isActive
                                ? Theme.of(ref.context).colorScheme.primary
                                : Theme.of(
                                    ref.context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Отображение активных фильтров
  Widget _buildActiveFilters(WidgetRef ref) {
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
    final searchQuery = ref.watch(
      filterSectionControllerProvider.select((s) => s.searchQuery),
    );

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Theme.of(ref.context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          if (searchQuery.isNotEmpty) ...[
            _FilterChip(
              label: 'Поиск: $searchQuery',
              onRemove: () => ref
                  .read(filterSectionControllerProvider.notifier)
                  .updateSearchQuery(''),
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: () => ref
                .read(filterSectionControllerProvider.notifier)
                .resetFilters(),
            child: const Text('Сбросить все'),
          ),
        ],
      ),
    );
  }

  /// Показать диалог дополнительных фильтров
  void _showFilterDialog(WidgetRef ref) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Дополнительные фильтры'),
        content: const Text(
          'Здесь будет интерфейс для настройки фильтров по категориям, тегам и датам',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              // Применить фильтры
              Navigator.of(context).pop();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  /// Навигация к добавлению нового пароля
  void _navigateToAddPassword(BuildContext context, WidgetRef ref) {
    // Пример навигации с callback для обновления списка
    Navigator.of(context).pushNamed('/password-add').then((result) {
      if (result == true) {
        // Уведомляем о создании нового пароля
        ref.read(passwordChangeNotifierProvider)();

        // Показываем snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароль успешно создан!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}

/// Виджет для отображения активного фильтра
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      deleteIconColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }
}

/// Пример использования в main.dart или router
class PasswordsApp extends StatelessWidget {
  const PasswordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Hoplixi Password Manager',
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        home: const PasswordsListIntegrationExample(),
        routes: {
          '/password-add': (context) =>
              const Placeholder(), // Ваша форма добавления
          '/password-edit': (context) =>
              const Placeholder(), // Ваша форма редактирования
        },
      ),
    );
  }
}
