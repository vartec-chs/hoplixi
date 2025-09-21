import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'base_filter_section.dart';

/// Секция для фильтров заметок
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
        // Базовые фильтры
        BaseFilterSection(
          filter: filter.base,
          entityTypeName: 'заметок',
          onFilterChanged: (baseFilter) {
            onFilterChanged(filter.copyWith(base: baseFilter));
          },
        ),
        const SizedBox(height: 24),

        // Специфичные для заметок фильтры
        const Text(
          'Специфичные фильтры для заметок',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Фильтр по заголовку
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по заголовку',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.title ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                title: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по содержимому
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по содержимому',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.content ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                content: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
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
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Минимальная длина',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.minContentLength?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(minContentLength: intValue));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Максимальная длина',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.maxContentLength?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(maxContentLength: intValue));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Булевые фильтры
        CheckboxListTile(
          title: const Text('Только закрепленные'),
          value: filter.isPined,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isPined: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с содержимым'),
          value: filter.hasContent,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasContent: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('С вложениями'),
          value: filter.hasAttachments,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasAttachments: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}