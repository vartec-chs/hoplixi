import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';

/// Секция для фильтров паролей
class PasswordFilterSection extends ConsumerWidget {
  final PasswordFilter filter;
  final Function(PasswordFilter) onFilterChanged;

  const PasswordFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Только часто используемые'),
          value: filter.isFrequent,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isFrequent: value));
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
        const SizedBox(height: 16),

        // Дата создания
        const Text(
          'Дата создания',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          'Создано после',
          filter.createdAfter,
          (date) => onFilterChanged(filter.copyWith(createdAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          'Создано до',
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
          'Изменено после',
          filter.modifiedAfter,
          (date) => onFilterChanged(filter.copyWith(modifiedAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          'Изменено до',
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
          'Доступ после',
          filter.lastAccessedAfter,
          (date) => onFilterChanged(filter.copyWith(lastAccessedAfter: date)),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          'Доступ до',
          filter.lastAccessedBefore,
          (date) => onFilterChanged(filter.copyWith(lastAccessedBefore: date)),
        ),
      ],
    );
  }

  Widget _buildDateRange(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return Builder(
      builder: (context) => Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  onChanged(date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value != null
                      ? '${value.day}.${value.month}.${value.year}'
                      : 'Выберите дату',
                  style: TextStyle(color: value != null ? null : Colors.grey),
                ),
              ),
            ),
          ),
          if (value != null)
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }
}
