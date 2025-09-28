import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/connection.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';
import 'package:hoplixi/features/localsend/models/ice_candidate_event.dart';
import 'package:hoplixi/features/localsend/models/message.dart';
import 'package:hoplixi/features/localsend/models/webrtc_config.dart' as config;
import 'package:hoplixi/features/localsend/services/http_signaling_service.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Размер чанка файла (128KB)
const int _chunkSize = 128 * 1024;

/// Менеджер WebRTC соединений для P2P передачи данных
class WebRTCService {
  static const String _logTag = 'WebRTCService';

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, WebRTCConnection> _connections = {};
  final Map<String, FileTransfer> _activeTransfers = {};
  final Map<String, Timer> _transferTimers = {};

  final StreamController<WebRTCConnection> _connectionStateController =
      StreamController<WebRTCConnection>.broadcast();
  final StreamController<LocalSendMessage> _messageController =
      StreamController<LocalSendMessage>.broadcast();
  final StreamController<FileTransfer> _fileTransferController =
      StreamController<FileTransfer>.broadcast();
  final StreamController<IceCandidateEvent> _iceCandidateController =
      StreamController<IceCandidateEvent>.broadcast();

  final HttpSignalingService _signalingService = HttpSignalingService();

  /// Порт сигналинг сервера
  int? _signalingPort;

  /// Поток состояний соединений
  Stream<WebRTCConnection> get connectionStates =>
      _connectionStateController.stream;

  /// Поток входящих сообщений
  Stream<LocalSendMessage> get incomingMessages => _messageController.stream;

  /// Поток состояний передач файлов
  Stream<FileTransfer> get fileTransferUpdates =>
      _fileTransferController.stream;

  /// Поток ICE кандидатов
  Stream<IceCandidateEvent> get iceCandidates => _iceCandidateController.stream;

  /// Инициализация сервиса
  Future<void> initialize() async {
    logInfo('Инициализация WebRTCService', tag: _logTag);

    // Подписываемся на сообщения сигналинга
    _signalingService.incomingMessages.listen(_handleSignalingMessage);

    logInfo('WebRTCService инициализирован', tag: _logTag);
  }

  /// Запускает HTTP сервер для сигналинга
  Future<int?> startSignalingServer({int? port}) async {
    await _signalingService.startServer(port: port);
    _signalingPort = _signalingService.port;
    return _signalingPort;
  }

  /// Останавливает HTTP сервер
  Future<void> stopSignalingServer() async {
    await _signalingService.stopServer();
  }

