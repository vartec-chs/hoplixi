import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend_rc/models/connection_mode.dart';
import 'package:hoplixi/features/localsend_rc/models/device_info.dart';
import 'package:hoplixi/features/localsend_rc/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend_rc/providers/webrtc_provider.dart';

class SettingsTab extends ConsumerStatefulWidget {
  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;
  final String remoteUri;

  const SettingsTab({
    super.key,
    required this.deviceInfo,
    required this.connectionMode,
    required this.remoteUri,
  });

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  static const _logTag = 'SettingsTab';

  StreamSubscription<String>? _dataChannelStateSubscription;
  String _dataChannelState = 'unknown';

  @override
  void dispose() {
    _dataChannelStateSubscription?.cancel();
    super.dispose();
  }

  void setupConnectionStateStream(WebRTCConnectionNotifier notifier) {
    _dataChannelStateSubscription?.cancel();

    _dataChannelStateSubscription = notifier.dataChannelStateStream.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _dataChannelState = state;
        });
        logInfo('DataChannel state changed: $state', tag: _logTag);
      }
    });
  }

  Widget _buildConnectionInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Информация о подключении',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.devices,
              label: 'Устройство',
              value: widget.deviceInfo?.name ?? 'Неизвестное',
              subtitle: widget.deviceInfo?.fullAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.swap_horiz,
              label: 'Режим подключения',
              value: widget.connectionMode?.displayName ?? 'Неизвестно',
              subtitle: widget.connectionMode?.description,
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final webrtcState = ref.watch(
                  signalingNotifierProvider(widget.remoteUri),
                );

                return webrtcState.when(
                  data: (status) => _buildInfoRow(
                    icon: _getStateIcon(status.state),
                    label: 'Состояние',
                    value: status.state.displayName,
                    subtitle: status.description,
                    valueColor: _getStateColor(status.state),
                  ),
                  loading: () => _buildInfoRow(
                    icon: Icons.sync,
                    label: 'Состояние',
                    value: 'Загрузка...',
                    valueColor: Theme.of(context).colorScheme.outline,
                  ),
                  error: (error, _) => _buildInfoRow(
                    icon: Icons.error,
                    label: 'Состояние',
                    value: 'Ошибка',
                    subtitle: error.toString(),
                    valueColor: Theme.of(context).colorScheme.error,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.cable,
              label: 'DataChannel',
              value: _formatDataChannelState(_dataChannelState),
              valueColor: _getDataChannelColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$label: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            valueColor ??
                            Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionActions() {
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(
          signalingNotifierProvider(widget.remoteUri),
        );

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Управление подключением',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    webrtcState.when(
                      data: (status) {
                        if (status.state == WebRTCConnectionState.connected) {
                          return SmoothButton(
                            type: SmoothButtonType.outlined,
                            size: SmoothButtonSize.medium,
                            label: 'Отключиться',
                            onPressed: () async {
                              try {
                                // Обновляем состояние провайдера, что приведет к очистке ресурсов
                                ref.invalidate(
                                  signalingNotifierProvider(widget.remoteUri),
                                );
                                ToastHelper.info(title: 'Отключение...');
                              } catch (e) {
                                logError(
                                  'Ошибка отключения',
                                  error: e,
                                  tag: _logTag,
                                );
                                ToastHelper.error(
                                  title: 'Ошибка отключения',
                                  description: e.toString(),
                                );
                              }
                            },
                          );
                        } else if (status.state.canReconnect) {
                          return SmoothButton(
                            type: SmoothButtonType.filled,
                            size: SmoothButtonSize.medium,
                            label: 'Переподключиться',
                            onPressed: () async {
                              try {
                                final notifier = ref.read(
                                  signalingNotifierProvider(
                                    widget.remoteUri,
                                  ).notifier,
                                );
                                await notifier.reconnect();
                                ToastHelper.info(title: 'Переподключение...');
                              } catch (e) {
                                logError(
                                  'Ошибка переподключения',
                                  error: e,
                                  tag: _logTag,
                                );
                                ToastHelper.error(
                                  title: 'Ошибка переподключения',
                                  description: e.toString(),
                                );
                              }
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => SmoothButton(
                        type: SmoothButtonType.filled,
                        size: SmoothButtonSize.medium,
                        label: 'Переподключиться',
                        onPressed: () async {
                          try {
                            ref.invalidate(
                              signalingNotifierProvider(widget.remoteUri),
                            );
                            ToastHelper.info(title: 'Переподключение...');
                          } catch (e) {
                            logError(
                              'Ошибка переподключения',
                              error: e,
                              tag: _logTag,
                            );
                            ToastHelper.error(
                              title: 'Ошибка переподключения',
                              description: e.toString(),
                            );
                          }
                        },
                      ),
                    ),
                    SmoothButton(
                      type: SmoothButtonType.outlined,
                      size: SmoothButtonSize.medium,
                      label: 'Копировать адрес',
                      onPressed: () async {
                        if (widget.deviceInfo?.fullAddress != null) {
                          await Clipboard.setData(
                            ClipboardData(text: widget.deviceInfo!.fullAddress),
                          );
                          ToastHelper.success(
                            title: 'Скопировано',
                            description: 'Адрес скопирован в буфер обмена',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechnicalInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(
          signalingNotifierProvider(widget.remoteUri),
        );

        return Card(
          margin: const EdgeInsets.all(16),
          child: ExpansionTile(
            leading: Icon(
              Icons.developer_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Техническая информация',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: webrtcState.when(
                  data: (status) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTechInfoRow(
                        'URI',
                        widget.remoteUri.isNotEmpty
                            ? widget.remoteUri
                            : 'Server mode',
                      ),
                      _buildTechInfoRow(
                        'Reconnect Attempts',
                        '${status.reconnectAttempts}',
                      ),
                      if (status.lastStateChange != null)
                        _buildTechInfoRow(
                          'Last State Change',
                          _formatDateTime(status.lastStateChange!),
                        ),
                      if (status.connectionStartTime != null)
                        _buildTechInfoRow(
                          'Connection Start',
                          _formatDateTime(status.connectionStartTime!),
                        ),
                      if (status.connectionDuration != null)
                        _buildTechInfoRow(
                          'Connection Duration',
                          _formatDuration(status.connectionDuration!),
                        ),
                      if (status.metadata != null &&
                          status.metadata!.isNotEmpty)
                        ...status.metadata!.entries.map(
                          (entry) => _buildTechInfoRow(
                            entry.key,
                            entry.value.toString(),
                          ),
                        ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Ошибка загрузки данных: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStateIcon(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.idle:
        return Icons.radio_button_unchecked;
      case WebRTCConnectionState.initializing:
      case WebRTCConnectionState.connecting:
      case WebRTCConnectionState.reconnecting:
        return Icons.sync;
      case WebRTCConnectionState.connected:
        return Icons.check_circle;
      case WebRTCConnectionState.disconnecting:
        return Icons.sync;
      case WebRTCConnectionState.disconnected:
        return Icons.radio_button_unchecked;
      case WebRTCConnectionState.failed:
        return Icons.error;
    }
  }

  Color _getStateColor(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.idle:
      case WebRTCConnectionState.disconnected:
        return Theme.of(context).colorScheme.outline;
      case WebRTCConnectionState.initializing:
      case WebRTCConnectionState.connecting:
      case WebRTCConnectionState.reconnecting:
      case WebRTCConnectionState.disconnecting:
        return Theme.of(context).colorScheme.primary;
      case WebRTCConnectionState.connected:
        return Theme.of(context).colorScheme.primary;
      case WebRTCConnectionState.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatDataChannelState(String state) {
    switch (state.toLowerCase()) {
      case 'open':
        return 'Открыт';
      case 'connecting':
        return 'Подключение';
      case 'closing':
        return 'Закрытие';
      case 'closed':
        return 'Закрыт';
      default:
        return 'Неизвестно';
    }
  }

  Color _getDataChannelColor() {
    switch (_dataChannelState.toLowerCase()) {
      case 'open':
        return Theme.of(context).colorScheme.primary;
      case 'connecting':
        return Theme.of(context).colorScheme.primary;
      case 'closing':
      case 'closed':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}ч ${minutes}м ${seconds}с';
    } else if (minutes > 0) {
      return '${minutes}м ${seconds}с';
    } else {
      return '${seconds}с';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Настраиваем потоки состояния подключения
    final webrtcState = ref.watch(signalingNotifierProvider(widget.remoteUri));

    webrtcState.whenData((status) {
      if (status.state == WebRTCConnectionState.connected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final notifier = ref.read(
            signalingNotifierProvider(widget.remoteUri).notifier,
          );
          setupConnectionStateStream(notifier);
        });
      }
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildConnectionInfo(),
          _buildConnectionActions(),
          _buildTechnicalInfo(),
          const SizedBox(height: 16), // Добавляем отступ снизу
        ],
      ),
    );
  }
}
