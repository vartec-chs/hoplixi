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
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';

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

  Widget _buildErrorState(String error) {
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
            'Ошибка подключения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          SmoothButton(
            type: SmoothButtonType.outlined,
            size: SmoothButtonSize.medium,
            label: 'Попробовать снова',
            onPressed: () {
              // Принудительно перестроить провайдер
              ref.invalidate(signalingNotifierProvider(_remoteUri));
            },
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
      body: webrtcState.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
        data: (state) {
          if (!state.connected) {
            return _buildErrorState(
              state.error ?? 'Не удалось установить соединение',
            );
          }

          // Настраиваем потоки сообщений при успешном подключении
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notifier = ref.read(
              signalingNotifierProvider(_remoteUri).notifier,
            );
            _setupStreams(notifier);
          });

          return Column(
            children: [
              _buildConnectionHeader(),
              _buildMessagesList(),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }
}
