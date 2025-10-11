import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/icons_manager/icons.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';

import '../categories_manager_control.dart';

/// Форма для создания и редактирования категории
class CategoryFormModal extends ConsumerStatefulWidget {
  /// Категория для редактирования (null для создания новой)
  final store.Category? category;

  /// Callback при успешном сохранении
  final VoidCallback? onSaved;

  const CategoryFormModal({super.key, this.category, this.onSaved});

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Color _selectedColor = Colors.blue;
  CategoryType _selectedType = CategoryType.mixed;
  String? _selectedIconId;
  store.IconData? _selectedIcon;
  bool _isLoading = false;
  bool _iconWasCleared = false; // Флаг для отслеживания очистки иконки
  String? _originalIconId; // Исходная иконка при редактировании

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditing && widget.category != null) {
      final category = widget.category!;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _selectedType = category.type;
      _selectedIconId = category.iconId;
      _originalIconId = category.iconId; // Сохраняем оригинальную иконку

      // Парсим цвет из HEX строки
      try {
        final colorValue = int.parse(category.color, radix: 16);
        _selectedColor = Color(0xFF000000 | colorValue);
      } catch (e) {
        _selectedColor = Colors.blue;
      }

      // Загружаем данные иконки если есть ID
      if (_selectedIconId != null) {
        _loadIconData(_selectedIconId!);
      }
    }
  }

  Future<void> _loadIconData(String iconId) async {
    try {
      final iconData = await ref.read(iconByIdProvider(iconId).future);
      if (mounted && iconData != null) {
        setState(() {
          _selectedIcon = iconData;
        });
      }
    } catch (e, stackTrace) {
      logError('Ошибка загрузки иконки', error: e, stackTrace: stackTrace);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось загрузить иконку: ${e.toString()}',
      );
      // Иконка не найдена или ошибка загрузки
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
    final breakpoints = ResponsiveBreakpoints.of(context);
    final isMobile = breakpoints.isMobile;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 600,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isMobile),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: _buildForm(),
              ),
            ),
          ),
          _buildActions(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing ? 'Редактировать категорию' : 'Создать категорию',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поле имени
          PrimaryTextFormField(
            label: 'Название категории *',
            controller: _nameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название категории *',
              hintText: 'Введите название категории',
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Название категории обязательно';
              }
              if (value!.length > 100) {
                return 'Название слишком длинное (максимум 100 символов)';
              }
              return null;
            },
            maxLength: 100,
            textInputAction: TextInputAction.next,
          ),

          // Поле описания
          PrimaryTextFormField(
            label: 'Описание',
            controller: _descriptionController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание',
              hintText: 'Введите описание категории (необязательно)',
            ),
            maxLines: 3,
            maxLength: 500,
            validator: (value) {
              if (value != null && value.length > 500) {
                return 'Описание слишком длинное (максимум 500 символов)';
              }
              return null;
            },
            textInputAction: TextInputAction.newline,
          ),

          // Выбор типа категории
          Text(
            'Тип категории *',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          _buildTypeSelector(),

          // Выбор цвета
          Text(
            'Цвет категории *',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          _buildColorPicker(),

          // Выбор иконки
          Text(
            'Иконка категории',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          _buildIconPicker(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CategoryType.values.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(_getCategoryTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedType = type);
            }
          },
          avatar: Icon(_getCategoryTypeIcon(type), size: 18),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return InkWell(
      onTap: _showColorPickerDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Цвет: ${_colorToHex(_selectedColor)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Center(
      child: IconPickerButton(
        selectedIconId: _selectedIconId,
        selectedIcon: _selectedIcon,
        onIconSelected: (iconId) {
          setState(() {
            _selectedIconId = iconId;
            _iconWasCleared = false; // Сбрасываем флаг при выборе новой иконки
          });
          _loadIconData(iconId);
        },
        onIconCleared: () {
          setState(() {
            _selectedIconId = null;
            _selectedIcon = null;
            // Устанавливаем флаг очистки только если изначально была иконка
            _iconWasCleared = _originalIconId != null;
          });
        },
        label: 'Нажмите для выбора иконки',
        size: 80,
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SmoothButton(
              type: SmoothButtonType.outlined,
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              label: 'Отмена',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SmoothButton(
              onPressed: _isLoading ? null : _saveCategory,
              loading: _isLoading,
              label: _isEditing ? "Сохранить" : "Создать",
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(categoriesManagerControllerProvider.notifier);
      final colorHex = _colorToHex(_selectedColor);

      bool success;
      if (_isEditing) {
        // Определяем iconId для передачи в updateCategory
        String? iconIdToSend;
        if (_iconWasCleared) {
          // Если иконка была очищена, передаем null для принудительной очистки
          iconIdToSend = null;
        } else if (_selectedIconId != _originalIconId) {
          // Если иконка изменилась, передаем новую иконку
          iconIdToSend = _selectedIconId;
        } else {
          // Если иконка не изменилась, не передаем это поле (оставляем как есть)
          iconIdToSend = _selectedIconId;
        }

        logDebug(
          'Сохранение категории: иконка',
          tag: 'CategoryFormModal',
          data: {
            'originalIconId': _originalIconId,
            'selectedIconId': _selectedIconId,
            'iconWasCleared': _iconWasCleared,
            'iconIdToSend': iconIdToSend,
          },
        );

        success = await controller.updateCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          iconId: iconIdToSend,
          color: colorHex,
          type: _selectedType,
        );
      } else {
        success = await controller.createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          iconId: _selectedIconId,
          color: colorHex,
          type: _selectedType,
        );
      }

      if (success && mounted) {
        widget.onSaved?.call();
        try {
          DataRefreshHelper.refreshAll(ref);
        } catch (e) {
          logError('Error notifying password change: $e');
        }
        Navigator.of(context).pop();

        // Показываем сообщение об успехе
        ToastHelper.success(
          title: 'Успех',
          description: _isEditing
              ? 'Категория успешно обновлена'
              : 'Категория успешно создана',
        );
      } else {
        // Ошибка будет показана через провайдер ошибок
        final error = ref.read(categoriesErrorProvider);
        if (error != null && mounted) {
          ToastHelper.error(title: 'Ошибка', description: error);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(8),
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            pickerAreaBorderRadius: BorderRadius.circular(8),
          ),
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Отмена',
            type: SmoothButtonType.outlined,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Выбрать',
          ),
        ],
      ),
    );
  }

  String _getCategoryTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.totp:
        return 'TOTP коды';
      case CategoryType.mixed:
        return 'Смешанная';
    }
  }

  IconData _getCategoryTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.lock;
      case CategoryType.notes:
        return Icons.note;
      case CategoryType.totp:
        return Icons.security;
      case CategoryType.mixed:
        return Icons.folder;
    }
  }

  String _colorToHex(Color color) {
    return color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }
}

/// Показывает модальное окно для создания/редактирования категории
Future<void> showCategoryFormModal({
  required BuildContext context,
  store.Category? category,
  VoidCallback? onSaved,
}) async {
  final breakpoints = ResponsiveBreakpoints.of(context);
  final isMobile = breakpoints.isMobile;

  if (isMobile) {
    // На мобильных показываем bottom sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,

      builder: (context) => SafeArea(
        child: CategoryFormModal(category: category, onSaved: onSaved),
      ),
    );
  } else {
    // На десктопе/планшете показываем диалог
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(8),
        child: CategoryFormModal(category: category, onSaved: onSaved),
      ),
    );
  }
}
