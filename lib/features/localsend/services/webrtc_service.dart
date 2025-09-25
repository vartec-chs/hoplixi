import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/index.dart';
import 'package:hoplixi/features/localsend/services/webrtc_config.dart'
    as config;
import 'package:uuid/uuid.dart';

/// Менеджер WebRTC соединений для P2P передачи данных
class WebRTCService {
  static const String _logTag = 'WebRTCService';

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, WebRTCConnection> _connections = {};

  final StreamController<WebRTCConnection> _connectionStateController =
      StreamController<WebRTCConnection>.broadcast();
  final StreamController<LocalSendMessage> _messageController =
      StreamController<LocalSendMessage>.broadcast();
  final StreamController<FileChunk> _fileChunkController =
      StreamController<FileChunk>.broadcast();

  /// Поток состояний соединений
  Stream<WebRTCConnection> get connectionStates =>
      _connectionStateController.stream;

  /// Поток входящих сообщений
  Stream<LocalSendMessage> get incomingMessages => _messageController.stream;

  /// Поток входящих чанков файлов
  Stream<FileChunk> get incomingFileChunks => _fileChunkController.stream;

  /// Создает новое WebRTC соединение как инициатор (caller)
  Future<String> createConnection({
    required String localDeviceId,
    required String remoteDeviceId,
  }) async {
    try {
      final connectionId = const Uuid().v4();

      logInfo(
        'Создание WebRTC соединения',
        tag: _logTag,
        data: {'connectionId': connectionId, 'remoteDeviceId': remoteDeviceId},
      );

      final connection = WebRTCConnection(
        connectionId: connectionId,
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        role: WebRTCRole.caller,
        state: WebRTCConnectionState.initializing,
        createdAt: DateTime.now(),
      );

      _connections[connectionId] = connection;
      _connectionStateController.add(connection);

      final peerConnection = await _createPeerConnection(connectionId);
      final dataChannel = await _createDataChannel(
        peerConnection,
        connectionId,
      );

      _peerConnections[connectionId] = peerConnection;
      _dataChannels[connectionId] = dataChannel;

      return connectionId;
    } catch (e) {
      logError('Ошибка создания WebRTC соединения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Принимает входящее WebRTC соединение как получатель (callee)
  Future<String> acceptConnection({
    required String localDeviceId,
    required String remoteDeviceId,
  }) async {
    try {
      final connectionId = const Uuid().v4();

      logInfo(
        'Принятие WebRTC соединения',
        tag: _logTag,
        data: {'connectionId': connectionId, 'remoteDeviceId': remoteDeviceId},
      );

      final connection = WebRTCConnection(
        connectionId: connectionId,
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        role: WebRTCRole.callee,
        state: WebRTCConnectionState.initializing,
        createdAt: DateTime.now(),
      );

      _connections[connectionId] = connection;
      _connectionStateController.add(connection);

      final peerConnection = await _createPeerConnection(connectionId);
      _peerConnections[connectionId] = peerConnection;

      return connectionId;
    } catch (e) {
      logError('Ошибка принятия WebRTC соединения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Создает WebRTC offer
  Future<RTCSessionDescription> createOffer(String connectionId) async {
    try {
      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        throw Exception('Соединение не найдено: $connectionId');
      }

      logDebug(
        'Создание WebRTC offer',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      _updateConnectionState(connectionId, WebRTCConnectionState.connecting);

      return offer;
    } catch (e) {
      logError('Ошибка создания offer', error: e, tag: _logTag);
      _updateConnectionState(
        connectionId,
        WebRTCConnectionState.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Создает WebRTC answer
  Future<RTCSessionDescription> createAnswer(String connectionId) async {
    try {
      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        throw Exception('Соединение не найдено: $connectionId');
      }

      logDebug(
        'Создание WebRTC answer',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      return answer;
    } catch (e) {
      logError('Ошибка создания answer', error: e, tag: _logTag);
      _updateConnectionState(
        connectionId,
        WebRTCConnectionState.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Устанавливает удаленное описание
  Future<void> setRemoteDescription(
    String connectionId,
    RTCSessionDescription description,
  ) async {
    try {
      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        throw Exception('Соединение не найдено: $connectionId');
      }

      logDebug(
        'Установка remote description',
        tag: _logTag,
        data: {'connectionId': connectionId, 'type': description.type},
      );

      await peerConnection.setRemoteDescription(description);
    } catch (e) {
      logError('Ошибка установки remote description', error: e, tag: _logTag);
      _updateConnectionState(
        connectionId,
        WebRTCConnectionState.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Добавляет ICE кандидат
  Future<void> addIceCandidate(
    String connectionId,
    RTCIceCandidate candidate,
  ) async {
    try {
      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        throw Exception('Соединение не найдено: $connectionId');
      }

      logDebug(
        'Добавление ICE candidate',
        tag: _logTag,
        data: {'connectionId': connectionId, 'candidate': candidate.candidate},
      );

      await peerConnection.addCandidate(candidate);
    } catch (e) {
      logError('Ошибка добавления ICE candidate', error: e, tag: _logTag);
    }
  }

  /// Отправляет текстовое сообщение
  Future<void> sendMessage(
    String connectionId,
    LocalSendMessage message,
  ) async {
    try {
      final dataChannel = _dataChannels[connectionId];
      if (dataChannel == null ||
          dataChannel.state != RTCDataChannelState.RTCDataChannelOpen) {
        throw Exception('DataChannel недоступен для соединения: $connectionId');
      }

      final jsonData = jsonEncode({
        'type': 'message',
        'data': message.toJson(),
      });

      logDebug(
        'Отправка сообщения',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'messageId': message.id,
          'contentLength': message.content.length,
        },
      );

      dataChannel.send(RTCDataChannelMessage(jsonData));
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Отправляет чанк файла
  Future<void> sendFileChunk(String connectionId, FileChunk chunk) async {
    try {
      final dataChannel = _dataChannels[connectionId];
      if (dataChannel == null ||
          dataChannel.state != RTCDataChannelState.RTCDataChannelOpen) {
        throw Exception('DataChannel недоступен для соединения: $connectionId');
      }

      final jsonData = jsonEncode({
        'type': 'file_chunk',
        'data': chunk.toJson(),
      });

      logDebug(
        'Отправка чанка файла',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'transferId': chunk.transferId,
          'chunkIndex': chunk.chunkIndex,
          'size': chunk.size,
        },
      );

      dataChannel.send(RTCDataChannelMessage(jsonData));
    } catch (e) {
      logError('Ошибка отправки чанка файла', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Закрывает соединение
  Future<void> closeConnection(String connectionId) async {
    try {
      logInfo(
        'Закрытие WebRTC соединения',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      _updateConnectionState(connectionId, WebRTCConnectionState.disconnecting);

      final dataChannel = _dataChannels.remove(connectionId);
      dataChannel?.close();

      final peerConnection = _peerConnections.remove(connectionId);
      await peerConnection?.close();

      _updateConnectionState(connectionId, WebRTCConnectionState.disconnected);

      _connections.remove(connectionId);
    } catch (e) {
      logError('Ошибка закрытия соединения', error: e, tag: _logTag);
    }
  }

  /// Получает информацию о соединении
  WebRTCConnection? getConnection(String connectionId) {
    return _connections[connectionId];
  }

  /// Получает все активные соединения
  List<WebRTCConnection> get activeConnections => _connections.values.toList();

  /// Проверяет, есть ли активные соединения
  bool get hasActiveConnections => _connections.isNotEmpty;

  /// Освобождает все ресурсы
  Future<void> dispose() async {
    logInfo('Освобождение WebRTCService', tag: _logTag);

    // Закрываем все соединения
    final connectionIds = _connections.keys.toList();
    for (final connectionId in connectionIds) {
      await closeConnection(connectionId);
    }

    await _connectionStateController.close();
    await _messageController.close();
    await _fileChunkController.close();

    logInfo('WebRTCService освобожден', tag: _logTag);
  }

  /// Создает RTCPeerConnection
  Future<RTCPeerConnection> _createPeerConnection(String connectionId) async {
    final configuration = {
      'iceServers': config.WebRTCConfig.iceServers,
      'sdpSemantics': 'unified-plan',
    };

    final peerConnection = await createPeerConnection(configuration);

    // Настраиваем обработчики событий
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      logDebug(
        'Новый ICE candidate',
        tag: _logTag,
        data: {'connectionId': connectionId, 'candidate': candidate.candidate},
      );

      // ICE кандидат будет передан через сигналинг
      _onIceCandidate(connectionId, candidate);
    };

    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      logDebug(
        'Состояние PeerConnection изменилось',
        tag: _logTag,
        data: {'connectionId': connectionId, 'state': state.toString()},
      );

      _onPeerConnectionStateChange(connectionId, state);
    };

    peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
      logDebug(
        'Получен DataChannel',
        tag: _logTag,
        data: {'connectionId': connectionId, 'label': dataChannel.label},
      );

      _setupDataChannelHandlers(connectionId, dataChannel);
      _dataChannels[connectionId] = dataChannel;
    };

    return peerConnection;
  }

  /// Создает DataChannel
  Future<RTCDataChannel> _createDataChannel(
    RTCPeerConnection peerConnection,
    String connectionId,
  ) async {
    final dataChannel = await peerConnection.createDataChannel(
      'localsend_data',
      config.WebRTCConfig.dataChannelConfig,
    );

    _setupDataChannelHandlers(connectionId, dataChannel);

    return dataChannel;
  }

  /// Настраивает обработчики событий DataChannel
  void _setupDataChannelHandlers(
    String connectionId,
    RTCDataChannel dataChannel,
  ) {
    // Подписываемся на изменения состояния DataChannel
    dataChannel.stateChangeStream.listen((RTCDataChannelState state) {
      logDebug(
        'Состояние DataChannel изменилось',
        tag: _logTag,
        data: {'connectionId': connectionId, 'state': state.toString()},
      );

      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          _updateConnectionState(connectionId, WebRTCConnectionState.connected);
          break;
        case RTCDataChannelState.RTCDataChannelClosed:
          _updateConnectionState(
            connectionId,
            WebRTCConnectionState.disconnected,
          );
          break;
        case RTCDataChannelState.RTCDataChannelClosing:
          _updateConnectionState(
            connectionId,
            WebRTCConnectionState.disconnecting,
          );
          break;
        case RTCDataChannelState.RTCDataChannelConnecting:
          _updateConnectionState(
            connectionId,
            WebRTCConnectionState.connecting,
          );
          break;
      }
    });

    // Подписываемся на входящие сообщения
    dataChannel.messageStream.listen((RTCDataChannelMessage message) {
      _handleDataChannelMessage(connectionId, message);
    });
  }

  /// Обрабатывает сообщения DataChannel
  void _handleDataChannelMessage(
    String connectionId,
    RTCDataChannelMessage message,
  ) {
    try {
      final jsonData = jsonDecode(message.text) as Map<String, dynamic>;
      final type = jsonData['type'] as String;
      final data = jsonData['data'] as Map<String, dynamic>;

      switch (type) {
        case 'message':
          final localMessage = LocalSendMessage.fromJson(data);
          logDebug(
            'Получено сообщение',
            tag: _logTag,
            data: {'connectionId': connectionId, 'messageId': localMessage.id},
          );
          _messageController.add(localMessage);
          break;

        case 'file_chunk':
          final chunk = FileChunk.fromJson(data);
          logDebug(
            'Получен чанк файла',
            tag: _logTag,
            data: {
              'connectionId': connectionId,
              'transferId': chunk.transferId,
              'chunkIndex': chunk.chunkIndex,
            },
          );
          _fileChunkController.add(chunk);
          break;

        default:
          logWarning(
            'Неизвестный тип сообщения DataChannel: $type',
            tag: _logTag,
          );
      }
    } catch (e) {
      logError(
        'Ошибка обработки сообщения DataChannel',
        error: e,
        tag: _logTag,
      );
    }
  }

  /// Обрабатывает изменения состояния PeerConnection
  void _onPeerConnectionStateChange(
    String connectionId,
    RTCPeerConnectionState state,
  ) {
    WebRTCConnectionState connectionState;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        connectionState = WebRTCConnectionState.initializing;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        connectionState = WebRTCConnectionState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        connectionState = WebRTCConnectionState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        connectionState = WebRTCConnectionState.disconnected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        connectionState = WebRTCConnectionState.failed;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        connectionState = WebRTCConnectionState.disconnected;
        break;
    }

    _updateConnectionState(connectionId, connectionState);
  }

  /// Обрабатывает новые ICE кандидаты
  void _onIceCandidate(String connectionId, RTCIceCandidate candidate) {
    // В реальном приложении здесь должен быть код для отправки
    // ICE кандидата через сигналинг сервер
    // Это будет реализовано в провайдерах
  }

  /// Обновляет состояние соединения
  void _updateConnectionState(
    String connectionId,
    WebRTCConnectionState state, {
    String? errorMessage,
  }) {
    final connection = _connections[connectionId];
    if (connection == null) return;

    final updatedConnection = connection.copyWith(
      state: state,
      lastActivity: DateTime.now(),
      errorMessage: errorMessage,
    );

    _connections[connectionId] = updatedConnection;
    _connectionStateController.add(updatedConnection);
  }
}
