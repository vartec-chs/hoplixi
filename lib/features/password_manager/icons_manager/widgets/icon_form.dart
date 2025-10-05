import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services/service_results.dart';

/// Форма для добавления или редактирования иконки
class IconFormWidget extends ConsumerStatefulWidget {
  final store.IconData? existingIcon;

  const IconFormWidget({super.key, this.existingIcon});

  @override
  ConsumerState<IconFormWidget> createState() => _IconFormWidgetState();
}

class _IconFormWidgetState extends ConsumerState<IconFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  IconType _selectedType = IconType.png;
  Uint8List? _selectedImageData;
  String? _selectedFileName;
  bool _isLoading = false;

  bool get _isEditing => widget.existingIcon != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    final icon = widget.existingIcon!;
    _nameController.text = icon.name;
    _selectedType = icon.type;
    _selectedImageData = icon.data;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svg', 'bmp', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          // Проверяем размер файла (максимум 5 МБ для обычных изображений, 10 МБ для SVG)
          final maxSize = file.extension?.toLowerCase() == 'svg'
              ? 10 * 1024 * 1024
              : 5 * 1024 * 1024;
          if (bytes.length > maxSize) {
            if (mounted) {
              ToastHelper.error(
                title: 'Ошибка',
                description:
                    'Файл слишком большой. Максимальный размер: ${_formatFileSize(maxSize)}',
                context: context,
              );
            }
            return;
          }

          // Определяем тип файла по расширению
          final extension = file.extension?.toLowerCase() ?? '';
          final IconType detectedType = _getIconTypeFromExtension(extension);

          logDebug(
            'Выбран файл: ${file.name}, тип: $detectedType',
            tag: 'IconForm',
          );

          setState(() {
            _selectedImageData = bytes;
            _selectedFileName = file.name;
            _selectedType = detectedType;
            // Если имя не задано, используем имя файла без расширения
            if (_nameController.text.isEmpty && file.name.isNotEmpty) {
              final nameWithoutExtension = file.name.split('.').first;
              _nameController.text = nameWithoutExtension;
            }
          });

          if (mounted) {
            ToastHelper.success(
              title: 'Успех',
              description: 'Файл "${file.name}" успешно загружен',
              context: context,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Ошибка выбора файла: $e',
          context: context,
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImageData == null) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Пожалуйста, выберите изображение для иконки',
          context: context,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final iconsService = ref.read(iconsServiceProvider);

      late IconResult result;

      if (_isEditing) {
        result = await iconsService.updateIcon(
          id: widget.existingIcon!.id,
          name: _nameController.text.trim(),
          type: _selectedType,
          data: _selectedImageData,
        );

        logDebug(
          'Обновление иконки: ${_nameController.text.trim()}, тип: $_selectedType',
          tag: 'IconForm',
        );
      } else {
        logDebug(
          'Создание новой иконки: ${_nameController.text.trim()}, тип: $_selectedType',
          tag: 'IconForm',
        );
        result = await iconsService.createIcon(
          name: _nameController.text.trim(),
          type: _selectedType,
          data: _selectedImageData!,
        );
      }

      if (mounted) {
        if (result.success) {
          try {
            DataRefreshHelper.refreshAll(ref);
          } catch (e) {
            logError('Error notifying password change: $e');
          }
          ToastHelper.success(
            title: 'Успех',
            description: _isEditing
                ? 'Иконка успешно обновлена'
                : 'Иконка успешно добавлена',
            context: context,
          );
          Navigator.of(context).pop();
        } else {
          ToastHelper.error(
            title: 'Ошибка',
            description: result.message ?? 'Не удалось сохранить иконку',
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Ошибка: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconType _getIconTypeFromExtension(String extension) {
    logDebug(
      'Определение типа иконки по расширению: $extension',
      tag: 'IconForm',
    );
    switch (extension) {
      case 'png':
        return IconType.png;
      case 'jpg':
      case 'jpeg':
        return IconType.jpg;
      case 'svg':
        return IconType.svg;
      case 'gif':
        return IconType.gif;
      case 'bmp':
        return IconType.bmp;
      case 'webp':
        return IconType.webp;
      default:
        return IconType.png; // По умолчанию PNG
    }
  }

  Color _getTypeColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_selectedType) {
      case IconType.svg:
        return colorScheme.primary;
      case IconType.gif:
        return colorScheme.tertiary;
      case IconType.png:
        return colorScheme.secondary;
      case IconType.jpg:
        return colorScheme.error;
      case IconType.webp:
        return colorScheme.primaryContainer;
      case IconType.bmp:
        return colorScheme.outline;
    }
  }

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case IconType.svg:
        return Icons.code;
      case IconType.gif:
        return Icons.gif_box;
      case IconType.png:
        return Icons.image;
      case IconType.jpg:
        return Icons.photo;
      case IconType.webp:
        return Icons.image_outlined;
      case IconType.bmp:
        return Icons.photo_library;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isMobile ? _buildMobileAppBar() : null,
      body: Column(
        children: [
          if (!isMobile) _buildDesktopHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Форма
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  _buildNameField(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(_isEditing ? 'Редактировать иконку' : 'Добавить иконку'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton(onPressed: _submitForm, child: const Text('Сохранить')),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Редактировать иконку' : 'Добавить иконку',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Изображение',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),

        // Превью изображения
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _selectedImageData != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImagePreview(),
                    ),
                    // Кнопка удаления изображения
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImageData = null;
                              _selectedFileName = null;
                              _selectedType = IconType.png;
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выберите изображение',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Поддерживаемые форматы: PNG, JPG, SVG, GIF, BMP, WebP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // Кнопки выбора изображения
        _buildImagePickerButtons(),

        // Информация о размере файла и имени
        if (_selectedImageData != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Файл: ${_selectedFileName ?? 'Неизвестно'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Размер: ${_formatFileSize(_selectedImageData!.length)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor().withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTypeIcon(), size: 12, color: _getTypeColor()),
                    const SizedBox(width: 4),
                    Text(
                      _selectedType.name.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImagePickerButtons() {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SmoothButton(
                  type: SmoothButtonType.outlined,
                  onPressed: _pickFile,
                  icon: const Icon(Icons.photo_library),
                  label: 'Галерея',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: SmoothButton(
              type: SmoothButtonType.outlined,
              onPressed: _pickFile,
              icon: const Icon(Icons.photo_library),
              label: 'Выбрать файл',
            ),
          ),
        ],
      );
    }
  }

  Widget _buildNameField() {
    return PrimaryTextFormField(
      controller: _nameController,
      label: 'Название иконки',
      hintText: 'Введите название...',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Пожалуйста, введите название иконки';
        }
        if (value.length > 100) {
          return 'Название не должно превышать 100 символов';
        }
        return null;
      },
      maxLength: 100,
    );
  }

  Widget _buildActionButtons() {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SmoothButton(
                    onPressed: _isLoading ? null : _submitForm,
                    loading: _isLoading,
                    label: _isEditing ? 'Сохранить' : 'Добавить',
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SmoothButton(
                    type: SmoothButtonType.outlined,
                    loading: _isLoading,
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    label: 'Отмена',
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SmoothButton(
                  type: SmoothButtonType.outlined,
                  loading: _isLoading,
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  label: 'Отмена',
                ),
                const SizedBox(width: 12),
                SmoothButton(
                  onPressed: _isLoading ? null : _submitForm,
                  loading: _isLoading,
                  label: _isEditing ? 'Сохранить' : 'Добавить',
                  icon: Icon(_isEditing ? Icons.save : Icons.add),
                ),
              ],
            ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageData == null) return Container();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _selectedType == IconType.svg
            ? _buildSvgPreview()
            : _buildRasterImagePreview(),
      ),
    );
  }

  Widget _buildSvgPreview() {
    try {
      // Конвертируем bytes в строку для SVG
      final svgString = utf8.decode(_selectedImageData!);

      logDebug('Рендеринг SVG файла: $_selectedFileName', tag: 'IconForm');

      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SvgPicture.string(
          svgString,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholderBuilder: (context) => Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Загрузка SVG...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      logError('Ошибка рендеринга SVG: $e', tag: 'IconForm');

      // Fallback для некорректных SVG файлов
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.code,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'SVG Векторное изображение',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedFileName ?? 'svg-файл',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ошибка рендеринга',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRasterImagePreview() {
    return Image.memory(
      _selectedImageData!,
      key: ValueKey(_selectedFileName),
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      gaplessPlayback: false,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 64,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 8),
              Text(
                'Ошибка превью',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedFileName ?? 'файл',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: frame == null
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Загрузка превью...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : child,
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
