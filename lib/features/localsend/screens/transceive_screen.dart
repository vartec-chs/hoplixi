import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/models/webrtc_error.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend/widgets/file_transfer_widgets.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';

class TransceiveScreen extends ConsumerStatefulWidget {
  const TransceiveScreen({super.key, this.deviceInfo, this.connectionMode});

  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;

  @override
  ConsumerState<TransceiveScreen> createState() => _TransceiveScreenState();
}

class _TransceiveScreenState extends ConsumerState<TransceiveScreen> {
  static const _logTag = 'TransceiveScreen';

  LocalSendDeviceInfo? get deviceInfo => widget.deviceInfo;
  ConnectionMode? get connectionMode => widget.connectionMode;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _usernameController = TextEditingController(text: 'User');

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<String>? _dataChannelStateSubscription;

  List<Map<String, dynamic>> _messages = [];
  String _dataChannelState = 'unknown';
  List<FileTransfer> _fileTransfers = [];
  StreamSubscription<FileTransfer>? _fileTransferSubscription;

  @override
  void initState() {
    super.initState();
    logInfo(
      'TransceiveScreen инициализирован',
      tag: _logTag,
      data: {
        'deviceName': deviceInfo?.name,
        'connectionMode': connectionMode?.name,
        'remoteAddress': deviceInfo?.fullAddress,
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _usernameController.dispose();
    _messageSubscription?.cancel();
    _dataChannelStateSubscription?.cancel();
    _fileTransferSubscription?.cancel();
    super.dispose();
  }

  String get _remoteUri {
    if (deviceInfo == null) return '';
    return connectionMode == ConnectionMode.initiator
        ? 'http://${deviceInfo!.fullAddress}'
        : ''; // Server mode - пустая строка
  }

  void _setupStreams(WebRTCConnectionNotifier notifier) {
    _messageSubscription?.cancel();
    _dataChannelStateSubscription?.cancel();
    _fileTransferSubscription?.cancel();

    _messageSubscription = notifier.onDataMessage.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });

    _dataChannelStateSubscription = notifier.dataChannelStateStream.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _dataChannelState = state;
        });
        logInfo('DataChannel state changed: $state', tag: _logTag);
      }
    });

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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final username = _usernameController.text.trim();

    if (text.isEmpty) return;

    try {
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
      await notifier.sendDataChannelJson(
        username: username.isEmpty ? 'User' : username,
        text: text,
      );

      _messageController.clear();
      logInfo('Сообщение отправлено', tag: _logTag, data: {'text': text});
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка отправки сообщения',
        description: e.toString(),
      );
    }
  }

  // Обработчики передачи файлов
  Future<void> _handleSelectFiles() async {
    try {
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
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
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
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
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
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
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
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
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
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
      final notifier = ref.read(signalingNotifierProvider(_remoteUri).notifier);
      await notifier.fileTransferService.resumeFileTransfer(transferId);

      ToastHelper.info(
        title: 'Передача возобновлена',
        description: 'Передача файла возобновлена',
      );
    } catch (e) {
      logError('Ошибка возобновления передачи', error: e, tag: _logTag);
    }
  }

  Widget _buildConnectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                deviceInfo?.deviceIcon ?? '📡',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceInfo?.name ?? 'Неизвестное устройство',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      deviceInfo?.fullAddress ?? 'Неизвестный адрес',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                connectionMode?.icon ?? '🔗',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                connectionMode?.displayName ?? 'Неизвестный режим',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              _buildDataChannelStatus(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataChannelStatus() {
    final isOpen = _dataChannelState.toLowerCase().contains('open');
    final color = isOpen
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Подключено' : 'Ожидание...',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTransferSection() {
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(
          signalingNotifierProvider(deviceInfo?.fullAddress ?? ''),
        );

        return webrtcState.when(
          data: (state) {
            if (state.state != WebRTCConnectionState.connected) {
              return const Text('Нет подключения');
            }

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.file_copy_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Передача файлов',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        SendFilesButton(
                          onPressed: _handleSelectFiles,
                          isEnabled:
                              state.state == WebRTCConnectionState.connected,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FileTransferList(
                      transfers: _fileTransfers,
                      onAcceptTransfer: _handleAcceptTransfer,
                      onRejectTransfer: _handleRejectTransfer,
                      onCancelTransfer: _handleCancelTransfer,
                      onPauseTransfer: _handlePauseTransfer,
                      onResumeTransfer: _handleResumeTransfer,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Сообщений пока нет',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Начните разговор, отправив первое сообщение',
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
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromMe = message['from'] == 'me';
    final isSystem = message['from'] == 'system';
    final username = message['username'] ?? 'Unknown';
    final text = message['text'] ?? '';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isFromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isFromMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isFromMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromMe && username.isNotEmpty)
                    Text(
                      username,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isFromMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _usernameController.text.isNotEmpty
                    ? _usernameController.text[0].toUpperCase()
                    : 'M',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PrimaryTextField(
                  controller: _usernameController,
                  label: 'Ваше имя',
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PrimaryTextField(
                  controller: _messageController,
                  label: 'Введите сообщение...',
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              SmoothButton(
                type: SmoothButtonType.filled,
                size: SmoothButtonSize.medium,
                label: 'Отправить',
                onPressed: _dataChannelState.toLowerCase().contains('open')
                    ? _sendMessage
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            connectionMode == ConnectionMode.initiator
                ? 'Подключение к устройству...'
                : 'Ожидание подключения...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (deviceInfo != null)
            Text(
              '${deviceInfo!.name} (${deviceInfo!.fullAddress})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WebRTCConnectionStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            status.error?.type.displayName ?? 'Ошибка подключения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              status.error?.userMessage ?? status.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmoothButton(
                type: SmoothButtonType.outlined,
                size: SmoothButtonSize.medium,
                label: 'Назад',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 16),
              SmoothButton(
                type: SmoothButtonType.filled,
                size: SmoothButtonSize.medium,
                label: 'Переподключиться',
                onPressed: () async {
                  final notifier = ref.read(
                    signalingNotifierProvider(_remoteUri).notifier,
                  );
                  await notifier.reconnect();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (deviceInfo == null || connectionMode == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Обмен данными'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Не хватает данных для подключения')),
      );
    }

    final webrtcState = ref.watch(signalingNotifierProvider(_remoteUri));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обмен данными'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(signalingNotifierProvider(_remoteUri));
              ToastHelper.info(title: 'Переподключение...');
            },
            tooltip: 'Переподключиться',
          ),
        ],
      ),
      body: SafeArea(
        child: webrtcState.when(
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState(
            WebRTCConnectionStatus(
              state: WebRTCConnectionState.failed,
              error: WebRTCError.unknown(error.toString()),
              lastStateChange: DateTime.now(),
            ),
          ),
          data: (status) {
            // Проверяем состояние подключения
            if (status.state == WebRTCConnectionState.failed) {
              return _buildErrorState(status);
            }

            if (!status.state.isActive) {
              return _buildLoadingState();
            }

            // Настраиваем потоки сообщений при успешном подключении
            if (status.state == WebRTCConnectionState.connected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final notifier = ref.read(
                  signalingNotifierProvider(_remoteUri).notifier,
                );
                _setupStreams(notifier);
              });
            }

            return Column(
              children: [
                _buildConnectionHeader(),
                _buildFileTransferSection(),
                _buildMessagesList(),
                _buildMessageInput(),
              ],
            );
          },
        ),
      ),
    );
  }
}
