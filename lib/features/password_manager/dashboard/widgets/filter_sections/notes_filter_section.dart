import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/common/text_field.dart';

/// Секция для настройки специфических фильтров заметок
class NotesFilterSection extends StatefulWidget {
  final NotesFilter filter;
  final Function(NotesFilter) onFilterChanged;

  const NotesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<NotesFilterSection> createState() => _NotesFilterSectionState();
}

class _NotesFilterSectionState extends State<NotesFilterSection> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _minContentLengthController;
  late final TextEditingController _maxContentLengthController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.filter.title ?? '');
    _contentController = TextEditingController(
      text: widget.filter.content ?? '',
    );
    _minContentLengthController = TextEditingController(
      text: widget.filter.minContentLength?.toString() ?? '',
    );
    _maxContentLengthController = TextEditingController(
      text: widget.filter.maxContentLength?.toString() ?? '',
    );
  }

  // @override
  // void didUpdateWidget(NotesFilterSection oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Обновляем текст контроллеров при изменении фильтра извне
  //   if (oldWidget.filter.title != widget.filter.title) {
  //     _titleController.text = widget.filter.title ?? '';
  //   }
  //   if (oldWidget.filter.content != widget.filter.content) {
  //     _contentController.text = widget.filter.content ?? '';
  //   }
  //   if (oldWidget.filter.minContentLength != widget.filter.minContentLength) {
  //     _minContentLengthController.text =
  //         widget.filter.minContentLength?.toString() ?? '';
  //   }
  //   if (oldWidget.filter.maxContentLength != widget.filter.maxContentLength) {
  //     _maxContentLengthController.text =
  //         widget.filter.maxContentLength?.toString() ?? '';
  //   }
  // }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _minContentLengthController.dispose();
    _maxContentLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фильтры для заметок',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Поля поиска
        PrimaryTextField(
          label: 'Заголовок',
          hintText: 'Поиск по заголовку заметки',
          controller: _titleController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(title: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.title),
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'Содержимое',
          hintText: 'Поиск по содержимому заметки',
          controller: _contentController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(content: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.text_snippet),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Булевые фильтры
        const Text(
          'Свойства заметок',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Закрепленные'),
          value: widget.filter.isPined,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(isPined: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть содержимое'),
          value: widget.filter.hasContent,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(hasContent: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть вложения'),
          value: widget.filter.hasAttachments,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(
              widget.filter.copyWith(hasAttachments: value),
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Диапазон длины содержимого
        const Text(
          'Длина содержимого',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PrimaryTextField(
                label: 'Минимум символов',
                controller: _minContentLengthController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  final validValue = intValue != null && intValue >= 0
                      ? intValue
                      : null;

                  // Проверяем, что минимум не больше максимума
                  if (validValue != null &&
                      widget.filter.maxContentLength != null &&
                      validValue > widget.filter.maxContentLength!) {
                    return; // Не обновляем, если минимум больше максимума
                  }

                  widget.onFilterChanged(
                    widget.filter.copyWith(minContentLength: validValue),
                  );
                },
                prefixIcon: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryTextField(
                label: 'Максимум символов',
                controller: _maxContentLengthController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  final validValue = intValue != null && intValue >= 0
                      ? intValue
                      : null;

                  // Проверяем, что максимум не меньше минимума
                  if (validValue != null &&
                      widget.filter.minContentLength != null &&
                      validValue < widget.filter.minContentLength!) {
                    return; // Не обновляем, если максимум меньше минимума
                  }

                  widget.onFilterChanged(
                    widget.filter.copyWith(maxContentLength: validValue),
                  );
                },
                prefixIcon: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
        ),
        if (!widget.filter.isValidContentLengthRange) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Минимальная длина не может быть больше максимальной',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Поле сортировки
        const Text('Сортировка', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<NotesSortField>(
          decoration: primaryInputDecoration(
            context,
            labelText: 'Поле сортировки',
          ),
          initialValue: widget.filter.sortField,
          items: NotesSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(_getNotesSortFieldLabel(field)),
            );
          }).toList(),
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(sortField: value));
          },
        ),
      ],
    );
  }

  String _getNotesSortFieldLabel(NotesSortField field) {
    switch (field) {
      case NotesSortField.title:
        return 'Заголовок';
      case NotesSortField.createdAt:
        return 'Дата создания';
      case NotesSortField.modifiedAt:
        return 'Дата изменения';
      case NotesSortField.lastAccessed:
        return 'Последний доступ';
      case NotesSortField.contentLength:
        return 'Длина содержимого';
    }
  }
}
