import 'package:flutter/material.dart';

/// Виджет для ввода и отправки сообщений
class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.hintText = 'Введите сообщение...',
  });

  final void Function(String message) onSendMessage;
  final bool enabled;
  final String hintText;

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending || !widget.enabled) return;

    setState(() => _isSending = true);

    try {
      widget.onSendMessage(message);
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.enabled
                    ? widget.hintText
                    : 'Соединение не установлено',
                filled: true,
                fillColor: widget.enabled
                    ? Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: widget.enabled && !_isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  widget.enabled &&
                      !_isSending &&
                      _controller.text.trim().isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: IconButton(
              onPressed:
                  widget.enabled &&
                      !_isSending &&
                      _controller.text.trim().isNotEmpty
                  ? _sendMessage
                  : null,
              icon: _isSending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color:
                          widget.enabled && _controller.text.trim().isNotEmpty
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
