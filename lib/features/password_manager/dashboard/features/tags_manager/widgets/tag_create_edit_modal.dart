import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import '../tags_management_control.dart';

class TagCreateEditModal extends ConsumerStatefulWidget {
  final store.Tag? tag;

  const TagCreateEditModal({Key? key, this.tag}) : super(key: key);

  @override
  ConsumerState<TagCreateEditModal> createState() => _TagCreateEditModalState();
}

class _TagCreateEditModalState extends ConsumerState<TagCreateEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late TagType _selectedType;
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  bool get isEditing => widget.tag != null;

  @override
  void initState() {
    super.initState();

    if (widget.tag != null) {
      _nameController.text = widget.tag!.name;
      _selectedType = widget.tag!.type;

      if (widget.tag!.color != null && widget.tag!.color!.isNotEmpty) {
        try {
          _selectedColor = Color(
            int.parse(widget.tag!.color!.replaceAll('#', '0xFF')),
          );
        } catch (e) {
          _selectedColor = _getDefaultTypeColor(_selectedType);
        }
      } else {
        _selectedColor = _getDefaultTypeColor(_selectedType);
      }
    } else {
      _selectedType = TagType.mixed;
      _selectedColor = _getDefaultTypeColor(_selectedType);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _getDefaultTypeColor(TagType type) {
    switch (type) {
      case TagType.password:
        return Colors.blue;
      case TagType.notes:
        return Colors.green;
      case TagType.totp:
        return Colors.orange;
      case TagType.mixed:
        return Colors.purple;
    }
  }

  String _getTypeLabel(TagType type) {
    switch (type) {
      case TagType.password:
        return 'Пароли';
      case TagType.notes:
        return 'Заметки';
      case TagType.totp:
        return 'TOTP';
      case TagType.mixed:
        return 'Смешанный';
    }
  }

  IconData _getTypeIcon(TagType type) {
    switch (type) {
      case TagType.password:
        return Icons.lock;
      case TagType.notes:
        return Icons.note;
      case TagType.totp:
        return Icons.security;
      case TagType.mixed:
        return Icons.category;
    }
  }

  Future<void> _selectColor() async {
    Color? pickedColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => pickedColor = color,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (pickedColor != null) {
                setState(() {
                  _selectedColor = pickedColor!;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = isEditing
          ? await ref
                .read(tagsManagementProvider.notifier)
                .updateTag(
                  id: widget.tag!.id,
                  name: _nameController.text.trim(),
                  color: _colorToHex(_selectedColor),
                  type: _selectedType,
                )
          : await ref
                .read(tagsManagementProvider.notifier)
                .createTag(
                  name: _nameController.text.trim(),
                  color: _colorToHex(_selectedColor),
                  type: _selectedType,
                );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Тег обновлен' : 'Тег создан')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagsManagementProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Редактировать тег' : 'Создать тег',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Поле имени
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название тега',
                hintText: 'Введите название тега',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Название не может быть пустым';
                }
                if (value.trim().length > 50) {
                  return 'Название не может превышать 50 символов';
                }
                return null;
              },
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Выбор типа
            DropdownButtonFormField<TagType>(
              value: _selectedType,
              onChanged: (TagType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedType = newValue;
                    // Автоматически обновляем цвет при смене типа, если это новый тег
                    if (!isEditing) {
                      _selectedColor = _getDefaultTypeColor(newValue);
                    }
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Тип тега',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: TagType.values.map((TagType type) {
                return DropdownMenuItem<TagType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getTypeLabel(type)),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Выбор цвета
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _selectedColor,
                child: const Icon(Icons.palette, color: Colors.white),
              ),
              title: const Text('Цвет тега'),
              subtitle: Text(_colorToHex(_selectedColor)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),

            const SizedBox(height: 24),

            // Ошибка
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Кнопки
            Row(
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
                    onPressed: _isLoading ? null : _saveTag,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Сохранить' : 'Создать'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
