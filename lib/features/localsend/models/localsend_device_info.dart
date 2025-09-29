import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

part 'localsend_device_info.freezed.dart';
part 'localsend_device_info.g.dart';

/// Типы устройств для LocalSend
enum LocalSendDeviceType { mobile, desktop, tablet, unknown }

/// Информация об устройстве в сети LocalSend
@freezed
abstract class LocalSendDeviceInfo with _$LocalSendDeviceInfo {
  const factory LocalSendDeviceInfo({
    /// Уникальный идентификатор устройства
    required String id,

    /// Отображаемое имя устройства
    required String name,

    /// Тип устройства
    required LocalSendDeviceType type,

    /// IP адрес устройства
    required String ipAddress,

    /// Порт для HTTP signaling сервера
    required int port,

    /// Дополнительная информация об устройстве
    Map<String, String>? attributes,

    /// Временная метка последнего обнаружения
    DateTime? lastSeen,

    /// Статус соединения с устройством
    @Default(DeviceConnectionStatus.discovered) DeviceConnectionStatus status,
  }) = _LocalSendDeviceInfo;

  factory LocalSendDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$LocalSendDeviceInfoFromJson(json);

  /// Создает информацию о текущем устройстве
  factory LocalSendDeviceInfo.currentDevice({
    String? customName,
    int? customPort,
  }) {
    final uuid = const Uuid();
    final deviceName = customName ?? _getDeviceName();
    final deviceType = _getDeviceType();

    return LocalSendDeviceInfo(
      id: uuid.v4(),
      name: deviceName,
      type: deviceType,
      ipAddress: '0.0.0.0', // Будет обновлено при получении реального IP
      port: customPort ?? 53317,
      attributes: {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
      lastSeen: DateTime.now(),
      status: DeviceConnectionStatus.self,
    );
  }
}

/// Статус соединения с устройством
enum DeviceConnectionStatus {
  /// Устройство обнаружено, но не подключено
  discovered,

  /// Идет процесс подключения
  connecting,

  /// Устройство подключено
  connected,

  /// Соединение потеряно
  disconnected,

  /// Текущее устройство
  self,
}

/// Определяет тип устройства по платформе
LocalSendDeviceType _getDeviceType() {
  if (Platform.isAndroid || Platform.isIOS) {
    return LocalSendDeviceType.mobile;
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return LocalSendDeviceType.desktop;
  } else {
    return LocalSendDeviceType.unknown;
  }
}

/// Получает имя устройства по умолчанию
String _getDeviceName() {
  final platform = Platform.operatingSystem;
  final hostname = Platform.localHostname;

  return '$hostname ($platform)';
}

/// Расширения для удобства работы с LocalSendDeviceInfo
extension LocalSendDeviceInfoExtension on LocalSendDeviceInfo {
  /// Проверяет, является ли устройство доступным для подключения
  bool get isAvailable =>
      status == DeviceConnectionStatus.discovered ||
      status == DeviceConnectionStatus.disconnected;

  /// Проверяет, подключено ли устройство
  bool get isConnected => status == DeviceConnectionStatus.connected;

  /// Проверяет, является ли это текущим устройством
  bool get isSelf => status == DeviceConnectionStatus.self;

  /// Возвращает иконку для типа устройства
  String get deviceIcon {
    switch (type) {
      case LocalSendDeviceType.mobile:
        return '📱';
      case LocalSendDeviceType.desktop:
        return '💻';
      case LocalSendDeviceType.tablet:
        return '📱'; // Используем тот же значок что и для мобильного
      case LocalSendDeviceType.unknown:
        return '📡';
    }
  }

  /// Возвращает полный адрес устройства
  String get fullAddress => '$ipAddress:$port';
}
