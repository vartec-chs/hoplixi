import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/features/localsend_rc/models/file_transfer.dart';

/// Виджет для отображения карточки передачи файла
class FileTransferCard extends ConsumerWidget {
  final FileTransfer transfer;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const FileTransferCard({
    super.key,
    required this.transfer,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с именем файла и иконкой
            Row(
              children: [
                Icon(
                  _getFileIcon(transfer.metadata.extension),
                  size: isMobile ? 20 : 24,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.metadata.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatFileSize(transfer.metadata.size)} • ${_getDirectionName(transfer.direction)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Статус и действия
                _buildActionButtons(context, isMobile),
              ],
            ),

            const SizedBox(height: 12),

            // Прогресс-бар
            if (_shouldShowProgress(transfer.state)) ...[
              _buildProgressBar(context),
              const SizedBox(height: 8),
            ],

            // Информация о передаче
            _buildTransferInfo(context, theme),

            // Сообщение об ошибке
            if (transfer.error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        transfer.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Создает кнопки действий
  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Для входящих файлов в состоянии ожидания
    if (transfer.direction == FileTransferDirection.incoming &&
        transfer.state == FileTransferState.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothButton(
            type: SmoothButtonType.filled,
            size: isMobile ? SmoothButtonSize.small : SmoothButtonSize.medium,
            label: 'Принять',
            onPressed: onAccept,
          ),
          const SizedBox(width: 8),
          SmoothButton(
            type: SmoothButtonType.outlined,
            size: isMobile ? SmoothButtonSize.small : SmoothButtonSize.medium,
            label: 'Отклонить',
            onPressed: onReject,
          ),
        ],
      );
    }

    // Для активных передач
    if (transfer.state.isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (transfer.state.canPause)
            IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause),
              tooltip: 'Приостановить',
              color: colors.primary,
            ),
          if (transfer.state.canResume)
            IconButton(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Возобновить',
              color: colors.primary,
            ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Отменить',
            color: colors.error,
          ),
        ],
      );
    }

    // Иконка состояния для завершенных/отмененных передач
    return Icon(
      _getStateIcon(transfer.state),
      color: _getStateColor(transfer.state, colors),
      size: isMobile ? 20 : 24,
    );
  }

  /// Создает прогресс-бар
  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(transfer.progress * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (transfer.speed > 0)
              Text(
                '${_formatSpeed(transfer.speed)}/с',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: transfer.progress.clamp(0.0, 1.0),
            backgroundColor: colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              transfer.state == FileTransferState.paused
                  ? colors.outline
                  : colors.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Создает информацию о передаче
  Widget _buildTransferInfo(BuildContext context, ThemeData theme) {
    final colors = theme.colorScheme;
    final items = <Widget>[];

    // Статус
    items.add(
      _buildInfoItem(
        icon: Icons.info_outline,
        label: 'Статус',
        value: transfer.state.displayName,
        color: _getStateColor(transfer.state, colors),
      ),
    );

    // Время передачи
    if (transfer.startTime != null) {
      final duration = transfer.endTime != null
          ? transfer.endTime!.difference(transfer.startTime!)
          : DateTime.now().difference(transfer.startTime!);

      items.add(
        _buildInfoItem(
          icon: Icons.schedule,
          label: transfer.endTime != null ? 'Время' : 'Прошло',
          value: _formatDuration(duration),
        ),
      );
    }

    // ETA для активных передач
    if (transfer.state.isActive && transfer.estimatedTimeRemaining != null) {
      items.add(
        _buildInfoItem(
          icon: Icons.schedule_outlined,
          label: 'Осталось',
          value: _formatDuration(transfer.estimatedTimeRemaining!),
        ),
      );
    }

    // Локальный путь для завершенных передач
    if (transfer.state == FileTransferState.completed &&
        transfer.localPath != null) {
      items.add(
        _buildInfoItem(
          icon: Icons.folder_outlined,
          label: 'Сохранено',
          value: transfer.localPath!,
          isPath: true,
        ),
      );
    }

    return Wrap(spacing: 16, runSpacing: 4, children: items);
  }

  /// Создает элемент информации
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    bool isPath = false,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color ?? colors.onSurface,
                  fontFamily: isPath ? 'monospace' : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Получает иконку файла по расширению
  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file_outlined;

    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
        return Icons.image_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_outlined;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive_outlined;
      case 'txt':
        return Icons.text_snippet_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Получает иконку состояния
  IconData _getStateIcon(FileTransferState state) {
    switch (state) {
      case FileTransferState.pending:
        return Icons.schedule;
      case FileTransferState.transferring:
        return Icons.sync;
      case FileTransferState.completed:
        return Icons.check_circle;
      case FileTransferState.cancelled:
        return Icons.cancel;
      case FileTransferState.failed:
        return Icons.error;
      case FileTransferState.paused:
        return Icons.pause_circle;
    }
  }

  /// Получает цвет состояния
  Color _getStateColor(FileTransferState state, ColorScheme colors) {
    switch (state) {
      case FileTransferState.pending:
        return colors.outline;
      case FileTransferState.transferring:
        return colors.primary;
      case FileTransferState.completed:
        return colors.primary;
      case FileTransferState.cancelled:
        return colors.outline;
      case FileTransferState.failed:
        return colors.error;
      case FileTransferState.paused:
        return colors.outline;
    }
  }

  /// Форматирует размер файла
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Форматирует скорость передачи
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(0)} B';
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB';
    }
    if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Форматирует продолжительность
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Получает название направления передачи
  String _getDirectionName(FileTransferDirection direction) {
    switch (direction) {
      case FileTransferDirection.outgoing:
        return 'Отправка';
      case FileTransferDirection.incoming:
        return 'Получение';
    }
  }

  /// Определяет, нужно ли показывать прогресс
  bool _shouldShowProgress(FileTransferState state) {
    switch (state) {
      case FileTransferState.transferring:
      case FileTransferState.paused:
        return true;
      case FileTransferState.pending:
      case FileTransferState.completed:
      case FileTransferState.cancelled:
      case FileTransferState.failed:
        return false;
    }
  }
}

