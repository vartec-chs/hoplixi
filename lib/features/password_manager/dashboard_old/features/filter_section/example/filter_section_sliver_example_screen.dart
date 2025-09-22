import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/features/filter_section/filter_section.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/features/filter_section/filter_section_controller.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';

/// Пример экрана с использованием FilterSection как SliverAppBar
class FilterSectionExampleScreen extends ConsumerWidget {
  const FilterSectionExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterSectionControllerProvider);
    final currentFilter = ref.watch(currentPasswordFilterProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);

    return Scaffold(
      drawer: const Drawer(child: Center(child: Text('Drawer Content'))),
      body: CustomScrollView(
        slivers: [
          // Секция фильтрации как SliverAppBar
          FilterSection(
            onMenuPressed: () {
              Scaffold.of(context).openDrawer();
            },
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 120.0,
            collapsedHeight: 60.0,
          ),

          // Контент в виде SliverPadding + SliverList
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Текущее состояние фильтрации:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  context,
                  title: 'Активная вкладка',
                  content: filterState.activeTab.label,
                ),

                _buildInfoCard(
                  context,
                  title: 'Поисковый запрос',
                  content: filterState.searchQuery.isEmpty
                      ? 'Нет'
                      : '"${filterState.searchQuery}"',
                ),

                _buildInfoCard(
                  context,
                  title: 'Есть активные фильтры',
                  content: hasActiveFilters ? 'Да' : 'Нет',
                ),

                _buildInfoCard(
                  context,
                  title: 'Категории',
                  content: currentFilter.categoryIds.isEmpty
                      ? 'Не выбраны'
                      : currentFilter.categoryIds.length.toString(),
                ),

                _buildInfoCard(
                  context,
                  title: 'Теги',
                  content: currentFilter.tagIds.isEmpty
                      ? 'Не выбраны'
                      : currentFilter.tagIds.length.toString(),
                ),

                _buildInfoCard(
                  context,
                  title: 'Избранные',
                  content: _getBoolFilterText(currentFilter.isFavorite),
                ),

                _buildInfoCard(
                  context,
                  title: 'Часто используемые',
                  content: _getBoolFilterText(currentFilter.isFrequent),
                ),

                _buildInfoCard(
                  context,
                  title: 'С заметками',
                  content: _getBoolFilterText(currentFilter.hasNotes),
                ),

                _buildInfoCard(
                  context,
                  title: 'Архивированные',
                  content: _getBoolFilterText(currentFilter.isArchived),
                ),

                if (currentFilter.sortField != null)
                  _buildInfoCard(
                    context,
                    title: 'Сортировка',
                    content:
                        '${_getSortFieldName(currentFilter.sortField!)} '
                        '(${_getSortDirectionName(currentFilter.sortDirection)})',
                  ),

                const SizedBox(height: 32),

                // Кнопка для сброса фильтров
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(filterSectionControllerProvider.notifier)
                          .resetFilters();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Фильтры сброшены'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Сбросить все фильтры'),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _getBoolFilterText(bool? value) {
    if (value == null) return 'Не учитывается';
    return value ? 'Только да' : 'Только нет';
  }

  String _getSortFieldName(PasswordSortField field) {
    switch (field) {
      case PasswordSortField.name:
        return 'По названию';
      case PasswordSortField.createdAt:
        return 'По дате создания';
      case PasswordSortField.modifiedAt:
        return 'По дате изменения';
      case PasswordSortField.lastAccessed:
        return 'По последнему доступу';
      case PasswordSortField.usedCount:
        return 'По использованию';
    }
  }

  String _getSortDirectionName(SortDirection direction) {
    switch (direction) {
      case SortDirection.asc:
        return 'по возрастанию';
      case SortDirection.desc:
        return 'по убыванию';
    }
  }
}
