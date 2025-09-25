import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend/models/index.dart';
import 'package:hoplixi/features/localsend/services/index.dart';
import 'package:hoplixi/features/localsend/providers/index.dart';

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

      // Запускаем сигналинг сервер
      await _signalingService.start(8080);
      logInfo('Сигналинг сервер запущен', tag: _logTag);

      // Обновляем информацию о текущем устройстве с реальным портом
      final currentDevice = _ref.read(currentDeviceProvider);
      _currentDevice.updateDevice(currentDevice.copyWith(port: 8080));

      // Запускаем обнаружение устройств
      await _discoveryService.startDiscovery();
      logInfo('Обнаружение устройств запущено', tag: _logTag);

      // Объявляем себя в сети
      await _discoveryService.startBroadcast(_ref.read(currentDeviceProvider));
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
}
