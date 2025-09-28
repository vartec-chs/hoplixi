import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_beta/models/message.dart';

/// Виджет для отображения списка сообщений
class MessageListWidget extends ConsumerWidget {
  const MessageListWidget({
    super.key,
    required this.messages,
    required this.currentDeviceId,
  });

  final List<LocalSendMessage> messages;
  final String currentDeviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет сообщений',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Отправьте первое сообщение',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true, // Показываем новые сообщения внизу
      itemCount: messages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final message =
            messages[messages.length - 1 - index]; // Обращаем порядок
        final isOutgoing = message.isOutgoing(currentDeviceId);

        return MessageBubbleWidget(message: message, isOutgoing: isOutgoing);
      },
    );
  }
}

/// Виджет для отображения отдельного сообщения
class MessageBubbleWidget extends StatelessWidget {
  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  final LocalSendMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isOutgoing ? 64 : 8,
        right: isOutgoing ? 8 : 64,
      ),
      child: Row(
        mainAxisAlignment: isOutgoing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOutgoing) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOutgoing
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
                  bottomRight: Radius.circular(isOutgoing ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.type == MessageType.system) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isOutgoing
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.7)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Системное',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isOutgoing
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withOpacity(0.7)
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isOutgoing
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isOutgoing
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.7)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      if (isOutgoing) ...[
                        const SizedBox(width: 4),
                        Text(
                          message.statusIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOutgoing) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
