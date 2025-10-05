import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

class TagFiltersWidget extends StatelessWidget {
  final TagType? selectedType;
  final String selectedSort;
  final bool isAscending;
  final ValueChanged<TagType?> onTypeChanged;
  final ValueChanged<String> onSortChanged;

  const TagFiltersWidget({
    super.key,
    this.selectedType,
    required this.selectedSort,
    required this.isAscending,
    required this.onTypeChanged,
    required this.onSortChanged,
  });

  String _getTypeLabel(TagType? type) {
    return switch (type) {
      TagType.password => 'Пароли',
      TagType.notes => 'Заметки',
      TagType.totp => 'TOTP',
      TagType.mixed => 'Смешанный',
      null => 'Все типы',
    };
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'name':
        return 'По имени';
      case 'created_at':
        return 'По дате создания';
      case 'modified_at':
        return 'По дате изменения';
      case 'type':
        return 'По типу';
      default:
        return 'По имени';
    }
  }

  IconData _getTypeIcon(TagType? type) {
    return switch (type) {
      TagType.password => Icons.lock,
      TagType.notes => Icons.note,
      TagType.totp => Icons.security,
      TagType.mixed => Icons.category,
      null => Icons.all_inclusive,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        // color: Theme.of(
        //   context,
        // ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Фильтр по типу
          Expanded(
            flex: 2,
            child: PopupMenuButton<TagType?>(
              initialValue: selectedType,
              onSelected: (TagType? value) {
                onTypeChanged(value);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(selectedType),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTypeLabel(selectedType),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<TagType?>(
                  value: null,
                  child: ListTile(
                    leading: const Icon(Icons.all_inclusive),
                    title: const Text('Все типы'),
                    contentPadding: EdgeInsets.zero,
                    selected: selectedType == null,
                  ),
                ),
                ...TagType.values.map(
                  (type) => PopupMenuItem<TagType?>(
                    value: type,
                    child: ListTile(
                      leading: Icon(_getTypeIcon(type)),
                      title: Text(_getTypeLabel(type)),
                      contentPadding: EdgeInsets.zero,
                      selected: selectedType == type,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Фильтр по сортировке
          Expanded(
            flex: 2,
            child: PopupMenuButton<String>(
              initialValue: selectedSort,
              onSelected: onSortChanged,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSortLabel(selectedSort),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'name',
                  child: ListTile(
                    leading: Icon(Icons.sort_by_alpha),
                    title: Text('По имени'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'created_at',
                  child: ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('По дате создания'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'modified_at',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('По дате изменения'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'type',
                  child: ListTile(
                    leading: Icon(Icons.category),
                    title: Text('По типу'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Кнопка смены направления сортировки
          IconButton(
            onPressed: () => onSortChanged(selectedSort),
            icon: Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: isAscending ? 'По возрастанию' : 'По убыванию',
          ),
        ],
      ),
    );
  }
}
