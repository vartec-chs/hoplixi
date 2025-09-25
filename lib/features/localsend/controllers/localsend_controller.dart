import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/index.dart';
import 'package:hoplixi/features/localsend/services/index.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';
import 'package:uuid/uuid.dart';

/// Главный контроллер LocalSend для координации всех операций
final localSendControllerProvider = Provider<LocalSendController>((ref) {
  return LocalSendController(ref);
});

class LocalSendController {
  static const String _logTag = 'LocalSendController';

  final Ref _ref;
  bool _isInitialized = false;

  LocalSendController(this._ref);

  // Геттеры для сервисов
  DiscoveryService get _discoveryService => _ref.read(discoveryServiceProvider);
  SignalingService get _signalingService => _ref.read(signalingServiceProvider);
  WebRTCService get _webrtcService => _ref.read(webrtcServiceProvider);
  FileService get _fileService => _ref.read(fileServiceProvider);
  FileServiceV2 get _fileServiceV2 => _ref.read(fileServiceV2Provider);

  // Геттеры для нотификаторов
  CurrentDeviceNotifier get _currentDevice =>
      _ref.read(currentDeviceProvider.notifier);
  DiscoveredDevicesNotifier get _discoveredDevices =>
      _ref.read(discoveredDevicesProvider.notifier);
  WebRTCConnectionsNotifier get _connections =>
      _ref.read(webrtcConnectionsProvider.notifier);
  FileTransfersNotifier get _transfers =>
      _ref.read(fileTransfersProvider.notifier);
  MessageHistoryNotifier get _messages =>
      _ref.read(messageHistoryProvider.notifier);

  /// Инициализирует LocalSend службы
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logInfo('Инициализация LocalSend контроллера', tag: _logTag);

      // Запускаем сигналинг сервер на конфигурируемом порту
      const signalingPort = 53317; // WebRTCConfig.defaultSignalingPort
      await _signalingService.start(signalingPort);
      logInfo('Сигналинг сервер запущен на порту $signalingPort', tag: _logTag);

      // Обновляем информацию о текущем устройстве с реальным портом
      final currentDevice = _ref.read(currentDeviceProvider);
      _currentDevice.updateDevice(currentDevice.copyWith(port: signalingPort));

      // Подписываемся на входящие сигналы
      _signalingService.incomingSignals.listen(_handleIncomingSignal);

      // Подписываемся на события обнаружения устройств
      _discoveryService.deviceFound.listen(_handleDeviceFound);
      _discoveryService.deviceLost.listen(_handleDeviceLost);
      _discoveryService.deviceUpdated.listen(_handleDeviceUpdated);

      // Подписываемся на события WebRTC соединений
      _webrtcService.connectionStates.listen(_handleConnectionStateChange);
      _webrtcService.incomingMessages.listen(_handleIncomingMessage);
      _webrtcService.incomingFileChunks.listen(_handleIncomingFileChunk);

      // Запускаем обнаружение устройств
      await _discoveryService.startDiscovery();
      logInfo('Обнаружение устройств запущено', tag: _logTag);

      // Объявляем себя в сети
      final updatedDevice = _ref.read(currentDeviceProvider);
      await _discoveryService.startBroadcast(updatedDevice);
      logInfo('Объявление в сети запущено', tag: _logTag);

