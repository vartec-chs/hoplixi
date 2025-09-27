import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/connection.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';

/// Демо виджет для демонстрации состояний соединения
/// Показывает как правильно отслеживать изменения состояния WebRTC соединения
class ConnectionStateDemo extends ConsumerWidget {
  const ConnectionStateDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConnection = ref.watch(currentConnectionProvider);
    final connectionsAsync = ref.watch(webrtcConnectionProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Состояние соединения',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Текущее соединение
            _buildCurrentConnectionSection(context, currentConnection),

            const Divider(height: 24),

            // Список всех соединений
            _buildAllConnectionsSection(context, connectionsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConnectionSection(
    BuildContext context,
    WebRTCConnection? connection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Текущее соединение',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        if (connection == null)
          const Text('Нет активного соединения')
        else ...[
          _buildConnectionStatusRow(
            'Статус:',
            _getConnectionStatusText(connection.state),
            _getConnectionStatusColor(connection.state),
          ),
          _buildConnectionStatusRow('ID:', connection.connectionId, null),
          _buildConnectionStatusRow(
            'Удаленное устройство:',
            connection.remoteDeviceId,
            null,
          ),
          _buildConnectionStatusRow('Роль:', connection.role.name, null),
          if (connection.errorMessage != null)
            _buildConnectionStatusRow(
              'Ошибка:',
              connection.errorMessage!,
              Colors.red,
            ),
        ],
      ],
    );
  }

  Widget _buildAllConnectionsSection(
    BuildContext context,
    AsyncValue<List<WebRTCConnection>> connectionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Все соединения', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        connectionsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) =>
              Text('Ошибка: $error', style: const TextStyle(color: Colors.red)),
          data: (connections) {
            if (connections.isEmpty) {
              return const Text('Нет соединений');
            }

            return Column(
              children: connections
                  .map(
                    (connection) => Card(
                      child: ListTile(
                        leading: Icon(
                          _getConnectionStateIcon(connection.state),
                          color: _getConnectionStatusColor(connection.state),
                        ),
                        title: Text(connection.remoteDeviceId),
                        subtitle: Text(
                          _getConnectionStatusText(connection.state),
                        ),
                        trailing: Text(
                          connection.role.name,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStatusRow(
    String label,
    String value,
    Color? valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getConnectionStatusText(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.initializing:
        return 'Инициализация...';
      case WebRTCConnectionState.connecting:
        return 'Подключение...';
      case WebRTCConnectionState.connected:
        return 'Подключено';
      case WebRTCConnectionState.disconnecting:
        return 'Отключение...';
      case WebRTCConnectionState.disconnected:
        return 'Отключено';
      case WebRTCConnectionState.failed:
        return 'Ошибка';
    }
  }

  Color _getConnectionStatusColor(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.initializing:
      case WebRTCConnectionState.connecting:
        return Colors.orange;
      case WebRTCConnectionState.connected:
        return Colors.green;
      case WebRTCConnectionState.disconnecting:
      case WebRTCConnectionState.disconnected:
        return Colors.grey;
      case WebRTCConnectionState.failed:
        return Colors.red;
    }
  }

  IconData _getConnectionStateIcon(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.initializing:
        return Icons.hourglass_empty;
      case WebRTCConnectionState.connecting:
        return Icons.sync;
      case WebRTCConnectionState.connected:
        return Icons.link;
      case WebRTCConnectionState.disconnecting:
        return Icons.link_off;
      case WebRTCConnectionState.disconnected:
        return Icons.link_off;
      case WebRTCConnectionState.failed:
        return Icons.error;
    }
  }
}

/// Демо-контроллер для тестирования состояний соединения
/// В реальном приложении не используется
class ConnectionStateController extends ConsumerWidget {
  const ConnectionStateController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConnectionNotifier = ref.read(
      currentConnectionProvider.notifier,
    );
    final currentConnection = ref.watch(currentConnectionProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Контроллер состояний (для отладки)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    logInfo('Симуляция подключения', tag: 'ConnectionDemo');
                    // В реальности это делает WebRTCService
                    currentConnectionNotifier.setConnection(
                      WebRTCConnection(
                        connectionId:
                            'demo-${DateTime.now().millisecondsSinceEpoch}',
                        localDeviceId: 'local-device',
                        remoteDeviceId: 'remote-device',
                        role: WebRTCRole.caller,
                        state: WebRTCConnectionState.connecting,
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Подключение...'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (currentConnection != null) {
                      logInfo(
                        'Симуляция успешного подключения',
                        tag: 'ConnectionDemo',
                      );
                      currentConnectionNotifier.updateConnectionState(
                        currentConnection.connectionId,
                        WebRTCConnectionState.connected,
                      );
                    }
                  },
                  child: const Text('Подключено'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (currentConnection != null) {
                      logInfo(
                        'Симуляция ошибки подключения',
                        tag: 'ConnectionDemo',
                      );
                      currentConnectionNotifier.updateConnectionState(
                        currentConnection.connectionId,
                        WebRTCConnectionState.failed,
                      );
                    }
                  },
                  child: const Text('Ошибка'),
                ),

                ElevatedButton(
                  onPressed: () {
                    logInfo('Очистка соединения', tag: 'ConnectionDemo');
                    currentConnectionNotifier.clearConnection();
                  },
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