  /// Создает новое WebRTC соединение как инициатор (caller)
  Future<String> createConnection({
    required String localDeviceId,
    required String remoteDeviceId,
    required String remoteIp,
    required int remotePort,
  }) async {
    try {
      final connectionId = const Uuid().v4();

      logInfo(
        'Создание WebRTC соединения',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'localDeviceId': localDeviceId,
          'remoteDeviceId': remoteDeviceId,
          'remoteIp': remoteIp,
          'remotePort': remotePort,
        },
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

      // Создаем и отправляем offer
      await _createAndSetOffer(connectionId, remoteIp, remotePort);

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
    required String remoteIp,
    required int remotePort,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      final connectionId = const Uuid().v4();

      logInfo(
        'Принятие WebRTC соединения',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'localDeviceId': localDeviceId,
          'remoteDeviceId': remoteDeviceId,
        },
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

      // Устанавливаем удаленный offer и создаем answer
      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await peerConnection.setRemoteDescription(offer);

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      // Отправляем answer
      final answerMessage = _signalingService.createAnswerMessage(
        fromDeviceId: localDeviceId,
        toDeviceId: remoteDeviceId,
        sdpAnswer: {'sdp': answer.sdp, 'type': answer.type},
      );

      await _signalingService.sendMessage(
        remoteDeviceId,
        remoteIp,
        remotePort,
        answerMessage,
      );

      _updateConnectionState(connectionId, WebRTCConnectionState.connecting);

      return connectionId;
    } catch (e) {
      logError('Ошибка принятия WebRTC соединения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Отправляет текстовое сообщение
  Future<bool> sendMessage(
    String connectionId,
    LocalSendMessage message,
  ) async {
    try {
      final dataChannel = _dataChannels[connectionId];
      if (dataChannel == null ||
          dataChannel.state != RTCDataChannelState.RTCDataChannelOpen) {
        logError('DataChannel недоступен для отправки сообщения', tag: _logTag);
        return false;
      }

      logDebug(
        'Отправка сообщения',
        tag: _logTag,
        data: {'connectionId': connectionId, 'type': message.type.name},
      );

      final messageWrapper = {'type': 'message', 'data': message.toJson()};

      final jsonData = json.encode(messageWrapper);
      dataChannel.send(RTCDataChannelMessage(jsonData));

      return true;
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      return false;
    }
  }

  /// Начинает отправку файла
  Future<String?> sendFile({
    required String connectionId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        logError('Файл не найден: $filePath', tag: _logTag);
        return null;
      }

      final connection = _connections[connectionId];
      if (connection == null ||
          connection.state != WebRTCConnectionState.connected) {
        logError('Соединение недоступно для передачи файла', tag: _logTag);
        return null;
      }

      final fileSize = await file.length();
      final fileHash = await _calculateFileHash(filePath);

      final transfer = FileTransfer.sending(
        senderId: connection.localDeviceId,
        receiverId: connection.remoteDeviceId,
        fileName: fileName,
        fileSize: fileSize,
        filePath: filePath,
        mimeType: mimeType,
        fileHash: fileHash,
      );

      _activeTransfers[transfer.id] = transfer;
      _fileTransferController.add(transfer);

      logInfo(
        'Начало передачи файла',
        tag: _logTag,
        data: {
          'transferId': transfer.id,
          'fileName': fileName,
          'fileSize': fileSize,
        },
      );

      // Отправляем метаданные файла
      await _sendFileMetadata(connectionId, transfer);

      // Запускаем передачу файла
      await _startFileSending(connectionId, transfer);

      return transfer.id;
    } catch (e) {
      logError('Ошибка начала передачи файла', error: e, tag: _logTag);
      return null;
    }
  }

  /// Принимает входящий файл
  Future<bool> acceptFileTransfer(String transferId, String savePath) async {
    try {
      final transfer = _activeTransfers[transferId];
      if (transfer == null) {
        logError('Передача файла не найдена: $transferId', tag: _logTag);
        return false;
      }

      final updatedTransfer = transfer.copyWith(
        filePath: savePath,
        status: FileTransferStatus.inProgress,
        startTime: DateTime.now(),
      );

      _activeTransfers[transferId] = updatedTransfer;
      _fileTransferController.add(updatedTransfer);

      logInfo(
        'Принятие входящего файла',
        tag: _logTag,
        data: {'transferId': transferId, 'savePath': savePath},
      );

      return true;
    } catch (e) {
      logError('Ошибка принятия файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Отклоняет передачу файла
  Future<bool> rejectFileTransfer(String transferId) async {
    try {
      final transfer = _activeTransfers[transferId];
      if (transfer == null) return false;

      final updatedTransfer = transfer.copyWith(
        status: FileTransferStatus.cancelled,
        endTime: DateTime.now(),
      );

      _activeTransfers[transferId] = updatedTransfer;
      _fileTransferController.add(updatedTransfer);

      logInfo(
        'Передача файла отклонена',
        tag: _logTag,
        data: {'transferId': transferId},
      );
      return true;
    } catch (e) {
      logError('Ошибка отклонения передачи файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Отменяет активную передачу файла
  Future<bool> cancelFileTransfer(String transferId) async {
    try {
      final transfer = _activeTransfers[transferId];
      if (transfer == null) return false;

      // Останавливаем таймер передачи
      _transferTimers[transferId]?.cancel();
      _transferTimers.remove(transferId);

      final updatedTransfer = transfer.copyWith(
        status: FileTransferStatus.cancelled,
        endTime: DateTime.now(),
      );

      _activeTransfers[transferId] = updatedTransfer;
      _fileTransferController.add(updatedTransfer);

      logInfo(
        'Передача файла отменена',
        tag: _logTag,
        data: {'transferId': transferId},
      );
      return true;
    } catch (e) {
      logError('Ошибка отмены передачи файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Закрывает соединение
  Future<void> closeConnection(String connectionId) async {
    try {
      logInfo(
        'Закрытие соединения',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      // Останавливаем все активные передачи файлов для этого соединения
      final connection = _connections[connectionId];
      if (connection != null) {
        final relatedTransfers = _activeTransfers.values
            .where(
              (transfer) =>
                  transfer.senderId == connection.localDeviceId ||
                  transfer.receiverId == connection.localDeviceId,
            )
            .toList();

        for (final transfer in relatedTransfers) {
          await cancelFileTransfer(transfer.id);
        }
      }

      // Закрываем DataChannel
      final dataChannel = _dataChannels[connectionId];
      if (dataChannel != null) {
        await dataChannel.close();
        _dataChannels.remove(connectionId);
      }

      // Закрываем PeerConnection
      final peerConnection = _peerConnections[connectionId];
      if (peerConnection != null) {
        await peerConnection.close();
        _peerConnections.remove(connectionId);
      }

      // Обновляем состояние соединения
      _updateConnectionState(connectionId, WebRTCConnectionState.disconnected);

      // Удаляем соединение из мапы
      _connections.remove(connectionId);

      logInfo(
        'Соединение закрыто',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );
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

  /// Получает все активные передачи файлов
  List<FileTransfer> get activeFileTransfers =>
      _activeTransfers.values.toList();

  /// Проверяет, есть ли активные соединения
  bool get hasActiveConnections => _connections.isNotEmpty;

  /// Освобождает все ресурсы
  Future<void> dispose() async {
    logInfo('Освобождение WebRTCService', tag: _logTag);

    // Останавливаем все таймеры передач
    _transferTimers.values.forEach((timer) => timer.cancel());
    _transferTimers.clear();

    // Закрываем все соединения
    final connectionIds = _connections.keys.toList();
    for (final connectionId in connectionIds) {
      await closeConnection(connectionId);
    }

    // Закрываем потоки
    await _connectionStateController.close();
    await _messageController.close();
    await _fileTransferController.close();
    await _iceCandidateController.close();

    // Освобождаем сигналинг сервис
    await _signalingService.dispose();

    logInfo('WebRTCService освобожден', tag: _logTag);
  }

  /// Создает RTCPeerConnection
  Future<RTCPeerConnection> _createPeerConnection(String connectionId) async {
    final configuration = config.WebRTCConfig.pcConfig;
    final peerConnection = await createPeerConnection(configuration);

    // Настраиваем обработчики событий
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _onIceCandidate(connectionId, candidate);
    };

    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      _onPeerConnectionStateChange(connectionId, state);
    };

    peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
      logInfo('Получен DataChannel от удаленного устройства', tag: _logTag);
      _dataChannels[connectionId] = dataChannel;
      _setupDataChannelHandlers(connectionId, dataChannel);
    };

    return peerConnection;
  }

  /// Создает DataChannel
  Future<RTCDataChannel> _createDataChannel(
    RTCPeerConnection peerConnection,
    String connectionId,
  ) async {
    final dataChannel = await peerConnection.createDataChannel(
      'fileTransfer',
      RTCDataChannelInit()..ordered = true,
    );

    _setupDataChannelHandlers(connectionId, dataChannel);
    return dataChannel;
  }

  /// Настраивает обработчики событий DataChannel
  void _setupDataChannelHandlers(
    String connectionId,
    RTCDataChannel dataChannel,
  ) {
    dataChannel.stateChangeStream.listen((RTCDataChannelState state) {
      logDebug(
        'DataChannel состояние изменено',
        tag: _logTag,
        data: {'connectionId': connectionId, 'state': state.name},
      );

      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _updateConnectionState(connectionId, WebRTCConnectionState.connected);
      }
    });

    dataChannel.messageStream.listen((RTCDataChannelMessage message) {
      _handleDataChannelMessage(connectionId, message);
    });
  }

  /// Создает и устанавливает offer
  Future<void> _createAndSetOffer(
    String connectionId,
    String remoteIp,
    int remotePort,
  ) async {
    final peerConnection = _peerConnections[connectionId];
    final connection = _connections[connectionId];

    if (peerConnection == null || connection == null) return;

    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    final offerMessage = _signalingService.createOfferMessage(
      fromDeviceId: connection.localDeviceId,
      toDeviceId: connection.remoteDeviceId,
      sdpOffer: {
        'sdp': offer.sdp,
        'type': offer.type,
        // Добавляем информацию о соединении
        'connectionInfo': {
          'ip': await _getLocalIpAddress(),
          'port': _signalingPort ?? 53317,
        },
      },
    );

    await _signalingService.sendMessage(
      connection.remoteDeviceId,
      remoteIp,
      remotePort,
      offerMessage,
    );

    _updateConnectionState(connectionId, WebRTCConnectionState.connecting);
  }

  /// Обрабатывает сообщения DataChannel
  void _handleDataChannelMessage(
    String connectionId,
    RTCDataChannelMessage message,
  ) {
    try {
      final data = json.decode(message.text);
      final type = data['type'] as String;

      switch (type) {
        case 'message':
          final messageData = LocalSendMessage.fromJson(data['data']);
          _messageController.add(messageData);
          break;

        case 'fileMetadata':
          _handleFileMetadata(connectionId, data['data']);
          break;

        case 'fileChunk':
          _handleFileChunk(data['data']);
          break;

        case 'transferComplete':
          _handleTransferComplete(data['data']);
          break;

        case 'transferCancel':
          _handleTransferCancel(data['data']);
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
        data: {'connectionId': connectionId},
      );
    }
  }

  /// Обрабатывает метаданные файла
  void _handleFileMetadata(String connectionId, Map<String, dynamic> data) {
    try {
      final transfer = FileTransfer.fromJson(data);
      _activeTransfers[transfer.id] = transfer;
      _fileTransferController.add(transfer);

      logInfo(
        'Получены метаданные файла',
        tag: _logTag,
        data: {
          'transferId': transfer.id,
          'fileName': transfer.fileName,
          'fileSize': transfer.fileSize,
        },
      );
    } catch (e) {
      logError('Ошибка обработки метаданных файла', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает чанк файла
  void _handleFileChunk(Map<String, dynamic> data) {
    try {
      final chunk = FileChunk.fromJson(data);
      final transfer = _activeTransfers[chunk.transferId];

      if (transfer == null ||
          transfer.status != FileTransferStatus.inProgress) {
        logWarning(
          'Получен чанк для неактивной передачи: ${chunk.transferId}',
          tag: _logTag,
        );
        return;
      }

      _writeFileChunk(transfer, chunk);
    } catch (e) {
      logError('Ошибка обработки чанка файла', error: e, tag: _logTag);
    }
  }

  /// Записывает чанк файла на диск
  Future<void> _writeFileChunk(FileTransfer transfer, FileChunk chunk) async {
    try {
      if (transfer.filePath == null) {
        logError(
          'Путь к файлу не установлен для передачи: ${transfer.id}',
          tag: _logTag,
        );
        return;
      }

      final file = File(transfer.filePath!);
      final randomAccessFile = await file.open(mode: FileMode.writeOnlyAppend);

      await randomAccessFile.writeFrom(chunk.data);
      await randomAccessFile.close();

      final newTransferredBytes = transfer.transferredBytes + chunk.size;
      final updatedTransfer = transfer.copyWith(
        transferredBytes: newTransferredBytes,
      );

      _activeTransfers[transfer.id] = updatedTransfer;
      _fileTransferController.add(updatedTransfer);

      // Проверяем, завершена ли передача
      if (newTransferredBytes >= transfer.fileSize) {
        await _completeFileTransfer(transfer.id);
      }
    } catch (e) {
      logError('Ошибка записи чанка файла', error: e, tag: _logTag);
      await _failFileTransfer(transfer.id, 'Ошибка записи файла: $e');
    }
  }

  /// Завершает передачу файла
  Future<void> _completeFileTransfer(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;

    final updatedTransfer = transfer.copyWith(
      status: FileTransferStatus.completed,
      endTime: DateTime.now(),
    );

    _activeTransfers[transferId] = updatedTransfer;
    _fileTransferController.add(updatedTransfer);

    // Останавливаем таймер
    _transferTimers[transferId]?.cancel();
    _transferTimers.remove(transferId);

    logInfo(
      'Передача файла завершена',
      tag: _logTag,
      data: {'transferId': transferId, 'fileName': transfer.fileName},
    );
  }

  /// Помечает передачу файла как неудачную
  Future<void> _failFileTransfer(String transferId, String error) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;

    final updatedTransfer = transfer.copyWith(
      status: FileTransferStatus.failed,
      endTime: DateTime.now(),
      errorMessage: error,
    );

    _activeTransfers[transferId] = updatedTransfer;
    _fileTransferController.add(updatedTransfer);

    _transferTimers[transferId]?.cancel();
    _transferTimers.remove(transferId);

    logError(
      'Передача файла неудачна',
      tag: _logTag,
      data: {'transferId': transferId},
    );
  }

  /// Обрабатывает завершение передачи
  void _handleTransferComplete(Map<String, dynamic> data) {
    final transferId = data['transferId'] as String;
    _completeFileTransfer(transferId);
  }

  /// Обрабатывает отмену передачи
  void _handleTransferCancel(Map<String, dynamic> data) {
    final transferId = data['transferId'] as String;
    cancelFileTransfer(transferId);
  }

  /// Отправляет метаданные файла
  Future<void> _sendFileMetadata(
    String connectionId,
    FileTransfer transfer,
  ) async {
    final dataChannel = _dataChannels[connectionId];
    if (dataChannel?.state != RTCDataChannelState.RTCDataChannelOpen) return;

    final metadata = {'type': 'fileMetadata', 'data': transfer.toJson()};

    final jsonData = json.encode(metadata);
    dataChannel!.send(RTCDataChannelMessage(jsonData));
  }

  /// Начинает отправку файла по чанкам
  Future<void> _startFileSending(
    String connectionId,
    FileTransfer transfer,
  ) async {
    try {
      final file = File(transfer.filePath!);
      final dataChannel = _dataChannels[connectionId];

      if (dataChannel?.state != RTCDataChannelState.RTCDataChannelOpen) {
        await _failFileTransfer(transfer.id, 'DataChannel недоступен');
        return;
      }

      final fileStream = file.openRead();
      final fileSize = await file.length();
      final totalChunks = (fileSize / _chunkSize).ceil();

      int chunkIndex = 0;
      int totalSent = 0;
      final startTime = DateTime.now();

      await for (final chunk in fileStream) {
        if (_activeTransfers[transfer.id]?.status !=
            FileTransferStatus.inProgress) {
          break; // Передача была отменена
        }

        final chunkData = chunk;
        final fileChunk = FileChunk(
          transferId: transfer.id,
          chunkIndex: chunkIndex,
          totalChunks: totalChunks,
          data: Uint8List.fromList(chunkData),
          size: chunkData.length,
        );

        final chunkMessage = {'type': 'fileChunk', 'data': fileChunk.toJson()};

        dataChannel!.send(RTCDataChannelMessage(json.encode(chunkMessage)));

        totalSent += chunkData.length;
        chunkIndex++;

        // Обновляем прогресс
        final elapsed = DateTime.now().difference(startTime);
        final speed = elapsed.inMilliseconds > 0
            ? (totalSent * 1000 / elapsed.inMilliseconds).toDouble()
            : 0.0;

        final updatedTransfer = transfer.copyWith(
          transferredBytes: totalSent,
          transferSpeed: speed,
        );

        _activeTransfers[transfer.id] = updatedTransfer;
        _fileTransferController.add(updatedTransfer);

        // Небольшая пауза между чанками для предотвращения перегрузки
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Отправляем сообщение о завершении
      final completeMessage = {
        'type': 'transferComplete',
        'data': {'transferId': transfer.id},
      };

      dataChannel!.send(RTCDataChannelMessage(json.encode(completeMessage)));

      await _completeFileTransfer(transfer.id);
    } catch (e) {
      await _failFileTransfer(transfer.id, 'Ошибка отправки файла: $e');
    }
  }

  /// Вычисляет хеш файла
  Future<String> _calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      logError('Ошибка вычисления хеша файла', error: e, tag: _logTag);
      return '';
    }
  }

  /// Обрабатывает сообщения сигналинга
  void _handleSignalingMessage(SignalingMessage message) {
    logInfo(
      'Получено сообщение сигналинга',
      tag: _logTag,
      data: {
        'type': message.type.name,
        'from': message.fromDeviceId,
        'to': message.toDeviceId,
      },
    );

    switch (message.type) {
      case SignalingMessageType.offer:
        _handleOfferMessage(message);
        break;
      case SignalingMessageType.answer:
        _handleAnswerMessage(message);
        break;
      case SignalingMessageType.iceCandidate:
        _handleIceCandidateMessage(message);
        break;
      default:
        logWarning(
          'Неизвестный тип сигналинг сообщения: ${message.type}',
          tag: _logTag,
        );
    }
  }

  /// Обрабатывает offer сообщение
  Future<void> _handleOfferMessage(SignalingMessage message) async {
    try {
      logInfo(
        'Получен WebRTC offer - автоматически принимаем',
        tag: _logTag,
        data: {'from': message.fromDeviceId},
      );

      // Извлекаем информацию о соединении из offer
      final connectionInfo =
          message.data['connectionInfo'] as Map<String, dynamic>?;
      final remoteIp = connectionInfo?['ip'] as String? ?? '127.0.0.1';
      final remotePort = connectionInfo?['port'] as int? ?? 53317;

      // Генерируем ID для локального устройства
      final localDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';

      // Автоматически принимаем соединение с исправленной структурой данных
      await acceptConnection(
        localDeviceId: localDeviceId,
        remoteDeviceId: message.fromDeviceId,
        remoteIp: remoteIp,
        remotePort: remotePort,
        offerData: {'sdp': message.data['sdp'], 'type': message.data['type']},
      );

      logInfo(
        'WebRTC offer автоматически принят',
        tag: _logTag,
        data: {
          'from': message.fromDeviceId,
          'localDeviceId': localDeviceId,
          'remoteIp': remoteIp,
          'remotePort': remotePort,
        },
      );
    } catch (e) {
      logError('Ошибка обработки offer сообщения', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает answer сообщение
  Future<void> _handleAnswerMessage(SignalingMessage message) async {
    try {
      final connectionId = _findConnectionIdByDeviceId(message.fromDeviceId);
      if (connectionId == null) {
        logWarning('Соединение не найдено для answer', tag: _logTag);
        return;
      }

      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        logWarning('PeerConnection не найден для answer', tag: _logTag);
        return;
      }

      final answerData = message.data;
      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );

      await peerConnection.setRemoteDescription(answer);

      logInfo(
        'WebRTC answer обработан',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );
    } catch (e) {
      logError('Ошибка обработки answer сообщения', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает ICE candidate сообщение
  Future<void> _handleIceCandidateMessage(SignalingMessage message) async {
    try {
      final connectionId = _findConnectionIdByDeviceId(message.fromDeviceId);
      if (connectionId == null) {
        logWarning('Соединение не найдено для ICE candidate', tag: _logTag);
        return;
      }

      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        logWarning('PeerConnection не найден для ICE candidate', tag: _logTag);
        return;
      }

      final candidateData = message.data;
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await peerConnection.addCandidate(candidate);

      logDebug(
        'ICE candidate добавлен',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );
    } catch (e) {
      logError(
        'Ошибка обработки ICE candidate сообщения',
        error: e,
        tag: _logTag,
      );
    }
  }

  /// Находит connectionId по deviceId
  String? _findConnectionIdByDeviceId(String deviceId) {
    for (final entry in _connections.entries) {
      if (entry.value.remoteDeviceId == deviceId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Обрабатывает изменения состояния PeerConnection
  void _onPeerConnectionStateChange(
    String connectionId,
    RTCPeerConnectionState state,
  ) {
    WebRTCConnectionState connectionState;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        connectionState = WebRTCConnectionState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        connectionState = WebRTCConnectionState.connecting;
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
      default:
        connectionState = WebRTCConnectionState.connecting;
    }

    _updateConnectionState(connectionId, connectionState);
  }

  /// Обрабатывает новые ICE кандидаты
  void _onIceCandidate(String connectionId, RTCIceCandidate candidate) {
    final connection = _connections[connectionId];
    if (connection == null) {
      logWarning('Соединение не найдено для ICE candidate', tag: _logTag);
      return;
    }

    logDebug(
      'Сгенерирован ICE candidate',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'candidate': candidate.candidate?.substring(0, 50),
      },
    );

    final event = IceCandidateEvent.fromRTCIceCandidate(
      deviceId: connection.localDeviceId,
      candidate: candidate,
    );

    _iceCandidateController.add(event);
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
      errorMessage: errorMessage,
    );

    _connections[connectionId] = updatedConnection;
    _connectionStateController.add(updatedConnection);

    logDebug(
      'Состояние соединения обновлено',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'state': state.name,
        'error': errorMessage,
      },
    );
  }

  /// Получает локальный IP адрес
  Future<String> _getLocalIpAddress() async {
    try {
      // Пытаемся найти IP адрес сетевого интерфейса
      for (final interface in await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      )) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            return address.address;
          }
        }
      }

      // Если не нашли, возвращаем localhost
      return '127.0.0.1';
    } catch (e) {
      logError('Ошибка получения локального IP', error: e, tag: _logTag);
      return '127.0.0.1';
    }
  }
}
