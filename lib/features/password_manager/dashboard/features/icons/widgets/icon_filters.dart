import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Виджет фильтров для управления иконками
class IconFiltersWidget extends StatelessWidget {
  final IconType? selectedType;
  final ValueChanged<IconType?> onTypeChanged;

  const IconFiltersWidget({
    super.key,
    this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтр по типу',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Все типы
            FilterChip(
              label: const Text('Все'),
              selected: selectedType == null,
              onSelected: (selected) {
                if (selected) {
                  onTypeChanged(null);
                }
              },
              backgroundColor: selectedType == null
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: selectedType == null
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                fontWeight: selectedType == null ? FontWeight.w500 : null,
              ),
            ),

            // Отдельные типы
            ...IconType.values.map((type) {
              final isSelected = selectedType == type;
              return FilterChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  onTypeChanged(selected ? type : null);
                },
                backgroundColor: isSelected
                    ? _getTypeColor(context, type).withOpacity(0.2)
                    : null,
                selectedColor: _getTypeColor(context, type).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? _getTypeColor(context, type) : null,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
                side: isSelected
                    ? BorderSide(color: _getTypeColor(context, type))
                    : null,
              );
            }),
          ],
        ),
      ],
    );
  }

  Color _getTypeColor(BuildContext context, IconType type) {
    switch (type) {
      case IconType.png:
        return Colors.blue;
      case IconType.jpg:
        return Colors.orange;
      case IconType.svg:
        return Colors.green;
      case IconType.gif:
        return Colors.purple;
      case IconType.bmp:
        return Colors.red;
      case IconType.webp:
        return Colors.teal;
    }
  }
}
