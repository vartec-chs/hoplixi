import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/device_info.dart';
import '../providers/discovery_provider.dart';

class TestDiscoveryScreen extends ConsumerWidget {
  const TestDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Discovery Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (devices) => ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              leading: Text(
                device.deviceIcon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(device.name),
              subtitle: Text(
                '${device.ipAddress}:${device.port} - ${device.status.name}',
              ),
              trailing: device.isSelf ? const Icon(Icons.person) : null,
            );
          },
        ),
      ),
    );
  }
}
