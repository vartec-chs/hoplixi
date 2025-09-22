import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/common/text_field.dart';

/// Секция для настройки специфических фильтров заметок
class NotesFilterSection extends ConsumerWidget {
  final NotesFilter filter;
  final Function(NotesFilter) onFilterChanged;

  const NotesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          controller: TextEditingController(text: filter.title ?? ''),
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            onFilterChanged(filter.copyWith(title: normalizedValue));
          },
          prefixIcon: const Icon(Icons.title),
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'Содержимое',
          hintText: 'Поиск по содержимому заметки',
          controller: TextEditingController(text: filter.content ?? ''),
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            onFilterChanged(filter.copyWith(content: normalizedValue));
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
          value: filter.isPined,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isPined: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть содержимое'),
          value: filter.hasContent,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasContent: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть вложения'),
          value: filter.hasAttachments,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasAttachments: value));
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
                controller: TextEditingController(
                  text: filter.minContentLength?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  final validValue = intValue != null && intValue >= 0
                      ? intValue
                      : null;

                  // Проверяем, что минимум не больше максимума
                  if (validValue != null &&
                      filter.maxContentLength != null &&
                      validValue > filter.maxContentLength!) {
                    return; // Не обновляем, если минимум больше максимума
                  }

                  onFilterChanged(
                    filter.copyWith(minContentLength: validValue),
                  );
                },
                prefixIcon: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryTextField(
                label: 'Максимум символов',
                controller: TextEditingController(
                  text: filter.maxContentLength?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  final validValue = intValue != null && intValue >= 0
                      ? intValue
                      : null;

                  // Проверяем, что максимум не меньше минимума
                  if (validValue != null &&
                      filter.minContentLength != null &&
                      validValue < filter.minContentLength!) {
                    return; // Не обновляем, если максимум меньше минимума
                  }

                  onFilterChanged(
                    filter.copyWith(maxContentLength: validValue),
                  );
                },
                prefixIcon: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
        ),
        if (!filter.isValidContentLengthRange) ...[
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
          value: filter.sortField,
          items: NotesSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(_getNotesSortFieldLabel(field)),
            );
          }).toList(),
          onChanged: (value) {
            onFilterChanged(filter.copyWith(sortField: value));
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
