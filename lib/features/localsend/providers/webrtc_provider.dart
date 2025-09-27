import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/connection.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';
import 'package:hoplixi/features/localsend/models/message.dart';
import 'package:hoplixi/features/localsend/services/webrtc_service.dart';

const _logTag = 'WebRTCProvider';

/// Provider для WebRTC сервиса
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider для управления WebRTC соединениями
final webrtcConnectionProvider =
    AsyncNotifierProvider.autoDispose<
      WebRTCConnectionNotifier,
      List<WebRTCConnection>
    >(WebRTCConnectionNotifier.new);

/// Provider для активных передач файлов
final fileTransferProvider =
    AsyncNotifierProvider.autoDispose<FileTransferNotifier, List<FileTransfer>>(
      FileTransferNotifier.new,
    );

/// Provider для текущего активного соединения
final currentConnectionProvider =
    NotifierProvider.autoDispose<CurrentConnectionNotifier, WebRTCConnection?>(
      CurrentConnectionNotifier.new,
    );

/// Notifier для текущего соединения
class CurrentConnectionNotifier extends Notifier<WebRTCConnection?> {
  @override
  WebRTCConnection? build() {
    return null;
  }

  /// Устанавливает текущее активное соединение
  void setConnection(WebRTCConnection? connection) {
    if (connection != state) {
      logInfo(
        'Текущее соединение изменено',
        tag: _logTag,
        data: {
          'oldConnectionId': state?.connectionId,
          'newConnectionId': connection?.connectionId,
          'newState': connection?.state.name,
        },
      );

      state = connection;
    }
  }

  /// Сбрасывает текущее соединение
  void clearConnection() {
    if (state != null) {
      logInfo(
        'Текущее соединение сброшено',
        tag: _logTag,
        data: {'connectionId': state!.connectionId},
      );

      state = null;
    }
  }

  /// Проверяет, является ли соединение текущим активным
  bool isCurrentConnection(String connectionId) {
    return state?.connectionId == connectionId;
  }

  /// Получает ID текущего соединения
  String? get currentConnectionId => state?.connectionId;

  /// Проверяет, есть ли активное соединение
  bool get hasActiveConnection => state != null;

  /// Проверяет, подключено ли текущее соединение
  bool get isConnected => state?.state == WebRTCConnectionState.connected;

  /// Получает информацию об удаленном устройстве текущего соединения
  String? get currentRemoteDeviceId => state?.remoteDeviceId;
}

/// Notifier для управления WebRTC соединениями
class WebRTCConnectionNotifier extends AsyncNotifier<List<WebRTCConnection>> {
  late WebRTCService _webrtcService;
  StreamSubscription<WebRTCConnection>? _connectionSubscription;
  StreamSubscription<LocalSendMessage>? _messageSubscription;

  @override
  Future<List<WebRTCConnection>> build() async {
    _webrtcService = ref.read(webrtcServiceProvider);

    // Инициализируем сервис
    await _webrtcService.initialize();

    // Подписываемся на изменения соединений
    _connectionSubscription = _webrtcService.connectionStates.listen(
      _onConnectionStateChanged,
    );

    // Подписываемся на входящие сообщения
    _messageSubscription = _webrtcService.incomingMessages.listen(
      _onMessageReceived,
    );

    ref.onDispose(() {
      _connectionSubscription?.cancel();
      _messageSubscription?.cancel();
    });

    return _webrtcService.activeConnections;
  }

