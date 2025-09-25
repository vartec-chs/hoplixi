import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// Вкладка с историей сообщений
class MessagesTab extends ConsumerWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageHistoryProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет сообщений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Отправьте текстовое сообщение\nс вкладки "Устройства"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Заголовок с кнопкой очистки
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'История сообщений (${messages.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: messages.isEmpty ? null : () => _clearHistory(ref),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Очистить'),
              ),
            ],
          ),
        ),

        // Список сообщений
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            reverse: true, // Показываем новые сообщения сверху
            itemBuilder: (context, index) {
              final message = messages[messages.length - 1 - index];

              // Находим информацию об устройстве
              final device = _findDevice(discoveredDevices, message);

              return MessageCard(
                message: message,
                deviceName: device?.name ?? 'Неизвестное устройство',
              );
            },
          ),
        ),
      ],
    );
  }

  DeviceInfo? _findDevice(List<DeviceInfo?> devices, LocalSendMessage message) {
    for (final device in devices) {
      if (device?.id == message.senderId || device?.id == message.receiverId) {
        return device;
      }
    }
    return null;
  }

  void _clearHistory(WidgetRef ref) {
    ref.read(messageHistoryProvider.notifier).clearHistory();
  }
}

/// Карточка сообщения
class MessageCard extends ConsumerWidget {
  final LocalSendMessage message;
  final String deviceName;

  const MessageCard({
    required this.message,
    required this.deviceName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentDevice = ref.watch(currentDeviceProvider);
    final isOutgoing = message.senderId == currentDevice.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOutgoing) ...[
            // Аватар отправителя
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                deviceName.isNotEmpty ? deviceName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Контент сообщения
          Expanded(
            child: Column(
              crossAxisAlignment: isOutgoing
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Заголовок с именем и временем
                Row(
                  mainAxisAlignment: isOutgoing
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isOutgoing) ...[
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (isOutgoing) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Вы',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                // Пузырь сообщения
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOutgoing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: isOutgoing
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      topRight: isOutgoing
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Тип сообщения (если не текст)
                      if (message.type != MessageType.text)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isOutgoing
                                ? Colors.white.withOpacity(0.2)
                                : theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getMessageTypeIcon(message.type),
                                size: 12,
                                color: isOutgoing
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getMessageTypeLabel(message.type),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOutgoing
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Контент сообщения
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isOutgoing
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Статус доставки
                Row(
                  mainAxisAlignment: isOutgoing
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      _getDeliveryStatusIcon(message.status),
                      size: 12,
                      color: _getDeliveryStatusColor(message.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDeliveryStatusText(message.status),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isOutgoing) ...[
            const SizedBox(width: 8),
            // Аватар текущего пользователя
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Сегодня - показываем только время
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Вчера
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Другие дни
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.text:
        return Icons.message;
      case MessageType.system:
        return Icons.info;
    }
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'Текст';
      case MessageType.system:
        return 'Системное';
    }
  }

  IconData _getDeliveryStatusIcon(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icons.schedule;
      case MessageDeliveryStatus.sent:
        return Icons.done;
      case MessageDeliveryStatus.delivered:
        return Icons.done_all;
      case MessageDeliveryStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getDeliveryStatusColor(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Colors.grey;
      case MessageDeliveryStatus.sent:
        return Colors.blue;
      case MessageDeliveryStatus.delivered:
        return Colors.green;
      case MessageDeliveryStatus.failed:
        return Colors.red;
    }
  }

  String _getDeliveryStatusText(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return 'Отправляется';
      case MessageDeliveryStatus.sent:
        return 'Отправлено';
      case MessageDeliveryStatus.delivered:
        return 'Доставлено';
      case MessageDeliveryStatus.failed:
        return 'Не доставлено';
    }
  }
}
