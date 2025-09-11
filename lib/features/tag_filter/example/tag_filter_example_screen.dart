import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/tag_filter/tag_filter.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Пример использования TagFilterWidget
class TagFilterExampleScreen extends ConsumerStatefulWidget {
  const TagFilterExampleScreen({super.key});

  @override
  ConsumerState<TagFilterExampleScreen> createState() =>
      _TagFilterExampleScreenState();
}

class _TagFilterExampleScreenState
    extends ConsumerState<TagFilterExampleScreen> {
  List<store.Tag> _selectedPasswordTags = [];
  List<store.Tag> _selectedNoteTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример Tag Filter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фильтр тегов паролей:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TagFilterWidget(
              tagType: TagType.password,
              selectedTags: _selectedPasswordTags,
              maxSelectedTags: 5,
              modalTitle: 'Выберите теги паролей',
              onTagSelect: (tag) {
                setState(() {
                  if (!_selectedPasswordTags.any((t) => t.id == tag.id)) {
                    _selectedPasswordTags.add(tag);
                  }
                });
              },
              onTagRemove: (tag) {
                setState(() {
                  _selectedPasswordTags.removeWhere((t) => t.id == tag.id);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedPasswordTags.clear();
                });
              },
              onApplyFilter: (tags) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Применен фильтр с ${tags.length} тегами паролей',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Фильтр тегов заметок:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TagFilterWidget(
              tagType: TagType.notes,
              selectedTags: _selectedNoteTags,
              maxSelectedTags: 3,
              modalTitle: 'Выберите теги заметок',
              searchPlaceholder: 'Поиск тегов заметок...',
              onTagSelect: (tag) {
                setState(() {
                  if (!_selectedNoteTags.any((t) => t.id == tag.id)) {
                    _selectedNoteTags.add(tag);
                  }
                });
              },
              onTagRemove: (tag) {
                setState(() {
                  _selectedNoteTags.removeWhere((t) => t.id == tag.id);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedNoteTags.clear();
                });
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Компактный фильтр (кнопка):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                TagFilterButton(
                  tagType: TagType.totp,
                  selectedTags:
                      _selectedNoteTags, // Используем те же теги для демонстрации
                  modalTitle: 'Выберите теги TOTP',
                  onTagSelect: (tag) {
                    setState(() {
                      if (!_selectedNoteTags.any((t) => t.id == tag.id)) {
                        _selectedNoteTags.add(tag);
                      }
                    });
                  },
                  onTagRemove: (tag) {
                    setState(() {
                      _selectedNoteTags.removeWhere((t) => t.id == tag.id);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _selectedNoteTags.clear();
                    });
                  },
                ),
                const SizedBox(width: 16),
                TagFilterButton(
                  tagType: TagType.mixed,
                  selectedTags: _selectedPasswordTags,
                  modalTitle: 'Выберите любые теги',
                  showButtonText: false, // Только иконка
                  buttonSize: const Size(40, 40),
                  onTagSelect: (tag) {
                    setState(() {
                      if (!_selectedPasswordTags.any((t) => t.id == tag.id)) {
                        _selectedPasswordTags.add(tag);
                      }
                    });
                  },
                  onTagRemove: (tag) {
                    setState(() {
                      _selectedPasswordTags.removeWhere((t) => t.id == tag.id);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _selectedPasswordTags.clear();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Отображение выбранных тегов
            const Text(
              'Выбранные теги:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              'Теги паролей: ${_selectedPasswordTags.map((t) => t.name).join(", ")}',
            ),
            const SizedBox(height: 4),
            Text(
              'Теги заметок: ${_selectedNoteTags.map((t) => t.name).join(", ")}',
            ),
          ],
        ),
      ),
    );
  }
}
