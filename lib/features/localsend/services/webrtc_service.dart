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
import 'package:hoplixi/features/localsend/utils/ip_utils.dart';
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

  /// Кэш реальных IP адресов устройств (deviceId -> realIp)
  final Map<String, String> _realDeviceIps = {};

  /// Кэш обработанных сообщений для предотвращения дубликатов
  final Set<String> _processedMessageIds = {};
  Timer? _cacheCleanupTimer;

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

    // Подписываемся на информацию о реальных IP адресах
    _signalingService.remoteIpInfo.listen(_handleRemoteIpInfo);

    // Запускаем периодическую очистку кэша обработанных сообщений (каждые 30 минут)
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _cleanupMessageCache(),
    );

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

      // IP уже должен быть резолвлен в DiscoveryProvider, но проверим на всякий случай
      final resolvedIp = await _resolveHostname(remoteIp);

      logInfo(
        'Создание WebRTC соединения',
        tag: '${_logTag}_createConnections',
        data: {
          'connectionId': connectionId,
          'localDeviceId': localDeviceId,
          'remoteDeviceId': remoteDeviceId,
          'remoteIp': remoteIp,
          'resolvedIp': resolvedIp,
          'remotePort': remotePort,
        },
      );

      final connection = WebRTCConnection(
        connectionId: connectionId,
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        remoteIp: resolvedIp,
        remotePort: remotePort,
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

      // Создаем и отправляем offer на резолвленый IP
      await _createAndSetOffer(connectionId, resolvedIp, remotePort);

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

      // Резолвим .local адрес в IP
      final resolvedIp = await _resolveHostname(remoteIp);

      logInfo(
        'Принятие WebRTC соединения',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'localDeviceId': localDeviceId,
          'remoteDeviceId': remoteDeviceId,
          'remoteIp': remoteIp,
          'resolvedIp': resolvedIp,
        },
      );

      final connection = WebRTCConnection(
        connectionId: connectionId,
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        remoteIp: resolvedIp,
        remotePort: remotePort,
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

      try {
        await peerConnection.setRemoteDescription(offer);
      } catch (setRemoteError) {
        final currentState = await peerConnection.getSignalingState();
        final errorString = setRemoteError.toString();

        logError(
          'Ошибка установки remote description для offer',
          error: setRemoteError,
          tag: _logTag,
          data: {
            'connectionId': connectionId,
            'currentState': currentState?.name ?? 'unknown',
            'errorString': errorString,
          },
        );

        rethrow; // Перебрасываем, так как это критическая ошибка для offer
      }

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      // Отправляем answer на резолвленый IP
      final answerMessage = _signalingService.createAnswerMessage(
        fromDeviceId: localDeviceId,
        toDeviceId: remoteDeviceId,
        sdpAnswer: {'sdp': answer.sdp, 'type': answer.type},
      );

      await _signalingService.sendMessage(
        remoteDeviceId,
        resolvedIp,
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

    // Останавливаем таймер очистки кэша
    _cacheCleanupTimer?.cancel();

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

  /// Очищает кэш обработанных сообщений, оставляя только последние элементы
  void _cleanupMessageCache() {
    const maxCacheSize = 1000; // Максимальный размер кэша

    if (_processedMessageIds.length > maxCacheSize) {
      // Преобразуем в список и оставляем только последние элементы
      // Поскольку Set не поддерживает порядок, очищаем весь кэш
      final removedCount = _processedMessageIds.length;
      _processedMessageIds.clear();

      logInfo(
        'Очистка кэша обработанных сообщений',
        tag: _logTag,
        data: {
          'removedMessages': removedCount,
          'reason': 'превышен максимальный размер кэша',
        },
      );
    }
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

    peerConnection.onSignalingState = (RTCSignalingState state) {
      _onSignalingStateChange(connectionId, state);
    };

    peerConnection.onIceGatheringState = (RTCIceGatheringState state) {
      _onIceGatheringStateChange(connectionId, state);
    };

    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      _onIceConnectionStateChange(connectionId, state);
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
      logInfo(
        'DataChannel состояние изменено',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'dataChannelState': state.name,
          'label': dataChannel.label,
        },
      );

      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          logInfo(
            'DataChannel открыт - готов к передаче данных!',
            tag: _logTag,
            data: {'connectionId': connectionId},
          );
          _updateConnectionState(connectionId, WebRTCConnectionState.connected);
          break;
        case RTCDataChannelState.RTCDataChannelClosed:
          logWarning(
            'DataChannel закрыт',
            tag: _logTag,
            data: {'connectionId': connectionId},
          );
          break;
        case RTCDataChannelState.RTCDataChannelClosing:
          logInfo(
            'DataChannel закрывается',
            tag: _logTag,
            data: {'connectionId': connectionId},
          );
          break;
        default:
          logDebug(
            'DataChannel состояние: ${state.name}',
            tag: _logTag,
            data: {'connectionId': connectionId},
          );
      }
    });

    dataChannel.messageStream.listen((RTCDataChannelMessage message) {
      _handleDataChannelMessage(connectionId, message);
    });
  }

  /// Диагностика состояния соединения
  Future<void> _debugConnectionState(String connectionId) async {
    final connection = _connections[connectionId];
    final peerConnection = _peerConnections[connectionId];
    final dataChannel = _dataChannels[connectionId];

    if (connection == null) {
      logError('Connection не найден', tag: _logTag);
      return;
    }

    final signalingState = peerConnection != null
        ? await peerConnection.getSignalingState()
        : null;
    final iceConnectionState = peerConnection != null
        ? await peerConnection.getIceConnectionState()
        : null;
    final iceGatheringState = peerConnection != null
        ? await peerConnection.getIceGatheringState()
        : null;

    logInfo(
      'Полная диагностика соединения',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'ourState': connection.state.name,
        'signalingState': signalingState?.name ?? 'null',
        'iceConnectionState': iceConnectionState?.name ?? 'null',
        'iceGatheringState': iceGatheringState?.name ?? 'null',
        'hasPeerConnection': peerConnection != null,
        'hasDataChannel': dataChannel != null,
        'dataChannelState': dataChannel?.state?.name ?? 'null',
        'dataChannelLabel': dataChannel?.label ?? 'null',
      },
    );
  }

  /// Создает и устанавливает offer
  Future<void> _createAndSetOffer(
    String connectionId,
    String remoteIp,
    int remotePort,
  ) async {
    final peerConnection = _peerConnections[connectionId];
    final connection = _connections[connectionId];

    if (peerConnection == null || connection == null) {
      logError(
        'PeerConnection или connection не найдены для offer',
        tag: _logTag,
      );
      return;
    }

    logInfo(
      'Создание WebRTC offer',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'remoteIp': remoteIp,
        'remotePort': remotePort,
      },
    );

    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    logDebug(
      'Offer создан и установлен локально',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'sdpType': offer.type,
        'sdpLength': offer.sdp?.length ?? 0,
      },
    );

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

    logInfo(
      'Отправка offer через signaling',
      tag: _logTag,
      data: {
        'connectionId': connectionId,
        'to': connection.remoteDeviceId,
        'targetIp': remoteIp,
        'targetPort': remotePort,
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

  /// Обрабатывает информацию о реальных IP адресах устройств
  void _handleRemoteIpInfo(Map<String, String> ipInfo) {
    final deviceId = ipInfo['deviceId'];
    final realIp = ipInfo['realIp'];
    final messageType = ipInfo['messageType'];

    if (deviceId != null && realIp != null) {
      _realDeviceIps[deviceId] = realIp;

      logInfo(
        'Получена информация о реальном IP устройства',
        tag: _logTag,
        data: {
          'deviceId': deviceId,
          'realIp': realIp,
          'messageType': messageType,
        },
      );
    }
  }

  /// Обрабатывает offer сообщение
  Future<void> _handleOfferMessage(SignalingMessage message) async {
    try {
      // Проверяем, не обрабатывали ли мы уже это сообщение
      if (_processedMessageIds.contains(message.messageId)) {
        logInfo(
          'Offer уже был обработан ранее - игнорируем дубликат',
          tag: _logTag,
          data: {
            'messageId': message.messageId,
            'fromDevice': message.fromDeviceId,
          },
        );
        return;
      }

      logInfo(
        'Получен WebRTC offer - автоматически принимаем',
        tag: _logTag,
        data: {'from': message.fromDeviceId, 'messageId': message.messageId},
      );

      // Проверяем, нет ли уже соединения с этим устройством
      final existingConnectionId = _findConnectionIdByDeviceId(
        message.fromDeviceId,
      );
      if (existingConnectionId != null) {
        final existingConnection = _connections[existingConnectionId];
        logInfo(
          'Уже есть соединение с этим устройством',
          tag: _logTag,
          data: {
            'existingConnectionId': existingConnectionId,
            'existingState': existingConnection?.state.name,
            'fromDevice': message.fromDeviceId,
            'messageId': message.messageId,
          },
        );

        // Если соединение уже подключено или подключается, игнорируем offer
        if (existingConnection?.state == WebRTCConnectionState.connected ||
            existingConnection?.state == WebRTCConnectionState.connecting) {
          logInfo(
            'Игнорируем дублирующий offer - соединение уже активно',
            tag: _logTag,
            data: {'messageId': message.messageId},
          );
          _processedMessageIds.add(message.messageId);
          return;
        }
      }

      // Извлекаем информацию о соединении из offer
      final connectionInfo =
          message.data['connectionInfo'] as Map<String, dynamic>?;

      // ВАЖНО: Используем реальный IP инициатора из HTTP request context
      // вместо того что он сам сообщил (может быть недоступен)
      final offeredIp = connectionInfo?['ip'] as String?;
      final remotePort = connectionInfo?['port'] as int? ?? 53317;

      // Получаем реальный IP из кэша или используем предложенный
      final realRemoteIp =
          _realDeviceIps[message.fromDeviceId] ?? offeredIp ?? '127.0.0.1';

      logInfo(
        'IP адреса для обратной связи',
        tag: _logTag,
        data: {
          'offeredIp': offeredIp,
          'cachedRealIp': _realDeviceIps[message.fromDeviceId],
          'willUse': realRemoteIp,
          'port': remotePort,
          'messageId': message.messageId,
        },
      );

      final remoteIp = realRemoteIp;

      // Получаем ожидаемый ID локального устройства из сообщения (если указан)
      // В offer поле toDeviceId должно содержать ID принимающего устройства,
      // используем его для корректного сопоставления ответов (answer) у инициатора.
      final localDeviceId = message.toDeviceId.isNotEmpty
          ? message.toDeviceId
          : 'device_${DateTime.now().millisecondsSinceEpoch}';

      // Автоматически принимаем соединение с корректным localDeviceId
      await acceptConnection(
        localDeviceId: localDeviceId,
        remoteDeviceId: message.fromDeviceId,
        remoteIp: remoteIp,
        remotePort: remotePort,
        offerData: {'sdp': message.data['sdp'], 'type': message.data['type']},
      );

      // Помечаем сообщение как успешно обработанное
      _processedMessageIds.add(message.messageId);

      logInfo(
        'WebRTC offer автоматически принят',
        tag: _logTag,
        data: {
          'from': message.fromDeviceId,
          'localDeviceId': localDeviceId,
          'remoteIp': remoteIp,
          'remotePort': remotePort,
          'messageId': message.messageId,
        },
      );
    } catch (e) {
      // Помечаем как обработанный даже при ошибке, чтобы не повторять
      _processedMessageIds.add(message.messageId);

      logError(
        'Ошибка обработки offer сообщения',
        error: e,
        tag: _logTag,
        data: {
          'messageId': message.messageId,
          'fromDevice': message.fromDeviceId,
        },
      );
    }
  }

  /// Обрабатывает answer сообщение
  Future<void> _handleAnswerMessage(SignalingMessage message) async {
    try {
      // Проверяем, не обрабатывали ли мы уже это сообщение
      if (_processedMessageIds.contains(message.messageId)) {
        logInfo(
          'Answer уже был обработан ранее - игнорируем дубликат',
          tag: _logTag,
          data: {
            'messageId': message.messageId,
            'fromDevice': message.fromDeviceId,
          },
        );
        return;
      }

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

      // Проверяем состояние PeerConnection перед установкой remote description
      final signalingState = await peerConnection.getSignalingState();

      logInfo(
        'Получен answer, проверка состояния PeerConnection',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'signalingState': signalingState?.name ?? 'unknown',
          'fromDevice': message.fromDeviceId,
          'messageId': message.messageId,
        },
      );

      // Answer можно устанавливать только в состоянии 'have-local-offer'
      if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        logWarning(
          'Неправильное состояние PeerConnection для answer',
          tag: _logTag,
          data: {
            'expectedState': 'have-local-offer',
            'currentState': signalingState?.name ?? 'unknown',
            'connectionId': connectionId,
            'messageId': message.messageId,
          },
        );

        // Если уже в stable - возможно, answer уже был обработан
        if (signalingState == RTCSignalingState.RTCSignalingStateStable) {
          logInfo(
            'PeerConnection уже в stable состоянии - answer уже обработан',
            tag: _logTag,
            data: {'messageId': message.messageId},
          );
          // Помечаем как обработанный, чтобы не пытаться снова
          _processedMessageIds.add(message.messageId);
          return;
        }

        // Для других состояний тоже возвращаемся без ошибки
        _processedMessageIds.add(message.messageId);
        return;
      }

      final answerData = message.data;
      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );

      logDebug(
        'Установка remote description для answer',
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'messageId': message.messageId,
          'sdpType': answer.type,
        },
      );

      // Используем try-catch для безопасной установки remote description
      // Если PeerConnection уже в stable, значит answer уже был обработан
      try {
        await peerConnection.setRemoteDescription(answer);

        // Помечаем сообщение как успешно обработанное
        _processedMessageIds.add(message.messageId);

        final stateAfterSet = await peerConnection.getSignalingState();

        logInfo(
          'WebRTC answer успешно обработан',
          tag: _logTag,
          data: {
            'connectionId': connectionId,
            'newState': stateAfterSet?.name ?? 'unknown',
            'messageId': message.messageId,
          },
        );
      } catch (setRemoteError) {
        // Проверяем, не является ли ошибка результатом того, что соединение уже в stable
        final currentState = await peerConnection.getSignalingState();
        final errorString = setRemoteError.toString();

        // Специальная обработка для ошибки "Called in wrong state: stable"
        if (currentState == RTCSignalingState.RTCSignalingStateStable ||
            errorString.contains('Called in wrong state: stable')) {
          logInfo(
            'Answer не установлен - PeerConnection уже в stable состоянии (дубликат или race condition)',
            tag: _logTag,
            data: {
              'connectionId': connectionId,
              'messageId': message.messageId,
              'currentState': currentState?.name ?? 'unknown',
              'errorType': 'stable_state_duplicate',
            },
          );

          // Помечаем как обработанный, так как соединение уже установлено
          _processedMessageIds.add(message.messageId);
          return;
        }

        // Для других ошибок перебрасываем исключение
        logError(
          'Неожиданная ошибка при установке remote description',
          error: setRemoteError,
          tag: _logTag,
          data: {
            'connectionId': connectionId,
            'currentState': currentState?.name ?? 'unknown',
            'messageId': message.messageId,
            'errorString': errorString,
          },
        );

        // Перебрасываем ошибку для обработки во внешнем catch
        rethrow;
      }
    } catch (e) {
      // Помечаем как обработанный даже при ошибке, чтобы не повторять
      _processedMessageIds.add(message.messageId);

      // Дополнительная информация в логе ошибки
      final connectionId = _findConnectionIdByDeviceId(message.fromDeviceId);
      final peerConnection = _peerConnections[connectionId ?? ''];
      final currentState = peerConnection != null
          ? (await peerConnection.getSignalingState())?.name ?? 'unknown'
          : 'no-peer-connection';

      logError(
        'Ошибка обработки answer сообщения',
        error: e,
        tag: _logTag,
        data: {
          'connectionId': connectionId,
          'currentState': currentState,
          'messageId': message.messageId,
          'fromDevice': message.fromDeviceId,
        },
      );
    }
  }

  /// Обрабатывает ICE candidate сообщение
  Future<void> _handleIceCandidateMessage(SignalingMessage message) async {
    try {
      // Проверяем, не обрабатывали ли мы уже это сообщение
      if (_processedMessageIds.contains(message.messageId)) {
        logDebug(
          'ICE candidate уже был обработан ранее - игнорируем дубликат',
          tag: _logTag,
          data: {
            'messageId': message.messageId,
            'fromDevice': message.fromDeviceId,
          },
        );
        return;
      }

      final connectionId = _findConnectionIdByDeviceId(message.fromDeviceId);
      if (connectionId == null) {
        logWarning(
          'Соединение не найдено для ICE candidate',
          tag: _logTag,
          data: {
            'messageId': message.messageId,
            'fromDevice': message.fromDeviceId,
          },
        );
        _processedMessageIds.add(message.messageId);
        return;
      }

      final peerConnection = _peerConnections[connectionId];
      if (peerConnection == null) {
        logWarning(
          'PeerConnection не найден для ICE candidate',
          tag: _logTag,
          data: {'connectionId': connectionId, 'messageId': message.messageId},
        );
        _processedMessageIds.add(message.messageId);
        return;
      }

      final candidateData = message.data;
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await peerConnection.addCandidate(candidate);

      // Помечаем сообщение как успешно обработанное
      _processedMessageIds.add(message.messageId);

      logDebug(
        'ICE candidate добавлен',
        tag: _logTag,
        data: {'connectionId': connectionId, 'messageId': message.messageId},
      );
    } catch (e) {
      // Помечаем как обработанный даже при ошибке, чтобы не повторять
      _processedMessageIds.add(message.messageId);

      logError(
        'Ошибка обработки ICE candidate сообщения',
        error: e,
        tag: _logTag,
        data: {
          'messageId': message.messageId,
          'fromDevice': message.fromDeviceId,
        },
      );
    }
  }

  /// Находит connectionId по deviceId (ищет как в remoteDeviceId, так и в localDeviceId)
  String? _findConnectionIdByDeviceId(String deviceId) {
    for (final entry in _connections.entries) {
      // Проверяем как удаленное, так и локальное устройство
      if (entry.value.remoteDeviceId == deviceId ||
          entry.value.localDeviceId == deviceId) {
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
    logInfo(
      'Изменение состояния PeerConnection',
      tag: _logTag,
      data: {'connectionId': connectionId, 'rtcState': state.name},
    );

    WebRTCConnectionState connectionState;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        connectionState = WebRTCConnectionState.connected;
        logInfo('WebRTC соединение установлено!', tag: _logTag);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        connectionState = WebRTCConnectionState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        connectionState = WebRTCConnectionState.disconnected;
        logWarning('WebRTC соединение разорвано', tag: _logTag);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        connectionState = WebRTCConnectionState.failed;
        logError('WebRTC соединение не удалось', tag: _logTag);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        connectionState = WebRTCConnectionState.disconnected;
        logInfo('WebRTC соединение закрыто', tag: _logTag);
        break;
      default:
        connectionState = WebRTCConnectionState.connecting;
        logDebug('WebRTC состояние: ${state.name}', tag: _logTag);
    }

    _updateConnectionState(connectionId, connectionState);
  }

  /// Обрабатывает изменения состояния сигналинга
  void _onSignalingStateChange(String connectionId, RTCSignalingState state) {
    logInfo(
      'Изменение состояния сигналинга',
      tag: _logTag,
      data: {'connectionId': connectionId, 'signalingState': state.name},
    );
  }

  /// Обрабатывает изменения состояния ICE gathering
  void _onIceGatheringStateChange(
    String connectionId,
    RTCIceGatheringState state,
  ) {
    logInfo(
      'Изменение состояния ICE gathering',
      tag: _logTag,
      data: {'connectionId': connectionId, 'iceGatheringState': state.name},
    );

    // Особенно важно отследить завершение ICE gathering
    if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      logInfo(
        'ICE gathering завершен - все кандидаты собраны',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      // Выполняем диагностику через небольшую задержку
      Future.delayed(const Duration(seconds: 2), () {
        _debugConnectionState(connectionId);
      });
    }
  }

  /// Обрабатывает изменения состояния ICE соединения
  void _onIceConnectionStateChange(
    String connectionId,
    RTCIceConnectionState state,
  ) {
    logInfo(
      'Изменение состояния ICE соединения',
      tag: _logTag,
      data: {'connectionId': connectionId, 'iceConnectionState': state.name},
    );

    // Критические состояния ICE соединения
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        logInfo(
          'ICE соединение установлено - P2P канал активен!',
          tag: _logTag,
          data: {'connectionId': connectionId},
        );
        // Диагностика после установления ICE соединения
        Future.delayed(const Duration(seconds: 1), () {
          _debugConnectionState(connectionId);
        });
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        logError(
          'ICE соединение не удалось - проблемы с сетевой связностью',
          tag: _logTag,
          data: {'connectionId': connectionId},
        );
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        logWarning(
          'ICE соединение разорвано',
          tag: _logTag,
          data: {'connectionId': connectionId},
        );
        break;
      default:
        logDebug(
          'ICE состояние: ${state.name}',
          tag: _logTag,
          data: {'connectionId': connectionId},
        );
    }
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

    // Отправляем ICE candidate через signaling
    _sendIceCandidate(connection, candidate);
  }

  /// Отправляет ICE candidate через signaling
  Future<void> _sendIceCandidate(
    WebRTCConnection connection,
    RTCIceCandidate candidate,
  ) async {
    try {
      final iceCandidateMessage = _signalingService.createIceCandidateMessage(
        fromDeviceId: connection.localDeviceId,
        toDeviceId: connection.remoteDeviceId,
        iceCandidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );

      await _signalingService.sendMessage(
        connection.remoteDeviceId,
        connection.remoteIp,
        connection.remotePort,
        iceCandidateMessage,
      );

      logDebug(
        'ICE candidate отправлен',
        tag: _logTag,
        data: {
          'connectionId': connection.connectionId,
          'remoteIp': connection.remoteIp,
          'remotePort': connection.remotePort,
        },
      );
    } catch (e) {
      logError(
        'Ошибка отправки ICE candidate',
        error: e,
        tag: _logTag,
        data: {'connectionId': connection.connectionId},
      );
    }
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

  /// Резолвит .local адреса в обычные IP адреса
  Future<String> _resolveHostname(String hostname) async {
    try {
      logDebug('Резолюция адреса', tag: _logTag, data: {'hostname': hostname});

      // Если это уже IP адрес, возвращаем как есть
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(hostname)) {
        logDebug('Адрес уже является IP', tag: _logTag);
        return hostname;
      }

      // Если это .local адрес, пытаемся резолвить
      if (hostname.endsWith('.local')) {
        logDebug('Резолюция .local адреса', tag: _logTag);
        final addresses = await InternetAddress.lookup(
          hostname,
        ).timeout(const Duration(seconds: 3));

        // Отображаем все найденные адреса для диагностики
        logInfo(
          'DNS резолюция найдены адреса',
          tag: _logTag,
          data: {
            'hostname': hostname,
            'foundAddresses': addresses
                .map((a) => '${a.address} (${a.type})')
                .toList(),
            'addressCount': addresses.length,
          },
        );

        // Ищем первый подходящий IPv4 адрес из локальной сети
        for (final address in addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final ip = address.address;
            final isLocalNetwork = _isLocalNetworkIp(ip);

            logInfo(
              'Проверка IPv4 адреса',
              tag: _logTag,
              data: {
                'ip': ip,
                'isLocalNetwork': isLocalNetwork,
                'isPrivate': _isPrivateIpRange(ip),
                'isLoopback': ip.startsWith('127.'),
              },
            );

            // Используем только адреса, подходящие для локального соединения
            if (IpUtils.isValidForLocalConnection(ip)) {
              logInfo(
                'Успешно резолвлен .local адрес в локальный IP',
                tag: _logTag,
                data: {
                  'hostname': hostname,
                  'resolvedIp': ip,
                  'priority': IpUtils.getIpPriority(ip),
                },
              );
              return ip;
            }
          }
        }

        logWarning(
          'Не найден подходящий локальный IPv4 адрес для .local домена',
          tag: _logTag,
          data: {'hostname': hostname},
        );
      }

      // Если не удалось резолвить, возвращаем оригинал
      logWarning(
        'Не удалось резолвить адрес, используем оригинал',
        tag: _logTag,
        data: {'hostname': hostname},
      );
      return hostname;
    } catch (e) {
      logError(
        'Ошибка резолюции адреса',
        error: e,
        tag: _logTag,
        data: {'hostname': hostname},
      );
      return hostname; // Возвращаем оригинал при ошибке
    }
  }

  /// Проверяет, является ли IP адрес из локальной сети
  bool _isLocalNetworkIp(String ip) {
    return _isPrivateIpRange(ip) ||
        ip.startsWith('127.') || // loopback
        ip.startsWith('169.254.'); // link-local
  }

  /// Проверяет, находится ли IP в приватном диапазоне
  bool _isPrivateIpRange(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.contains(null)) return false;

    final a = parts[0]!;
    final b = parts[1]!;

    // 10.0.0.0/8
    if (a == 10) return true;

    // 172.16.0.0/12
    if (a == 172 && b >= 16 && b <= 31) return true;

    // 192.168.0.0/16
    if (a == 192 && b == 168) return true;

    return false;
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
