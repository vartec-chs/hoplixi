import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;

class CategoryFormModal extends ConsumerStatefulWidget {
  final store.Category? category; // null for creating new category
  final CategoryType? initialType;
  final bool isBottomSheet;

  const CategoryFormModal({
    super.key,
    this.category,
    this.initialType,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late CategoryType _selectedType;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      // Editing existing category
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _selectedType = widget.category!.type;
      _selectedColor = Color(
        int.parse(widget.category!.color.substring(1), radix: 16) + 0xFF000000,
      );
    } else {
      // Creating new category
      _selectedType = widget.initialType ?? CategoryType.password;
      _selectedColor = _predefinedColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isBottomSheet ? 0 : 16),
      ),
      child: Container(
        width: widget.isBottomSheet ? double.infinity : 500,
        padding: EdgeInsets.only(
          bottom: widget.isBottomSheet ? mediaQuery.viewInsets.bottom : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.isBottomSheet ? 24 : 16),
                  topRight: Radius.circular(widget.isBottomSheet ? 24 : 16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _selectedColor.withOpacity(0.2),
                    child: Icon(
                      _getTypeIcon(_selectedType),
                      color: _selectedColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category != null
                              ? 'Редактирование категории'
                              : 'Новая категория',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTypeDisplayName(_selectedType),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isBottomSheet)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Category name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Название категории',
                          hintText: 'Введите название категории',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название категории';
                          }
                          if (value.trim().length < 2) {
                            return 'Название должно содержать минимум 2 символа';
                          }
                          if (value.trim().length > 50) {
                            return 'Название не должно превышать 50 символов';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Category description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Описание (необязательно)',
                          hintText: 'Добавьте описание категории',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) {
                          if (value != null && value.trim().length > 200) {
                            return 'Описание не должно превышать 200 символов';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 24),

                      // Category type
                      Text(
                        'Тип категории',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CategoryType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return FilterChip(
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedType = type);
                            },
                            avatar: Icon(
                              _getTypeIcon(type),
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : null,
                            ),
                            label: Text(_getTypeDisplayName(type)),
                            backgroundColor: isSelected ? _selectedColor : null,
                            selectedColor: _selectedColor,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Color picker
                      Text(
                        'Цвет категории',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Selected color preview
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Выбранный цвет',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      _colorToHex(_selectedColor),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontFamily: 'monospace',
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Color grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _predefinedColors.length,
                              itemBuilder: (context, index) {
                                final color = _predefinedColors[index];
                                final isSelected =
                                    _selectedColor.value == color.value;

                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedColor = color),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.category != null ? 'Сохранить' : 'Создать',
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom sheet handle
            if (widget.isBottomSheet)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoriesService = ref.read(categoriesServiceProvider);

      if (widget.category != null) {
        // Update existing category
        final result = await categoriesService.updateCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _selectedType,
          color: _colorToHex(_selectedColor),
        );

        if (mounted) {
          if (result.success) {
            ToastHelper.success(
              title: 'Категория обновлена',
              context: context,
              description:
                  'Категория "${_nameController.text.trim()}" успешно обновлена',
            );
            Navigator.of(context).pop();
          } else {
            ToastHelper.error(
              title: 'Ошибка при обновлении категории',
              context: context,
              description: result.message ?? 'Ошибка при обновлении категории',
            );
          }
        }
      } else {
        // Create new category
        final result = await categoriesService.createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _selectedType,
          color: _colorToHex(_selectedColor),
        );

        if (mounted) {
          if (result.success) {
            ToastHelper.success(
              title: 'Категория создана',
              context: context,
              description: 'Категория "${_nameController.text.trim()}" создана',
            );
            Navigator.of(context).pop();
          } else {
            ToastHelper.error(
              title: 'Ошибка при создании категории',
              context: context,
              description: result.message ?? 'Ошибка при создании категории',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          context: context,
          description: 'Ошибка: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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
