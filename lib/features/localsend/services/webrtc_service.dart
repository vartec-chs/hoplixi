import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:uuid/uuid.dart';

import './http_signaling_service.dart';

class WebrtcProviderException implements Exception {
  final String message;
  final StackTrace stackTrace;
  final String? code;
  WebrtcProviderException(this.message, this.stackTrace, {this.code});

  @override
  String toString() =>
      'WebrtcProviderException: $message\nCode: $code\n$stackTrace';
}

class WebRTCService {
  static const String _logTag = 'WebRTCService';
  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  final HttpSignalingService signalingService;
  final ConnectionMode mode;
  final String? remoteUrl;
  WebRTCService(this.signalingService, this.mode, {this.remoteUrl});

  bool get isConnected => _pc != null;
  bool get isDataChannelOpen =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  RTCPeerConnection? _pc; // Peer connection
  StreamSubscription? _sigSub; // Signaling subscription

  //peer connection state
  final _pcStateCtr = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onPeerConnectionState =>
      _pcStateCtr.stream; // Стрим состояния PeerConnection

  // ice connection state
  final _iceStateCtr = StreamController<RTCIceConnectionState>.broadcast();
  Stream<RTCIceConnectionState> get onIceConnectionState =>
      _iceStateCtr.stream; // Стрим состояния ICE соединения

  RTCDataChannel? _dataChannel; // Data channel
  final _dcMessageCtr =
      StreamController<
        Map<String, dynamic>
      >.broadcast(); // Data channel message controller
  Stream<Map<String, dynamic>> get onDataMessage =>
      _dcMessageCtr.stream; // Стрим входящих сообщений

  final _dcStateCtr = StreamController<RTCDataChannelState>.broadcast();
  Stream<RTCDataChannelState> get onDataChannelState =>
      _dcStateCtr.stream; // Стрим состояния datachannel

  Future<void> start() async {
    try {
      // Создание PeerConnection
      _pc = await createPeerConnection(_config);

      // Обработка ICE кандидатов
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
        signalingService.send({
          'type': 'candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      };

      _sigSub = signalingService.onMessageWs.listen(_handleSignalingMessage);

      if (mode == ConnectionMode.initiator) {
        // режим Server (ждём подключений)
        await signalingService.startServer(port: 53317);
        // не инициируем offer — будем ждать, пока другой клиент пришлёт offer
      } else {
        if (remoteUrl == null || remoteUrl!.isEmpty) {
          throw WebrtcProviderException(
            'Remote URL is required in client mode',
            StackTrace.current,
            code: 'NO_REMOTE_URL',
          );
        }
        // режим Client: подключаемся и инициируем offer
        await signalingService.connect(remoteUrl!);

        // create datachannel before createOffer so remote side will get onDataChannel
        _createDataChannel(label: 'data');

        // небольшой таймаут чтоб подписки успели встать
        await Future.delayed(const Duration(milliseconds: 200));
        await _createAndSendOffer();

        // ждем ICE gathering и отправляем кандидатов по мере их появления
      }
    } catch (e, s) {
      logError(
        'Failed to start signaling service',
        tag: _logTag,
        error: e,
        stackTrace: s,
      );
      throw WebrtcProviderException('Failed to start signaling service', s);
    }
  }

  void _createDataChannel({required String label}) async {
    if (_pc == null) return;
    final init = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = -1;
    try {
      final dc = await _pc!.createDataChannel(label, init);
      await _setDataChannel(dc);
    } catch (e, st) {
      logError(
        'Ошибка при создании dataChannel',
        error: e,
        tag: _logTag,
        stackTrace: st,
      );
    }
  }

  Future<void> _setDataChannel(RTCDataChannel dc) async {
    _dataChannel = dc;

    // push initial state
    if (!_dcStateCtr.isClosed) {
      _dcStateCtr.add(
        _dataChannel!.state ?? RTCDataChannelState.RTCDataChannelClosed,
      );
    }

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
        // if (parsed['type'] == 'file_transfer') {
        //   final payload = parsed['payload'] as Map<String, dynamic>;
        //   _fileTransferService.handleFileTransferMessage(payload);
        //   return;
        // }

        // normalize fields
        final id =
            parsed['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        final username = parsed['username']?.toString() ?? 'peer';
        final msgText = parsed['text']?.toString() ?? '';
        final ts = parsed['ts']?.toString() ?? DateTime.now().toIso8601String();

        if (!_dcMessageCtr.isClosed) {
          final messageData = {
            'from': 'peer',
            'id': id,
            'username': username,
            'text': msgText,
            'ts': ts,
          };
          _dcMessageCtr.add(messageData);
          // _addMessageToHistory(messageData);
        }
      } catch (e) {
        // не JSON — просто текст
        if (!_dcMessageCtr.isClosed) {
          final messageData = {
            'from': 'peer',
            'id': DateTime.now().microsecondsSinceEpoch.toString(),
            'username': 'peer',
            'text': text,
            'ts': DateTime.now().toIso8601String(),
          };
          _dcMessageCtr.add(messageData);
          // _addMessageToHistory(messageData);
        }
      }
    };

    // отслеживаем состояние канала
    _dataChannel!.onDataChannelState = (state) {
      if (!_dcStateCtr.isClosed) _dcStateCtr.add(state);
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
        await signalingService.send({'type': 'answer', 'sdp': answer.sdp});
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

  void _updateConnectionState(RTCPeerConnectionState state) {
    if (!_pcStateCtr.isClosed) {
      _pcStateCtr.add(state);
    } else {
      logWarning(
        'PC state stream is closed, cannot add new state',
        tag: _logTag,
      );
    }
  }

  void _updateIceConnectionState(RTCIceConnectionState state) {
    if (!_iceStateCtr.isClosed) {
      _iceStateCtr.add(state);
    } else {
      logWarning(
        'ICE state stream is closed, cannot add new state',
        tag: _logTag,
      );
    }
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await signalingService.send({'type': 'offer', 'sdp': offer.sdp});
  }

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
        final messageData = {
          'from': 'me',
          'id': id,
          'username': username,
          'text': text,
          'ts': payload['ts'],
        };
        _dcMessageCtr.add(messageData);
        // _addMessageToHistory(messageData);
      }
    } else {
      logError('DataChannel is not open, cannot send message', tag: _logTag);
      throw WebrtcProviderException(
        'DataChannel is not open',
        StackTrace.current,
        code: 'DC_NOT_OPEN',
      );
    }
  }

  Future<void> dispose() async {
    await _sigSub?.cancel();
    await _pcStateCtr.close();
    await _iceStateCtr.close();
    await _dcStateCtr.close();
    await _dcMessageCtr.close();
    await _pc?.close();
    await _dataChannel?.close();
    await signalingService.stop();
    await _dcMessageCtr.close();

    _pc = null;
    _dataChannel = null;
    _sigSub = null;
    logInfo('WebRTCService disposed', tag: _logTag);
  }
}
