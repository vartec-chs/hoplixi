import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/features/password_manager/filters/category_filter/category_filter_widget.dart';
import 'package:hoplixi/features/password_manager/filters/tag_filter/tag_filter_widget.dart';

/// Полноэкранное модальное окно для настройки фильтров
class FilterModal extends ConsumerStatefulWidget {
  /// Начальный фильтр
  final PasswordFilter initialFilter;

  /// Callback при применении фильтра
  final void Function(PasswordFilter filter) onApply;

  /// Callback при отмене
  final VoidCallback onCancel;

  const FilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onCancel,
  });

  @override
  ConsumerState<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<FilterModal> {
  late PasswordFilter _currentFilter;
  late List<store.Category> _selectedCategories;
  late List<store.Tag> _selectedTags;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _selectedCategories = [];
    _selectedTags = [];
    _notesController = TextEditingController();

    // Инициализация контроллера заметок
    _notesController.text = _currentFilter.query;

    // Загружаем выбранные категории и теги по ID
    _loadSelectedItems();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedItems() async {
    // TODO: Загрузить категории и теги по ID из _currentFilter
    // Здесь должна быть логика загрузки из базы данных
    // Пока оставляю заглушку
  }

  void _applyFilter() {
    final updatedFilter = _currentFilter.copyWith(
      categoryIds: _selectedCategories.map((cat) => cat.id).toList(),
      tagIds: _selectedTags.map((tag) => tag.id).toList(),
    );
    widget.onApply(updatedFilter);
  }

  void _resetFilter() {
    setState(() {
      _currentFilter = const PasswordFilter();
      _selectedCategories.clear();
      _selectedTags.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Фильтры паролей'),
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          leading: IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
          ),
          actions: [
            SmoothButton(
              onPressed: _resetFilter,
              label: 'Сбросить',
              size: SmoothButtonSize.small,
              type: SmoothButtonType.outlined,
            ),
            const SizedBox(width: 8),
            SmoothButton(
              onPressed: _applyFilter,
              label: 'Применить',
              size: SmoothButtonSize.small,
              type: SmoothButtonType.filled,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Поиск по названию
              _buildSection(
                title: 'Поиск',
                child: PrimaryTextField(
                  controller: _notesController,
                  hintText: 'Поиск по названию, логину, заметкам...',
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(query: value);
                    });
                  },
                  prefixIcon: const Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 24),

              // Категории
              _buildSection(
                title: 'Категории',
                child: CategoryFilterWidget(
                  categoryType: CategoryType.password,
                  selectedCategories: _selectedCategories,
                  onSelect: (category) {
                    setState(() {
                      if (!_selectedCategories.contains(category)) {
                        _selectedCategories.add(category);
                      }
                    });
                  },
                  onRemove: (category) {
                    setState(() {
                      _selectedCategories.remove(category);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _selectedCategories.clear();
                    });
                  },
                  searchPlaceholder: 'Выберите категории...',
                ),
              ),

              const SizedBox(height: 24),

              // Теги
              _buildSection(
                title: 'Теги',
                child: TagFilterWidget(
                  tagType: TagType.password,
                  selectedTags: _selectedTags,
                  onTagSelect: (tag) {
                    setState(() {
                      if (!_selectedTags.contains(tag)) {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  onTagRemove: (tag) {
                    setState(() {
                      _selectedTags.remove(tag);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _selectedTags.clear();
                    });
                  },
                  searchPlaceholder: 'Выберите теги...',
                ),
              ),

              const SizedBox(height: 24),

              // Дополнительные фильтры
              _buildSection(
                title: 'Дополнительные фильтры',
                child: Column(
                  children: [
                    // Checkbox для фильтра "Только с заметками"
                    CheckboxListTile(
                      title: const Text('Только с заметками'),
                      value: _currentFilter.hasNotes,
                      tristate: true,
                      onChanged: (value) {
                        setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            hasNotes: value,
                          );
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // Checkbox для архивированных
                    CheckboxListTile(
                      title: const Text('Включать архивированные'),
                      value: _currentFilter.isArchived,
                      tristate: true,
                      onChanged: (value) {
                        setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            isArchived: value,
                          );
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Сортировка
              _buildSection(
                title: 'Сортировка',
                child: Column(
                  children: [
                    DropdownButtonFormField<PasswordSortField>(
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Сортировать по',
                      ),
                      initialValue: _currentFilter.sortField,
                      onChanged: (value) {
                        setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            sortField: value,
                          );
                        });
                      },
                      items: PasswordSortField.values.map((field) {
                        return DropdownMenuItem(
                          value: field,
                          child: Text(_getSortFieldLabel(field)),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<SortDirection>(
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Направление',
                      ),
                      initialValue: _currentFilter.sortDirection,
                      onChanged: (value) {
                        setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            sortDirection: value ?? SortDirection.desc,
                          );
                        });
                      },
                      items: SortDirection.values.map((direction) {
                        return DropdownMenuItem(
                          value: direction,
                          child: Text(_getSortDirectionLabel(direction)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Добавляем отступ в конце для удобства прокрутки
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _getSortFieldLabel(PasswordSortField field) {
    switch (field) {
      case PasswordSortField.name:
        return 'Название';
      case PasswordSortField.createdAt:
        return 'Дата создания';
      case PasswordSortField.modifiedAt:
        return 'Дата изменения';
      case PasswordSortField.lastAccessed:
        return 'Последний доступ';
      case PasswordSortField.usedCount:
        return 'Количество использований';
    }
  }

  String _getSortDirectionLabel(SortDirection direction) {
    switch (direction) {
      case SortDirection.asc:
        return 'По возрастанию';
      case SortDirection.desc:
        return 'По убыванию';
    }
  }
}
