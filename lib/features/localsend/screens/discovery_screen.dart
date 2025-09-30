import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/router/routes_path.dart';
import '../models/localsend_device_info.dart';
import '../providers/discovery_provider.dart';
import '../widgets/connection_mode_dialog.dart';

const _logTag = 'DiscoveryScreen';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(discoveryProvider);
    final discoveryController = ref.read(discoveryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск устройств LocalSend'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              discoveryController
                  .reloadDiscovery()
                  .then((success) {
                    ToastHelper.success(title: 'Обнаружение перезагружено');
                  })
                  .onError((error, stackTrace) {
                    ToastHelper.error(
                      title: 'Ошибка при перезагрузке обнаружения',
                      description: error.toString(),
                    );
                  });
            },
            tooltip: 'Перезагрузить обнаружение',
          ),
        ],
      ),
      body: SafeArea(
        child: devicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (devices) => Consumer(
            builder: (context, ref, child) {
              final selfDevice = ref.watch(selfDeviceProvider);
              return Column(
                children: [
                  // Карточка нашего устройства
                  Card(
                    margin: const EdgeInsets.all(8),
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
                        '${selfDevice.ipAddress}:${selfDevice.port} - ${selfDevice.status.name} (Это ваше устройство)',
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
                            horizontal: 8,
                            vertical: 8,
                          ),
                          elevation: 4,
                          child: InkWell(
                            onTap: () async {
                              logInfo(
                                'Пользователь нажал на устройство',
                                tag: _logTag,
                                data: {
                                  'deviceName': device.name,
                                  'deviceId': device.id,
                                  'deviceIp': device.ipAddress,
                                  'devicePort': device.port,
                                  'deviceType': device.type.name,
                                },
                              );

                              // Показываем диалог выбора режима подключения
                              final selectedMode =
                                  await ConnectionModeDialog.show(
                                    context,
                                    device,
                                  );

                              if (selectedMode != null && context.mounted) {
                                // Переходим на экран обмена с информацией о режиме
                                context.push(
                                  AppRoutes.localSendTransfer,
                                  extra: {
                                    'device': device,
                                    'mode': selectedMode,
                                  },
                                );
                              }
                            },
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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
        content: PrimaryTextField(
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
