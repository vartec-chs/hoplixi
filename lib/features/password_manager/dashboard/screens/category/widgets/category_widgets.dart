import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;

/// Виджет для выбора категории из списка
class CategorySelector extends ConsumerWidget {
  final CategoryType? filterType;
  final store.Category? selectedCategory;
  final ValueChanged<store.Category?> onCategorySelected;
  final String hintText;
  final bool allowEmpty;

  const CategorySelector({
    super.key,
    this.filterType,
    this.selectedCategory,
    required this.onCategorySelected,
    this.hintText = 'Выберите категорию',
    this.allowEmpty = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final allCategoriesAsync = ref.watch(allCategoriesStreamProvider);

        return allCategoriesAsync.when(
          data: (allCategories) {
            final filteredCategories = filterType != null
                ? allCategories.where((cat) => cat.type == filterType).toList()
                : allCategories;

            return DropdownButtonFormField<store.Category?>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Категория',
                hintText: hintText,
                prefixIcon: selectedCategory != null
                    ? Icon(
                        _getTypeIcon(selectedCategory!.type),
                        color: Color(
                          int.parse(
                                selectedCategory!.color.substring(1),
                                radix: 16,
                              ) +
                              0xFF000000,
                        ),
                      )
                    : const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                if (allowEmpty)
                  const DropdownMenuItem<store.Category?>(
                    value: null,
                    child: Text('Без категории'),
                  ),
                ...filteredCategories.map((category) {
                  final categoryColor = Color(
                    int.parse(category.color.substring(1), radix: 16) +
                        0xFF000000,
                  );

                  return DropdownMenuItem<store.Category?>(
                    value: category,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: categoryColor.withOpacity(0.2),
                          child: Icon(
                            _getTypeIcon(category.type),
                            size: 14,
                            color: categoryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _getTypeDisplayName(category.type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: onCategorySelected,
              validator: allowEmpty
                  ? null
                  : (value) {
                      if (value == null) {
                        return 'Выберите категорию';
                      }
                      return null;
                    },
            );
          },
          loading: () => DropdownButtonFormField<store.Category?>(
            initialValue: null,
            decoration: InputDecoration(
              labelText: 'Категория',
              hintText: 'Загрузка...',
              prefixIcon: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [],
            onChanged: null,
          ),
          error: (error, stack) => DropdownButtonFormField<store.Category?>(
            initialValue: null,
            decoration: InputDecoration(
              labelText: 'Категория',
              hintText: 'Ошибка загрузки',
              prefixIcon: Icon(Icons.error, color: theme.colorScheme.error),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [],
            onChanged: null,
          ),
        );
      },
    );
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанные';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.key;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.category;
    }
  }
}

/// Компактный виджет для отображения категории
class CategoryChip extends StatelessWidget {
  final store.Category category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showType;

  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
    this.onDelete,
    this.showType = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: categoryColor.withOpacity(0.2),
          child: Icon(
            _getTypeIcon(category.type),
            size: 16,
            color: categoryColor,
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.name),
            if (showType) ...[
              const SizedBox(width: 4),
              Text(
                '(${_getTypeDisplayName(category.type)})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        deleteIcon: onDelete != null ? const Icon(Icons.close, size: 18) : null,
        onDeleted: onDelete,
        backgroundColor: categoryColor.withOpacity(0.1),
        side: BorderSide(color: categoryColor.withOpacity(0.3)),
      ),
    );
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанные';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.key;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.category;
    }
  }
}

/// Виджет для отображения списка категорий по типу
class CategoriesTypeList extends ConsumerWidget {
  final CategoryType type;
  final Function(store.Category)? onCategoryTap;
  final bool compact;

  const CategoriesTypeList({
    super.key,
    required this.type,
    this.onCategoryTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesByTypeStreamProvider(type));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTypeIcon(type),
                  size: compact ? 32 : 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  'Нет категорий типа ${_getTypeDisplayName(type)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              return CategoryChip(
                category: category,
                onTap: onCategoryTap != null
                    ? () => onCategoryTap!(category)
                    : null,
                showType: false,
              );
            }).toList(),
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryColor = Color(
              int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
            );

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: categoryColor.withOpacity(0.2),
                child: Icon(_getTypeIcon(category.type), color: categoryColor),
              ),
              title: Text(category.name),
              subtitle:
                  category.description != null &&
                      category.description!.isNotEmpty
                  ? Text(category.description!)
                  : null,
              onTap: onCategoryTap != null
                  ? () => onCategoryTap!(category)
                  : null,
              trailing: onCategoryTap != null
                  ? const Icon(Icons.arrow_forward_ios, size: 16)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: compact ? 32 : 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Ошибка загрузки',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанные';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.key;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.category;
    }
  }
}
