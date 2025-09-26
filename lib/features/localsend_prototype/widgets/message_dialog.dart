import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend_prototype/controllers/index.dart';
import 'package:hoplixi/features/localsend_prototype/models/index.dart';
import 'package:hoplixi/features/localsend_prototype/providers/index.dart';

/// Диалог отправки текстового сообщения
class MessageDialog extends ConsumerStatefulWidget {
  const MessageDialog({super.key, required this.targetDevice});

  final DeviceInfo targetDevice;

  @override
  ConsumerState<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends ConsumerState<MessageDialog> {
  static const String _logTag = 'MessageDialog';
  static const int _maxMessageLength = 1000;

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Автофокус на поле ввода
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final messageHistory = ref.watch(messageHistoryProvider);

    // Фильтруем сообщения для данного устройства
    final deviceMessages = messageHistory
        .where(
          (msg) =>
              msg.senderId == widget.targetDevice.id ||
              msg.receiverId == widget.targetDevice.id,
        )
        .take(3)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.message_outlined, size: 24, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Сообщение для ${widget.targetDevice.name}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // История последних сообщений
            if (deviceMessages.isNotEmpty) ...[
              Text(
                'Последние сообщения:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: deviceMessages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final message = deviceMessages[index];
                    final isOutgoing =
                        message.senderId != widget.targetDevice.id;

                    return Row(
                      mainAxisAlignment: isOutgoing
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOutgoing
                                  ? colors.primary.withOpacity(0.1)
                                  : colors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              message.content,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Поле ввода сообщения
            PrimaryTextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              hintText: 'Введите ваше сообщение...',
              maxLines: 3,
              maxLength: _maxMessageLength,
              onChanged: (_) => setState(() {}),
              enabled: !_isSending,
            ),

            // Счетчик символов
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_messageController.text.length}/$_maxMessageLength',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        _messageController.text.length > _maxMessageLength * 0.9
                        ? colors.error
                        : colors.onSurface.withOpacity(0.6),
                  ),
                ),
                if (_isSending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(width: 8),
                      Text(
                        'Отправка...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        SmoothButton(
          type: SmoothButtonType.outlined,
          size: SmoothButtonSize.medium,
          label: 'Отмена',
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
        ),
        SmoothButton(
          type: SmoothButtonType.filled,
          size: SmoothButtonSize.medium,
          label: 'Отправить',
          icon: Icon(Icons.send, size: 16),
          onPressed: _canSend() ? _sendMessage : null,
        ),
      ],
    );
  }

  bool _canSend() {
    return !_isSending &&
        _messageController.text.trim().isNotEmpty &&
        _messageController.text.length <= _maxMessageLength;
  }

  Future<void> _sendMessage() async {
    if (!_canSend()) return;

    setState(() {
      _isSending = true;
    });

    try {
      final messageText = _messageController.text.trim();

      logInfo(
        'Sending message to device: ${widget.targetDevice.name}',
        tag: _logTag,
        data: {
          'deviceId': widget.targetDevice.id,
          'messageLength': messageText.length,
        },
      );

      final controller = ref.read(localSendControllerProvider);
      final success = await controller.sendTextMessage(
        widget.targetDevice.id,
        messageText,
      );

      if (success && mounted) {
        ToastHelper.success(
          title: 'Сообщение отправлено',
          description: 'Сообщение доставлено на ${widget.targetDevice.name}',
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ToastHelper.error(
          title: 'Ошибка отправки',
          description: 'Не удалось отправить сообщение',
        );
      }
    } catch (e) {
      logError('Error sending message', error: e, tag: _logTag);

      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Произошла ошибка при отправке сообщения',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
