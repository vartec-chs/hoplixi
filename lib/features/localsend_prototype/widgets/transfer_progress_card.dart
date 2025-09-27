import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/index.dart';

/// Карточка прогресса передачи файла с кнопками управления
class TransferProgressCard extends ConsumerWidget {
  final String transferId;
  final String fileName;
  final int fileSize;
  final double progress;
  final String status;
  final bool isOutgoing;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const TransferProgressCard({
    super.key,
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.progress,
    required this.status,
    required this.isOutgoing,
    this.onResume,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with file info and status
            Row(
              children: [
                // File icon
                Icon(_getFileIcon(), size: 24, color: colors.primary),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatFileSize(fileSize),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.onSurface.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOutgoing ? 'Отправка' : 'Получение',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                _buildStatusIndicator(context),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(context),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),

            // Control buttons
            if (_shouldShowButtons()) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Retry button
                  if (status == 'Ошибка' && onRetry != null) ...[
                    SmoothButton(
                      type: SmoothButtonType.outlined,
                      size: SmoothButtonSize.small,
                      label: 'Повторить',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Resume button
                  if ((status == 'Приостановлено' || status == 'Прервано') &&
                      onResume != null) ...[
                    SmoothButton(
                      type: SmoothButtonType.filled,
                      size: SmoothButtonSize.small,
                      label: 'Продолжить',
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow, size: 16),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Cancel button
                  if ((status == 'В процессе' || status == 'Приостановлено') &&
                      onCancel != null)
                    SmoothButton(
                      type: SmoothButtonType.text,
                      size: SmoothButtonSize.small,
                      label: 'Отменить',
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    IconData icon;
    Color color;

    switch (status) {
      case 'В процессе':
        icon = Icons.sync;
        color = colors.primary;
        break;
      case 'Завершено':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Ошибка':
        icon = Icons.error;
        color = colors.error;
        break;
      case 'Приостановлено':
      case 'Прервано':
        icon = Icons.pause_circle;
        color = colors.tertiary;
        break;
      default:
        icon = Icons.info;
        color = colors.onSurface.withOpacity(0.7);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  IconData _getFileIcon() {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'exe':
      case 'msi':
        return Icons.apps;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Color _getStatusColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (status) {
      case 'В процессе':
        return colors.primary;
      case 'Завершено':
        return Colors.green;
      case 'Ошибка':
        return colors.error;
      case 'Приостановлено':
      case 'Прервано':
        return colors.tertiary;
      default:
        return colors.onSurface.withOpacity(0.7);
    }
  }

  Color _getProgressColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (status) {
      case 'В процессе':
        return colors.primary;
      case 'Завершено':
        return Colors.green;
      case 'Ошибка':
        return colors.error;
      case 'Приостановлено':
      case 'Прервано':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  bool _shouldShowButtons() {
    return status == 'Ошибка' ||
        status == 'Приостановлено' ||
        status == 'Прервано' ||
        status == 'В процессе';
  }
}
