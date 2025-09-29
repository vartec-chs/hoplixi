import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/device_info.dart';

const _serviceType = '_localsend._tcp';
const _logTag = 'DiscoveryProvider';
final discoveryProvider =
    AsyncNotifierProvider.autoDispose<
      DiscoveryNotifier,
      List<LocalSendDeviceInfo>
    >(DiscoveryNotifier.new);

final selfDeviceProvider = Provider.autoDispose<LocalSendDeviceInfo>((ref) {
  final discoveryNotifier = ref.watch(discoveryProvider.notifier);
  return discoveryNotifier.selfDevice;
});

class DiscoveryNotifier extends AsyncNotifier<List<LocalSendDeviceInfo>> {
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  StreamSubscription<BonsoirBroadcastEvent>? _broadcastSubscription;
  late bool _isDiscovering = false;
  late bool _isBroadcasting = false;
  late LocalSendDeviceInfo _selfDevice = LocalSendDeviceInfo.currentDevice();
  final List<LocalSendDeviceInfo> _devices = [];

  // Флаги состояния для контроля cleanup
  bool _isDisposed = false;
  bool _isCleaningUp = false;

  @override
  Future<List<LocalSendDeviceInfo>> build() async {
    state = const AsyncValue.loading();
    await startDiscovery();

    ref.onDispose(() {
      _dispose();
    });

    state = AsyncValue.data(List.unmodifiable(_devices));
    return List.unmodifiable(_devices);
  }

  LocalSendDeviceInfo get selfDevice => _selfDevice;

  void setName(String name) {
    _selfDevice = _selfDevice.copyWith(name: name);
    logInfo('Device name set to $name', tag: _logTag);
    _updateState();
  }

