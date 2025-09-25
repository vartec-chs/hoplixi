import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/controllers/index.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';
import 'package:hoplixi/features/localsend/models/index.dart';
import 'package:hoplixi/common/button.dart';

/// Вкладка со списком обнаруженных устройств
class DevicesTab extends ConsumerWidget {
  static const String _logTag = 'DevicesTab';

  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final currentDevice = ref.watch(currentDeviceProvider);

    return Column(
      children: [
        // Информация о текущем устройстве
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Это устройство',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    currentDevice.type == DeviceType.mobile
                        ? Icons.phone_android
                        : Icons.computer,
                    size: 32,
                    color: Colors.blue,
                  ),
                  title: Text(currentDevice.name),
                  subtitle: Text(
                    '${currentDevice.ipAddress}:${currentDevice.port}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Активен',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Заголовок списка устройств
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Обнаруженные устройства (${discoveredDevices.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (discoveredDevices.isEmpty)
                TextButton.icon(
                  onPressed: () => _addTestDevices(ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить тестовые'),
                ),
            ],
          ),
        ),

        // Список устройств
        Expanded(
          child: discoveredDevices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices_other, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Устройства не найдены',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Убедитесь, что другие устройства\nнаходятся в той же сети',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = discoveredDevices[index];
                    return DeviceCard(device: device);
                  },
                ),
        ),
      ],
    );
  }

  void _addTestDevices(WidgetRef ref) {
    logInfo('Добавление тестовых устройств из DevicesTab', tag: _logTag);
    ref.read(localSendControllerProvider).addTestDevices();
  }
}

/// Карточка устройства
class DeviceCard extends ConsumerWidget {
  final DeviceInfo device;

  const DeviceCard({required this.device, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(
            device.type == DeviceType.mobile
                ? Icons.phone_android
                : Icons.computer,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.ipAddress}:${device.port}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(device.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(device.status),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  device.type == DeviceType.mobile ? 'Мобильное' : 'Компьютер',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmoothButton(
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.small,
              label: 'Файл',
              icon: const Icon(Icons.attach_file, size: 16),
              onPressed: () => _sendFile(ref, device.id),
            ),
            const SizedBox(width: 8),
            SmoothButton(
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.small,
              label: 'Текст',
              icon: const Icon(Icons.message, size: 16),
              onPressed: () => _sendMessage(context, ref, device.id),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DeviceConnectionStatus status) {
    switch (status) {
      case DeviceConnectionStatus.discovered:
        return Colors.green;
      case DeviceConnectionStatus.connecting:
        return Colors.orange;
      case DeviceConnectionStatus.connected:
        return Colors.blue;
      case DeviceConnectionStatus.disconnected:
        return Colors.red;
      case DeviceConnectionStatus.self:
        return Colors.purple;
    }
  }

  String _getStatusText(DeviceConnectionStatus status) {
    switch (status) {
      case DeviceConnectionStatus.discovered:
        return 'Обнаружен';
      case DeviceConnectionStatus.connecting:
        return 'Подключение';
      case DeviceConnectionStatus.connected:
        return 'Подключен';
      case DeviceConnectionStatus.disconnected:
        return 'Офлайн';
      case DeviceConnectionStatus.self:
        return 'Это устройство';
    }
  }

  Future<void> _sendFile(WidgetRef ref, String deviceId) async {
    final controller = ref.read(localSendControllerProvider);
    await controller.pickAndSendFiles(deviceId);
  }

  void _sendMessage(BuildContext context, WidgetRef ref, String deviceId) {
    showDialog(
      context: context,
      builder: (context) => SendMessageDialog(deviceId: deviceId),
    );
  }
}

/// Диалог отправки сообщения
class SendMessageDialog extends ConsumerStatefulWidget {
  final String deviceId;

  const SendMessageDialog({required this.deviceId, super.key});

  @override
  ConsumerState<SendMessageDialog> createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends ConsumerState<SendMessageDialog> {
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Отправить сообщение'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Текст сообщения',
              hintText: 'Введите сообщение...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        SmoothButton(
          type: SmoothButtonType.filled,
          size: SmoothButtonSize.medium,
          label: _isSending ? 'Отправка...' : 'Отправить',
          onPressed: _isSending ? null : _sendMessage,
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final controller = ref.read(localSendControllerProvider);
      final success = await controller.sendTextMessage(
        widget.deviceId,
        _textController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          // Переключаемся на вкладку сообщений (если у нас есть доступ к TabController)
        }
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
    }
  }
}
