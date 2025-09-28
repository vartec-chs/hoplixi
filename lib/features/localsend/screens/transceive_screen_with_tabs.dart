import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/models/webrtc_error.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend/screens/tabs/index.dart';

class TransceiveScreenWithTabs extends ConsumerStatefulWidget {
  const TransceiveScreenWithTabs({
    super.key,
    this.deviceInfo,
    this.connectionMode,
  });

  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;

  @override
  ConsumerState<TransceiveScreenWithTabs> createState() =>
      _TransceiveScreenWithTabsState();
}

class _TransceiveScreenWithTabsState
    extends ConsumerState<TransceiveScreenWithTabs>
    with TickerProviderStateMixin {
  static const _logTag = 'TransceiveScreenWithTabs';

  LocalSendDeviceInfo? get deviceInfo => widget.deviceInfo;
  ConnectionMode? get connectionMode => widget.connectionMode;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    logInfo(
      'TransceiveScreenWithTabs инициализирован',
      tag: _logTag,
      data: {
        'deviceName': deviceInfo?.name,
        'connectionMode': connectionMode?.name,
        'remoteAddress': deviceInfo?.fullAddress,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _remoteUri {
    if (deviceInfo == null) return '';
    return connectionMode == ConnectionMode.initiator
        ? 'http://${deviceInfo!.fullAddress}'
        : ''; // Server mode - пустая строка
  }

  Widget _buildConnectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                deviceInfo?.deviceIcon ?? '📡',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceInfo?.name ?? 'Неизвестное устройство',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      deviceInfo?.fullAddress ?? 'Неизвестный адрес',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                connectionMode?.icon ?? '🔗',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                connectionMode?.displayName ?? 'Неизвестный режим',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              _buildConnectionStatus(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final webrtcState = ref.watch(signalingNotifierProvider(_remoteUri));

        return webrtcState.when(
          data: (status) {
            final isConnected = status.state == WebRTCConnectionState.connected;
            final color = isConnected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status.state.displayName,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Загрузка...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  size: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ошибка',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Чат'),
        Tab(icon: Icon(Icons.file_copy_outlined), text: 'Файлы'),
        Tab(icon: Icon(Icons.settings_outlined), text: 'Настройки'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          ChatTab(
            deviceInfo: deviceInfo,
            connectionMode: connectionMode,
            remoteUri: _remoteUri,
          ),
          FilesTab(
            deviceInfo: deviceInfo,
            connectionMode: connectionMode,
            remoteUri: _remoteUri,
          ),
          SettingsTab(
            deviceInfo: deviceInfo,
            connectionMode: connectionMode,
            remoteUri: _remoteUri,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            connectionMode == ConnectionMode.initiator
                ? 'Подключение к устройству...'
                : 'Ожидание подключения...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (deviceInfo != null)
            Text(
              '${deviceInfo!.name} (${deviceInfo!.fullAddress})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WebRTCConnectionStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            status.error?.type.displayName ?? 'Ошибка подключения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              status.error?.userMessage ?? status.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmoothButton(
                type: SmoothButtonType.outlined,
                size: SmoothButtonSize.medium,
                label: 'Назад',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 16),
              SmoothButton(
                type: SmoothButtonType.filled,
                size: SmoothButtonSize.medium,
                label: 'Переподключиться',
                onPressed: () async {
                  final notifier = ref.read(
                    signalingNotifierProvider(_remoteUri).notifier,
                  );
                  await notifier.reconnect();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (deviceInfo == null || connectionMode == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Обмен данными'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Не хватает данных для подключения')),
      );
    }

    final webrtcState = ref.watch(signalingNotifierProvider(_remoteUri));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обмен данными'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(signalingNotifierProvider(_remoteUri));
              ToastHelper.info(title: 'Переподключение...');
            },
            tooltip: 'Переподключиться',
          ),
        ],
        bottom: webrtcState.when(
          data: (status) {
            // Показываем TabBar только при успешном подключении
            if (status.state == WebRTCConnectionState.connected) {
              return PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: _buildTabBar(),
              );
            }
            return null;
          },
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: SafeArea(
        child: webrtcState.when(
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState(
            WebRTCConnectionStatus(
              state: WebRTCConnectionState.failed,
              error: WebRTCError.unknown(error.toString()),
              lastStateChange: DateTime.now(),
            ),
          ),
          data: (status) {
            // Проверяем состояние подключения
            if (status.state == WebRTCConnectionState.failed) {
              return _buildErrorState(status);
            }

            if (status.state != WebRTCConnectionState.connected) {
              return _buildLoadingState();
            }

            return Column(
              children: [_buildConnectionHeader(), _buildTabBarView()],
            );
          },
        ),
      ),
    );
  }
}
