import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend_rc/models/connection_mode.dart';
import 'package:hoplixi/features/localsend_rc/models/device_info.dart';
import 'package:hoplixi/features/localsend_rc/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend_rc/models/message.dart';
import 'package:hoplixi/features/localsend_rc/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend_rc/providers/message_history_provider.dart';

class ChatTab extends ConsumerStatefulWidget {
  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;
  final String remoteUri;

  const ChatTab({
    super.key,
    required this.deviceInfo,
    required this.connectionMode,
    required this.remoteUri,
  });

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  static const _logTag = 'ChatTab';

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _usernameController = TextEditingController(text: 'User');

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  bool _isStreamSetup = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _usernameController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Отложенная инициализация потока сообщений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSetupMessageStream();
    });
  }

  void _checkAndSetupMessageStream() {
    if (!mounted || _isStreamSetup) return;

    final webrtcState = ref.read(signalingNotifierProvider(widget.remoteUri));
    webrtcState.whenData((status) {
      if (status.state == WebRTCConnectionState.connected && !_isStreamSetup) {
        final notifier = ref.read(
          signalingNotifierProvider(widget.remoteUri).notifier,
        );
        setupMessageStream(notifier);
        _isStreamSetup = true;
      }
    });
  }

  void setupMessageStream(WebRTCConnectionNotifier notifier) {
    _messageSubscription?.cancel();

    // Подписка на сообщения остается для уведомлений и скролла
    _messageSubscription = notifier.onDataMessage.listen((message) {
      if (mounted) {
        _scrollToBottom();
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
      final notifier = ref.read(
        signalingNotifierProvider(widget.remoteUri).notifier,
      );
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

  Widget _buildMessagesList() {
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(
          messageHistoryProvider(widget.remoteUri),
        );

        return messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) {
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
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            );
          },
          loading: () =>
              const Expanded(child: Center(child: CircularProgressIndicator())),
          error: (error, _) => Expanded(
            child: Center(
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
                    'Ошибка загрузки сообщений',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(LocalSendMessage message) {
    final isFromMe = message.sender == MessageSender.me;
    final isSystem = message.sender == MessageSender.system;
    final username = message.username;
    final text = message.text;

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
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(
          signalingNotifierProvider(widget.remoteUri),
        );

        return webrtcState.when(
          data: (state) {
            final isConnected = state.state == WebRTCConnectionState.connected;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
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
                          enabled: isConnected,
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
                          enabled: isConnected,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SmoothButton(
                        type: SmoothButtonType.filled,
                        size: SmoothButtonSize.medium,
                        label: 'Отправить',
                        onPressed: isConnected ? _sendMessage : null,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildMessagesList(), _buildMessageInput()]);
  }
}
