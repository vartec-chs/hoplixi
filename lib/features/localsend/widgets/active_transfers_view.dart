import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/controllers/index.dart';
import 'package:hoplixi/features/localsend/widgets/transfer_progress_card.dart';

/// Виджет для отображения активных передач файлов
class ActiveTransfersView extends ConsumerStatefulWidget {
  const ActiveTransfersView({super.key});

  @override
  ConsumerState<ActiveTransfersView> createState() =>
      _ActiveTransfersViewState();
}

class _ActiveTransfersViewState extends ConsumerState<ActiveTransfersView> {
  static const String _logTag = 'ActiveTransfersView';

  @override
  void initState() {
    super.initState();
    // Подписываемся на обновления прогресса передач
    _subscribeToTransferUpdates();
  }

  void _subscribeToTransferUpdates() {
    final controller = ref.read(localSendControllerProvider);

    controller.fileTransferProgress.listen((event) {
      logDebug('Transfer progress event: ${event['type']}', tag: _logTag);

      // Обновляем UI при получении событий
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(localSendControllerProvider);
    final activeTransfers = controller.getActiveTransfersStatus();

    if (activeTransfers.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: activeTransfers.length,
        itemBuilder: (context, index) {
          final transferId = activeTransfers.keys.elementAt(index);
          final transfer = activeTransfers[transferId]!;

          return TransferProgressCard(
            transferId: transferId,
            fileName: _extractFileName(transfer['filePath'] as String),
            fileSize: transfer['fileSize'] as int,
            progress: _calculateProgress(transfer),
            status: _getTransferStatus(transfer),
            isOutgoing:
                transfer['completedChunks'] >
                0, // Если есть completed chunks, значит отправляем
            onResume: () => _handleResume(transferId),
            onCancel: () => _handleCancel(transferId),
            onRetry: () => _handleRetry(transferId),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 64,
            color: colors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет активных передач',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Передачи файлов будут отображаться здесь',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _extractFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  double _calculateProgress(Map<String, dynamic> transfer) {
    final completedChunks = transfer['completedChunks'] as int;
    final receivedChunks = transfer['receivedChunks'] as int;
    final totalChunks = transfer['totalChunks'] as int;

    if (totalChunks == 0) return 0.0;

    // Берем максимальный прогресс между отправкой и получением
    final sendProgress = completedChunks / totalChunks;
    final receiveProgress = receivedChunks / totalChunks;

    return sendProgress > receiveProgress ? sendProgress : receiveProgress;
  }

  String _getTransferStatus(Map<String, dynamic> transfer) {
    final completedChunks = transfer['completedChunks'] as int;
    final receivedChunks = transfer['receivedChunks'] as int;
    final totalChunks = transfer['totalChunks'] as int;
    final lastActivity = DateTime.fromMillisecondsSinceEpoch(
      transfer['lastActivity'] as int,
    );

    final now = DateTime.now();
    final timeDiff = now.difference(lastActivity);

    // Проверяем на завершенность
    if (completedChunks == totalChunks || receivedChunks == totalChunks) {
      return 'Завершено';
    }

    // Проверяем на приостановку (нет активности больше 30 секунд)
    if (timeDiff.inSeconds > 30) {
      return 'Прервано';
    }

    // Проверяем на активную передачу
    if (completedChunks > 0 || receivedChunks > 0) {
      return 'В процессе';
    }

    return 'Ожидание';
  }

  Future<void> _handleResume(String transferId) async {
    try {
      logInfo('Resuming transfer: $transferId', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      await controller.resumeTransfer(transferId);

      setState(() {}); // Обновляем UI
    } catch (e) {
      logError('Error resuming transfer', error: e, tag: _logTag);
    }
  }

  Future<void> _handleCancel(String transferId) async {
    try {
      // Показываем диалог подтверждения
      final shouldCancel = await _showCancelDialog(context);
      if (!shouldCancel) return;

      logInfo('Cancelling transfer: $transferId', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      await controller.cancelTransfer(transferId);

      setState(() {}); // Обновляем UI
    } catch (e) {
      logError('Error cancelling transfer', error: e, tag: _logTag);
    }
  }

  Future<void> _handleRetry(String transferId) async {
    try {
      logInfo('Retrying transfer: $transferId', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      await controller.resumeTransfer(transferId);

      setState(() {}); // Обновляем UI
    } catch (e) {
      logError('Error retrying transfer', error: e, tag: _logTag);
    }
  }

  Future<bool> _showCancelDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Отменить передачу?'),
            content: const Text(
              'Передача файла будет остановлена и не может быть возобновлена. '
              'Вы уверены, что хотите отменить?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Нет'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Да, отменить'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
