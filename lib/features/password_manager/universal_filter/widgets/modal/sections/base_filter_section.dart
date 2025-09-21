import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';

/// Переиспользуемая секция для настройки базовых фильтров
/// Содержит общие поля для всех типов фильтров
class BaseFilterSection extends ConsumerWidget {
  final BaseFilter filter;
  final Function(BaseFilter) onFilterChanged;
  final String entityTypeName; // Название типа сущности для UI

  const BaseFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.entityTypeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Общие фильтры для $entityTypeName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Поисковый запрос
        TextField(
          decoration: const InputDecoration(
            labelText: 'Поисковый запрос',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          controller: TextEditingController(text: filter.query),
          onChanged: (value) {
            onFilterChanged(filter.copyWith(query: value.trim()));
          },
        ),
        const SizedBox(height: 16),

        // Булевые фильтры
        CheckboxListTile(
          title: const Text('Только избранные'),
          value: filter.isFavorite,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isFavorite: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только архивированные'),
          value: filter.isArchived,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isArchived: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с заметками'),
          value: filter.hasNotes,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasNotes: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Дата создания
        const Text(
          'Дата создания',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'После',
          filter.createdAfter,
          (date) => onFilterChanged(filter.copyWith(createdAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          filter.createdBefore,
          (date) => onFilterChanged(filter.copyWith(createdBefore: date)),
        ),
        const SizedBox(height: 16),

        // Дата изменения
        const Text(
          'Дата изменения',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'После',
          filter.modifiedAfter,
          (date) => onFilterChanged(filter.copyWith(modifiedAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          filter.modifiedBefore,
          (date) => onFilterChanged(filter.copyWith(modifiedBefore: date)),
        ),
        const SizedBox(height: 16),

        // Дата последнего доступа
        const Text(
          'Дата последнего доступа',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'После',
          filter.lastAccessedAfter,
          (date) => onFilterChanged(filter.copyWith(lastAccessedAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          filter.lastAccessedBefore,
          (date) => onFilterChanged(filter.copyWith(lastAccessedBefore: date)),
        ),
        const SizedBox(height: 16),

        // Пагинация
        const Text('Пагинация', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Лимит',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.limit?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(limit: intValue));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Смещение',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.offset?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(offset: intValue));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Направление сортировки
        const Text(
          'Направление сортировки',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<SortDirection>(
                title: const Text('По возрастанию'),
                value: SortDirection.asc,
                groupValue: filter.sortDirection,
                onChanged: (value) {
                  if (value != null) {
                    onFilterChanged(filter.copyWith(sortDirection: value));
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<SortDirection>(
                title: const Text('По убыванию'),
                value: SortDirection.desc,
                groupValue: filter.sortDirection,
                onChanged: (value) {
                  if (value != null) {
                    onFilterChanged(filter.copyWith(sortDirection: value));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRange(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onChanged(date);
              }
            },
            child: Text(
              value != null
                  ? '${value.day}.${value.month}.${value.year}'
                  : 'Выбрать дату',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: value != null ? () => onChanged(null) : null,
          icon: const Icon(Icons.clear),
          tooltip: 'Очистить',
        ),
      ],
    );
  }
}
