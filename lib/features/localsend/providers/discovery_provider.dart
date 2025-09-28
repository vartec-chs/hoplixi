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
    AsyncNotifierProvider.autoDispose<DiscoveryNotifier, List<DeviceInfo>>(
      DiscoveryNotifier.new,
    );

final selfDeviceProvider = Provider.autoDispose<DeviceInfo>((ref) {
  final discoveryNotifier = ref.watch(discoveryProvider.notifier);
  return discoveryNotifier.selfDevice;
});

class DiscoveryNotifier extends AsyncNotifier<List<DeviceInfo>> {
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  StreamSubscription<BonsoirBroadcastEvent>? _broadcastSubscription;
  late bool _isDiscovering = false;
  late bool _isBroadcasting = false;
  late DeviceInfo _selfDevice = DeviceInfo.currentDevice();
  final List<DeviceInfo> _devices = [];

  @override
  Future<List<DeviceInfo>> build() async {
    state = const AsyncValue.loading();
    await startDiscovery();

    ref.onDispose(() {
      _dispose();
    });

    state = AsyncValue.data(List.unmodifiable(_devices));
    return List.unmodifiable(_devices);
  }

  DeviceInfo get selfDevice => _selfDevice;

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
                  return (info as AndroidDeviceInfo).model ?? 'Android';
                } else if (Platform.isIOS) {
                  return (info as IosDeviceInfo).name ?? 'iOS';
                } else if (Platform.isLinux) {
                  return (info as LinuxDeviceInfo).prettyName ?? 'Linux';
                } else if (Platform.isMacOS) {
                  return (info as MacOsDeviceInfo).model ?? 'macOS';
                } else if (Platform.isWindows) {
                  return (info as WindowsDeviceInfo).computerName ?? 'Windows';
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

  Future<DeviceInfo> _serviceToDeviceInfo(BonsoirService service) async {
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
    String ipAddress;

    // Проверяем, является ли host уже IP адресом
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      ipAddress = host;
    } else if (host.contains('.local')) {
      // Для .local доменов резолвим DNS в реальный IP

      ipAddress = await _resolveHostname(host);
      logDebug('Резолвлен .local домен: $host -> $ipAddress', tag: _logTag);
    } else {
      ipAddress = host;
    }

    final port = service.port;
    final deviceType = _getDeviceTypeFromAttributes(attributes);

    final deviceInfo = DeviceInfo(
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

  /// Резолвит .local адреса в обычные IP адреса
  Future<String> _resolveHostname(String hostname) async {
    try {
      logDebug(
        'Резолюция адреса устройства',
        tag: _logTag,
        data: {'hostname': hostname},
      );

      // Если это уже IP адрес, возвращаем как есть
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(hostname)) {
        logDebug('Адрес уже является IP', tag: _logTag);
        return hostname;
      }

      // Если это .local адрес, пытаемся резолвить
      if (hostname.endsWith('.local')) {
        logDebug('Резолюция .local адреса', tag: _logTag);

        final addresses = await InternetAddress.lookup(hostname).timeout(
          const Duration(seconds: 3), // Таймаут для DNS запроса
        );

        // Ищем первый IPv4 адрес
        for (final address in addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final resolvedIp = address.address;
            logInfo(
              'Успешно резолвлен .local адрес',
              tag: _logTag,
              data: {'hostname': hostname, 'resolvedIp': resolvedIp},
            );
            return resolvedIp;
          }
        }

        logWarning(
          'Не найден IPv4 адрес для .local домена',
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

  DeviceType _getDeviceTypeFromAttributes(Map<String, String> attributes) {
    final platform = attributes['platform']?.toLowerCase();
    if (platform == 'android' || platform == 'ios') {
      return DeviceType.mobile;
    } else if (platform == 'windows' ||
        platform == 'macos' ||
        platform == 'linux') {
      return DeviceType.desktop;
    } else {
      return DeviceType.unknown;
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
    state = AsyncValue.data(List.unmodifiable(_devices));
  }

  Future<void> _dispose() async {
    await _discoverySubscription?.cancel();
    await _broadcastSubscription?.cancel();
    try {
      await _discovery?.stop();
    } catch (_) {}
    try {
      await _broadcast?.stop();
    } catch (_) {}
    _discovery = null;
    _broadcast = null;
    _discoverySubscription = null;
    _broadcastSubscription = null;
  }
}
