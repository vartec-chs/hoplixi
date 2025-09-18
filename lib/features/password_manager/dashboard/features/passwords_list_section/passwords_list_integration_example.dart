import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../passwords_list_section/passwords_list.dart';
import '../filter_section/filter_section_controller.dart';
import '../passwords_list_section/passwords_stream_provider.dart';

/// Пример интеграции компонентов списка паролей с новым StreamProvider подходом
/// Демонстрирует использование реактивных провайдеров для управления состоянием
class PasswordsListIntegrationExample extends ConsumerWidget {
  const PasswordsListIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Наблюдаем за состоянием через AsyncValue
    final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер паролей'),
        actions: [
          // Показываем индикатор загрузки в AppBar при обновлении
          if (asyncPasswords.isRefreshing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

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
          _buildFilterTabs(ref, context),

          // Отображение активных фильтров
          _buildActiveFilters(ref, context),

          // Статистика паролей
          _buildPasswordsStats(ref, context),

          // Основной список паролей
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(passwordsActionsProvider).refreshPasswords();
              },
              child: const CustomScrollView(slivers: [PasswordsList()]),
            ),
          ),
        ],
      ),
      // FAB для быстрого добавления
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPassword(context, ref),
        tooltip: 'Добавить пароль',
        child: const Icon(Icons.add),
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
  Widget _buildFilterTabs(WidgetRef ref, BuildContext context) {
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
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tab.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
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
  Widget _buildActiveFilters(WidgetRef ref, BuildContext context) {
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
            color: Theme.of(context).colorScheme.primary,
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

  /// Статистика паролей
  Widget _buildPasswordsStats(WidgetRef ref, BuildContext context) {
    final totalCount = ref.watch(passwordsTotalCountProvider);
    final isLoading = ref.watch(isPasswordsLoadingProvider);
    final hasData = ref.watch(hasPasswordsDataProvider);

    if (!hasData && !isLoading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            isLoading
                ? 'Загрузка...'
                : 'Найдено: $totalCount ${_getPasswordsLabel(totalCount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Получение правильного склонения для слова "пароль"
  String _getPasswordsLabel(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'пароль';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'пароля';
    } else {
      return 'паролей';
    }
  }

  /// Показать диалог дополнительных фильтров
  void _showFilterDialog(WidgetRef ref) {
    // Нужен BuildContext, получим его через Consumer
  }

  /// Показать диалог дополнительных фильтров с контекстом
  void _showFilterDialogWithContext(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дополнительные фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Здесь будет интерфейс для настройки фильтров по категориям, тегам и датам',
            ),
            const SizedBox(height: 16),
            // Пример расширенной информации о текущем состоянии
            Consumer(
              builder: (context, ref, child) {
                final currentFilter = ref.watch(currentPasswordFilterProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущий фильтр:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Поисковый запрос: "${currentFilter.query}"'),
                    if (currentFilter.isFavorite != null)
                      Text(
                        'Избранные: ${currentFilter.isFavorite! ? "Да" : "Нет"}',
                      ),
                    if (currentFilter.isFrequent != null)
                      Text(
                        'Часто используемые: ${currentFilter.isFrequent! ? "Да" : "Нет"}',
                      ),
                  ],
                );
              },
            ),
          ],
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
        // В новом подходе обновление происходит автоматически через StreamProvider
        // Но можно показать snackbar для подтверждения
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

/// Пример использования в main.dart или router с новым подходом
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

/// Пример демо-виджета для тестирования нового подхода
class StreamProviderDemo extends ConsumerWidget {
  const StreamProviderDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreamProvider Demo')),
      body: Column(
        children: [
          // Показываем состояние AsyncValue
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Состояние StreamProvider:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final asyncPasswords = ref.watch(
                        filteredPasswordsStreamProvider,
                      );

                      return asyncPasswords.when(
                        loading: () => const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Загрузка данных...'),
                          ],
                        ),
                        error: (error, stackTrace) => Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text('Ошибка: $error'),
                          ],
                        ),
                        data: (passwords) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text('Загружено ${passwords.length} паролей'),
                              ],
                            ),
                            if (asyncPasswords.isRefreshing) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Обновление...'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Кнопки управления
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(passwordsActionsProvider).refreshPasswords();
                  },
                  child: const Text('Обновить'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(passwordsActionsProvider).searchPasswords('test');
                  },
                  child: const Text('Поиск "test"'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(passwordsActionsProvider).searchPasswords('');
                  },
                  child: const Text('Очистить поиск'),
                ),
              ],
            ),
          ),

          // Миниатюрный список
          Expanded(child: const CustomScrollView(slivers: [PasswordsList()])),
        ],
      ),
    );
  }
}
