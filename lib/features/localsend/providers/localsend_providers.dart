import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/services/index.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// Провайдер для сервиса обнаружения устройств
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService();
});

/// Провайдер для сервиса сигналинга
final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SignalingService();
});

/// Провайдер для WebRTC сервиса
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService();
});

/// Провайдер для объединенного файлового сервиса
final unifiedFileServiceProvider = Provider<UnifiedFileService>((ref) {
  final service = UnifiedFileService();

  // Добавляем dispose callback
  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
});

/// Провайдер для информации о текущем устройстве
final currentDeviceProvider =
    NotifierProvider<CurrentDeviceNotifier, DeviceInfo>(
      CurrentDeviceNotifier.new,
    );

class CurrentDeviceNotifier extends Notifier<DeviceInfo> {
  static const String _logTag = 'CurrentDevice';

  @override
  DeviceInfo build() {
    final device = DeviceInfo.currentDevice();
    logInfo(
      'Инициализация текущего устройства',
      tag: _logTag,
      data: {'deviceName': device.name, 'deviceType': device.type.name},
    );
    return device;
  }

  /// Обновляет информацию об устройстве
  void updateDevice(DeviceInfo device) {
    logInfo('Обновление информации об устройстве', tag: _logTag);
    state = device;
  }

  /// Обновляет статус подключения
  void updateConnectionStatus(DeviceConnectionStatus status) {
    logDebug('Обновление статуса подключения: ${status.name}', tag: _logTag);
    state = state.copyWith(status: status);
  }

  /// Обновляет IP адрес
  void updateIpAddress(String ipAddress) {
    logDebug('Обновление IP адреса: $ipAddress', tag: _logTag);
    state = state.copyWith(ipAddress: ipAddress);
  }
}

/// Провайдер для списка обнаруженных устройств
final discoveredDevicesProvider =
    NotifierProvider<DiscoveredDevicesNotifier, List<DeviceInfo>>(
      DiscoveredDevicesNotifier.new,
    );

class DiscoveredDevicesNotifier extends Notifier<List<DeviceInfo>> {
  static const String _logTag = 'DiscoveredDevices';

  @override
  List<DeviceInfo> build() {
    return [];
  }

  /// Добавляет или обновляет устройство
  void addOrUpdateDevice(DeviceInfo device) {
    final existingIndex = state.indexWhere((d) => d.id == device.id);

    if (existingIndex != -1) {
      // Обновляем существующее устройство
      final updatedDevices = [...state];
      updatedDevices[existingIndex] = device;
      state = updatedDevices;
      logDebug('Обновлено устройство: ${device.name}', tag: _logTag);
    } else {
      // Добавляем новое устройство
      state = [...state, device];
      logInfo('Добавлено новое устройство: ${device.name}', tag: _logTag);
    }
  }

  /// Удаляет устройство
  void removeDevice(String deviceId) {
    state = state.where((device) => device.id != deviceId).toList();
    logInfo('Удалено устройство: $deviceId', tag: _logTag);
  }

  /// Очищает список устройств
  void clearDevices() {
    state = [];
    logInfo('Очищен список устройств', tag: _logTag);
  }
}

/// Провайдер для активных WebRTC подключений
final webrtcConnectionsProvider =
    NotifierProvider<WebRTCConnectionsNotifier, Map<String, WebRTCConnection>>(
      WebRTCConnectionsNotifier.new,
    );

class WebRTCConnectionsNotifier
    extends Notifier<Map<String, WebRTCConnection>> {
  static const String _logTag = 'WebRTCConnections';

  @override
  Map<String, WebRTCConnection> build() {
    return {};
  }

  /// Очищает все подключения
  void clearConnections() {
    state = {};
    logInfo('Очищены все WebRTC подключения', tag: _logTag);
  }

  /// Добавляет новое подключение
  void addConnection(WebRTCConnection connection) {
    state = {...state, connection.connectionId: connection};
    logInfo(
      'Добавлено WebRTC подключение',
      tag: _logTag,
      data: {
        'connectionId': connection.connectionId,
        'remoteDeviceId': connection.remoteDeviceId,
      },
    );
  }

  /// Обновляет состояние подключения
  void updateConnection(String connectionId, WebRTCConnection connection) {
    if (state.containsKey(connectionId)) {
      state = {...state, connectionId: connection};
      logDebug('Обновлено WebRTC подключение: $connectionId', tag: _logTag);
    }
  }

  /// Удаляет подключение
  void removeConnection(String connectionId) {
    final updatedState = Map<String, WebRTCConnection>.from(state);
    updatedState.remove(connectionId);
    state = updatedState;
    logInfo('Удалено WebRTC подключение: $connectionId', tag: _logTag);
  }

  /// Получает подключение по ID устройства
  WebRTCConnection? getConnectionByPeerId(String peerId) {
    return state.values
        .where((connection) => connection.remoteDeviceId == peerId)
        .firstOrNull;
  }

  /// Получает активные подключения
  List<WebRTCConnection> getActiveConnections() {
    return state.values
        .where(
          (connection) => connection.state == WebRTCConnectionState.connected,
        )
        .toList();
  }
}

