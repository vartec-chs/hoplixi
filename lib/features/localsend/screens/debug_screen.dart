import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';
import 'package:hoplixi/features/localsend/providers/discovery_provider.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend/screens/network_diagnostics_screen.dart';
import 'package:hoplixi/features/localsend/utils/dns_test.dart';

const _logTag = 'LocalSendDebug';

/// Отладочный экран для тестирования LocalSend подключений
class LocalSendDebugScreen extends ConsumerStatefulWidget {
  const LocalSendDebugScreen({super.key});

  @override
  ConsumerState<LocalSendDebugScreen> createState() =>
      _LocalSendDebugScreenState();
}

class _LocalSendDebugScreenState extends ConsumerState<LocalSendDebugScreen> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(discoveryProvider);
    final selfDevice = ref.watch(selfDeviceProvider);
    final connectionsAsync = ref.watch(webrtcConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LocalSend Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о собственном устройстве
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мое устройство',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Имя: ${selfDevice.name}'),
                    Text('ID: ${selfDevice.id}'),
                    Text('IP: ${selfDevice.ipAddress}'),
                    Text('Порт: ${selfDevice.port}'),
                    Text('Тип: ${selfDevice.type.name}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Список обнаруженных устройств
            Text(
              'Обнаруженные устройства',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Expanded(
              child: devicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('Ошибка: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(discoveryProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
                data: (devices) {
                  if (devices.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('Устройства не найдены'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_getDeviceIcon(device.type)),
                          title: Text(device.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${device.ipAddress}:${device.port}'),
                              Text('ID: ${device.id}'),
                            ],
                          ),
                          trailing: _isConnecting
                              ? const CircularProgressIndicator()
                              : SmoothButton(
                                  type: SmoothButtonType.filled,
                                  size: SmoothButtonSize.small,
                                  label: 'Подключить',
                                  onPressed: () => _testConnection(device),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Информация о соединениях
            const SizedBox(height: 16),
            Text(
              'Активные соединения',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 150,
              child: connectionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Ошибка: $error')),
                data: (connections) {
                  if (connections.isEmpty) {
                    return const Center(child: Text('Нет активных соединений'));
                  }

                  return ListView.builder(
                    itemCount: connections.length,
                    itemBuilder: (context, index) {
                      final connection = connections[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${connection.remoteDeviceId.substring(0, 8)}...',
                          ),
                          subtitle: Text('Состояние: ${connection.state.name}'),
                          trailing: Text(connection.role.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Диагностические функции
            const SizedBox(height: 16),
            Text('Диагностика', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Первый ряд кнопок
            Row(
              children: [
                Expanded(
                  child: SmoothButton(
                    type: SmoothButtonType.outlined,
                    size: SmoothButtonSize.small,
                    label: 'Показать сетевые интерфейсы',
                    onPressed: () async {
                      logInfo('Показ сетевых интерфейсов', tag: _logTag);
                      await DNSTestUtil.showNetworkInterfaces();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SmoothButton(
                    type: SmoothButtonType.outlined,
                    size: SmoothButtonSize.small,
                    label: 'Тест DNS резолюции',
                    onPressed: () => _testDNSResolution(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Второй ряд - диагностика сети
            SmoothButton(
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
              label: 'Полная диагностика сети',
              onPressed: () => _openNetworkDiagnostics(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          logInfo('Обновление списка устройств', tag: _logTag);
          await ref.read(discoveryProvider.notifier).reloadDiscovery();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  Future<void> _testConnection(DeviceInfo device) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      logInfo(
        'Попытка тестового подключения к устройству',
        tag: _logTag,
        data: {
          'deviceName': device.name,
          'deviceId': device.id,
          'deviceIp': device.ipAddress,
          'devicePort': device.port,
        },
      );

      final selfDevice = ref.read(selfDeviceProvider);
      final webrtcNotifier = ref.read(webrtcConnectionProvider.notifier);

      // Инициализируем WebRTC Service
      final webrtcService = ref.read(webrtcServiceProvider);
      await webrtcService.initialize();

      final connectionId = await webrtcNotifier.connectToDevice(
        localDeviceId: selfDevice.id,
        targetDevice: device,
      );

      if (connectionId != null) {
        logInfo(
          'Тестовое соединение создано',
          tag: _logTag,
          data: {'connectionId': connectionId},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Подключение к ${device.name} инициировано'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        logError('Не удалось создать тестовое соединение', tag: _logTag);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось создать соединение'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      logError('Ошибка тестового подключения', error: e, tag: _logTag);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _testDNSResolution() async {
    final devicesAsync = ref.read(discoveryProvider);
    final devices = devicesAsync.asData?.value ?? [];

    logInfo('Тестирование DNS резолюции для всех устройств', tag: _logTag);

    for (final device in devices) {
      await DNSTestUtil.testLocalResolution(device.ipAddress);
      await DNSTestUtil.testHttpConnectivity(device.ipAddress, device.port);
    }
  }

  void _openNetworkDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NetworkDiagnosticsScreen()),
    );
  }
}
