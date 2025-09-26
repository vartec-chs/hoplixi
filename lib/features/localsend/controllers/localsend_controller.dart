import 'dart:async';
import 'dart:io';
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
  UnifiedFileService get _fileService => _ref.read(unifiedFileServiceProvider);

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
    if (_isInitialized) {
      logInfo('LocalSend контроллер уже инициализирован', tag: _logTag);
      return;
    }

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
      _webrtcService.iceCandidates.listen(_handleOutgoingIceCandidate);

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

  /// Полная очистка всех данных LocalSend (для dispose)
  Future<void> disposeAll() async {
    try {
      logInfo('=== НАЧАЛО ПОЛНОЙ ОЧИСТКИ LOCALSEND ===', tag: _logTag);

      // Останавливаем все службы
      await shutdown();

      // Закрываем все WebRTC соединения
      final connections = _ref.read(webrtcConnectionsProvider);
      for (final connection in connections.values) {
        try {
          await _webrtcService.closeConnection(connection.connectionId);
          logDebug(
            'Закрыто соединение: ${connection.connectionId}',
            tag: _logTag,
          );
        } catch (e) {
          logWarning(
            'Ошибка закрытия соединения ${connection.connectionId}',
            tag: _logTag,
          );
        }
      }

      // Очищаем все провайдеры состояния
      _discoveredDevices.clearDevices();
      _connections.clearConnections();
      _transfers.clearTransfers();
      _messages.clearHistory();

      // Сбрасываем текущее устройство к исходному состоянию
      final defaultDevice = DeviceInfo.currentDevice();
      _currentDevice.updateDevice(defaultDevice);

      logInfo('=== ПОЛНАЯ ОЧИСТКА LOCALSEND ЗАВЕРШЕНА ===', tag: _logTag);
    } catch (e) {
      logError('Ошибка полной очистки LocalSend', error: e, tag: _logTag);
    }
  }

  /// Перезапускает поиск устройств в сети
  Future<void> refreshDeviceDiscovery() async {
    if (!_isInitialized) {
      logWarning(
        'LocalSend не инициализирован - невозможно перезапустить поиск',
        tag: _logTag,
      );
      return;
    }

    try {
      logInfo('Перезапуск поиска устройств', tag: _logTag);

      // Останавливаем текущий поиск
      await _discoveryService.stopDiscovery();

      // Очищаем список обнаруженных устройств
      _discoveredDevices.clearDevices();

      // Ждем немного для завершения остановки
      await Future.delayed(const Duration(milliseconds: 500));

      // Запускаем поиск заново
      await _discoveryService.startDiscovery();

      logInfo('Поиск устройств перезапущен', tag: _logTag);

      ToastHelper.success(
        title: 'Поиск обновлен',
        description: 'Поиск устройств в сети перезапущен',
      );
    } catch (e) {
      logError(
        'Ошибка при перезапуске поиска устройств',
        error: e,
        tag: _logTag,
      );

      ToastHelper.error(
        title: 'Ошибка обновления',
        description: 'Не удалось перезапустить поиск устройств',
      );
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

      // Найти активное WebRTC соединение с устройством
      final webrtcConnections = _ref.read(webrtcConnectionsProvider);
      var connection = webrtcConnections.values
          .where(
            (conn) =>
                conn.remoteDeviceId == deviceId &&
                conn.state == WebRTCConnectionState.connected,
          )
          .firstOrNull;

      if (connection == null) {
        logInfo(
          'Соединение отсутствует, устанавливаем соединение с устройством: $deviceId',
          tag: _logTag,
        );

        // Устанавливаем соединение
        final connected = await connectToDevice(deviceId);
        if (!connected) {
          logError(
            'Не удалось установить соединение с устройством: $deviceId',
            tag: _logTag,
          );

          ToastHelper.error(
            title: 'Ошибка передачи',
            description: 'Не удалось подключиться к устройству',
          );
          return false;
        }

        // Получаем обновленные соединения после установки
        final updatedConnections = _ref.read(webrtcConnectionsProvider);
        connection = updatedConnections.values
            .where(
              (conn) =>
                  conn.remoteDeviceId == deviceId &&
                  conn.state == WebRTCConnectionState.connected,
            )
            .firstOrNull;
      }

      if (connection == null) {
        logError(
          'Активное соединение с устройством не найдено после подключения: $deviceId',
          tag: _logTag,
        );

        ToastHelper.error(
          title: 'Ошибка передачи',
          description: 'Нет активного соединения с устройством',
        );
        return false;
      }

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

        logInfo(
          'Отправка файла через WebRTC',
          tag: _logTag,
          data: {
            'fileName': transfer.fileName,
            'connectionId': connection.connectionId,
          },
        );

        // TODO: Здесь будет реальная передача через WebRTC DataChannel
        // await _webrtcService.sendFile(connection.connectionId, transfer);

        // Симулируем передачу файла (в реальном приложении здесь будет WebRTC)
        _simulateFileTransfer(transfer);
      }

      ToastHelper.success(
        title: 'Файлы отправлены',
        description: 'Начата передача ${files.length} файлов через WebRTC',
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

      // Найти активное WebRTC соединение с устройством
      final webrtcConnections = _ref.read(webrtcConnectionsProvider);
      var connection = webrtcConnections.values
          .where(
            (conn) =>
                conn.remoteDeviceId == deviceId &&
                conn.state == WebRTCConnectionState.connected,
          )
          .firstOrNull;

      if (connection == null) {
        logInfo(
          'Соединение отсутствует, устанавливаем соединение с устройством: $deviceId',
          tag: _logTag,
        );

        // Устанавливаем соединение
        final connected = await connectToDevice(deviceId);
        if (!connected) {
          logError(
            'Не удалось установить соединение с устройством: $deviceId',
            tag: _logTag,
          );

          ToastHelper.error(
            title: 'Ошибка передачи',
            description: 'Не удалось подключиться к устройству',
          );
          return false;
        }

        // Получаем обновленные соединения после установки
        final updatedConnections = _ref.read(webrtcConnectionsProvider);
        connection = updatedConnections.values
            .where(
              (conn) =>
                  conn.remoteDeviceId == deviceId &&
                  conn.state == WebRTCConnectionState.connected,
            )
            .firstOrNull;
      }

      if (connection == null) {
        logError(
          'Активное соединение с устройством не найдено после подключения: $deviceId',
          tag: _logTag,
        );

        ToastHelper.error(
          title: 'Ошибка передачи',
          description: 'Нет активного соединения с устройством',
        );
        return false;
      }

      for (final filePath in filePaths) {
        // Создаем передачу файла
        final file = File(filePath);
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

        logInfo(
          'Отправка файла через WebRTC',
          tag: _logTag,
          data: {
            'fileName': transfer.fileName,
            'connectionId': connection.connectionId,
          },
        );

        // TODO: Здесь будет реальная передача через WebRTC DataChannel
        // await _webrtcService.sendFile(connection.connectionId, transfer);

        // Отправляем файл через существующий механизм передачи
        await sendFileWithResume(deviceId: deviceId, filePath: filePath);
      }

      ToastHelper.success(
        title: 'Файлы отправлены',
        description: 'Начата передача ${filePaths.length} файлов через WebRTC',
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

      // Добавляем в локальную историю
      _messages.addMessage(message);

      // Найти активное WebRTC соединение с устройством
      final webrtcConnections = _ref.read(webrtcConnectionsProvider);
      var connection = webrtcConnections.values
          .where(
            (conn) =>
                conn.remoteDeviceId == deviceId &&
                conn.state == WebRTCConnectionState.connected,
          )
          .firstOrNull;

      if (connection == null) {
        logInfo(
          'Соединение отсутствует, устанавливаем соединение с устройством: $deviceId',
          tag: _logTag,
        );

        // Устанавливаем соединение
        final connected = await connectToDevice(deviceId);
        if (!connected) {
          logError(
            'Не удалось установить соединение с устройством: $deviceId',
            tag: _logTag,
          );
          _messages.updateMessageStatus(
            message.id,
            MessageDeliveryStatus.failed,
          );

          ToastHelper.error(
            title: 'Ошибка отправки',
            description: 'Не удалось подключиться к устройству',
          );
          return false;
        }

        // Получаем обновленные соединения после установки
        final updatedConnections = _ref.read(webrtcConnectionsProvider);
        connection = updatedConnections.values
            .where(
              (conn) =>
                  conn.remoteDeviceId == deviceId &&
                  conn.state == WebRTCConnectionState.connected,
            )
            .firstOrNull;

        logDebug(
          'Проверка соединения после подключения',
          tag: _logTag,
          data: {
            'connectionFound': connection != null,
            'connectionState': connection?.state.name ?? 'null',
            'totalConnections': updatedConnections.length,
          },
        );
      }

      if (connection == null) {
        logError(
          'Активное соединение с устройством не найдено после подключения: $deviceId',
          tag: _logTag,
        );
        _messages.updateMessageStatus(message.id, MessageDeliveryStatus.failed);

        ToastHelper.error(
          title: 'Ошибка отправки',
          description: 'Нет активного соединения с устройством',
        );
        return false;
      }

      // Отправляем сообщение через WebRTC
      await _webrtcService.sendMessage(connection.connectionId, message);
      _messages.updateMessageStatus(message.id, MessageDeliveryStatus.sent);

      logInfo(
        'Сообщение отправлено через WebRTC',
        tag: _logTag,
        data: {
          'connectionId': connection.connectionId,
          'messageId': message.id,
        },
      );
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

  /// Устанавливает WebRTC соединение с устройством
  Future<bool> connectToDevice(String deviceId) async {
    try {
      logInfo('=== НАЧАЛО УСТАНОВКИ СОЕДИНЕНИЯ ===', tag: _logTag);
      logInfo('Целевое устройство ID: $deviceId', tag: _logTag);

      final device = _ref
          .read(discoveredDevicesProvider)
          .where((d) => d.id == deviceId)
          .firstOrNull;

      if (device == null) {
        logError('Устройство не найдено: $deviceId', tag: _logTag);
        return false;
      }

      logInfo(
        'Устройство найдено: ${device.name} (${device.ipAddress}:${device.port})',
        tag: _logTag,
      );

      logInfo(
        'Установка соединения с устройством: ${device.name}',
        tag: _logTag,
      );

      // Проверяем, существует ли уже соединение
      final connections = _ref.read(webrtcConnectionsProvider);
      final existingConnection = connections.values
          .where(
            (conn) =>
                conn.remoteDeviceId == deviceId &&
                conn.state == WebRTCConnectionState.connected,
          )
          .firstOrNull;

      if (existingConnection != null) {
        logInfo(
          'Соединение уже установлено с устройством: $deviceId',
          tag: _logTag,
        );
        return true;
      }

      // Получаем текущее устройство
      final currentDevice = _ref.read(currentDeviceProvider);

      // Создаем WebRTC соединение
      logInfo('Создаем WebRTC соединение...', tag: _logTag);
      final connectionId = await _webrtcService.createConnection(
        localDeviceId: currentDevice.id,
        remoteDeviceId: deviceId,
      );
      logInfo('WebRTC соединение создано: $connectionId', tag: _logTag);

      // Создаем Completer для ожидания установления соединения
      final connectionCompleter = Completer<bool>();
      late StreamSubscription<WebRTCConnection> subscription;

      logInfo('Настраиваем подписку на состояния соединения...', tag: _logTag);

      // Подписываемся на изменения состояния соединения
      subscription = _webrtcService.connectionStates
          .where((conn) => conn.connectionId == connectionId)
          .listen((connection) {
            logDebug(
              'Состояние соединения изменилось',
              tag: _logTag,
              data: {
                'connectionId': connectionId,
                'state': connection.state.name,
              },
            );

            if (connection.state == WebRTCConnectionState.connected) {
              logInfo('WebRTC соединение установлено успешно', tag: _logTag);
              subscription.cancel();
              if (!connectionCompleter.isCompleted) {
                connectionCompleter.complete(true);
              }
            } else if (connection.state == WebRTCConnectionState.failed) {
              logError('WebRTC соединение не удалось установить', tag: _logTag);
              subscription.cancel();
              if (!connectionCompleter.isCompleted) {
                connectionCompleter.complete(false);
              }
            }
          });

      // Создаем offer и начинаем сигналинг
      logInfo('Создаем WebRTC offer...', tag: _logTag);
      final offer = await _webrtcService.createOffer(connectionId);
      logInfo('WebRTC offer создан: ${offer.type}', tag: _logTag);

      // Создаем сообщение сигналинга
      logInfo('Создаем сообщение сигналинга...', tag: _logTag);
      final signalingMessage = SignalingMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: currentDevice.id,
        toDeviceId: deviceId,
        type: SignalingMessageType.offer,
        timestamp: DateTime.now(),
        data: {
          'connectionId': connectionId,
          'sdp': offer.sdp,
          'type': offer.type,
        },
      );

      // Отправляем offer через сигналинг
      logInfo(
        'Отправляем offer через сигналинг на ${device.ipAddress}:${device.port}...',
        tag: _logTag,
      );
      final signalingSuccess = await _signalingService.sendSignal(
        device,
        signalingMessage,
      );

      logInfo('Результат отправки offer: $signalingSuccess', tag: _logTag);

      if (!signalingSuccess) {
        logError(
          'Не удалось отправить offer устройству: ${device.name}',
          tag: _logTag,
        );
        subscription.cancel();
        return false;
      }

      logInfo(
        'Offer отправлен, ожидаем установления соединения...',
        tag: _logTag,
      );

      // Ждем установления соединения с таймаутом
      final connectionResult = await connectionCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          logError('Таймаут при установлении WebRTC соединения', tag: _logTag);
          subscription.cancel();
          return false;
        },
      );

      return connectionResult;
    } catch (e) {
      logError('Ошибка установки соединения', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка подключения',
        description: 'Не удалось подключиться к устройству',
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
    final currentDevice = _ref.read(currentDeviceProvider);

    // Дополнительная проверка против собственного устройства
    if (device.id == currentDevice.id ||
        device.name == currentDevice.name ||
        (device.ipAddress == currentDevice.ipAddress &&
            device.port == currentDevice.port)) {
      logDebug(
        'Пропуск обнаружения собственного устройства: ${device.name}',
        tag: _logTag,
      );
      return;
    }

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

    // Добавляем или обновляем соединение в провайдере состояния
    final existingConnections = _ref.read(webrtcConnectionsProvider);
    if (existingConnections.containsKey(connection.connectionId)) {
      _connections.updateConnection(connection.connectionId, connection);
    } else {
      _connections.addConnection(connection);
    }

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
      logInfo('=== ОБРАБОТКА ВХОДЯЩЕГО WEBRTC OFFER ===', tag: _logTag);
      logInfo('От устройства: ${signal.fromDeviceId}', tag: _logTag);
      logInfo('Данные offer: ${signal.data.keys.join(", ")}', tag: _logTag);

      final currentDevice = _ref.read(currentDeviceProvider);

      // Принимаем входящее соединение
      logInfo('Принимаем входящее WebRTC соединение...', tag: _logTag);
      final connectionId = await _webrtcService.acceptConnection(
        localDeviceId: currentDevice.id,
        remoteDeviceId: signal.fromDeviceId,
      );
      logInfo('Входящее соединение принято: $connectionId', tag: _logTag);

      // Устанавливаем remote description
      logInfo('Устанавливаем remote description (offer)...', tag: _logTag);
      final offer = signal.data;
      await _webrtcService.setRemoteDescription(
        connectionId,
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      logInfo('Remote description (offer) установлен', tag: _logTag);

      // Создаем answer
      logInfo('Создаем WebRTC answer...', tag: _logTag);
      final answer = await _webrtcService.createAnswer(connectionId);
      logInfo('WebRTC answer создан: ${answer.type}', tag: _logTag);

      // Отправляем answer обратно
      final devices = _ref.read(discoveredDevicesProvider);
      final targetDevice = devices.firstWhere(
        (device) => device.id == signal.fromDeviceId,
        orElse: () => throw Exception('Устройство не найдено'),
      );

      logInfo(
        'Отправляем answer на ${targetDevice.ipAddress}:${targetDevice.port}...',
        tag: _logTag,
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

      final answerSent = await _signalingService.sendSignal(
        targetDevice,
        answerSignal,
      );
      logInfo('Результат отправки answer: $answerSent', tag: _logTag);

      if (answerSent) {
        logInfo('=== OFFER ОБРАБОТАН УСПЕШНО ===', tag: _logTag);
      } else {
        logError('Не удалось отправить answer', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка обработки WebRTC offer', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает WebRTC answer
  Future<void> _handleWebRTCAnswer(SignalingMessage signal) async {
    try {
      logInfo('=== ОБРАБОТКА ВХОДЯЩЕГО WEBRTC ANSWER ===', tag: _logTag);
      logInfo('От устройства: ${signal.fromDeviceId}', tag: _logTag);

      // Найти соединение в провайдере состояния или WebRTC сервисе
      final connections = _ref.read(webrtcConnectionsProvider);
      logInfo(
        'Поиск соединения для answer, всего соединений: ${connections.length}',
        tag: _logTag,
      );

      var connection = connections.values
          .where((conn) => conn.remoteDeviceId == signal.fromDeviceId)
          .firstOrNull;

      logInfo(
        'Соединение найдено в провайдере: ${connection != null}',
        tag: _logTag,
      );

      // Если не найдено в провайдере, попробуем найти в WebRTC сервисе
      if (connection == null) {
        final activeConnections = _webrtcService.activeConnections;
        logInfo(
          'Поиск в WebRTC сервисе, активных соединений: ${activeConnections.length}',
          tag: _logTag,
        );
        connection = activeConnections
            .where((conn) => conn.remoteDeviceId == signal.fromDeviceId)
            .firstOrNull;
        logInfo(
          'Соединение найдено в WebRTC сервисе: ${connection != null}',
          tag: _logTag,
        );
      }

      if (connection == null) {
        logError(
          'Соединение для answer не найдено: ${signal.fromDeviceId}',
          tag: _logTag,
        );
        return;
      }

      logInfo(
        'Найдено соединение: ${connection.connectionId}, состояние: ${connection.state.name}',
        tag: _logTag,
      );

      // Устанавливаем remote description
      logInfo('Устанавливаем remote description (answer)...', tag: _logTag);
      final answer = signal.data;
      await _webrtcService.setRemoteDescription(
        connection.connectionId,
        RTCSessionDescription(answer['sdp'], answer['type']),
      );

      logInfo('=== WEBRTC ANSWER ОБРАБОТАН УСПЕШНО ===', tag: _logTag);
    } catch (e) {
      logError('Ошибка обработки WebRTC answer', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает ICE candidate
  Future<void> _handleIceCandidate(SignalingMessage signal) async {
    try {
      logInfo('=== ОБРАБОТКА ICE CANDIDATE ===', tag: _logTag);
      logInfo('От устройства: ${signal.fromDeviceId}', tag: _logTag);
      logInfo('Данные candidate: ${signal.data.keys.join(", ")}', tag: _logTag);

      // Найти соединение
      final connections = _webrtcService.activeConnections;
      logInfo(
        'Поиск соединения для ICE, активных соединений: ${connections.length}',
        tag: _logTag,
      );

      WebRTCConnection? connection;
      try {
        connection = connections.firstWhere(
          (conn) => conn.remoteDeviceId == signal.fromDeviceId,
        );
      } catch (e) {
        logWarning(
          'Соединение не найдено для устройства ${signal.fromDeviceId}',
          tag: _logTag,
        );
        return;
      }

      logInfo(
        'Найдено соединение для ICE: ${connection.connectionId}',
        tag: _logTag,
      );

      // Создаем событие ICE candidate
      final candidateData = signal.data;
      final iceCandidateEvent = IceCandidateEvent(
        deviceId: signal.fromDeviceId,
        candidate: candidateData['candidate'],
        sdpMid: candidateData['sdpMid'],
        sdpMLineIndex: candidateData['sdpMLineIndex'],
      );

      logInfo('Обрабатываем ICE candidate через WebRTCService', tag: _logTag);
      final success = await _webrtcService.handleIncomingIceCandidate(
        iceCandidateEvent,
      );

      if (success) {
        logInfo('ICE candidate успешно добавлен', tag: _logTag);
      } else {
        logWarning('Не удалось добавить ICE candidate', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка обработки ICE candidate', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает исходящие ICE candidates от WebRTCService
  Future<void> _handleOutgoingIceCandidate(IceCandidateEvent event) async {
    try {
      logInfo('=== ОТПРАВКА ICE CANDIDATE ===', tag: _logTag);
      logInfo('Для устройства: ${event.deviceId}', tag: _logTag);
      logInfo('Candidate: ${event.candidate}', tag: _logTag);

      // Отправляем ICE candidate через сигналинг
      final signalingMessage = SignalingMessage(
        type: SignalingMessageType.iceCandidate,
        fromDeviceId: _ref.read(currentDeviceProvider).id,
        toDeviceId: event.deviceId,
        data: {
          'candidate': event.candidate,
          'sdpMid': event.sdpMid,
          'sdpMLineIndex': event.sdpMLineIndex,
        },
        timestamp: DateTime.now(),
        messageId: const Uuid().v4(),
      );

      // Находим устройство для отправки сигнала с безопасной проверкой
      final devices = _ref.read(discoveredDevicesProvider);
      logInfo(
        'Ищем устройство ${event.deviceId} среди ${devices.length} обнаруженных',
        tag: _logTag,
      );
      logInfo(
        'Доступные устройства: ${devices.map((d) => "${d.id} (${d.name})").join(", ")}',
        tag: _logTag,
      );

      DeviceInfo? targetDevice;
      try {
        targetDevice = devices.firstWhere(
          (device) => device.id == event.deviceId,
        );
        logInfo(
          'Устройство найдено: ${targetDevice.name} (${targetDevice.fullAddress})',
          tag: _logTag,
        );
      } catch (e) {
        logError(
          'Устройство ${event.deviceId} не найдено в списке обнаруженных',
          tag: _logTag,
        );
        logError(
          'Не могу отправить ICE candidate - устройство недоступно',
          tag: _logTag,
        );
        return;
      }

      await _signalingService.sendSignal(targetDevice, signalingMessage);
      logInfo('ICE candidate отправлен через сигналинг', tag: _logTag);
    } catch (e) {
      logError('Ошибка при отправке ICE candidate', error: e, tag: _logTag);
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
      // Находим активное WebRTC соединение с устройством
      final webrtcConnections = _ref.read(webrtcConnectionsProvider);
      final connection = webrtcConnections.values
          .where(
            (conn) =>
                conn.remoteDeviceId == deviceId &&
                conn.state == WebRTCConnectionState.connected,
          )
          .firstOrNull;

      if (connection == null) {
        logError(
          'Нет активного WebRTC соединения с устройством: $deviceId',
          tag: _logTag,
        );
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Нет соединения с устройством',
        );
        return false;
      }

      // Проверяем наличие DataChannel
      if (connection.dataChannel == null) {
        logError(
          'DataChannel отсутствует в соединении: ${connection.connectionId}',
          tag: _logTag,
        );
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Канал передачи данных не готов',
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
          'connectionId': connection.connectionId,
        },
      );

      final success = await _fileService.sendFileChunked(
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

      final success = await _fileService.resumeTransfer(transferId);

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

      await _fileService.cancelTransfer(transferId);
      ToastHelper.info(title: 'Информация', description: 'Передача отменена');
    } catch (e) {
      logError('Ошибка отмены передачи', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка', description: 'Ошибка отмены передачи');
    }
  }

  /// Получает статус всех активных передач
  Map<String, Map<String, dynamic>> getActiveTransfersStatus() {
    try {
      return _fileService.getActiveTransfersStatus();
    } catch (e) {
      logError('Ошибка получения статуса передач', error: e, tag: _logTag);
      return {};
    }
  }

  /// Подписывается на прогресс передач файлов
  Stream<Map<String, dynamic>> get fileTransferProgress {
    return _fileService.transferProgress;
  }
}
