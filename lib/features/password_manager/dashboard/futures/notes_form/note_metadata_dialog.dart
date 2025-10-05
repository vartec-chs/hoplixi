import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_picker/tags_picker.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Модель метаданных заметки
class NoteMetadata {
  final String title;
  final String? description;
  final String? categoryId;
  final List<String> tagIds;

  NoteMetadata({
    required this.title,
    this.description,
    this.categoryId,
    this.tagIds = const [],
  });

  NoteMetadata copyWith({
    String? title,
    String? description,
    String? categoryId,
    List<String>? tagIds,
  }) {
    return NoteMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}

/// Диалог для редактирования метаданных заметки
class NoteMetadataDialog extends ConsumerStatefulWidget {
  final NoteMetadata? initialMetadata;
  final bool isEditing;

  const NoteMetadataDialog({
    super.key,
    this.initialMetadata,
    this.isEditing = false,
  });

  @override
  ConsumerState<NoteMetadataDialog> createState() => _NoteMetadataDialogState();
}

class _NoteMetadataDialogState extends ConsumerState<NoteMetadataDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String? _categoryId;
  List<String> _tagIds = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMetadata;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _categoryId = initial?.categoryId;
    _tagIds = List.from(initial?.tagIds ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Валидация вручную
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Название обязательно')));
      return;
    }

    if (_titleController.text.trim().length > 255) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Название не должно превышать 255 символов'),
        ),
      );
      return;
    }

    final metadata = NoteMetadata(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _categoryId,
      tagIds: _tagIds,
    );
    Navigator.of(context).pop(metadata);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Редактировать метаданные заметки'
                          : 'Сохранить заметку',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _onCancel,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Поля формы
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Название
                      PrimaryTextField(
                        controller: _titleController,
                        label: 'Название',
                        hintText: 'Введите название заметки',
                        autofocus: true,
                        maxLength: 255,
                      ),

                      const SizedBox(height: 16),

                      // Описание
                      PrimaryTextField(
                        controller: _descriptionController,
                        label: 'Описание',
                        hintText: 'Введите описание заметки (необязательно)',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Категория
                      CategoriesPicker(
                        categoryType: CategoryType.notes,
                        maxSelection: 1,
                        selectedCategoryIds: _categoryId != null
                            ? [_categoryId!]
                            : [],
                        onSelect: (selectedIds) {
                          setState(() {
                            _categoryId = selectedIds.isNotEmpty
                                ? selectedIds.first
                                : null;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _categoryId = null;
                          });
                        },
                        labelText: 'Категория',
                        hintText: 'Выберите категорию (необязательно)',
                      ),

                      const SizedBox(height: 16),

                      // Теги
                      TagsPicker(
                        tagType: TagType.notes,
                        maxSelection: 10,
                        selectedTagIds: _tagIds,
                        onSelect: (selectedIds) {
                          setState(() {
                            _tagIds = selectedIds;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _tagIds = [];
                          });
                        },
                        labelText: 'Теги',
                        hintText: 'Выберите теги (необязательно)',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SmoothButton(
                    onPressed: _onCancel,
                    label: 'Отмена',
                    type: SmoothButtonType.outlined,
                  ),
                  const SizedBox(width: 12),
                  SmoothButton(
                    onPressed: _onSave,
                    label: widget.isEditing ? 'Обновить' : 'Сохранить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показывает диалог метаданных заметки
Future<NoteMetadata?> showNoteMetadataDialog(
  BuildContext context, {
  NoteMetadata? initialMetadata,
  bool isEditing = false,
}) async {
  return showDialog<NoteMetadata>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NoteMetadataDialog(
      initialMetadata: initialMetadata,
      isEditing: isEditing,
    ),
  );
}
