import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// Сервис обнаружения устройств через mDNS/DNS-SD
class DiscoveryService {
  static const String _serviceType = '_localsend._tcp';
  static const String _logTag = 'DiscoveryService';

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  StreamSubscription<BonsoirBroadcastEvent>? _broadcastSubscription;

  final StreamController<DeviceInfo> _deviceFoundController =
      StreamController<DeviceInfo>.broadcast();
  final StreamController<DeviceInfo> _deviceLostController =
      StreamController<DeviceInfo>.broadcast();
  final StreamController<DeviceInfo> _deviceUpdatedController =
      StreamController<DeviceInfo>.broadcast();

  /// Поток найденных устройств
  Stream<DeviceInfo> get deviceFound => _deviceFoundController.stream;

  /// Поток потерянных устройств
  Stream<DeviceInfo> get deviceLost => _deviceLostController.stream;

  /// Поток обновленных устройств
  Stream<DeviceInfo> get deviceUpdated => _deviceUpdatedController.stream;

  /// Текущее устройство
  DeviceInfo? _currentDevice;

  /// Запускает обнаружение устройств
  Future<void> startDiscovery() async {
    try {
      logInfo('Запуск обнаружения устройств', tag: _logTag);

      await stopDiscovery(); // Останавливаем предыдущее обнаружение

      _discovery = BonsoirDiscovery(type: _serviceType);
      await _discovery!.initialize();

      _discoverySubscription = _discovery!.eventStream?.listen(
        _handleDiscoveryEvent,
      );

      await _discovery!.start();

      logInfo('Обнаружение устройств запущено', tag: _logTag);
    } catch (e) {
      logError('Ошибка запуска обнаружения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Останавливает обнаружение устройств
  Future<void> stopDiscovery() async {
    try {
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;

      if (_discovery != null) {
        await _discovery!.stop();
        _discovery = null;
        logInfo('Обнаружение устройств остановлено', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка остановки обнаружения', error: e, tag: _logTag);
    }
  }

  /// Начинает трансляцию текущего устройства
  Future<void> startBroadcast(DeviceInfo deviceInfo) async {
    try {
      logInfo('Запуск трансляции устройства: ${deviceInfo.name}', tag: _logTag);

      await stopBroadcast(); // Останавливаем предыдущую трансляцию

      _currentDevice = deviceInfo;

      // Получаем локальный IP адрес
      final localIp = await _getLocalIpAddress();
      final updatedDevice = deviceInfo.copyWith(ipAddress: localIp);
      _currentDevice = updatedDevice;

      final service = BonsoirService(
        name: updatedDevice.name,
        type: _serviceType,
        port: updatedDevice.port,
        attributes: {
          'id': updatedDevice.id,
          'type': updatedDevice.type.name,
          'platform': updatedDevice.attributes?['platform'] ?? 'unknown',
          'version': updatedDevice.attributes?['version'] ?? 'unknown',
        },
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();

      _broadcastSubscription = _broadcast!.eventStream?.listen(
        _handleBroadcastEvent,
      );

      await _broadcast!.start();

      logInfo(
        'Трансляция устройства запущена на $localIp:${updatedDevice.port}',
        tag: _logTag,
      );
    } catch (e) {
      logError('Ошибка запуска трансляции', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Останавливает трансляцию текущего устройства
  Future<void> stopBroadcast() async {
    try {
      await _broadcastSubscription?.cancel();
      _broadcastSubscription = null;

      if (_broadcast != null) {
        await _broadcast!.stop();
        _broadcast = null;
        logInfo('Трансляция устройства остановлена', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка остановки трансляции', error: e, tag: _logTag);
    }
  }

  /// Получает информацию о текущем устройстве
  DeviceInfo? get currentDevice => _currentDevice;

  /// Освобождает ресурсы
  Future<void> dispose() async {
    await stopDiscovery();
    await stopBroadcast();

    await _deviceFoundController.close();
    await _deviceLostController.close();
    await _deviceUpdatedController.close();

    logInfo('DiscoveryService освобожден', tag: _logTag);
  }

  /// Обрабатывает события обнаружения
  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    try {
      switch (event.runtimeType) {
        case BonsoirDiscoveryStartedEvent:
          logDebug('Обнаружение началось', tag: _logTag);
          break;

        case BonsoirDiscoveryServiceFoundEvent:
          final foundEvent = event as BonsoirDiscoveryServiceFoundEvent;
          logDebug('Найден сервис: ${foundEvent.service.name}', tag: _logTag);

          // Запрашиваем разрешение сервиса для получения IP и атрибутов
          foundEvent.service.resolve(_discovery!.serviceResolver);
          break;

        case BonsoirDiscoveryServiceResolvedEvent:
          final resolvedEvent = event as BonsoirDiscoveryServiceResolvedEvent;
          final service = resolvedEvent.service;

          // Пропускаем наше собственное устройство (проверяем по ID и имени)
          if (service.attributes['id'] == _currentDevice?.id ||
              service.name == _currentDevice?.name) {
            logDebug(
              'Пропускаем собственное устройство: ${service.name}',
              tag: _logTag,
            );
            return;
          }

          final deviceInfo = _serviceToDeviceInfo(service);
          if (deviceInfo != null) {
            logInfo(
              'Устройство разрешено: ${deviceInfo.name} (${deviceInfo.ipAddress})',
              tag: _logTag,
            );
            _deviceFoundController.add(deviceInfo);
          }
          break;

        case BonsoirDiscoveryServiceUpdatedEvent:
          final updatedEvent = event as BonsoirDiscoveryServiceUpdatedEvent;
          final service = updatedEvent.service;

          // Пропускаем наше собственное устройство (проверяем по ID и имени)
          if (service.attributes['id'] == _currentDevice?.id ||
              service.name == _currentDevice?.name) {
            logDebug(
              'Пропускаем обновление собственного устройства: ${service.name}',
              tag: _logTag,
            );
            return;
          }

          final deviceInfo = _serviceToDeviceInfo(service);
          if (deviceInfo != null) {
            logInfo('Устройство обновлено: ${deviceInfo.name}', tag: _logTag);
            _deviceUpdatedController.add(deviceInfo);
          }
          break;

        case BonsoirDiscoveryServiceLostEvent:
          final lostEvent = event as BonsoirDiscoveryServiceLostEvent;
          final service = lostEvent.service;

          final deviceInfo = _serviceToDeviceInfo(service);
          if (deviceInfo != null) {
            logInfo('Устройство потеряно: ${deviceInfo.name}', tag: _logTag);
            _deviceLostController.add(deviceInfo);
          }
          break;

        case BonsoirDiscoveryStoppedEvent:
          logDebug('Обнаружение остановлено', tag: _logTag);
          break;

        default:
          logDebug(
            'Неизвестное событие обнаружения: ${event.runtimeType}',
            tag: _logTag,
          );
      }
    } catch (e) {
      logError('Ошибка обработки события обнаружения', error: e, tag: _logTag);
    }
  }

  /// Обрабатывает события трансляции
  void _handleBroadcastEvent(BonsoirBroadcastEvent event) {
    try {
      switch (event.runtimeType) {
        case BonsoirBroadcastStartedEvent:
          logDebug('Трансляция началась', tag: _logTag);
          break;

        case BonsoirBroadcastStoppedEvent:
          logDebug('Трансляция остановлена', tag: _logTag);
          break;

        case BonsoirBroadcastNameAlreadyExistsEvent:
          logWarning('Имя сервиса уже существует', tag: _logTag);
          break;

        default:
          logDebug(
            'Неизвестное событие трансляции: ${event.runtimeType}',
            tag: _logTag,
          );
      }
    } catch (e) {
      logError('Ошибка обработки события трансляции', error: e, tag: _logTag);
    }
  }

  /// Преобразует BonsoirService в DeviceInfo
  DeviceInfo? _serviceToDeviceInfo(BonsoirService service) {
    try {
      final attributes = service.attributes;
      final deviceId = attributes['id'];
      final deviceTypeStr = attributes['type'];

      if (deviceId == null || service.host == null) {
        return null;
      }

      DeviceType deviceType;
      try {
        deviceType = DeviceType.values.firstWhere(
          (type) => type.name == deviceTypeStr,
          orElse: () => DeviceType.unknown,
        );
      } catch (e) {
        deviceType = DeviceType.unknown;
      }

      return DeviceInfo(
        id: deviceId,
        name: service.name,
        type: deviceType,
        ipAddress: service.host!,
        port: service.port,
        attributes: {
          'platform': attributes['platform'] ?? 'unknown',
          'version': attributes['version'] ?? 'unknown',
        },
        lastSeen: DateTime.now(),
        status: DeviceConnectionStatus.discovered,
      );
    } catch (e) {
      logError(
        'Ошибка преобразования сервиса в DeviceInfo',
        error: e,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Получает локальный IP адрес
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      // Ищем не-loopback интерфейс
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }

      // Если не нашли, используем localhost
      return '127.0.0.1';
    } catch (e) {
      logError('Ошибка получения локального IP', error: e, tag: _logTag);
      return '127.0.0.1';
    }
  }
}
