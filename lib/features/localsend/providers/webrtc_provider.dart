// состояние для Notifier
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/localsend/services/http_signaling_service.dart';
import 'package:hoplixi/features/localsend/providers/signaling_service_provider.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/models/webrtc_error.dart';
import 'package:hoplixi/features/localsend/services/file_transfer_service.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

class WebrtcProviderException implements Exception {
  final String message;
  WebrtcProviderException(this.message);

  @override
  String toString() => 'WebrtcProviderException: $message';
}

final signalingNotifierProvider = AsyncNotifierProvider.family
    .autoDispose<WebRTCConnectionNotifier, WebRTCConnectionStatus, String>(
      WebRTCConnectionNotifier.new,
    );

class WebRTCConnectionNotifier extends AsyncNotifier<WebRTCConnectionStatus> {
  static const _logTag = 'WebRTCConnectionNotifier';
  WebRTCConnectionNotifier(this._remoteUriOrEmpty);
  late final HttpSignalingService _httpSignalingService;
  late final FileTransferService _fileTransferService;
  RTCPeerConnection? _pc;
  StreamSubscription? _sigSub;

  final String _remoteUriOrEmpty;

  // DataChannel
  RTCDataChannel? _dataChannel;
  final _dcMessageCtr = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDataMessage => _dcMessageCtr.stream;

  // DataChannel state stream for UI indicator
  final _dcStateCtr = StreamController<String>.broadcast();
  Stream<String> get dataChannelStateStream => _dcStateCtr.stream;

  /// Получить сервис передачи файлов
  FileTransferService get fileTransferService => _fileTransferService;

  @override
  Future<WebRTCConnectionStatus> build() async {
    _httpSignalingService = ref.read(
      signalingServiceProvider(_remoteUriOrEmpty),
    );

    // Инициализируем сервис передачи файлов
    _fileTransferService = FileTransferService();
    _fileTransferService.onSendData = _sendDataChannelMessage;

    ref.onDispose(() {
      _cleanup();
      _fileTransferService.dispose();
    });

    // Начальное состояние
    final initialStatus = WebRTCConnectionStatus(
      state: WebRTCConnectionState.initializing,
      lastStateChange: DateTime.now(),
    );

    try {
      await start();
      return initialStatus.copyWithState(WebRTCConnectionState.connected);
    } catch (e, st) {
      logError(
        'Ошибка при установке WebRTC соединения',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );

      final error = _createErrorFromException(e);
      return initialStatus.copyWithState(
        WebRTCConnectionState.failed,
        error: error,
      );
    }
  }

  /// Создает ошибку из исключения
  WebRTCError _createErrorFromException(dynamic exception) {
    if (exception is SocketException) {
      return WebRTCError.network(exception.message);
    } else if (exception is TimeoutException) {
      return WebRTCError.timeout(
        'Превышено время ожидания: ${exception.message}',
      );
    } else {
      return WebRTCError.unknown(exception.toString());
    }
  }

  /// Обновляет состояние соединения на основе PeerConnection state
  void _updateConnectionState(RTCPeerConnectionState connectionState) {
    final currentState = state.value;
    if (currentState == null) return;

    WebRTCConnectionState newState;
    WebRTCError? error;

    switch (connectionState) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        newState = WebRTCConnectionState.initializing;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        newState = WebRTCConnectionState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        newState = WebRTCConnectionState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        newState = WebRTCConnectionState.disconnected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        newState = WebRTCConnectionState.failed;
        error = WebRTCError.iceConnection('PeerConnection failed');
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        newState = WebRTCConnectionState.disconnected;
        break;
    }

