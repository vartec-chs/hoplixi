import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import '../models/device_info.dart';
import '../providers/discovery_provider.dart';

class TestDiscoveryScreen extends ConsumerWidget {
  const TestDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(discoveryProvider);
    final discoveryController = ref.read(discoveryProvider.notifier);
    final selfDevice = discoveryController.selfDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск устройств LocalSend'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: devicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (devices) => Column(
            children: [
              // Карточка нашего устройства
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: ListTile(
                  leading: Text(
                    selfDevice.deviceIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    selfDevice.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  subtitle: Text(
                    '${selfDevice.ipAddress}:${selfDevice.port} - ${selfDevice.status.name}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showRenameDialog(context, ref, selfDevice.name),
                  ),
                ),
              ),
              // Разделитель
              const Divider(),
              // Список других устройств
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Text(
                          device.deviceIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(device.name),
                        subtitle: Text(
                          '${device.ipAddress}:${device.port} - ${device.status.name}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    final discoveryController = ref.read(discoveryProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать устройство'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Новое имя',
            hintText: 'Введите новое имя устройства',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                discoveryController.setName(newName);
                logInfo('Device renamed to $newName', tag: 'DiscoveryScreen');
              }
              Navigator.of(context).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
