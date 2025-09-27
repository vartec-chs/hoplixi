import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_prototype/providers/index.dart';
import 'package:hoplixi/features/localsend_prototype/models/index.dart';

/// Вкладка с активными передачами файлов
class TransfersTab extends ConsumerWidget {
  const TransfersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(fileTransfersProvider);

    if (transfers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет активных передач',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Отправьте файл с вкладки "Устройства"\nчтобы увидеть прогресс передачи',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        if (transfer == null) return const SizedBox.shrink();
        return TransferCard(transfer: transfer);
      },
    );
  }
}

/// Карточка передачи файла
class TransferCard extends ConsumerWidget {
  final FileTransfer transfer;

  const TransferCard({required this.transfer, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = transfer.fileSize > 0
        ? transfer.transferredBytes / transfer.fileSize
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с именем файла и статусом
            Row(
              children: [
                Icon(
                  _getFileIcon(transfer.fileName),
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(transfer.fileSize),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transfer.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(transfer.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о направлении передачи
            Row(
              children: [
                Icon(
                  transfer.direction == FileTransferDirection.sending
                      ? Icons.upload
                      : Icons.download,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  transfer.direction == FileTransferDirection.sending
                      ? 'Отправка'
                      : 'Получение',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${_formatBytes(transfer.transferredBytes)} / ${_formatBytes(transfer.fileSize)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Прогресс-бар
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(transfer.status),
              ),
            ),

            const SizedBox(height: 8),

            // Процент и скорость (если передача активна)
            Row(
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (transfer.status == FileTransferStatus.inProgress) ...[
                  const Spacer(),
                  Text(
                    _calculateSpeed(transfer),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),

            // Действия
            if (transfer.status == FileTransferStatus.inProgress ||
                transfer.status == FileTransferStatus.failed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (transfer.status == FileTransferStatus.inProgress)
                    TextButton.icon(
                      onPressed: () => _cancelTransfer(ref, transfer.id),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Отменить'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  if (transfer.status == FileTransferStatus.failed) ...[
                    TextButton.icon(
                      onPressed: () => _retryTransfer(ref, transfer.id),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Повторить'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _removeTransfer(ref, transfer.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Удалить'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'ogg':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getStatusColor(FileTransferStatus status) {
    switch (status) {
      case FileTransferStatus.pending:
        return Colors.grey;
      case FileTransferStatus.inProgress:
        return Colors.blue;
      case FileTransferStatus.completed:
        return Colors.green;
      case FileTransferStatus.failed:
        return Colors.red;
      case FileTransferStatus.cancelled:
        return Colors.orange;
      case FileTransferStatus.paused:
        return Colors.yellow[700] ?? Colors.yellow;
    }
  }

  String _getStatusText(FileTransferStatus status) {
    switch (status) {
      case FileTransferStatus.pending:
        return 'Ожидание';
      case FileTransferStatus.inProgress:
        return 'Передача';
      case FileTransferStatus.completed:
        return 'Завершено';
      case FileTransferStatus.failed:
        return 'Ошибка';
      case FileTransferStatus.cancelled:
        return 'Отменено';
      case FileTransferStatus.paused:
        return 'Приостановлено';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  String _calculateSpeed(FileTransfer transfer) {
    // Простая симуляция скорости - в реальном приложении
    // это будет рассчитываться на основе фактического времени
    return '2.5 МБ/с';
  }

  void _cancelTransfer(WidgetRef ref, String transferId) {
    ref
        .read(fileTransfersProvider.notifier)
        .updateTransfer(
          transferId,
          transfer.copyWith(status: FileTransferStatus.cancelled),
        );
  }

  void _retryTransfer(WidgetRef ref, String transferId) {
    ref
        .read(fileTransfersProvider.notifier)
        .updateTransfer(
          transferId,
          transfer.copyWith(
            status: FileTransferStatus.pending,
            transferredBytes: 0,
          ),
        );

    // В реальном приложении здесь был бы перезапуск передачи
  }

  void _removeTransfer(WidgetRef ref, String transferId) {
    ref.read(fileTransfersProvider.notifier).removeTransfer(transferId);
  }
}
