import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_picker/tags_picker.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Пример использования компонента TagsPicker
class TagsPickerExample extends ConsumerStatefulWidget {
  const TagsPickerExample({super.key});

  @override
  ConsumerState<TagsPickerExample> createState() => _TagsPickerExampleState();
}

class _TagsPickerExampleState extends ConsumerState<TagsPickerExample> {
  List<String> _selectedPasswordTags = [];
  List<String> _selectedNotesTags = [];
  List<String> _selectedTotpTags = [];
  List<String> _selectedMixedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример TagsPicker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Пример 1: Теги для паролей (по умолчанию 5 тегов)
            Text(
              'Теги для пароля (до 5 тегов)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TagsPicker(
              tagType: TagType.password,
              selectedTagIds: _selectedPasswordTags,
              labelText: 'Теги для пароля',
              hintText: 'Выберите теги для пароля',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedPasswordTags = selectedIds;
                });
                print('Выбранные теги для пароля: $selectedIds');
              },
              onClear: () {
                print('Очистка тегов для пароля');
              },
              onRemove: (tagId) {
                print('Удаление тега для пароля: $tagId');
              },
            ),

            const SizedBox(height: 24),

            // Пример 2: Теги для заметок с ограничением до 3
            Text(
              'Теги для заметки (до 3 тегов)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TagsPicker(
              tagType: TagType.notes,
              maxSelection: 3,
              selectedTagIds: _selectedNotesTags,
              labelText: 'Теги для заметки',
              hintText: 'Выберите до 3 тегов для заметки',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedNotesTags = selectedIds;
                });
                print('Выбранные теги для заметки: $selectedIds');
              },
              onClear: () {
                print('Очистка тегов для заметки');
              },
              onRemove: (tagId) {
                print('Удаление тега для заметки: $tagId');
              },
            ),

            const SizedBox(height: 24),

            // Пример 3: Теги для TOTP с ограничением до 2
            Text(
              'Теги для TOTP (до 2 тегов)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TagsPicker(
              tagType: TagType.totp,
              maxSelection: 2,
              selectedTagIds: _selectedTotpTags,
              labelText: 'Теги для TOTP',
              hintText: 'Выберите до 2 тегов для TOTP',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedTotpTags = selectedIds;
                });
                print('Выбранные теги для TOTP: $selectedIds');
              },
              onClear: () {
                print('Очистка тегов для TOTP');
              },
            ),

            const SizedBox(height: 24),

            // Пример 4: Смешанные теги с максимальным лимитом
            Text(
              'Смешанные теги (до 10 тегов)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TagsPicker(
              tagType: TagType.mixed,
              maxSelection: 10,
              selectedTagIds: _selectedMixedTags,
              labelText: 'Смешанные теги',
              hintText: 'Выберите до 10 смешанных тегов',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedMixedTags = selectedIds;
                });
                print('Выбранные смешанные теги: $selectedIds');
              },
              onClear: () {
                print('Очистка смешанных тегов');
              },
            ),

            const SizedBox(height: 24),

            // Отображение результатов
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Результаты выбора:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Теги для пароля:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedPasswordTags.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedPasswordTags.toString(),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Теги для заметки:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedNotesTags.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedNotesTags.toString(),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Теги для TOTP:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedTotpTags.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedTotpTags.toString(),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Смешанные теги:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedMixedTags.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedMixedTags.toString(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
