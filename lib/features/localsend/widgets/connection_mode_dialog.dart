import 'package:flutter/material.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/localsend_device_info.dart';

/// Диалог для выбора режима подключения к устройству
class ConnectionModeDialog extends StatelessWidget {
  const ConnectionModeDialog({super.key, required this.targetDevice});

  final LocalSendDeviceInfo targetDevice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      title: Row(
        children: [
          Text(targetDevice.deviceIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Подключение к ${targetDevice.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите режим подключения:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Режим инициатора
          _ModeOptionCard(
            mode: ConnectionMode.initiator,
            onTap: () => Navigator.of(context).pop(ConnectionMode.initiator),
          ),

          const SizedBox(height: 12),

          // Режим получателя
          _ModeOptionCard(
            mode: ConnectionMode.receiver,
            onTap: () => Navigator.of(context).pop(ConnectionMode.receiver),
          ),

          const SizedBox(height: 16),

          // Информация
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Оба устройства должны выбрать разные режимы для успешного подключения',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
      ],
    );
  }

  /// Показывает диалог выбора режима подключения
  static Future<ConnectionMode?> show(
    BuildContext context,
    LocalSendDeviceInfo targetDevice,
  ) {
    return showDialog<ConnectionMode>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionModeDialog(targetDevice: targetDevice),
    );
  }
}

/// Карточка с опцией режима подключения
class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({required this.mode, required this.onTap});

  final ConnectionMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mode.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mode.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mode.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
