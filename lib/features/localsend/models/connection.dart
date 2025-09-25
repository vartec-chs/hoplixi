import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

/// Состояние WebRTC соединения
enum WebRTCConnectionState {
  /// Соединение инициализируется
  initializing,

  /// Ожидание подключения
  connecting,

  /// Соединение установлено
  connected,

  /// Соединение разрывается
  disconnecting,

  /// Соединение разорвано
  disconnected,

  /// Ошибка соединения
  failed,
}

/// Роль устройства в WebRTC соединении
enum WebRTCRole {
  /// Инициатор соединения (создает offer)
  caller,

  /// Принимающий соединение (создает answer)
  callee,
}

/// Тип WebRTC сигнала для обмена через HTTP
enum SignalingMessageType {
  /// SDP offer
  offer,

  /// SDP answer
  answer,

  /// ICE кандидат
  iceCandidate,

  /// Пинг для проверки соединения
  ping,

  /// Запрос на завершение соединения
  bye,
}

/// Сообщение для WebRTC сигналинга
@freezed
abstract class SignalingMessage with _$SignalingMessage {
  const factory SignalingMessage({
    /// Тип сообщения
    required SignalingMessageType type,

    /// ID отправителя
    required String fromDeviceId,

    /// ID получателя
    required String toDeviceId,

    /// Данные сообщения (SDP, ICE candidate и т.д.)
    required Map<String, dynamic> data,

    /// Временная метка
    required DateTime timestamp,

    /// Уникальный идентификатор сообщения
    required String messageId,
  }) = _SignalingMessage;

  factory SignalingMessage.fromJson(Map<String, dynamic> json) =>
      _$SignalingMessageFromJson(json);
}

/// Информация о WebRTC соединении
@freezed
abstract class WebRTCConnection with _$WebRTCConnection {
  const factory WebRTCConnection({
    /// ID соединения
    required String connectionId,

    /// ID локального устройства
    required String localDeviceId,

    /// ID удаленного устройства
    required String remoteDeviceId,

    /// Роль в соединении
    required WebRTCRole role,

    /// Состояние соединения
    @Default(WebRTCConnectionState.initializing) WebRTCConnectionState state,

    /// Время создания соединения
    required DateTime createdAt,

    /// Время последней активности
    DateTime? lastActivity,

    /// Статистика соединения
    Map<String, dynamic>? stats,

    /// Сообщение об ошибке (если есть)
    String? errorMessage,
  }) = _WebRTCConnection;

  factory WebRTCConnection.fromJson(Map<String, dynamic> json) =>
      _$WebRTCConnectionFromJson(json);
}

/// Конфигурация для WebRTC
class WebRTCConfig {
  /// ICE серверы для STUN/TURN
  static const List<Map<String, dynamic>> iceServers = [
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
    },
  ];

  /// Настройки для DataChannel
  static RTCDataChannelInit get dataChannelConfig => RTCDataChannelInit()
    ..id = 1
    ..ordered = true
    ..protocol = 'sctp'
    ..negotiated = false;

  /// Размер чанка для передачи файлов (64KB)
  static const int fileChunkSize = 64 * 1024;

  /// Максимальное количество одновременных передач файлов
  static const int maxConcurrentTransfers = 3;

  /// Таймаут для WebRTC соединения в секундах
  static const int connectionTimeout = 30;

  /// Интервал пинга для поддержания соединения в секундах
  static const int pingInterval = 10;
}

/// Расширения для удобства работы с соединениями
extension WebRTCConnectionExtension on WebRTCConnection {
  /// Проверяет, активно ли соединение
  bool get isActive => state == WebRTCConnectionState.connected;

  /// Проверяет, есть ли ошибка соединения
  bool get hasFailed => state == WebRTCConnectionState.failed;

  /// Проверяет, находится ли соединение в процессе установки
  bool get isConnecting =>
      state == WebRTCConnectionState.connecting ||
      state == WebRTCConnectionState.initializing;

  /// Проверяет, завершено ли соединение
  bool get isDisconnected => state == WebRTCConnectionState.disconnected;

  /// Возвращает иконку состояния соединения
  String get stateIcon {
    switch (state) {
      case WebRTCConnectionState.initializing:
      case WebRTCConnectionState.connecting:
        return '🔄';
      case WebRTCConnectionState.connected:
        return '🟢';
      case WebRTCConnectionState.disconnecting:
        return '🔶';
      case WebRTCConnectionState.disconnected:
        return '⚪';
      case WebRTCConnectionState.failed:
        return '🔴';
    }
  }

  /// Возвращает текстовое описание состояния
  String get stateDescription {
    switch (state) {
      case WebRTCConnectionState.initializing:
        return 'Инициализация';
      case WebRTCConnectionState.connecting:
        return 'Подключение';
      case WebRTCConnectionState.connected:
        return 'Подключено';
      case WebRTCConnectionState.disconnecting:
        return 'Отключение';
      case WebRTCConnectionState.disconnected:
        return 'Отключено';
      case WebRTCConnectionState.failed:
        return 'Ошибка';
    }
  }

  /// Проверяет, является ли это исходящим соединением
  bool get isOutgoing => role == WebRTCRole.caller;

  /// Проверяет, является ли это входящим соединением
  bool get isIncoming => role == WebRTCRole.callee;

  /// Вычисляет время жизни соединения
  Duration get connectionDuration {
    final endTime = lastActivity ?? DateTime.now();
    return endTime.difference(createdAt);
  }
}