/// Виджет для отображения списка передач файлов
class FileTransferList extends ConsumerWidget {
  final List<FileTransfer> transfers;
  final Function(String transferId)? onCancelTransfer;
  final Function(String transferId)? onPauseTransfer;
  final Function(String transferId)? onResumeTransfer;
  final Function(String transferId)? onAcceptTransfer;
  final Function(String transferId)? onRejectTransfer;

  const FileTransferList({
    super.key,
    required this.transfers,
    this.onCancelTransfer,
    this.onPauseTransfer,
    this.onResumeTransfer,
    this.onAcceptTransfer,
    this.onRejectTransfer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transfers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Нет активных передач файлов',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return FileTransferCard(
          transfer: transfer,
          onCancel: onCancelTransfer != null
              ? () => onCancelTransfer!(transfer.id)
              : null,
          onPause: onPauseTransfer != null && transfer.state.canPause
              ? () => onPauseTransfer!(transfer.id)
              : null,
          onResume: onResumeTransfer != null && transfer.state.canResume
              ? () => onResumeTransfer!(transfer.id)
              : null,
          onAccept:
              onAcceptTransfer != null &&
                  transfer.direction == FileTransferDirection.incoming &&
                  transfer.state == FileTransferState.pending
              ? () => onAcceptTransfer!(transfer.id)
              : null,
          onReject:
              onRejectTransfer != null &&
                  transfer.direction == FileTransferDirection.incoming &&
                  transfer.state == FileTransferState.pending
              ? () => onRejectTransfer!(transfer.id)
              : null,
        );
      },
    );
  }
}

/// Кнопка для выбора и отправки файлов
class SendFilesButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const SendFilesButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return SmoothButton(
      type: SmoothButtonType.filled,
      size: isMobile ? SmoothButtonSize.medium : SmoothButtonSize.large,
      label: 'Отправить файлы',
      onPressed: isEnabled ? onPressed : null,
    );
  }
}
