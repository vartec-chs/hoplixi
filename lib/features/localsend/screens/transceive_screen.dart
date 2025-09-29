import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/localsend_device_info.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/common/button.dart';

class TransceiveScreen extends ConsumerStatefulWidget {
  const TransceiveScreen({super.key, this.mode, this.deviceInfo});

  final ConnectionMode? mode;
  final LocalSendDeviceInfo? deviceInfo;

  @override
  ConsumerState<TransceiveScreen> createState() => _TransceiveScreenState();
}

class _TransceiveScreenState extends ConsumerState<TransceiveScreen> {
  static const String _logTag = 'TransceiveScreen';

  late final ConnectionMode _connectionMode;
  late final String _remoteUrl;
  late final TextEditingController _messageController;
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();

    // Автоматическая настройка параметров для тестирования
    _connectionMode = widget.mode ?? _getDefaultConnectionMode();
    _remoteUrl = widget.deviceInfo?.fullAddress ?? _getDefaultRemoteUrl();

    _messageController = TextEditingController();
    _usernameController = TextEditingController(text: 'TestUser');

    logInfo(
      'Инициализация TransceiveScreen',
      tag: _logTag,
      data: {
        'mode': _connectionMode.name,
        'remoteUrl': _remoteUrl.isNotEmpty ? 'provided' : 'empty',
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Получение режима подключения по умолчанию для тестирования
  ConnectionMode _getDefaultConnectionMode() {
    // Автоматически выбираем режим инициатора
    return ConnectionMode.initiator;
  }

  /// Получение URL по умолчанию для тестирования
  String _getDefaultRemoteUrl() {
    // Возвращаем тестовый URL
    return 'http://192.168.1.100:8080';
  }

  @override
  Widget build(BuildContext context) {
    final webrtcAsyncValue = ref.watch(
      webrtcProvider((_connectionMode, _remoteUrl)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Transceive Test'),
        // leading: BackButton(
        //   onPressed: () {
        //     // context.pop();
        //   },
        // ),
        actions: [
          // Информация о параметрах
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showParametersInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Карточка с информацией о параметрах
                  _buildParametersCard(),
                  const SizedBox(height: 16),

                  // Статус соединения
                  _buildConnectionStatus(webrtcAsyncValue),
                  const SizedBox(height: 16),

                  // Кнопки управления соединением
                  _buildConnectionControls(webrtcAsyncValue),
                  const SizedBox(height: 16),

                  // Поле для ввода сообщения
                  _buildMessageInput(webrtcAsyncValue),
                  const SizedBox(height: 16),

                  // История сообщений
                  _buildMessagesHistory(webrtcAsyncValue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Карточка с информацией о параметрах
  Widget _buildParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Параметры подключения',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildParameterRow(
              'Режим:',
              '${_connectionMode.icon} ${_connectionMode.displayName}',
            ),
            const SizedBox(height: 4),
            _buildParameterRow(
              'Remote URL:',
              _remoteUrl.isNotEmpty ? _remoteUrl : 'Не указан',
            ),
            const SizedBox(height: 4),
            _buildParameterRow(
              'Источник:',
              widget.mode != null ? 'Передан извне' : 'Автоматически',
            ),
          ],
        ),
      ),
    );
  }

  /// Строка с параметром
  Widget _buildParameterRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  /// Статус соединения
  Widget _buildConnectionStatus(AsyncValue<WebrtcState> webrtcAsyncValue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус соединения',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            webrtcAsyncValue.when(
              data: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.statusSummary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.detailedStatus,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Инициализация...'),
                ],
              ),
              error: (error, stack) => Text(
                'Ошибка: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопки управления соединением
  Widget _buildConnectionControls(AsyncValue<WebrtcState> webrtcAsyncValue) {
    return webrtcAsyncValue.when(
      data: (state) => Row(
        children: [
          Expanded(
            child: SmoothButton(
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
              label: state.isConnected ? 'Переподключить' : 'Подключиться',
              onPressed: _handleConnect,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SmoothButton(
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.medium,
              label: 'Отключиться',
              onPressed: state.isConnected ? _handleDisconnect : null,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SmoothButton(
        type: SmoothButtonType.filled,
        size: SmoothButtonSize.medium,
        label: 'Повторить',
        onPressed: _handleConnect,
      ),
    );
  }

  /// Поле для ввода сообщения
  Widget _buildMessageInput(AsyncValue<WebrtcState> webrtcAsyncValue) {
    final canSend = webrtcAsyncValue.value?.isReadyToSend ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PrimaryTextField(
                    controller: _usernameController,
                    label: 'Имя пользователя',
                    enabled: canSend,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: PrimaryTextField(
                    controller: _messageController,
                    label: 'Сообщение',
                    enabled: canSend,
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SmoothButton(
              type: SmoothButtonType.tonal,
              size: SmoothButtonSize.small,
              label: 'Отправить',
              onPressed: canSend && _messageController.text.isNotEmpty
                  ? _handleSendMessage
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// История сообщений
  Widget _buildMessagesHistory(AsyncValue<WebrtcState> webrtcAsyncValue) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'История сообщений',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: webrtcAsyncValue.when(
              data: (state) => state.hasMessages
                  ? ListView.builder(
                      itemCount: state.messages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _buildMessageTile(message);
                      },
                    )
                  : const Center(child: Text('Сообщений пока нет')),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Ошибка загрузки сообщений')),
            ),
          ),
        ],
      ),
    );
  }

  /// Плитка сообщения
  Widget _buildMessageTile(Map<String, dynamic> message) {
    final isFromMe = message['from'] == 'me';
    final username = message['username'] ?? 'Unknown';
    final text = message['text'] ?? '';
    final timestamp = message['timestamp'] as DateTime?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFromMe
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                username,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (timestamp != null)
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Обработка подключения
  Future<void> _handleConnect() async {
    try {
      logInfo('Попытка подключения', tag: _logTag);

      final notifier = ref.read(
        webrtcProvider((_connectionMode, _remoteUrl)).notifier,
      );
      await notifier.startConnection();

      ToastHelper.success(
        title: 'Соединение',
        description: 'Попытка подключения запущена',
      );
    } catch (e) {
      logError('Ошибка подключения', error: e, tag: _logTag);

      ToastHelper.error(title: 'Ошибка подключения', description: e.toString());
    }
  }

  /// Обработка отключения
  Future<void> _handleDisconnect() async {
    try {
      logInfo('Отключение', tag: _logTag);

      final notifier = ref.read(
        webrtcProvider((_connectionMode, _remoteUrl)).notifier,
      );
      await notifier.disconnect();

      ToastHelper.info(title: 'Соединение', description: 'Отключено от peer');
    } catch (e) {
      logError('Ошибка отключения', error: e, tag: _logTag);
    }
  }

  /// Обработка отправки сообщения
  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    final username = _usernameController.text.trim();

    if (message.isEmpty || username.isEmpty) return;

    try {
      logInfo(
        'Отправка сообщения',
        tag: _logTag,
        data: {'username': username, 'messageLength': message.length},
      );

      final notifier = ref.read(
        webrtcProvider((_connectionMode, _remoteUrl)).notifier,
      );
      await notifier.sendMessage(username: username, text: message);

      _messageController.clear();

      ToastHelper.success(
        title: 'Сообщение отправлено',
        description: 'Сообщение отправлено успешно',
      );
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);

      ToastHelper.error(title: 'Ошибка отправки', description: e.toString());
    }
  }

  /// Показ информации о параметрах
  void _showParametersInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о параметрах'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode: ${widget.mode?.name ?? 'null'} ${widget.mode != null ? '(передан)' : '(автоматически)'}',
            ),
            const SizedBox(height: 8),
            Text(
              'RemoteUrl: ${widget.deviceInfo?.fullAddress ?? 'null'} ${widget.deviceInfo != null ? '(передан)' : '(автоматически)'}',
            ),
            const SizedBox(height: 8),
            Text('Используемый mode: ${_connectionMode.name}'),
            const SizedBox(height: 8),
            Text(
              'Используемый URL: ${_remoteUrl.isEmpty ? 'Пустой' : _remoteUrl}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}
