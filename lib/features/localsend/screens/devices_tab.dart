import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';
import 'package:hoplixi/features/localsend/widgets/index.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';

/// Вкладка с найденными устройствами
class DevicesTab extends ConsumerWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final currentDevice = ref.watch(currentDeviceProvider);

    return CustomScrollView(
      slivers: [
        // Секция текущего устройства
        SliverToBoxAdapter(
          child: _buildCurrentDeviceSection(context, currentDevice),
        ),

        // Заголовок обнаруженных устройств
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Обнаруженные устройства',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Список обнаруженных устройств
        if (discoveredDevices.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyState(context))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final device = discoveredDevices[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DeviceCard(device: device),
              );
            }, childCount: discoveredDevices.length),
          ),
      ],
    );
  }

  Widget _buildCurrentDeviceSection(
    BuildContext context,
    DeviceInfo currentDevice,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(currentDevice.type),
                  size: 32,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Это устройство',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentDevice.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'АКТИВНО',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeviceInfoRow(
              context,
              Icons.computer,
              'Тип устройства',
              _getDeviceTypeName(currentDevice.type),
            ),
            const SizedBox(height: 8),
            _buildDeviceInfoRow(
              context,
              Icons.network_wifi,
              'IP адрес',
              currentDevice.ipAddress,
            ),
            const SizedBox(height: 8),
            _buildDeviceInfoRow(
              context,
              Icons.router,
              'Порт',
              '${currentDevice.port}',
            ),
            if (currentDevice.attributes?['platform'] != null) ...[
              const SizedBox(height: 8),
              _buildDeviceInfoRow(
                context,
                Icons.info_outline,
                'Платформа',
                currentDevice.attributes!['platform']!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onPrimaryContainer.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  String _getDeviceTypeName(DeviceType type) {
    switch (type) {
      case DeviceType.desktop:
        return 'Компьютер';
      case DeviceType.mobile:
        return 'Мобильное устройство';
      case DeviceType.tablet:
        return 'Планшет';
      case DeviceType.unknown:
        return 'Неизвестный тип';
    }
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
