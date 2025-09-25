import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/index.dart';
import 'package:hoplixi/features/localsend/widgets/index.dart';

/// Карточка обнаруженного устройства
class DeviceCard extends ConsumerWidget {
  const DeviceCard({super.key, required this.device});

  final DeviceInfo device;

  static const String _logTag = 'DeviceCard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getDeviceColor(colors),
                  child: Icon(_getDeviceIcon(), color: colors.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${device.type.name} • ${device.ipAddress}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConnectionStatus(colors),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SmoothButton(
                  type: SmoothButtonType.outlined,
                  size: SmoothButtonSize.small,
                  label: 'Сообщение',
                  icon: const Icon(Icons.message_outlined, size: 16),
                  onPressed: () => _sendMessage(context, ref),
                ),
                const SizedBox(width: 8),
                SmoothButton(
                  type: SmoothButtonType.filled,
                  size: SmoothButtonSize.small,
                  label: 'Отправить файл',
                  icon: const Icon(Icons.send_outlined, size: 16),
                  onPressed: () => _sendFile(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ColorScheme colors) {
    final isConnected = device.status == DeviceConnectionStatus.connected;
    final color = isConnected ? colors.primary : colors.outline;
    final icon = isConnected ? Icons.link : Icons.link_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Подключено' : 'Отключено',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeviceColor(ColorScheme colors) {
    switch (device.type) {
      case DeviceType.desktop:
        return colors.primary;
      case DeviceType.mobile:
        return colors.secondary;
      case DeviceType.tablet:
        return colors.tertiary;
      case DeviceType.unknown:
        return colors.outline;
    }
  }

  IconData _getDeviceIcon() {
    switch (device.type) {
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet_mac;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  Future<void> _sendMessage(BuildContext context, WidgetRef ref) async {
    try {
      logInfo(
        'Opening message dialog for device: ${device.name}',
        tag: _logTag,
      );

      await showDialog<void>(
        context: context,
        builder: (context) => MessageDialog(targetDevice: device),
      );
    } catch (e) {
      logError('Error opening message dialog', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось открыть диалог сообщения',
      );
    }
  }

  Future<void> _sendFile(BuildContext context, WidgetRef ref) async {
    try {
      logInfo(
        'Opening file send dialog for device: ${device.name}',
        tag: _logTag,
      );

      await showDialog<void>(
        context: context,
        builder: (context) => SendFileDialog(targetDevice: device),
      );
    } catch (e) {
      logError('Error opening file send dialog', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось открыть диалог отправки файла',
      );
    }
  }
}
