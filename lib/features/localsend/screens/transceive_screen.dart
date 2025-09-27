import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';

class TransceiverScreen extends StatelessWidget {
  const TransceiverScreen({super.key, this.deviceInfo});

  final DeviceInfo? deviceInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalSend - Передача файлов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: deviceInfo != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Подключено к устройству:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${deviceInfo!.deviceIcon} ${deviceInfo!.name}',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${deviceInfo!.ipAddress}:${deviceInfo!.port}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Статус: ${deviceInfo!.status.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement file transfer functionality
                      },
                      child: const Text('Передать файл'),
                    ),
                  ],
                )
              : const Text('Нет подключенного устройства'),
        ),
      ),
    );
  }
}