      _isInitialized = true;
      logInfo('LocalSend контроллер инициализирован', tag: _logTag);
    } catch (e) {
      logError('Ошибка инициализации LocalSend', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка инициализации',
        description: 'Не удалось запустить LocalSend: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Останавливает все службы LocalSend
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    try {
      logInfo('Остановка LocalSend контроллера', tag: _logTag);

      // Останавливаем службы
      await _discoveryService.stopDiscovery();
      await _discoveryService.stopBroadcast();
      await _signalingService.stop();

      // Очищаем состояние
      _discoveredDevices.clearDevices();
      _isInitialized = false;

      logInfo('LocalSend контроллер остановлен', tag: _logTag);
    } catch (e) {
      logError('Ошибка остановки LocalSend', error: e, tag: _logTag);
    }
  }

  /// Выбирает и отправляет файлы
  Future<bool> pickAndSendFiles(String deviceId) async {
    try {
      logInfo(
        'Выбор файлов для отправки на устройство: $deviceId',
        tag: _logTag,
      );

      final files = await _fileService.pickFiles();
      if (files.isEmpty) {
        logInfo('Файлы не выбраны', tag: _logTag);
        return false;
      }

      final currentDevice = _ref.read(currentDeviceProvider);

      for (final file in files) {
        // Создаем передачу файла
        final transfer = await _fileService.createFileTransferForSending(
          file: file,
          senderId: currentDevice.id,
          receiverId: deviceId,
        );

        // Добавляем в состояние
        _transfers.addTransfer(transfer);

        // Создаем сообщение о файле
        final fileMessage = LocalSendMessage.text(
          senderId: currentDevice.id,
          receiverId: deviceId,
          content:
              'Файл: ${transfer.fileName} (${_fileService.formatFileSize(transfer.fileSize)})',
        );

        _messages.addMessage(fileMessage);

        // Обновляем статус на "в процессе"
        _transfers.updateTransfer(
          transfer.id,
          transfer.copyWith(status: FileTransferStatus.inProgress),
        );

        // Симулируем передачу файла (в реальном приложении здесь будет WebRTC)
        _simulateFileTransfer(transfer);
      }

      ToastHelper.success(
        title: 'Файлы отправлены',
        description: 'Начата передача ${files.length} файлов',
      );
      return true;
    } catch (e) {
      logError('Ошибка отправки файлов', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить файлы',
      );
      return false;
    }
  }

  /// Отправляет выбранные файлы по их путям
  Future<bool> sendFiles(String deviceId, List<String> filePaths) async {
    try {
      logInfo(
        'Отправка файлов на устройство: $deviceId',
        tag: _logTag,
        data: {'fileCount': filePaths.length},
      );

      if (filePaths.isEmpty) {
        logInfo('Список файлов пуст', tag: _logTag);
        return false;
      }

      final currentDevice = _ref.read(currentDeviceProvider);

      for (final filePath in filePaths) {
        // Создаем передачу файла
        final transfer = await _fileServiceV2.createFileTransferForSending(
          filePath: filePath,
          senderId: currentDevice.id,
          receiverId: deviceId,
        );

        // Добавляем в состояние
        _transfers.addTransfer(transfer);

        // Создаем сообщение о файле
        final fileMessage = LocalSendMessage.text(
          senderId: currentDevice.id,
          receiverId: deviceId,
          content:
              'Файл: ${transfer.fileName} (${_fileServiceV2.formatFileSize(transfer.fileSize)})',
        );

        _messages.addMessage(fileMessage);

        // Обновляем статус на "в процессе"
        _transfers.updateTransfer(
          transfer.id,
          transfer.copyWith(status: FileTransferStatus.inProgress),
        );

        // Отправляем файл через существующий механизм передачи
        await sendFileWithResume(deviceId: deviceId, filePath: filePath);
      }

      ToastHelper.success(
        title: 'Файлы отправлены',
        description: 'Начата передача ${filePaths.length} файлов',
      );
      return true;
    } catch (e) {
      logError('Ошибка отправки файлов', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить файлы',
      );
      return false;
    }
  }

  /// Отправляет текстовое сообщение
  Future<bool> sendTextMessage(String deviceId, String text) async {
    try {
      final currentDevice = _ref.read(currentDeviceProvider);

      final message = LocalSendMessage.text(
        senderId: currentDevice.id,
        receiverId: deviceId,
        content: text,
      );

      // Добавляем в историю
      _messages.addMessage(message);

      // Симулируем отправку (в реальном приложении здесь будет WebRTC)
      await Future.delayed(const Duration(milliseconds: 500));

      _messages.updateMessageStatus(message.id, MessageDeliveryStatus.sent);

      logInfo('Сообщение отправлено', tag: _logTag);
      return true;
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить сообщение',
      );
      return false;
    }
  }

  /// Симулирует передачу файла для демонстрации
  void _simulateFileTransfer(FileTransfer transfer) async {
    try {
      final totalSize = transfer.fileSize;
      const chunkSize = 64 * 1024; // 64KB
      int transferred = 0;

      while (transferred < totalSize) {
        await Future.delayed(const Duration(milliseconds: 100));

        transferred = (transferred + chunkSize).clamp(0, totalSize);
        _transfers.updateTransferProgress(transfer.id, transferred);

        if (transferred >= totalSize) {
          _transfers.updateTransfer(
            transfer.id,
            transfer.copyWith(status: FileTransferStatus.completed),
          );
          break;
        }
      }

      logInfo(
        'Симуляция передачи файла завершена: ${transfer.fileName}',
        tag: _logTag,
      );
    } catch (e) {
      logError('Ошибка симуляции передачи файла', error: e, tag: _logTag);
      _transfers.updateTransfer(
        transfer.id,
        transfer.copyWith(status: FileTransferStatus.failed),
      );
    }
  }

  /// Добавляет тестовые устройства для демонстрации
  void addTestDevices() {
    logInfo('Добавление тестовых устройств', tag: _logTag);

    final testDevices = [
      DeviceInfo(
        id: 'test-device-1',
        name: 'iPhone Test',
        type: DeviceType.mobile,
        ipAddress: '192.168.1.100',
        port: 8080,
        status: DeviceConnectionStatus.discovered,
      ),
      DeviceInfo(
        id: 'test-device-2',
        name: 'MacBook Pro',
        type: DeviceType.desktop,
        ipAddress: '192.168.1.101',
        port: 8080,
        status: DeviceConnectionStatus.discovered,
      ),
      DeviceInfo(
        id: 'test-device-3',
        name: 'Android Phone',
        type: DeviceType.mobile,
        ipAddress: '192.168.1.102',
        port: 8080,
        status: DeviceConnectionStatus.discovered,
      ),
    ];

    for (final device in testDevices) {
      _discoveredDevices.addOrUpdateDevice(device);
    }
  }

  /// Проверяет, инициализирован ли контроллер
  bool get isInitialized => _isInitialized;

  // === Обработчики событий ===

  /// Обрабатывает входящие сигналы WebRTC
  void _handleIncomingSignal(SignalingMessage signal) async {
    try {
      logDebug(
        'Получен входящий сигнал',
        tag: _logTag,
        data: {
          'type': signal.type.name,
          'from': signal.fromDeviceId,
          'to': signal.toDeviceId,
        },
      );

      switch (signal.type) {
        case SignalingMessageType.offer:
          await _handleWebRTCOffer(signal);
          break;
        case SignalingMessageType.answer:
          await _handleWebRTCAnswer(signal);
          break;
        case SignalingMessageType.iceCandidate:
          await _handleIceCandidate(signal);
          break;
        case SignalingMessageType.ping:
          // Ping сигналы обычно не требуют обработки
          break;
        case SignalingMessageType.bye:
          // Обрабатываем закрытие соединения
          logInfo('Получен bye сигнал от ${signal.fromDeviceId}', tag: _logTag);
          break;
        // TODO: Добавить обработку других типов сигналов когда они будут нужны
      }
    } catch (e) {
      logError('Ошибка обработки входящего сигнала', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает найденные устройства
  void _handleDeviceFound(DeviceInfo device) {
    logDebug('Найдено устройство: ${device.name}', tag: _logTag);
    _discoveredDevices.addOrUpdateDevice(device);

    ToastHelper.info(
      title: 'Устройство найдено',
      description: '${device.name} (${device.ipAddress})',
    );
  }

  /// Обрабатывает потерянные устройства
  void _handleDeviceLost(DeviceInfo device) {
    logDebug('Устройство потеряно: ${device.name}', tag: _logTag);
    _discoveredDevices.removeDevice(device.id);
  }

  /// Обрабатывает обновленные устройства
  void _handleDeviceUpdated(DeviceInfo device) {
    logDebug('Устройство обновлено: ${device.name}', tag: _logTag);
    _discoveredDevices.addOrUpdateDevice(device);
  }

  /// Обрабатывает изменения состояния WebRTC соединений
  void _handleConnectionStateChange(WebRTCConnection connection) {
    logDebug(
      'Изменение состояния соединения',
      tag: _logTag,
      data: {
        'connectionId': connection.connectionId,
        'state': connection.state.name,
      },
    );

    _connections.updateConnection(connection.connectionId, connection);

    // Показываем уведомление о важных изменениях состояния
    switch (connection.state) {
      case WebRTCConnectionState.connected:
        ToastHelper.success(
          title: 'Соединение установлено',
          description: 'Готово к передаче данных',
        );
        break;
      case WebRTCConnectionState.failed:
        ToastHelper.error(
          title: 'Соединение прервано',
          description: connection.errorMessage ?? 'Неизвестная ошибка',
        );
        break;
      case WebRTCConnectionState.disconnected:
        ToastHelper.info(
          title: 'Соединение завершено',
          description: 'Устройство отключилось',
        );
        break;
      default:
        // Остальные состояния не требуют уведомлений
        break;
    }
  }

  /// Обрабатывает входящие сообщения
  void _handleIncomingMessage(LocalSendMessage message) {
    logDebug(
      'Получено сообщение',
      tag: _logTag,
      data: {'messageId': message.id, 'sender': message.senderId},
    );

    _messages.addMessage(message);

    ToastHelper.success(
      title: 'Новое сообщение',
      description: message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content,
    );
  }

  /// Обрабатывает входящие чанки файлов
  void _handleIncomingFileChunk(FileChunk chunk) async {
    try {
      logDebug(
        'Получен чанк файла',
        tag: _logTag,
        data: {
          'transferId': chunk.transferId,
          'chunkIndex': chunk.chunkIndex,
          'size': chunk.size,
        },
      );

      // TODO: Обработка чанка файла через FileService будет добавлена позже
      // await _fileService.processIncomingChunk(chunk);

      // Обновляем прогресс передачи
      final transfers = _ref.read(fileTransfersProvider);
      final transfer = transfers[chunk.transferId];
      if (transfer != null) {
        final newTransferred = transfer.transferredBytes + chunk.size;
        _transfers.updateTransferProgress(chunk.transferId, newTransferred);

        // Проверяем завершение передачи
        if (newTransferred >= transfer.fileSize) {
          _transfers.updateTransfer(
            chunk.transferId,
            transfer.copyWith(status: FileTransferStatus.completed),
          );

          ToastHelper.success(
            title: 'Файл получен',
            description: transfer.fileName,
          );
        }
      }
    } catch (e) {
      logError('Ошибка обработки чанка файла', error: e, tag: _logTag);
    }
  }

  // === Обработчики WebRTC сигналов ===

  /// Обрабатывает WebRTC offer
  Future<void> _handleWebRTCOffer(SignalingMessage signal) async {
    try {
      final currentDevice = _ref.read(currentDeviceProvider);

      // Принимаем входящее соединение
      final connectionId = await _webrtcService.acceptConnection(
        localDeviceId: currentDevice.id,
        remoteDeviceId: signal.fromDeviceId,
      );

      // Устанавливаем remote description
      final offer = signal.data;
      await _webrtcService.setRemoteDescription(
        connectionId,
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Создаем answer
      final answer = await _webrtcService.createAnswer(connectionId);

      // Отправляем answer обратно
      final devices = _ref.read(discoveredDevicesProvider);
      final targetDevice = devices.firstWhere(
        (device) => device.id == signal.fromDeviceId,
        orElse: () => throw Exception('Устройство не найдено'),
      );

      // TODO: Создать SignalingMessage.answer конструктор в моделях
      final answerSignal = SignalingMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: currentDevice.id,
        toDeviceId: signal.fromDeviceId,
        type: SignalingMessageType.answer,
        data: {'sdp': answer.sdp, 'type': answer.type},
        timestamp: DateTime.now(),
      );

      await _signalingService.sendSignal(targetDevice, answerSignal);
    } catch (e) {
      logError('Ошибка обработки WebRTC offer', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает WebRTC answer
  Future<void> _handleWebRTCAnswer(SignalingMessage signal) async {
    try {
      // Найти соединение по originalMessageId или другим критериям
      final connections = _webrtcService.activeConnections;
      final connection = connections.firstWhere(
        (conn) => conn.remoteDeviceId == signal.fromDeviceId,
        orElse: () => throw Exception('Соединение не найдено'),
      );

      // Устанавливаем remote description
      final answer = signal.data;
      await _webrtcService.setRemoteDescription(
        connection.connectionId,
        RTCSessionDescription(answer['sdp'], answer['type']),
      );
    } catch (e) {
      logError('Ошибка обработки WebRTC answer', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает ICE candidate
  Future<void> _handleIceCandidate(SignalingMessage signal) async {
    try {
      // Найти соединение
      final connections = _webrtcService.activeConnections;
      final connection = connections.firstWhere(
        (conn) => conn.remoteDeviceId == signal.fromDeviceId,
        orElse: () => throw Exception('Соединение не найдено'),
      );

      // Добавляем ICE candidate
      final candidateData = signal.data;
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await _webrtcService.addIceCandidate(connection.connectionId, candidate);
    } catch (e) {
      logError('Ошибка обработки ICE candidate', error: e, tag: _logTag);
    }
  }

  // Методы для работы с chunked file transfer

  /// Отправляет файл с поддержкой resume
  Future<bool> sendFileWithResume({
    required String filePath,
    required String deviceId,
    Function(double)? onProgress,
  }) async {
    try {
      // Находим соединение с устройством
      final connections = _ref.read(webrtcConnectionsProvider);
      final connection = connections[deviceId];
      if (connection == null || connection.dataChannel == null) {
        logError('Нет соединения с устройством: $deviceId', tag: _logTag);
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Нет соединения с устройством',
        );
        return false;
      }

      final transferId = const Uuid().v4();

      logInfo(
        'Отправка файла с поддержкой resume',
        tag: _logTag,
        data: {
          'filePath': filePath,
          'deviceId': deviceId,
          'transferId': transferId,
        },
      );

      final success = await _fileServiceV2.sendFileChunked(
        dataChannel: connection.dataChannel!,
        filePath: filePath,
        transferId: transferId,
        onProgress: onProgress,
      );

      if (success) {
        ToastHelper.success(
          title: 'Успешно',
          description: 'Файл отправлен успешно',
        );
      } else {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Ошибка отправки файла',
        );
      }

      return success;
    } catch (e) {
      logError('Ошибка отправки файла с resume', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка', description: 'Ошибка отправки файла');
      return false;
    }
  }

  /// Возобновляет прерванную передачу
  Future<bool> resumeTransfer(String transferId) async {
    try {
      logInfo(
        'Возобновление передачи',
        tag: _logTag,
        data: {'transferId': transferId},
      );

      final success = await _fileServiceV2.resumeTransfer(transferId);

      if (success) {
        ToastHelper.success(
          title: 'Успешно',
          description: 'Передача возобновлена',
        );
      } else {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Не удалось возобновить передачу',
        );
      }

      return success;
    } catch (e) {
      logError('Ошибка возобновления передачи', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Ошибка возобновления передачи',
      );
      return false;
    }
  }

  /// Отменяет передачу
  Future<void> cancelTransfer(String transferId) async {
    try {
      logInfo(
        'Отмена передачи',
        tag: _logTag,
        data: {'transferId': transferId},
      );

      await _fileServiceV2.cancelTransfer(transferId);
      ToastHelper.info(title: 'Информация', description: 'Передача отменена');
    } catch (e) {
      logError('Ошибка отмены передачи', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка', description: 'Ошибка отмены передачи');
    }
  }

  /// Получает статус всех активных передач
  Map<String, Map<String, dynamic>> getActiveTransfersStatus() {
    try {
      return _fileServiceV2.getActiveTransfersStatus();
    } catch (e) {
      logError('Ошибка получения статуса передач', error: e, tag: _logTag);
      return {};
    }
  }

  /// Подписывается на прогресс передач файлов
  Stream<Map<String, dynamic>> get fileTransferProgress {
    return _fileServiceV2.transferProgress;
  }
}
