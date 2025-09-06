import 'package:flutter/material.dart';
import '../../../../common/text_field.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  Set<String> selectedCategories = {};
  Set<String> selectedTags = {};
  String sortBy = 'name';
  bool sortAscending = true;

  // Контроллеры для поиска
  final TextEditingController categorySearchController =
      TextEditingController();
  final TextEditingController tagSearchController = TextEditingController();

  // Фильтрованные списки
  List<String> filteredCategories = [];
  List<String> filteredTags = [];

  final List<String> categories = [
    'Email',
    'Development',
    'Finance',
    'Social',
    'Work',
    'Entertainment',
    'Shopping',
    'Education',
    'Healthcare',
    'Travel',
    'Gaming',
    'Utilities',
    'News',
    'Photography',
    'Music',
    'Sports',
    'Food & Drink',
    'Productivity',
    'Communication',
    'Security',
  ];

  final List<String> tags = [
    'Важный',
    'Работа',
    'Личное',
    'Временный',
    'Архив',
    'Проект',
    'Клиент',
    'Сервер',
    'API',
    'Тестовый',
    'Продакшн',
    'Разработка',
    'Мобильное',
    'Веб',
    'Администрирование',
    'Резервный',
    'Устаревший',
    'Активный',
    'Приоритетный',
    'Конфиденциальный',
  ];

  final List<Map<String, String>> sortOptions = [
    {'value': 'name', 'label': 'По названию'},
    {'value': 'created', 'label': 'По дате создания'},
    {'value': 'modified', 'label': 'По дате изменения'},
    {'value': 'category', 'label': 'По категории'},
  ];

  @override
  void initState() {
    super.initState();
    filteredCategories = List.from(categories);
    filteredTags = List.from(tags);

    categorySearchController.addListener(_filterCategories);
    tagSearchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    categorySearchController.dispose();
    tagSearchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = categorySearchController.text.toLowerCase();
    setState(() {
      filteredCategories = categories
          .where((category) => category.toLowerCase().contains(query))
          .toList();
    });
  }

  void _filterTags() {
    final query = tagSearchController.text.toLowerCase();
    setState(() {
      filteredTags = tags
          .where((tag) => tag.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBottomSheet = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: isBottomSheet
            ? const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              )
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Фильтры',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isBottomSheet)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Filters Summary
                  if (selectedCategories.isNotEmpty ||
                      selectedTags.isNotEmpty) ...[
                    _SectionHeader('Выбранные фильтры', theme),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...selectedCategories.map(
                          (category) => Chip(
                            label: Text(category),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                selectedCategories.remove(category);
                              });
                            },
                          ),
                        ),
                        ...selectedTags.map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 12,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                selectedTags.remove(tag);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Categories Section
                  Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(
                          'Категории',
                          theme,
                          selectedCount: selectedCategories.length,
                        ),
                      ),
                      if (filteredCategories.isNotEmpty) ...[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedCategories.length ==
                                  filteredCategories.length) {
                                // Очистить все видимые
                                for (final category in filteredCategories) {
                                  selectedCategories.remove(category);
                                }
                              } else {
                                // Выбрать все видимые
                                selectedCategories.addAll(filteredCategories);
                              }
                            });
                          },
                          child: Text(
                            selectedCategories.length ==
                                    filteredCategories.length
                                ? 'Очистить'
                                : 'Выбрать все',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Categories Search
                  TextField(
                    controller: categorySearchController,
                    decoration:
                        primaryInputDecoration(
                          context,
                          hintText: 'Поиск категорий...',
                        ).copyWith(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: categorySearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    categorySearchController.clear();
                                  },
                                )
                              : null,
                        ),
                    onChanged: (value) {
                      // Обновление в реальном времени для анимации suffixIcon
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  // Categories List
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: filteredCategories.isEmpty
                        ? const Center(child: Text('Категории не найдены'))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filteredCategories.map((category) {
                                final isSelected = selectedCategories.contains(
                                  category,
                                );
                                return FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedCategories.add(category);
                                      } else {
                                        selectedCategories.remove(category);
                                      }
                                    });
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                                .withOpacity(0.2),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Tags Section
                  Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(
                          'Теги',
                          theme,
                          selectedCount: selectedTags.length,
                        ),
                      ),
                      if (filteredTags.isNotEmpty) ...[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedTags.length == filteredTags.length) {
                                // Очистить все видимые
                                for (final tag in filteredTags) {
                                  selectedTags.remove(tag);
                                }
                              } else {
                                // Выбрать все видимые
                                selectedTags.addAll(filteredTags);
                              }
                            });
                          },
                          child: Text(
                            selectedTags.length == filteredTags.length
                                ? 'Очистить'
                                : 'Выбрать все',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags Search
                  TextField(
                    controller: tagSearchController,
                    decoration:
                        primaryInputDecoration(
                          context,
                          hintText: 'Поиск тегов...',
                        ).copyWith(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: tagSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    tagSearchController.clear();
                                  },
                                )
                              : null,
                        ),
                    onChanged: (value) {
                      // Обновление в реальном времени для анимации suffixIcon
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  // Tags List
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: filteredTags.isEmpty
                        ? const Center(child: Text('Теги не найдены'))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filteredTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedTags.add(tag);
                                      } else {
                                        selectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.outline
                                                .withOpacity(0.2),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Sort Section
                  _SectionHeader('Сортировка', theme),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: sortBy,
                    borderRadius: BorderRadius.circular(12),
                    autovalidateMode: AutovalidateMode.onUserInteraction,

                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Сортировать по',
                    ),
                    items: sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          sortBy = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Sort Direction
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('По возрастанию'),
                          value: true,
                          groupValue: sortAscending,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                sortAscending = value;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('По убыванию'),
                          value: false,
                          groupValue: sortAscending,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                sortAscending = value;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories.clear();
                        selectedTags.clear();
                        sortBy = 'name';
                        sortAscending = true;
                        categorySearchController.clear();
                        tagSearchController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Apply filters
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Фильтры применены')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionHeader(String title, ThemeData theme, {int? selectedCount}) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (selectedCount != null && selectedCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