  /// Создает новое соединение с устройством
  Future<String?> connectToDevice({
    required String localDeviceId,
    required DeviceInfo targetDevice,
  }) async {
    try {
      logInfo(
        'Попытка подключения к устройству',
        tag: _logTag,
        data: {
          'targetDevice': targetDevice.name,
          'targetId': targetDevice.id,
          'targetIp': targetDevice.ipAddress,
        },
      );

      // Запускаем сигналинг сервер если он еще не запущен
      final signalingPort = await _webrtcService.startSignalingServer();
      logInfo('Сигналинг сервер запущен на порту $signalingPort', tag: _logTag);

      final connectionId = await _webrtcService.createConnection(
        localDeviceId: localDeviceId,
        remoteDeviceId: targetDevice.id,
        remoteIp: targetDevice.ipAddress,
        remotePort: targetDevice.port,
      );

      logInfo(
        'Соединение создано',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      return connectionId;
    } catch (e) {
      logError('Ошибка подключения к устройству', error: e, tag: _logTag);
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Принимает входящее соединение
  Future<String?> acceptConnection({
    required String localDeviceId,
    required String remoteDeviceId,
    required String remoteIp,
    required int remotePort,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      logInfo(
        'Принятие входящего соединения',
        tag: _logTag,
        data: {
          'remoteDeviceId': remoteDeviceId,
          'remoteIp': remoteIp,
          'remotePort': remotePort,
        },
      );

      final connectionId = await _webrtcService.acceptConnection(
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        remoteIp: remoteIp,
        remotePort: remotePort,
        offerData: offerData,
      );

      logInfo(
        'Входящее соединение принято',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );

      return connectionId;
    } catch (e) {
      logError('Ошибка принятия соединения', error: e, tag: _logTag);
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Отправляет сообщение через указанное соединение
  Future<bool> sendMessage({
    required String connectionId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final connection = _webrtcService.getConnection(connectionId);
      if (connection == null) {
        logError('Соединение не найдено для отправки сообщения', tag: _logTag);
        return false;
      }

      final message = LocalSendMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        content: content,
        senderId: connection.localDeviceId,
        receiverId: connection.remoteDeviceId,
        timestamp: DateTime.now(),
      );

      final success = await _webrtcService.sendMessage(connectionId, message);

      if (success) {
        logInfo(
          'Сообщение отправлено',
          tag: _logTag,
          data: {'type': type.name},
        );
      } else {
        logError('Не удалось отправить сообщение', tag: _logTag);
      }

      return success;
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      return false;
    }
  }

  /// Закрывает соединение
  Future<void> closeConnection(String connectionId) async {
    try {
      await _webrtcService.closeConnection(connectionId);

      // Обновляем текущее соединение если оно было закрыто
      final currentConnection = ref.read(currentConnectionProvider);
      if (currentConnection?.connectionId == connectionId) {
        ref.read(currentConnectionProvider.notifier).clearConnection();
      }

      logInfo(
        'Соединение закрыто',
        tag: _logTag,
        data: {'connectionId': connectionId},
      );
    } catch (e) {
      logError('Ошибка закрытия соединения', error: e, tag: _logTag);
    }
  }

  /// Закрывает все активные соединения
  Future<void> closeAllConnections() async {
    try {
      final connections = _webrtcService.activeConnections;
      for (final connection in connections) {
        await closeConnection(connection.connectionId);
      }

      ref.read(currentConnectionProvider.notifier).clearConnection();
      await _webrtcService.stopSignalingServer();

      logInfo('Все соединения закрыты', tag: _logTag);
    } catch (e) {
      logError('Ошибка закрытия всех соединений', error: e, tag: _logTag);
    }
  }

  /// Получает информацию о соединении
  WebRTCConnection? getConnection(String connectionId) {
    return _webrtcService.getConnection(connectionId);
  }

  /// Устанавливает текущее активное соединение
  void setCurrentConnection(WebRTCConnection? connection) {
    ref.read(currentConnectionProvider.notifier).setConnection(connection);
  }

  /// Обрабатывает изменения состояния соединений
  void _onConnectionStateChanged(WebRTCConnection connection) {
    logInfo(
      'Состояние соединения изменилось',
      tag: _logTag,
      data: {
        'connectionId': connection.connectionId,
        'state': connection.state.name,
        'remoteDevice': connection.remoteDeviceId,
      },
    );

    // Обновляем состояние
    final currentConnections = _webrtcService.activeConnections;
    state = AsyncData(currentConnections);

    // Если соединение установлено, устанавливаем его как текущее
    if (connection.state == WebRTCConnectionState.connected) {
      setCurrentConnection(connection);
    }

    // Если соединение разорвано, убираем его из текущего
    if (connection.state == WebRTCConnectionState.disconnected ||
        connection.state == WebRTCConnectionState.failed) {
      final currentConnection = ref.read(currentConnectionProvider);
      if (currentConnection?.connectionId == connection.connectionId) {
        setCurrentConnection(null);
      }
    }
  }

  /// Обрабатывает входящие сообщения
  void _onMessageReceived(LocalSendMessage message) {
    logInfo(
      'Получено сообщение',
      tag: _logTag,
      data: {
        'type': message.type.name,
        'senderId': message.senderId,
        'content': message.content.length > 50
            ? '${message.content.substring(0, 50)}...'
            : message.content,
      },
    );

    // Здесь можно добавить дополнительную обработку сообщений
    // Например, показать уведомление пользователю
  }
}

/// Notifier для управления передачами файлов
class FileTransferNotifier extends AsyncNotifier<List<FileTransfer>> {
  late WebRTCService _webrtcService;
  StreamSubscription<FileTransfer>? _transferSubscription;

  @override
  Future<List<FileTransfer>> build() async {
    _webrtcService = ref.read(webrtcServiceProvider);

    // Подписываемся на обновления передач файлов
    _transferSubscription = _webrtcService.fileTransferUpdates.listen(
      _onFileTransferUpdate,
    );

    ref.onDispose(() {
      _transferSubscription?.cancel();
    });

    return _webrtcService.activeFileTransfers;
  }

  /// Начинает отправку файла
  Future<String?> sendFile({
    required String connectionId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      logInfo(
        'Начало отправки файла',
        tag: _logTag,
        data: {
          'fileName': fileName,
          'filePath': filePath,
          'connectionId': connectionId,
        },
      );

      final transferId = await _webrtcService.sendFile(
        connectionId: connectionId,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
      );

      if (transferId != null) {
        logInfo(
          'Передача файла начата',
          tag: _logTag,
          data: {'transferId': transferId},
        );
      } else {
        logError('Не удалось начать передачу файла', tag: _logTag);
      }

      return transferId;
    } catch (e) {
      logError('Ошибка отправки файла', error: e, tag: _logTag);
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Принимает входящий файл
  Future<bool> acceptFile(String transferId, String savePath) async {
    try {
      final success = await _webrtcService.acceptFileTransfer(
        transferId,
        savePath,
      );

      if (success) {
        logInfo('Файл принят', tag: _logTag, data: {'transferId': transferId});
      } else {
        logError('Не удалось принять файл', tag: _logTag);
      }

      return success;
    } catch (e) {
      logError('Ошибка принятия файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Отклоняет передачу файла
  Future<bool> rejectFile(String transferId) async {
    try {
      final success = await _webrtcService.rejectFileTransfer(transferId);

      if (success) {
        logInfo(
          'Файл отклонен',
          tag: _logTag,
          data: {'transferId': transferId},
        );
      } else {
        logError('Не удалось отклонить файл', tag: _logTag);
      }

      return success;
    } catch (e) {
      logError('Ошибка отклонения файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Отменяет передачу файла
  Future<bool> cancelTransfer(String transferId) async {
    try {
      final success = await _webrtcService.cancelFileTransfer(transferId);

      if (success) {
        logInfo(
          'Передача файла отменена',
          tag: _logTag,
          data: {'transferId': transferId},
        );
      } else {
        logError('Не удалось отменить передачу файла', tag: _logTag);
      }

      return success;
    } catch (e) {
      logError('Ошибка отмены передачи файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Получает передачу файла по ID
  FileTransfer? getTransfer(String transferId) {
    return state.value?.firstWhere(
      (transfer) => transfer.id == transferId,
      orElse: () => throw StateError('Transfer not found'),
    );
  }

  /// Обрабатывает обновления передач файлов
  void _onFileTransferUpdate(FileTransfer transfer) {
    logDebug(
      'Обновление передачи файла',
      tag: _logTag,
      data: {
        'transferId': transfer.id,
        'fileName': transfer.fileName,
        'status': transfer.status.name,
        'progress': '${transfer.progressPercent}%',
      },
    );

    // Обновляем состояние
    final currentTransfers = _webrtcService.activeFileTransfers;
    state = AsyncData(currentTransfers);
  }
}
