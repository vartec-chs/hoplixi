import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/providers/http_signaling_provider.dart';
import 'package:hoplixi/features/localsend/services/http_signaling_service.dart';
import 'package:hoplixi/features/localsend/services/webrtc_service.dart';

/// Provider для управления WebRTC соединениями
///
/// Использует family pattern для поддержки множественных соединений
/// с различными режимами подключения и удаленными URL
final webrtcProvider = AsyncNotifierProvider.family
    .autoDispose<WebrtcNotifier, WebrtcState, (ConnectionMode, String)>(
      WebrtcNotifier.new,
    );

/// WebRTC провайдер следующий архитектуре Riverpod v3 Notifier API
///
/// Управляет состоянием WebRTC соединения, включая:
/// - Инициализацию соединения
/// - Отслеживание состояний PeerConnection, ICE и DataChannel
/// - Обработку входящих и исходящих сообщений
/// - Управление жизненным циклом соединения
class WebrtcNotifier extends AsyncNotifier<WebrtcState> {
  static const String _logTag = 'WebrtcNotifier';
  final (ConnectionMode, String) params;

  WebrtcNotifier(this.params);

  late HttpSignalingService? _signalingService;

  /// Параметры соединения: режим подключения и удаленный URL (если необходим)

  ConnectionMode get connectionMode => params.$1;
  String get remoteUrl => params.$2;

  /// Основной сервис WebRTC
  WebRTCService? _webrtcService;

  /// Подписки на стримы для отслеживания состояний
  StreamSubscription? _pcStateSubscription;
  StreamSubscription? _iceStateSubscription;
  StreamSubscription? _dcStateSubscription;
  StreamSubscription? _messageSubscription;

  @override
  Future<WebrtcState> build() async {
    if (!ref.mounted) return WebrtcState.initial();
    _signalingService = ref.read(httpSignalingProvider);
    logInfo(
      'Инициализация WebRTC провайдера',
      tag: _logTag,
      data: {
        'connectionMode': connectionMode.name,
        'remoteUrl': remoteUrl.isEmpty ? 'null' : 'provided',
      },
    );

    // Настройка cleanup при disposal
    ref.onDispose(() {
      if (!ref.mounted) return;
      logInfo('Очистка WebRTC провайдера', tag: _logTag);

      _cleanupResources();
    });

    // Инициализация с базовым состоянием
    return WebrtcState.initial();
  }

