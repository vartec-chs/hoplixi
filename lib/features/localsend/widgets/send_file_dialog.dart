import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/common/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/controllers/index.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// Диалог выбора и отправки файлов
class SendFileDialog extends ConsumerStatefulWidget {
  const SendFileDialog({super.key, required this.targetDevice});

  final DeviceInfo targetDevice;

  @override
  ConsumerState<SendFileDialog> createState() => _SendFileDialogState();
}

class _SendFileDialogState extends ConsumerState<SendFileDialog> {
  static const String _logTag = 'SendFileDialog';
  static const int _maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const int _maxFiles = 10;

  List<File> _selectedFiles = [];
  bool _isPickingFiles = false;
  bool _isSendingFiles = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_upload_outlined, size: 24, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Отправить файлы на ${widget.targetDevice.name}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Кнопки выбора файлов
            Row(
              children: [
                Expanded(
                  child: SmoothButton(
                    type: SmoothButtonType.outlined,
                    size: SmoothButtonSize.medium,
                    label: 'Выбрать файлы',
                    icon: Icon(Icons.file_present, size: 16),
                    onPressed: _isPickingFiles || _isSendingFiles
                        ? null
                        : () => _pickFiles(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SmoothButton(
                    type: SmoothButtonType.outlined,
                    size: SmoothButtonSize.medium,
                    label: 'Выбрать папку',
                    icon: Icon(Icons.folder_open, size: 16),
                    onPressed: _isPickingFiles || _isSendingFiles
                        ? null
                        : () => _pickFiles(true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Информация о лимитах
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Максимум $_maxFiles файлов, до ${_formatFileSize(_maxFileSize)} каждый',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Список выбранных файлов
            Expanded(
              child: _selectedFiles.isEmpty
                  ? _buildEmptyState(theme, colors)
                  : _buildFilesList(theme, colors),
            ),

            // Статус операции
            if (_isPickingFiles || _isSendingFiles)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isPickingFiles
                          ? 'Выбор файлов...'
                          : 'Отправка файлов...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        SmoothButton(
          type: SmoothButtonType.outlined,
          size: SmoothButtonSize.medium,
          label: 'Отмена',
          onPressed: _isSendingFiles ? null : () => Navigator.of(context).pop(),
        ),
        if (_selectedFiles.isNotEmpty)
          SmoothButton(
            type: SmoothButtonType.outlined,
            size: SmoothButtonSize.medium,
            label: 'Очистить',
            icon: Icon(Icons.clear, size: 16),
            onPressed: _isSendingFiles
                ? null
                : () => setState(() => _selectedFiles.clear()),
          ),
        SmoothButton(
          type: SmoothButtonType.filled,
          size: SmoothButtonSize.medium,
          label: 'Отправить',
          icon: Icon(Icons.send, size: 16),
          onPressed: _canSendFiles() ? _sendFiles : null,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_upload_outlined,
            size: 64,
            color: colors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Файлы не выбраны',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите файлы или папку для отправки',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок списка
        Row(
          children: [
            Text(
              'Выбранные файлы (${_selectedFiles.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _getTotalSizeText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Список файлов
        Expanded(
          child: ListView.separated(
            itemCount: _selectedFiles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              final stat = file.statSync();
              final isLarge = stat.size > _maxFileSize;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLarge
                      ? colors.errorContainer.withOpacity(0.3)
                      : colors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLarge
                        ? colors.error.withOpacity(0.3)
                        : colors.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(file.path),
                      size: 20,
                      color: isLarge
                          ? colors.error
                          : colors.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(file.path),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isLarge ? colors.error : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(stat.size),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isLarge
                                  ? colors.error
                                  : colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (isLarge)
                            Text(
                              'Файл слишком большой',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                      onPressed: _isSendingFiles
                          ? null
                          : () =>
                                setState(() => _selectedFiles.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  IconData _getFileIcon(String path) {
    final extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  String _getTotalSizeText() {
    final totalSize = _selectedFiles
        .map((file) => file.statSync().size)
        .reduce((a, b) => a + b);
    return 'Общий размер: ${_formatFileSize(totalSize)}';
  }

  bool _canSendFiles() {
    return _selectedFiles.isNotEmpty &&
        !_isSendingFiles &&
        !_isPickingFiles &&
        _selectedFiles.length <= _maxFiles &&
        _selectedFiles.every((file) => file.statSync().size <= _maxFileSize);
  }

  Future<void> _pickFiles(bool pickDirectory) async {
    setState(() {
      _isPickingFiles = true;
    });

    try {
      List<File> pickedFiles = [];

      if (pickDirectory) {
        final directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath != null) {
          final directory = Directory(directoryPath);
          final entities = await directory.list(recursive: true).toList();
          pickedFiles = entities.whereType<File>().take(_maxFiles).toList();
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
        );
        if (result != null) {
          pickedFiles = result.paths
              .whereType<String>()
              .map((path) => File(path))
              .take(_maxFiles)
              .toList();
        }
      }

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedFiles.addAll(pickedFiles);
          // Убираем дубликаты по пути
          final uniquePaths = <String>{};
          _selectedFiles = _selectedFiles
              .where((file) => uniquePaths.add(file.path))
              .take(_maxFiles)
              .toList();
        });

        logInfo(
          'Files selected',
          tag: _logTag,
          data: {'count': _selectedFiles.length, 'directory': pickDirectory},
        );
      }
    } catch (e) {
      logError('Error picking files', error: e, tag: _logTag);

      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Не удалось выбрать файлы',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFiles = false;
        });
      }
    }
  }

  Future<void> _sendFiles() async {
    if (!_canSendFiles()) return;

    setState(() {
      _isSendingFiles = true;
    });

    try {
      logInfo(
        'Sending files to device: ${widget.targetDevice.name}',
        tag: _logTag,
        data: {
          'deviceId': widget.targetDevice.id,
          'fileCount': _selectedFiles.length,
        },
      );

      final controller = ref.read(localSendControllerProvider);
      final filePaths = _selectedFiles.map((file) => file.path).toList();

      final success = await controller.sendFiles(
        widget.targetDevice.id,
        filePaths,
      );

      if (success && mounted) {
        ToastHelper.success(
          title: 'Файлы отправлены',
          description:
              'Файлы (${_selectedFiles.length}) отправлены на ${widget.targetDevice.name}',
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ToastHelper.error(
          title: 'Ошибка отправки',
          description: 'Не удалось отправить файлы',
        );
      }
    } catch (e) {
      logError('Error sending files', error: e, tag: _logTag);

      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Произошла ошибка при отправке файлов',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingFiles = false;
        });
      }
    }
  }
}
