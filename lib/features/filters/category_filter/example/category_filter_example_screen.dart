import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import '../category_filter.dart';

/// Пример экрана с демонстрацией использования фильтра категорий
class CategoryFilterExampleScreen extends ConsumerStatefulWidget {
  const CategoryFilterExampleScreen({super.key});

  @override
  ConsumerState<CategoryFilterExampleScreen> createState() =>
      _CategoryFilterExampleScreenState();
}

class _CategoryFilterExampleScreenState
    extends ConsumerState<CategoryFilterExampleScreen> {
  // Состояние для различных типов категорий
  List<store.Category> _selectedPasswordCategories = [];
  List<store.Category> _selectedNotesCategories = [];
  List<store.Category> _selectedTotpCategories = [];
  List<store.Category> _selectedMixedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Примеры фильтра категорий')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Примеры использования виджета фильтрации категорий',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Пример 1: Основной виджет для паролей
            const Text(
              '1. Фильтр категорий паролей (основной виджет)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CategoryFilterWidget(
              categoryType: CategoryType.password,
              selectedCategories: _selectedPasswordCategories,
              onSelect: (category) {
                setState(() {
                  if (!_selectedPasswordCategories.contains(category)) {
                    _selectedPasswordCategories.add(category);
                  }
                });
              },
              onRemove: (category) {
                setState(() {
                  _selectedPasswordCategories.remove(category);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedPasswordCategories.clear();
                });
              },
              onApplyFilter: (categories) {
                // Здесь можно применить фильтрацию
                debugPrint(
                  'Применены категории паролей: ${categories.map((c) => c.name).join(', ')}',
                );
              },
            ),
            const SizedBox(height: 24),

            // Пример 2: Кнопка для заметок
            const Text(
              '2. Кнопка фильтра категорий заметок',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CategoryFilterButton(
                  categoryType: CategoryType.notes,
                  selectedCategories: _selectedNotesCategories,
                  onSelect: (category) {
                    setState(() {
                      if (!_selectedNotesCategories.contains(category)) {
                        _selectedNotesCategories.add(category);
                      }
                    });
                  },
                  onRemove: (category) {
                    setState(() {
                      _selectedNotesCategories.remove(category);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _selectedNotesCategories.clear();
                    });
                  },
                  buttonText: 'Выбрать категории заметок',
                  maxSelectedCategories: 5,
                ),
                const SizedBox(width: 16),
                if (_selectedNotesCategories.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Выбрано: ${_selectedNotesCategories.map((c) => c.name).join(', ')}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Пример 3: Компактная версия для TOTP с ограничением
            const Text(
              '3. Компактный фильтр TOTP (макс. 3 категории)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CategoryFilterWidget(
              categoryType: CategoryType.totp,
              selectedCategories: _selectedTotpCategories,
              maxSelectedCategories: 3,
              height: 48,
              searchPlaceholder: 'Выберите до 3 категорий TOTP',
              onSelect: (category) {
                setState(() {
                  if (!_selectedTotpCategories.contains(category)) {
                    _selectedTotpCategories.add(category);
                  }
                });
              },
              onRemove: (category) {
                setState(() {
                  _selectedTotpCategories.remove(category);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedTotpCategories.clear();
                });
              },
              pageSize: 15,
              sortBy: CategorySortBy.modifiedAt,
              ascending: false,
            ),
            const SizedBox(height: 24),

            // Пример 4: Смешанные категории с кастомной пагинацией
            const Text(
              '4. Смешанные категории (кастомная пагинация)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CategoryFilterWidget(
              categoryType: CategoryType.mixed,
              selectedCategories: _selectedMixedCategories,
              showSelectedCount: true,
              modalTitle: 'Выберите нужные категории',
              pageSize: 10,
              sortBy: CategorySortBy.name,
              ascending: true,
              onSelect: (category) {
                setState(() {
                  if (!_selectedMixedCategories.contains(category)) {
                    _selectedMixedCategories.add(category);
                  }
                });
              },
              onRemove: (category) {
                setState(() {
                  _selectedMixedCategories.remove(category);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedMixedCategories.clear();
                });
              },
              onApplyFilter: (categories) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Выбрано ${categories.length} смешанных категорий',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Статистика выбора
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика выбранных категорий:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Пароли', _selectedPasswordCategories.length),
                    _buildStatRow('Заметки', _selectedNotesCategories.length),
                    _buildStatRow('TOTP', _selectedTotpCategories.length),
                    _buildStatRow('Смешанные', _selectedMixedCategories.length),
                    const Divider(),
                    _buildStatRow(
                      'Всего',
                      _selectedPasswordCategories.length +
                          _selectedNotesCategories.length +
                          _selectedTotpCategories.length +
                          _selectedMixedCategories.length,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Кнопка сброса всех фильтров
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedPasswordCategories.clear();
                  _selectedNotesCategories.clear();
                  _selectedTotpCategories.clear();
                  _selectedMixedCategories.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Все фильтры очищены'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Очистить все фильтры'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: count > 0 ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
