import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';

class IconUploadWidget extends ConsumerStatefulWidget {
  final Function(String iconId)? onIconUploaded;

  const IconUploadWidget({super.key, this.onIconUploaded});

  @override
  ConsumerState<IconUploadWidget> createState() => _IconUploadWidgetState();
}

class _IconUploadWidgetState extends ConsumerState<IconUploadWidget> {
  Uint8List? _selectedFileData;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          onTap: _isUploading ? null : _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_selectedFileData != null) ...[
                  // Preview of selected file
                  Container(
                    width: 80,
                    height: 80,
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
                            size: 32,
                            color: theme.colorScheme.error,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFileName ?? 'Файл выбран',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (_isUploading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Загрузка...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _uploadIcon,
                          icon: const Icon(Icons.upload),
                          label: const Text('Загрузить'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.clear),
                          label: const Text('Очистить'),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  // File selection prompt
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Выберите иконку',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG, SVG, GIF, BMP, WebP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessengerManager.instance.showError(
        //   'Ошибка при выборе файла: $e',
        // );
        ToastHelper.error(
          title: 'Ошибка при выборе файла',
          context: context,
          description: e.toString(),
        );
      }
    }
  }

  Future<void> _uploadIcon() async {
    if (_selectedFileData == null) return;

    setState(() => _isUploading = true);

    try {
      // Auto-detect file type from extension
      IconType iconType = IconType.png;
      if (_selectedFileName != null) {
        final extension = _selectedFileName!.split('.').last.toLowerCase();
        switch (extension) {
          case 'png':
            iconType = IconType.png;
            break;
          case 'jpg':
          case 'jpeg':
            iconType = IconType.jpg;
            break;
          case 'svg':
            iconType = IconType.svg;
            break;
          case 'gif':
            iconType = IconType.gif;
            break;
          case 'bmp':
            iconType = IconType.bmp;
            break;
          case 'webp':
            iconType = IconType.webp;
            break;
        }
      }

      final createState = ref.read(createIconStateProvider.notifier);
      final name = _selectedFileName?.split('.').first ?? 'Иконка';

      final success = await createState.createIcon(
        name: name,
        type: iconType,
        data: _selectedFileData!,
      );

      if (success && mounted) {
        // Get the created icon ID (this would need to be returned from createIcon)
        // For now, we'll just call the callback with a placeholder
        widget.onIconUploaded?.call('new-icon-id');

        ToastHelper.success(
          title: 'Иконка успешно загружена',
          context: context,
        );

        _clearSelection();
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

  void _clearSelection() {
    setState(() {
      _selectedFileData = null;
      _selectedFileName = null;
    });
  }
}
