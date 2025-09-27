import 'package:flutter/material.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';

/// Виджет для отображения передачи файла
class FileTransferWidget extends StatelessWidget {
  const FileTransferWidget({
    super.key,
    required this.transfer,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.onRetry,
  });

  final FileTransfer transfer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с информацией о файле
            Row(
              children: [
                Icon(
                  _getFileIcon(),
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${transfer.formattedFileSize} • ${transfer.direction.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(transfer.statusIcon, style: const TextStyle(fontSize: 20)),
              ],
            ),

            const SizedBox(height: 12),

            // Прогресс бар
            if (transfer.status == FileTransferStatus.inProgress) ...[
              LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transfer.progressPercent}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${transfer.formattedTransferSpeed} • ${transfer.formattedTimeRemaining}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            // Статус передачи
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getStatusTextColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (transfer.errorMessage != null)
                  Tooltip(
                    message: transfer.errorMessage!,
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),

            // Кнопки действий
            if (_shouldShowActionButtons()) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final fileName = transfer.fileName.toLowerCase();

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif')) {
      return Icons.image;
    } else if (fileName.endsWith('.mp4') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv')) {
      return Icons.movie;
    } else if (fileName.endsWith('.mp3') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.flac')) {
      return Icons.music_note;
    } else if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.zip') ||
        fileName.endsWith('.rar') ||
        fileName.endsWith('.7z')) {
      return Icons.folder_zip;
    } else if (fileName.endsWith('.txt')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getStatusText() {
    switch (transfer.status) {
      case FileTransferStatus.pending:
        return 'ОЖИДАНИЕ';
      case FileTransferStatus.inProgress:
        return 'ПЕРЕДАЧА';
      case FileTransferStatus.completed:
        return 'ЗАВЕРШЕНО';
      case FileTransferStatus.cancelled:
        return 'ОТМЕНЕНО';
      case FileTransferStatus.failed:
        return 'ОШИБКА';
      case FileTransferStatus.paused:
        return 'ПАУЗА';
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (transfer.status) {
      case FileTransferStatus.pending:
        return Theme.of(context).colorScheme.secondaryContainer;
      case FileTransferStatus.inProgress:
        return Theme.of(context).colorScheme.primaryContainer;
      case FileTransferStatus.completed:
        return Colors.green.withOpacity(0.2);
      case FileTransferStatus.cancelled:
        return Theme.of(context).colorScheme.surfaceVariant;
      case FileTransferStatus.failed:
        return Theme.of(context).colorScheme.errorContainer;
      case FileTransferStatus.paused:
        return Colors.orange.withOpacity(0.2);
    }
  }

  Color _getStatusTextColor(BuildContext context) {
    switch (transfer.status) {
      case FileTransferStatus.pending:
        return Theme.of(context).colorScheme.onSecondaryContainer;
      case FileTransferStatus.inProgress:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case FileTransferStatus.completed:
        return Colors.green.shade700;
      case FileTransferStatus.cancelled:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case FileTransferStatus.failed:
        return Theme.of(context).colorScheme.onErrorContainer;
      case FileTransferStatus.paused:
        return Colors.orange.shade700;
    }
  }

  bool _shouldShowActionButtons() {
    return transfer.status == FileTransferStatus.pending ||
        transfer.status == FileTransferStatus.inProgress ||
        transfer.status == FileTransferStatus.failed;
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (transfer.status == FileTransferStatus.pending) {
      if (transfer.direction == FileTransferDirection.receiving) {
        // Входящий файл - показываем кнопки принять/отклонить
        buttons.addAll([
          TextButton(onPressed: onReject, child: const Text('Отклонить')),
          const SizedBox(width: 8),
          FilledButton(onPressed: onAccept, child: const Text('Принять')),
        ]);
      } else {
        // Исходящий файл - показываем кнопку отмены
        buttons.add(
          TextButton(onPressed: onCancel, child: const Text('Отменить')),
        );
      }
    } else if (transfer.status == FileTransferStatus.inProgress) {
      // Активная передача - показываем кнопку отмены
      buttons.add(
        TextButton(onPressed: onCancel, child: const Text('Отменить')),
      );
    } else if (transfer.status == FileTransferStatus.failed) {
      // Ошибка - показываем кнопку повтора (если есть)
      if (onRetry != null) {
        buttons.add(
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        );
      }
    }

    return buttons;
  }
}