  /// Перезагрузка обнаружения устройств
  Future<bool> reloadDiscovery() async {
    try {
      logInfo('Перезагрузка обнаружения устройств', tag: _logTag);
      await stopDiscovery();
      await stopBroadcast();
      _devices.clear();
      _updateState();
      await startDiscovery();
      return true;
    } catch (e, stack) {
      logError(
        'Ошибка перезагрузки обнаружения',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      rethrow;
    }
  }

  // Начать поиск устройств
  Future<void> startDiscovery() async {
    if (_isDisposed) {
      logWarning('Попытка запуска discovery после dispose', tag: _logTag);
      return;
    }

    try {
      if (_isDiscovering) return;
      _discovery = BonsoirDiscovery(type: _serviceType);
      await _discovery!.initialize();
      _discoverySubscription = _discovery!.eventStream!.listen(
        _handleEventDiscovery,
      );
      await _discovery!.start();
      _isDiscovering = true;
      // Добавляем текущее устройство
      // _devices.add(_selfDevice);
      _updateState();
      // Начинаем трансляцию текущего устройства
      await startBroadcasting();
    } catch (e, stack) {
      _isDiscovering = false;
      logError(
        'Ошибка запуска обнаружения',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      rethrow;
    }
  }

  // Остановить поиск устройств
  Future<void> stopDiscovery() async {
    try {
      if (!_isDiscovering) return;
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;

      if (_discovery != null) {
        await _discovery!.stop();
        _discovery = null;
        logInfo('Обнаружение устройств остановлено', tag: _logTag);
      }
    } catch (e, stack) {
      logError(
        'Ошибка остановки обнаружения',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
    } finally {
      // Гарантированно сбрасываем флаг
      _isDiscovering = false;
    }
  }

  /// Начинает трансляцию текущего устройства
  Future<void> startBroadcasting() async {
    if (_isDisposed) {
      logWarning('Попытка запуска broadcasting после dispose', tag: _logTag);
      return;
    }

    try {
      if (_isBroadcasting) return;
      _isBroadcasting = true;
      // Обновляем IP адрес текущего устройства
      final localIp = await _getLocalIpAddress();
      _selfDevice = _selfDevice.copyWith(ipAddress: localIp);

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      // Останавливаем предыдущую трансляцию, если была
      await stopBroadcast();
      final bonsoirService = BonsoirService(
        name: _selfDevice.name,
        type: _serviceType,
        port: _selfDevice.port,
        attributes: {
          'id': _selfDevice.id,
          'type': _selfDevice.type.name,
          'platform':
              _selfDevice.attributes?['platform'] ??
              await deviceInfo.deviceInfo.then((info) {
                if (Platform.isAndroid) {
                  return (info as AndroidDeviceInfo).model;
                } else if (Platform.isIOS) {
                  return (info as IosDeviceInfo).name;
                } else if (Platform.isLinux) {
                  return (info as LinuxDeviceInfo).prettyName;
                } else if (Platform.isMacOS) {
                  return (info as MacOsDeviceInfo).model;
                } else if (Platform.isWindows) {
                  return (info as WindowsDeviceInfo).computerName;
                } else {
                  return 'unknown';
                }
              }),
          'version':
              _selfDevice.attributes?['version'] ??
              Platform.operatingSystemVersion,
        },
      );

      _broadcast = BonsoirBroadcast(service: bonsoirService);
      await _broadcast!.initialize();
      _broadcastSubscription = _broadcast!.eventStream?.listen(
        _handleBroadcastEvent,
      );
      await _broadcast!.start();
      logInfo(
        'Трансляция устройства запущена на $localIp:${_selfDevice.port}',
        tag: _logTag,
      );
    } catch (e, stack) {
      _isBroadcasting = false;
      logError(
        'Ошибка запуска трансляции',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      rethrow;
    }
  }

  // Обработчик событий обнаружения
  void _handleEventDiscovery(BonsoirDiscoveryEvent event) async {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        // Разрешаем сервис для получения IP и других деталей
        event.service.resolve(_discovery!.serviceResolver);
        break;
      case BonsoirDiscoveryServiceResolvedEvent():
        // Проверяем, не является ли это нашим собственным устройством
        if (event.service.attributes['id'] == _selfDevice.id) {
          logDebug('Игнорируем собственное устройство', tag: _logTag);
          return;
        }
        // Добавляем или обновляем устройство
        final device = await _serviceToDeviceInfo(event.service);
        final existingIndex = _devices.indexWhere((d) => d.id == device.id);
        if (existingIndex >= 0) {
          _devices[existingIndex] = device;
        } else {
          _devices.add(device);
        }
        _updateState();
        break;
      case BonsoirDiscoveryServiceUpdatedEvent():
        // Проверяем, не является ли это нашим собственным устройством
        if (event.service.attributes['id'] == _selfDevice.id) {
          logDebug(
            'Игнорируем обновление собственного устройства',
            tag: _logTag,
          );
          return;
        }
        // Обновляем устройство
        final device = await _serviceToDeviceInfo(event.service);
        final existingIndex = _devices.indexWhere((d) => d.id == device.id);
        if (existingIndex >= 0) {
          _devices[existingIndex] = device;
        }
        _updateState();
        break;
      case BonsoirDiscoveryServiceLostEvent():
        // Проверяем, не является ли это нашим собственным устройством
        if (event.service.attributes['id'] == _selfDevice.id) {
          logDebug('Игнорируем потерю собственного устройства', tag: _logTag);
          return;
        }
        // Удаляем устройство
        _devices.removeWhere((d) => d.id == event.service.attributes['id']);
        _updateState();
        break;
      default:
        break;
    }
  }

  void _handleBroadcastEvent(BonsoirBroadcastEvent event) {
    try {
      switch (event.runtimeType) {
        case BonsoirBroadcastStartedEvent _:
          logDebug('Трансляция началась', tag: _logTag);
          break;

        case BonsoirBroadcastStoppedEvent _:
          logDebug('Трансляция остановлена', tag: _logTag);
          break;

        case BonsoirBroadcastNameAlreadyExistsEvent _:
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
    } finally {
      // Сбрасываем флаг трансляции
      _isBroadcasting = false;
    }
  }

  Future<LocalSendDeviceInfo> _serviceToDeviceInfo(
    BonsoirService service,
  ) async {
    final attributes = service.attributes;
    final id =
        attributes['id'] ??
        service.name; // Используем уникальный id из атрибутов
    final name = service.name;

    // Пытаемся извлечь IP адрес из host
    final host = service.host ?? '';
    logDebug(
      'Service host: $host, platform: ${attributes['platform']}',
      tag: '_serviceToDeviceInfo',
    );
    String ipAddress = host;

    final port = service.port;
    final deviceType = _getDeviceTypeFromAttributes(attributes);

    final deviceInfo = LocalSendDeviceInfo(
      id: id,
      name: name,
      type: deviceType,
      ipAddress: ipAddress,
      port: port,
      attributes: attributes,
      lastSeen: DateTime.now(),
      status: DeviceConnectionStatus.discovered,
    );

    logInfo(
      'Обнаружено устройство',
      tag: _logTag,
      data: {
        'name': name,
        'id': id,
        'host': host,
        'ipAddress': ipAddress,
        'port': port,
        'type': deviceType.name,
      },
    );

    return deviceInfo;
  }

  LocalSendDeviceType _getDeviceTypeFromAttributes(
    Map<String, String> attributes,
  ) {
    final platform = attributes['platform']?.toLowerCase();
    if (platform == 'android' || platform == 'ios') {
      return LocalSendDeviceType.mobile;
    } else if (platform == 'windows' ||
        platform == 'macos' ||
        platform == 'linux') {
      return LocalSendDeviceType.desktop;
    } else {
      return LocalSendDeviceType.unknown;
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

  void _updateState() {
    if (_isDisposed) {
      logDebug('Попытка обновления состояния после dispose', tag: _logTag);
      return;
    }
    state = AsyncValue.data(List.unmodifiable(_devices));
  }

  Future<void> _dispose() async {
    // Предотвращаем повторный dispose
    if (_isDisposed || _isCleaningUp) {
      logDebug('Dispose уже выполняется или завершен', tag: _logTag);
      return;
    }

    _isCleaningUp = true;
    logInfo('Начинаем dispose Discovery сервиса', tag: _logTag);

    try {
      // 1. Отменяем подписки
      final subscriptions = [
        ('discoverySubscription', _discoverySubscription),
        ('broadcastSubscription', _broadcastSubscription),
      ];

      for (final (name, subscription) in subscriptions) {
        if (subscription != null) {
          try {
            await subscription.cancel();
            logDebug('$name отменена', tag: _logTag);
          } catch (e) {
            logError('Ошибка при отмене $name', error: e, tag: _logTag);
          }
        }
      }

      // 2. Останавливаем discovery
      if (_discovery != null && _isDiscovering) {
        try {
          await _discovery!.stop();
          logDebug('Discovery остановлено', tag: _logTag);
        } catch (e) {
          logError('Ошибка остановки discovery', error: e, tag: _logTag);
        }
      }

      // 3. Останавливаем broadcast
      if (_broadcast != null && _isBroadcasting) {
        try {
          await _broadcast!.stop();
          logDebug('Broadcast остановлено', tag: _logTag);
        } catch (e) {
          logError('Ошибка остановки broadcast', error: e, tag: _logTag);
        }
      }

      logInfo('Dispose Discovery сервиса завершен успешно', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Критическая ошибка при dispose Discovery сервиса',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    } finally {
      // Гарантированно очищаем ресурсы
      _discovery = null;
      _broadcast = null;
      _discoverySubscription = null;
      _broadcastSubscription = null;
      _isDiscovering = false;
      _isBroadcasting = false;
      _isDisposed = true;
      _isCleaningUp = false;
    }
  }
}
