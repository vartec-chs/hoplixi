import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_rc/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend_rc/models/webrtc_error.dart';
import 'package:hoplixi/features/localsend_rc/providers/webrtc_provider.dart';

/// Виджет для отображения детализированного статуса WebRTC подключения
class ConnectionStatusWidget extends ConsumerWidget {
  const ConnectionStatusWidget({
    super.key,
    required this.remoteUri,
    this.showDetails = true,
    this.compact = false,
  });

  final String remoteUri;
  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(signalingNotifierProvider(remoteUri));

    return connectionState.when(
      loading: () => _buildLoadingStatus(context),
      error: (error, _) => _buildErrorStatus(
        context,
        WebRTCConnectionStatus(
          state: WebRTCConnectionState.failed,
          error: WebRTCError.unknown(error.toString()),
          lastStateChange: DateTime.now(),
        ),
      ),
      data: (status) => _buildStatus(context, status),
    );
  }

  Widget _buildLoadingStatus(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Подключение...', style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Установка соединения...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStatus(
    BuildContext context,
    WebRTCConnectionStatus status,
  ) {
    final color = Theme.of(context).colorScheme.error;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12, color: color),
          const SizedBox(width: 8),
          Text(
            'Ошибка',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.error?.type.displayName ?? 'Ошибка подключения',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            if (showDetails && status.error != null) ...[
              const SizedBox(height: 8),
              Text(
                status.error!.userMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, WebRTCConnectionStatus status) {
    final stateColor = _getStateColor(context, status.state);
    final stateIcon = status.state.icon;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stateIcon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            status.state.displayName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: stateColor),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(stateIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.state.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: stateColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (showDetails && status.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          status.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              _buildDetailsRow(context, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsRow(BuildContext context, WebRTCConnectionStatus status) {
    final details = <Widget>[];

    // Время последнего изменения состояния
    if (status.lastStateChange != null) {
      final timeSince = status.timeSinceLastChange;
      if (timeSince != null) {
        details.add(
          _buildDetailChip(context, Icons.schedule, _formatDuration(timeSince)),
        );
      }
    }

    // Количество попыток переподключения
    if (status.reconnectAttempts > 0) {
      details.add(
        _buildDetailChip(
          context,
          Icons.refresh,
          'Попытка ${status.reconnectAttempts}',
        ),
      );
    }

    // Длительность подключения
    if (status.connectionDuration != null) {
      details.add(
        _buildDetailChip(
          context,
          Icons.timer,
          _formatDuration(status.connectionDuration!),
        ),
      );
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 4, children: details);
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(BuildContext context, WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.connected:
        return Theme.of(context).colorScheme.primary;
      case WebRTCConnectionState.connecting:
      case WebRTCConnectionState.initializing:
      case WebRTCConnectionState.reconnecting:
        return Theme.of(context).colorScheme.secondary;
      case WebRTCConnectionState.failed:
        return Theme.of(context).colorScheme.error;
      case WebRTCConnectionState.disconnected:
      case WebRTCConnectionState.disconnecting:
        return Theme.of(context).colorScheme.outline;
      case WebRTCConnectionState.idle:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}ч ${duration.inMinutes % 60}м';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    } else {
      return '${duration.inSeconds}с';
    }
  }
}

/// Кнопка переподключения
class ReconnectButton extends ConsumerWidget {
  const ReconnectButton({
    super.key,
    required this.remoteUri,
    this.size = ReconnectButtonSize.medium,
  });

  final String remoteUri;
  final ReconnectButtonSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(signalingNotifierProvider(remoteUri));

    return connectionState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildButton(context, ref, true),
      data: (status) => _buildButton(context, ref, status.state.canReconnect),
    );
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, bool canReconnect) {
    if (!canReconnect) {
      return const SizedBox.shrink();
    }

    final buttonSize = switch (size) {
      ReconnectButtonSize.small => const Size(32, 32),
      ReconnectButtonSize.medium => const Size(40, 40),
      ReconnectButtonSize.large => const Size(48, 48),
    };

    final iconSize = switch (size) {
      ReconnectButtonSize.small => 16.0,
      ReconnectButtonSize.medium => 20.0,
      ReconnectButtonSize.large => 24.0,
    };

    return SizedBox(
      width: buttonSize.width,
      height: buttonSize.height,
      child: IconButton(
        onPressed: () async {
          final notifier = ref.read(
            signalingNotifierProvider(remoteUri).notifier,
          );
          await notifier.reconnect();
        },
        icon: Icon(Icons.refresh, size: iconSize),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        ),
        tooltip: 'Переподключиться',
      ),
    );
  }
}

/// Размеры кнопки переподключения
enum ReconnectButtonSize { small, medium, large }
