import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_beta/models/device_info.dart'
    as localsend;
import 'package:hoplixi/features/localsend_beta/models/connection.dart';

/// Виджет отображения статуса соединения с устройством
class ConnectionStatusWidget extends ConsumerWidget {
  const ConnectionStatusWidget({
    super.key,
    required this.deviceInfo,
    required this.isConnecting,
    this.connection,
  });

  final localsend.DeviceInfo deviceInfo;
  final bool isConnecting;
  final WebRTCConnection? connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Информация об устройстве
            Row(
              children: [
                Text(
                  deviceInfo.deviceIcon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceInfo.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${deviceInfo.ipAddress}:${deviceInfo.port}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        deviceInfo.type.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Статус соединения
            _buildConnectionStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    if (isConnecting) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Подключение...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    if (connection == null) {
      return Row(
        children: [
          Icon(
            Icons.circle,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Text(
            'Не подключено',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      );
    }

    final (statusIcon, statusText, statusColor) = _getConnectionStatus(context);

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 12),
        Text(
          statusText,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: statusColor),
        ),
        const Spacer(),
        if (connection!.state == WebRTCConnectionState.connected)
          Chip(
            label: const Text('ГОТОВ'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  (IconData, String, Color) _getConnectionStatus(BuildContext context) {
    switch (connection!.state) {
      case WebRTCConnectionState.initializing:
        return (
          Icons.hourglass_empty,
          'Инициализация...',
          Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case WebRTCConnectionState.connecting:
        return (
          Icons.sync,
          'Соединение...',
          Theme.of(context).colorScheme.primary,
        );
      case WebRTCConnectionState.connected:
        return (
          Icons.check_circle,
          'Подключено',
          Theme.of(context).colorScheme.primary,
        );
      case WebRTCConnectionState.disconnecting:
        return (
          Icons.sync_disabled,
          'Разрыв соединения...',
          Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case WebRTCConnectionState.disconnected:
        return (
          Icons.circle_outlined,
          'Отключено',
          Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case WebRTCConnectionState.failed:
        return (
          Icons.error,
          'Ошибка соединения',
          Theme.of(context).colorScheme.error,
        );
    }
  }
}