/// Провайдер для активных передач файлов
final fileTransfersProvider =
    NotifierProvider<FileTransfersNotifier, Map<String, FileTransfer>>(
      FileTransfersNotifier.new,
    );

class FileTransfersNotifier extends Notifier<Map<String, FileTransfer>> {
  static const String _logTag = 'FileTransfers';

  @override
  Map<String, FileTransfer> build() {
    return {};
  }

  /// Добавляет новую передачу
  void addTransfer(FileTransfer transfer) {
    state = {...state, transfer.id: transfer};
    logInfo(
      'Добавлена передача файла',
      tag: _logTag,
      data: {
        'transferId': transfer.id,
        'fileName': transfer.fileName,
        'direction': transfer.direction.name,
      },
    );
  }

  /// Обновляет передачу
  void updateTransfer(String transferId, FileTransfer transfer) {
    if (state.containsKey(transferId)) {
      state = {...state, transferId: transfer};

      if (transfer.status == FileTransferStatus.completed) {
        logInfo('Передача файла завершена: ${transfer.fileName}', tag: _logTag);
      } else if (transfer.status == FileTransferStatus.failed) {
        logError(
          'Передача файла не удалась: ${transfer.fileName}',
          tag: _logTag,
        );
      }
    }
  }

  /// Обновляет прогресс передачи
  void updateTransferProgress(String transferId, int transferredBytes) {
    if (state.containsKey(transferId)) {
      final transfer = state[transferId]!;
      final updatedTransfer = transfer.copyWith(
        transferredBytes: transferredBytes,
      );
      state = {...state, transferId: updatedTransfer};
    }
  }

  /// Удаляет передачу
  void removeTransfer(String transferId) {
    final updatedState = Map<String, FileTransfer>.from(state);
    updatedState.remove(transferId);
    state = updatedState;
    logInfo('Удалена передача: $transferId', tag: _logTag);
  }

  /// Получает активные передачи
  List<FileTransfer> getActiveTransfers() {
    return state.values
        .where(
          (transfer) =>
              transfer.status == FileTransferStatus.inProgress ||
              transfer.status == FileTransferStatus.pending,
        )
        .toList();
  }

  /// Получает завершенные передачи
  List<FileTransfer> getCompletedTransfers() {
    return state.values
        .where((transfer) => transfer.status == FileTransferStatus.completed)
        .toList();
  }

  /// Очищает все передачи
  void clearTransfers() {
    state = {};
    logInfo('Очищена история передач', tag: _logTag);
  }
}

/// Провайдер для истории сообщений
final messageHistoryProvider =
    NotifierProvider<MessageHistoryNotifier, List<LocalSendMessage>>(
      MessageHistoryNotifier.new,
    );

class MessageHistoryNotifier extends Notifier<List<LocalSendMessage>> {
  static const String _logTag = 'MessageHistory';

  @override
  List<LocalSendMessage> build() {
    return [];
  }

  /// Добавляет новое сообщение
  void addMessage(LocalSendMessage message) {
    state = [...state, message];
    logInfo(
      'Добавлено сообщение',
      tag: _logTag,
      data: {
        'messageId': message.id,
        'type': message.type.name,
        'senderId': message.senderId,
      },
    );
  }

  /// Обновляет статус сообщения
  void updateMessageStatus(String messageId, MessageDeliveryStatus status) {
    state = state.map((message) {
      if (message.id == messageId) {
        return message.copyWith(status: status);
      }
      return message;
    }).toList();
  }

  /// Получает сообщения между двумя устройствами
  List<LocalSendMessage> getConversation(String deviceId1, String deviceId2) {
    return state
        .where(
          (message) =>
              (message.senderId == deviceId1 &&
                  message.receiverId == deviceId2) ||
              (message.senderId == deviceId2 &&
                  message.receiverId == deviceId1),
        )
        .toList();
  }

  /// Очищает историю сообщений
  void clearHistory() {
    state = [];
    logInfo('Очищена история сообщений', tag: _logTag);
  }
}
