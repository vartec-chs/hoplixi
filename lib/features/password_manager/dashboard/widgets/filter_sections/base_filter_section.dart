import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/common/text_field.dart';

/// Переиспользуемая секция для настройки базовых фильтров
/// Содержит общие поля для всех типов фильтров
class BaseFilterSection extends StatefulWidget {
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
  State<BaseFilterSection> createState() => _BaseFilterSectionState();
}

class _BaseFilterSectionState extends State<BaseFilterSection> {
  late final TextEditingController _limitController;
  late final TextEditingController _offsetController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.filter.limit?.toString() ?? '',
    );
    _offsetController = TextEditingController(
      text: widget.filter.offset?.toString() ?? '',
    );
  }

  // @override
  // void didUpdateWidget(BaseFilterSection oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Обновляем текст контроллеров при изменении фильтра извне
  //   if (oldWidget.filter.limit != widget.filter.limit) {
  //     _limitController.text = widget.filter.limit?.toString() ?? '';
  //   }
  //   if (oldWidget.filter.offset != widget.filter.offset) {
  //     _offsetController.text = widget.filter.offset?.toString() ?? '';
  //   }
  // }

  @override
  void dispose() {
    _limitController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Общие фильтры для ${widget.entityTypeName}',
        //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 16),

        // Булевые фильтры
        CheckboxListTile(
          title: const Text('Только избранные'),
          value: widget.filter.isFavorite,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(isFavorite: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только архивированные'),
          value: widget.filter.isArchived,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(isArchived: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с заметками'),
          value: widget.filter.hasNotes,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(hasNotes: value));
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
          widget.filter.createdAfter,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(createdAfter: date),
          ),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          widget.filter.createdBefore,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(createdBefore: date),
          ),
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
          widget.filter.modifiedAfter,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(modifiedAfter: date),
          ),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          widget.filter.modifiedBefore,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(modifiedBefore: date),
          ),
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
          widget.filter.lastAccessedAfter,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(lastAccessedAfter: date),
          ),
        ),
        const SizedBox(height: 8),
        _buildDateRange(
          context,
          'До',
          widget.filter.lastAccessedBefore,
          (date) => widget.onFilterChanged(
            widget.filter.copyWith(lastAccessedBefore: date),
          ),
        ),
        const SizedBox(height: 16),

        // Пагинация
        Visibility(
          visible: MainConstants.isProduction == false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Пагинация',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PrimaryTextField(
                      label: 'Лимит',
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        widget.onFilterChanged(
                          widget.filter.copyWith(limit: intValue),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryTextField(
                      label: 'Смещение',
                      controller: _offsetController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        widget.onFilterChanged(
                          widget.filter.copyWith(offset: intValue),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

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
                groupValue: widget.filter.sortDirection,
                onChanged: (value) {
                  if (value != null) {
                    widget.onFilterChanged(
                      widget.filter.copyWith(sortDirection: value),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<SortDirection>(
                title: const Text('По убыванию'),
                value: SortDirection.desc,
                groupValue: widget.filter.sortDirection,
                onChanged: (value) {
                  if (value != null) {
                    widget.onFilterChanged(
                      widget.filter.copyWith(sortDirection: value),
                    );
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
          child: FilledButton.tonal(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 1),
                keyboardType: TextInputType.datetime,
              );
              if (date != null) {
                onChanged(date);
              }
            },
            style: FilledButton.styleFrom(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
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
