import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Пример использования компонента CategoriesPicker
class CategoriesPickerExample extends ConsumerStatefulWidget {
  const CategoriesPickerExample({super.key});

  @override
  ConsumerState<CategoriesPickerExample> createState() =>
      _CategoriesPickerExampleState();
}

class _CategoriesPickerExampleState
    extends ConsumerState<CategoriesPickerExample> {
  List<String> _selectedPasswordCategories = [];
  List<String> _selectedNotesCategories = [];
  List<String> _selectedMultipleCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример CategoriesPicker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Пример 1: Одиночный выбор для паролей
            Text(
              'Выбор категории для пароля (одна категория)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CategoriesPicker(
              categoryType: CategoryType.password,
              maxSelection: 1,
              selectedCategoryIds: _selectedPasswordCategories,
              labelText: 'Категория пароля',
              hintText: 'Выберите категорию для пароля',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedPasswordCategories = selectedIds;
                });
                print('Выбранные категории для пароля: $selectedIds');
              },
              onClear: () {
                print('Очистка выбора категорий для пароля');
              },
            ),

            const SizedBox(height: 24),

            // Пример 2: Одиночный выбор для заметок
            Text(
              'Выбор категории для заметки (одна категория)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CategoriesPicker(
              categoryType: CategoryType.notes,
              maxSelection: 1,
              selectedCategoryIds: _selectedNotesCategories,
              labelText: 'Категория заметки',
              hintText: 'Выберите категорию для заметки',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedNotesCategories = selectedIds;
                });
                print('Выбранные категории для заметки: $selectedIds');
              },
              onClear: () {
                print('Очистка выбора категорий для заметки');
              },
            ),

            const SizedBox(height: 24),

            // Пример 3: Множественный выбор
            Text(
              'Выбор нескольких категорий (до 3 категорий)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CategoriesPicker(
              categoryType: CategoryType.password,
              maxSelection: 3,
              selectedCategoryIds: _selectedMultipleCategories,
              labelText: 'Категории',
              hintText: 'Выберите до 3 категорий',
              onSelect: (selectedIds) {
                setState(() {
                  _selectedMultipleCategories = selectedIds;
                });
                print('Выбранные множественные категории: $selectedIds');
              },
              onClear: () {
                print('Очистка множественного выбора');
              },
              onRemove: (categoryId) {
                print('Удаление категории: $categoryId');
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
                              'Категории для пароля:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedPasswordCategories.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedPasswordCategories.toString(),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Категории для заметки:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedNotesCategories.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedNotesCategories.toString(),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Множественные категории:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _selectedMultipleCategories.isEmpty
                                  ? 'Не выбрано'
                                  : _selectedMultipleCategories.toString(),
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
