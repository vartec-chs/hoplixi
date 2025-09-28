import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend/widgets/file_transfer_widgets.dart';

class FilesTab extends ConsumerStatefulWidget {
  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;
  final String remoteUri;

  const FilesTab({
    super.key,
    required this.deviceInfo,
    required this.connectionMode,
    required this.remoteUri,
  });

  @override
  ConsumerState<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<FilesTab> {
  static const _logTag = 'FilesTab';

  List<FileTransfer> _fileTransfers = [];
  StreamSubscription<FileTransfer>? _fileTransferSubscription;

  @override
  void dispose() {
    _fileTransferSubscription?.cancel();
    super.dispose();
  }

  void setupFileTransferStream(WebRTCConnectionNotifier notifier) {
    _fileTransferSubscription?.cancel();

    // Подписка на обновления передач файлов
    _fileTransferSubscription = notifier.fileTransferService.transferUpdates
        .listen((transfer) {
          if (mounted) {
            setState(() {
              final index = _fileTransfers.indexWhere(
                (t) => t.id == transfer.id,
              );
              if (index >= 0) {
                _fileTransfers[index] = transfer;
              } else {
                _fileTransfers.add(transfer);
              }
            });

            logInfo(
              'Обновление передачи файла',
              tag: _logTag,
              data: {
                'transferId': transfer.id,
                'state': transfer.state.name,
                'progress': '${(transfer.progress * 100).toStringAsFixed(1)}%',
              },
            );
          }
        });
  }

  // Обработчики передачи файлов
  Future<void> _handleSelectFiles() async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      final fileTransferService = notifier.fileTransferService;

      final transfers = await fileTransferService.selectFilesToSend();
      if (transfers == null || transfers.isEmpty) return;

      setState(() {
        _fileTransfers.addAll(transfers);
      });

      // Запускаем передачу для каждого файла
      for (final transfer in transfers) {
        await fileTransferService.startFileTransfer(transfer.id);
      }

      logInfo(
        'Выбрано файлов для отправки',
        tag: _logTag,
        data: {'count': transfers.length},
      );
    } catch (e) {
      logError('Ошибка выбора файлов', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка выбора файлов',
        description: e.toString(),
      );
    }
  }

  Future<void> _handleAcceptTransfer(String transferId) async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      final success = await notifier.fileTransferService.acceptFileTransfer(
        transferId,
      );

      if (success) {
        ToastHelper.success(
          title: 'Файл принят',
          description: 'Начинается загрузка файла',
        );
      }
    } catch (e) {
      logError('Ошибка принятия файла', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка принятия файла',
        description: e.toString(),
      );
    }
  }

  Future<void> _handleRejectTransfer(String transferId) async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      await notifier.fileTransferService.rejectFileTransfer(transferId);

      setState(() {
        _fileTransfers.removeWhere((t) => t.id == transferId);
      });

      ToastHelper.info(
        title: 'Файл отклонен',
        description: 'Передача файла отклонена',
      );
    } catch (e) {
      logError('Ошибка отклонения файла', error: e, tag: _logTag);
    }
  }

  Future<void> _handleCancelTransfer(String transferId) async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      await notifier.fileTransferService.cancelFileTransfer(transferId);

      setState(() {
        _fileTransfers.removeWhere((t) => t.id == transferId);
      });

      ToastHelper.info(
        title: 'Передача отменена',
        description: 'Передача файла отменена',
      );
    } catch (e) {
      logError('Ошибка отмены передачи', error: e, tag: _logTag);
    }
  }

  Future<void> _handlePauseTransfer(String transferId) async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      await notifier.fileTransferService.pauseFileTransfer(transferId);

      ToastHelper.info(
        title: 'Передача приостановлена',
        description: 'Передача файла приостановлена',
      );
    } catch (e) {
      logError('Ошибка приостановки передачи', error: e, tag: _logTag);
    }
  }

  Future<void> _handleResumeTransfer(String transferId) async {
    try {
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
      await notifier.fileTransferService.resumeFileTransfer(transferId);

      ToastHelper.info(
        title: 'Передача возобновлена',
        description: 'Передача файла возобновлена',
      );
    } catch (e) {
      logError('Ошибка возобновления передачи', error: e, tag: _logTag);
    }
  }

  Widget _buildFileTransferHeader() {
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(
          signalingNotifierProvider(widget.remoteUri),
        );

        return webrtcState.when(
          data: (state) {
            final isConnected = state.state == WebRTCConnectionState.connected;

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.file_copy_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Передача файлов',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected
                                ? 'Готов к передаче файлов'
                                : 'Подключение не установлено',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isConnected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SendFilesButton(
                      onPressed: _handleSelectFiles,
                      isEnabled: isConnected,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Text('Ошибка подключения'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransferStatistics() {
    if (_fileTransfers.isEmpty) return const SizedBox.shrink();

    final activeTransfers = _fileTransfers
        .where((t) => t.state.isActive)
        .length;
    final completedTransfers = _fileTransfers
        .where((t) => t.state == FileTransferState.completed)
        .length;
    final failedTransfers = _fileTransfers
        .where((t) => t.state == FileTransferState.failed)
        .length;
    final totalSize = _fileTransfers.fold<int>(
      0,
      (sum, t) => sum + t.metadata.size,
    );
    final transferredSize = _fileTransfers.fold<int>(
      0,
      (sum, t) => sum + (t.metadata.size * t.progress).round(),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Статистика передач',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatItem(
                  icon: Icons.sync,
                  label: 'Активных',
                  value: activeTransfers.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Завершено',
                  value: completedTransfers.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (failedTransfers > 0)
                  _buildStatItem(
                    icon: Icons.error,
                    label: 'Ошибки',
                    value: failedTransfers.toString(),
                    color: Theme.of(context).colorScheme.error,
                  ),
                _buildStatItem(
                  icon: Icons.data_usage,
                  label: 'Передано',
                  value:
                      '${_formatFileSize(transferredSize)} / ${_formatFileSize(totalSize)}',
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFileTransfersList() {
    if (_fileTransfers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Нет активных передач',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите файлы для отправки или ожидайте входящие',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FileTransferList(
          transfers: _fileTransfers,
          onAcceptTransfer: _handleAcceptTransfer,
          onRejectTransfer: _handleRejectTransfer,
          onCancelTransfer: _handleCancelTransfer,
          onPauseTransfer: _handlePauseTransfer,
          onResumeTransfer: _handleResumeTransfer,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    // Настраиваем потоки передач файлов при подключении
    final webrtcState = ref.watch(signalingNotifierProvider(widget.remoteUri));

    webrtcState.whenData((status) {
      if (status.state == WebRTCConnectionState.connected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final notifier = ref.read(
            signalingNotifierProvider(widget.remoteUri).notifier,
          );
          setupFileTransferStream(notifier);
        });
      }
    });

    return Column(
      children: [
        _buildFileTransferHeader(),
        _buildTransferStatistics(),
        _buildFileTransfersList(),
      ],
    );
  }
}
