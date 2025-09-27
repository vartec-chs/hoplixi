import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_prototype/models/index.dart';

/// Карточка сообщения в истории
class MessageCard extends ConsumerWidget {
  const MessageCard({
    super.key,
    required this.message,
    required this.deviceName,
  });

  final LocalSendMessage message;
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOutgoing =
        message.type ==
        MessageType.system; // Временно используем system как outgoing

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isOutgoing
                      ? colors.primary.withOpacity(0.2)
                      : colors.secondary.withOpacity(0.2),
                  child: Icon(
                    isOutgoing ? Icons.send : Icons.inbox,
                    size: 16,
                    color: isOutgoing ? colors.primary : colors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        message.formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(colors),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message.content, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colors) {
    Color iconColor;
    IconData iconData;

    switch (message.status) {
      case MessageDeliveryStatus.sending:
        iconColor = colors.outline;
        iconData = Icons.schedule;
        break;
      case MessageDeliveryStatus.sent:
        iconColor = colors.primary;
        iconData = Icons.done;
        break;
      case MessageDeliveryStatus.delivered:
        iconColor = colors.primary;
        iconData = Icons.done_all;
        break;
      case MessageDeliveryStatus.failed:
        iconColor = colors.error;
        iconData = Icons.error_outline;
        break;
    }

    return Icon(iconData, size: 16, color: iconColor);
  }
}
