import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';
import 'package:hoplixi/features/localsend/widgets/index.dart';

/// Вкладка с найденными устройствами
class DevicesTab extends ConsumerWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredDevices = ref.watch(discoveredDevicesProvider);

    if (discoveredDevices.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = discoveredDevices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: DeviceCard(device: device),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices,
            size: 64,
            color: colors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Устройства не найдены',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Убедитесь, что другие устройства находятся\nв той же сети и имеют включенный LocalSend',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
