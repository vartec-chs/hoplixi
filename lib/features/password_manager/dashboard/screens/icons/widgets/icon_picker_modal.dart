import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

class IconPickerModal extends ConsumerStatefulWidget {
  final bool isBottomSheet;

  const IconPickerModal({super.key, this.isBottomSheet = false});

  @override
  ConsumerState<IconPickerModal> createState() => _IconPickerModalState();
}

class _IconPickerModalState extends ConsumerState<IconPickerModal> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IconType _selectedType = IconType.png;
  Uint8List? _selectedFileData;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: widget.isBottomSheet ? double.infinity : 500,
      padding: EdgeInsets.only(
        bottom: widget.isBottomSheet ? mediaQuery.viewInsets.bottom : 0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Добавить иконку',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (widget.isBottomSheet)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File selection area
                  _buildFileSelectionArea(theme),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название иконки',
                      hintText: 'Введите название',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название иконки';
                      }
                      if (value.trim().length < 2) {
                        return 'Название должно содержать минимум 2 символа';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type selection
                  _buildTypeSelection(theme),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadIcon,
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Добавить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionArea(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFileData != null
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedFileData != null
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (_selectedFileData != null) ...[
                  // Preview of selected file
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedFileData!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 48,
                            color: theme.colorScheme.error,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName ?? 'Файл выбран',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите для смены файла',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  // File selection prompt
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выберите файл иконки',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Поддерживаемые форматы: PNG, JPG, SVG, GIF, BMP, WebP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Нажмите для выбора',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип файла',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IconType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              avatar: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'gif', 'bmp', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedFileData = file.bytes!;
            _selectedFileName = file.name;

            // Auto-detect file type
            final extension = file.extension?.toLowerCase();
            if (extension != null) {
              switch (extension) {
                case 'png':
                  _selectedType = IconType.png;
                  break;
                case 'jpg':
                case 'jpeg':
                  _selectedType = IconType.jpg;
                  break;
                case 'svg':
                  _selectedType = IconType.svg;
                  break;
                case 'gif':
                  _selectedType = IconType.gif;
                  break;
                case 'bmp':
                  _selectedType = IconType.bmp;
                  break;
                case 'webp':
                  _selectedType = IconType.webp;
                  break;
              }
            }

            // Auto-fill name if empty
            if (_nameController.text.isEmpty) {
              final nameWithoutExtension = file.name.split('.').first;
              _nameController.text = nameWithoutExtension;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка при выборе файла',
          context: context,
          description: e.toString(),
        );
      }
    }
  }

  Future<void> _uploadIcon() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileData == null) {
      ToastHelper.info(title: 'Выберите файл для загрузки', context: context);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final createState = ref.read(createIconStateProvider.notifier);

      final success = await createState.createIcon(
        name: _nameController.text.trim(),
        type: _selectedType,
        data: _selectedFileData!,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ToastHelper.success(
          title: 'Иконка успешно добавлена',
          context: context,
          description:
              'Иконка "${_nameController.text.trim()}" успешно добавлена',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка при загрузке иконки',
          context: context,
          description: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