  /// Запуск WebRTC соединения
  ///
  /// Создает сервис, настраивает подписки и инициирует подключение
  Future<void> startConnection() async {
    if (!ref.mounted) return;
    try {
      logInfo('Запуск WebRTC соединения', tag: _logTag);

      _webrtcService = WebRTCService(
        _signalingService!,
        connectionMode,
        remoteUrl: remoteUrl.isEmpty ? null : remoteUrl,
      );

      // Настройка подписок на изменения состояний
      _setupStateSubscriptions();

      // Запуск сервиса
      await _webrtcService!.start();

      logInfo('WebRTC соединение запущено успешно', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Ошибка запуска WebRTC соединения',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      ToastHelper.error(
        title: 'Ошибка подключения',
        description: 'Не удалось запустить соединение: ${e.toString()}',
      );

      // Устанавливаем состояние ошибки
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Настройка подписок на изменения состояний WebRTC
  void _setupStateSubscriptions() {
    if (_webrtcService == null || !ref.mounted) return;

    // Подписка на состояние PeerConnection
    _pcStateSubscription = _webrtcService!.onPeerConnectionState.listen((
      pcState,
    ) {
      logDebug(
        'PeerConnection состояние изменено: ${pcState.displayName}',
        tag: _logTag,
      );
      _updateState(pcState: pcState);
    });

    // Подписка на состояние ICE соединения
    _iceStateSubscription = _webrtcService!.onIceConnectionState.listen((
      iceState,
    ) {
      logDebug('ICE состояние изменено: ${iceState.displayName}', tag: _logTag);
      _updateState(iceState: iceState);
    });

    // Подписка на состояние DataChannel
    _dcStateSubscription = _webrtcService!.onDataChannelState.listen((dcState) {
      logDebug(
        'DataChannel состояние изменено: ${dcState.displayName}',
        tag: _logTag,
      );
      _updateState(dcState: dcState);
    });

    // Подписка на входящие сообщения
    _messageSubscription = _webrtcService!.onDataMessage.listen((message) {
      logDebug('Получено сообщение через DataChannel', tag: _logTag);
      _handleIncomingMessage(message);
    });
  }

  /// Обновление состояния с новыми значениями
  void _updateState({
    RTCPeerConnectionState? pcState,
    RTCIceConnectionState? iceState,
    RTCDataChannelState? dcState,
  }) {
    if (!ref.mounted) return;
    final currentState = state.value ?? WebrtcState.initial();

    final newState = currentState.copyWith(
      pcState: pcState ?? currentState.pcState,
      iceState: iceState ?? currentState.iceState,
      dcState: dcState ?? currentState.dcState,
      isConnected: _determineConnectionStatus(
        pcState ?? currentState.pcState,
        iceState ?? currentState.iceState,
      ),
    );

    state = AsyncValue.data(newState);
  }

  /// Определение статуса подключения на основе состояний PC и ICE
  bool _determineConnectionStatus(
    RTCPeerConnectionState pcState,
    RTCIceConnectionState iceState,
  ) {
    if (!ref.mounted) return false;
    return pcState.isSuccess && iceState.isSuccess;
  }

  /// Обработка входящих сообщений
  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (!ref.mounted) return;
    final currentState = state.value;
    if (currentState == null) return;

    final updatedMessages = [...currentState.messages, message];

    final newState = currentState.copyWith(messages: updatedMessages);

    state = AsyncValue.data(newState);
  }

  /// Отправка сообщения через DataChannel
  ///
  /// Проверяет готовность канала и отправляет JSON сообщение
  Future<void> sendMessage({
    required String username,
    required String text,
  }) async {
    if (!ref.mounted) return;
    try {
      if (_webrtcService == null) {
        throw Exception('WebRTC сервис не инициализирован');
      }

      if (!_webrtcService!.isDataChannelOpen) {
        throw Exception('DataChannel не открыт для отправки');
      }

      logInfo(
        'Отправка сообщения',
        tag: _logTag,
        data: {'username': username, 'textLength': text.length},
      );

      await _webrtcService!.sendDataChannelJson(username: username, text: text);
    } catch (e, stackTrace) {
      logError(
        'Ошибка отправки сообщения',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      ToastHelper.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить сообщение: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Закрытие соединения
  Future<void> disconnect() async {
    if (!ref.mounted) return;
    try {
      logInfo('Закрытие WebRTC соединения', tag: _logTag);

      await _webrtcService?.dispose();
      _cleanupResources();

      // Возврат к начальному состоянию
      state = AsyncValue.data(WebrtcState.initial());
    } catch (e, stackTrace) {
      logError(
        'Ошибка при закрытии соединения',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Очистка ресурсов и подписок
  void _cleanupResources() {
    if (!ref.mounted) return;
    _webrtcService?.dispose();
    _signalingService!.stop();
    _pcStateSubscription?.cancel();
    _iceStateSubscription?.cancel();
    _dcStateSubscription?.cancel();
    _messageSubscription?.cancel();
    if (!ref.mounted) return;
    _pcStateSubscription = null;
    _iceStateSubscription = null;
    _dcStateSubscription = null;
    _messageSubscription = null;
    if (!ref.mounted) return;
    _webrtcService = null;
    _signalingService = null;
  }

  /// Получение текущего состояния соединения (геттер для UI)
  WebrtcState? get currentState => state.value;

  /// Проверка готовности для отправки сообщений
  bool get canSendMessages => _webrtcService?.isDataChannelOpen ?? false;

  /// Проверка активности соединения
  bool get isConnected => currentState?.isConnected ?? false;

  /// Получение количества сообщений
  int get messageCount => currentState?.messageCount ?? 0;
}