    state = AsyncData(currentState.copyWithState(newState, error: error));
  }

  /// Обновляет состояние соединения на основе ICE connection state
  void _updateIceConnectionState(RTCIceConnectionState iceState) {
    final currentState = state.value;
    if (currentState == null) return;

    if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      final error = WebRTCError.iceConnection('ICE connection failed');
      state = AsyncData(
        currentState.copyWithState(WebRTCConnectionState.failed, error: error),
      );
    } else if (iceState ==
        RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      state = AsyncData(
        currentState.copyWithState(WebRTCConnectionState.disconnected),
      );
    }
  }

  Future<void> start() async {
    final config = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);

    // Подписываемся на состояние подключения, чтобы обновлять провайдер и логировать
    _pc!.onConnectionState = (connectionState) {
      logInfo('PeerConnection state: $connectionState', tag: _logTag);
      _updateConnectionState(connectionState);
    };

    _pc!.onIceConnectionState = (iceState) {
      logInfo('ICE connection state: $iceState', tag: _logTag);
      _updateIceConnectionState(iceState);
    };

    _pc!.onIceGatheringState = (gatheringState) {
      logInfo('ICE gathering state: $gatheringState', tag: _logTag);
    };

    _pc!.onDataChannel = (RTCDataChannel dc) {
      _setDataChannel(dc);
    };

    _pc!.onIceCandidate = (candidate) {
      _httpSignalingService.send({
        'type': 'candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _sigSub = _httpSignalingService.onMessageWs.listen(_handleSignalingMessage);

    if (_remoteUriOrEmpty.isEmpty) {
      // режим Server (ждём подключений)
      await _httpSignalingService.startServer(port: 53317);
      // не инициируем offer — будем ждать, пока другой клиент пришлёт offer
    } else {
      // режим Client: подключаемся и инициируем offer
      await _httpSignalingService.connect(_remoteUriOrEmpty);

      // create datachannel before createOffer so remote side will get onDataChannel
      _createDataChannel(label: 'data');

      // небольшой таймаут чтоб подписки успели встать
      await Future.delayed(const Duration(milliseconds: 200));
      await _createAndSendOffer();

      // ждем ICE gathering и отправляем кандидатов по мере их появления
    }
  }

  // Создание dataChannel (на стороне, которая инициирует offer)
  void _createDataChannel({required String label}) async {
    if (_pc == null) return;
    final init = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = -1;
    try {
      final dc = await _pc!.createDataChannel(label, init);
      _setDataChannel(dc);
    } catch (e, st) {
      logError(
        'Ошибка при создании dataChannel',
        error: e,
        tag: _logTag,
        stackTrace: st,
      );
    }
  }

  // Установка и подписка на dataChannel
  void _setDataChannel(RTCDataChannel dc) async {
    _dataChannel = dc;

    // push initial state
    if (!_dcStateCtr.isClosed) _dcStateCtr.add(_dataChannel!.state.toString());

    // входящие сообщения
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      final text = message.isBinary ? null : message.text;
      if (text == null) {
        if (!_dcMessageCtr.isClosed) {
          _dcMessageCtr.add({
            'from': 'peer',
            'username': 'peer',
            'text': '<binary>',
            'id': DateTime.now().microsecondsSinceEpoch.toString(),
            'ts': DateTime.now().toIso8601String(),
          });
        }
        return;
      }

      // пытаемся распарсить JSON-строку с {id, username, text, ts}
      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;

        // Проверяем, является ли это сообщением передачи файла
        if (parsed['type'] == 'file_transfer') {
          final payload = parsed['payload'] as Map<String, dynamic>;
          _fileTransferService.handleFileTransferMessage(payload);
          return;
        }

        // normalize fields
        final id =
            parsed['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        final username = parsed['username']?.toString() ?? 'peer';
        final msgText = parsed['text']?.toString() ?? '';
        final ts = parsed['ts']?.toString() ?? DateTime.now().toIso8601String();

        if (!_dcMessageCtr.isClosed) {
          _dcMessageCtr.add({
            'from': 'peer',
            'id': id,
            'username': username,
            'text': msgText,
            'ts': ts,
          });
        }
      } catch (e) {
        // не JSON — просто текст
        if (!_dcMessageCtr.isClosed) {
          _dcMessageCtr.add({
            'from': 'peer',
            'id': DateTime.now().microsecondsSinceEpoch.toString(),
            'username': 'peer',
            'text': text,
            'ts': DateTime.now().toIso8601String(),
          });
        }
      }
    };

    // отслеживаем состояние канала
    _dataChannel!.onDataChannelState = (state) {
      if (!_dcStateCtr.isClosed) _dcStateCtr.add(state.toString());
      if (!_dcMessageCtr.isClosed) {
        _dcMessageCtr.add({
          'from': 'system',
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'username': 'system',
          'text': 'datachannel state: $state',
          'ts': DateTime.now().toIso8601String(),
        });
      }
    };
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> msg) async {
    final type = msg['type'] as String?;
    if (type == null) return;
    try {
      if (type == 'offer') {
        final sdp = msg['sdp'] as String;
        await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        await _httpSignalingService.send({'type': 'answer', 'sdp': answer.sdp});
      } else if (type == 'answer') {
        final sdp = msg['sdp'] as String;
        await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      } else if (type == 'candidate') {
        final c = msg['candidate'] as Map<String, dynamic>;
        final candidate = RTCIceCandidate(
          c['candidate'] as String,
          c['sdpMid'] as String?,
          c['sdpMLineIndex'] as int?,
        );
        await _pc!.addCandidate(candidate);
      } else if (type == 'chat_fallback') {
        // Получили fallback-чат через signaling — отобразим как входящее сообщение
        final payload = msg['payload'] as Map<String, dynamic>?;
        if (payload != null && !_dcMessageCtr.isClosed) {
          _dcMessageCtr.add({
            'from': 'peer',
            'id':
                payload['id']?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            'username': payload['username']?.toString() ?? 'peer',
            'text': payload['text']?.toString() ?? '',
            'ts': payload['ts']?.toString() ?? DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e, st) {
      logError(
        'Ошибка при обработке signaling сообщения',
        error: e,
        tag: _logTag,
        stackTrace: st,
      );
    }
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await _httpSignalingService.send({'type': 'offer', 'sdp': offer.sdp});
  }

  // public method, можно вызвать из UI — послать signaling сообщение (debug)
  Future<void> sendData(Map<String, dynamic> data) async {
    await _httpSignalingService.send(data);
  }

  // Новый: отправка структурированного JSON-сообщения через DataChannel
  Future<void> sendDataChannelJson({
    required String username,
    required String text,
  }) async {
    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final id = Uuid().v4();
      final payload = {
        'id': id,
        'username': username,
        'text': text,
        'ts': DateTime.now().toIso8601String(),
      };
      final jsonText = jsonEncode(payload);
      _dataChannel!.send(RTCDataChannelMessage(jsonText));
      // локально добавляем сообщение в поток, чтобы UI сразу показал
      if (!_dcMessageCtr.isClosed) {
        _dcMessageCtr.add({
          'from': 'me',
          'id': id,
          'username': username,
          'text': text,
          'ts': payload['ts'],
        });
      }
    } else {
      logError('DataChannel is not open, cannot send message', tag: _logTag);
      // не кидаем исключение — просто логируем ошибку
      throw WebrtcProviderException('DataChannel is not open');
    }
  }

  /// Принудительное переподключение
  Future<void> reconnect() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Обновляем состояние на переподключение
      state = AsyncData(
        currentState
            .copyWithState(WebRTCConnectionState.reconnecting)
            .incrementReconnectAttempts(),
      );

      // Очищаем текущие ресурсы
      await _cleanup();

      // Ждем немного перед переподключением
      await Future.delayed(const Duration(seconds: 1));

      // Перезапускаем соединение
      await start();

      // Обновляем состояние на подключено
      final updatedState = state.value;
      if (updatedState != null) {
        state = AsyncData(
          updatedState
              .copyWithState(WebRTCConnectionState.connected)
              .resetReconnectAttempts(),
        );
      }
    } catch (e, st) {
      logError(
        'Ошибка при переподключении',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );

      final error = _createErrorFromException(e);
      final updatedState = state.value;
      if (updatedState != null) {
        state = AsyncData(
          updatedState.copyWithState(
            WebRTCConnectionState.failed,
            error: error,
          ),
        );
      }
    }
  }

  /// Отправляет данные через DataChannel (для FileTransferService)
  Future<void> _sendDataChannelMessage(Map<String, dynamic> data) async {
    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final jsonText = jsonEncode(data);
      _dataChannel!.send(RTCDataChannelMessage(jsonText));
    } else {
      logError('DataChannel не открыт для отправки данных', tag: _logTag);
      throw WebrtcProviderException('DataChannel is not open');
    }
  }

  // очистка ресурсов
  Future<void> _cleanup() async {
    if (!ref.mounted) return;
    await _sigSub?.cancel();
    _sigSub = null;

    try {
      await _dataChannel?.close();
    } catch (e) {
      logError('Ошибка при закрытии dataChannel', error: e, tag: _logTag);
    }
    _dataChannel = null;

    if (_pc != null) {
      await _pc!.close();
      _pc = null;
    }

    try {
      await _dcMessageCtr.close();
    } catch (e) {
      logError('Ошибка при закрытии dcMessageCtr', error: e, tag: _logTag);
    }
    try {
      await _dcStateCtr.close();
    } catch (e) {
      logError('Ошибка при закрытии dcStateCtr', error: e, tag: _logTag);
    }

    // всегда останавливаем signaling
    try {
      await _httpSignalingService.stop();
    } catch (e) {
      logError(
        'Ошибка при остановке signaling сервиса',
        error: e,
        tag: _logTag,
      );
    }
  }

  // Методы для управления состоянием соединения будут добавлены здесь
}
