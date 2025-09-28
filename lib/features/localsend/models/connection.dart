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

    /// IP адрес удаленного устройства
    required String remoteIp,

    /// Порт удаленного устройства
    required int remotePort,

    /// Роль в соединении
    required WebRTCRole role,

    /// Состояние соединения
    @Default(WebRTCConnectionState.initializing) WebRTCConnectionState state,

    /// WebRTC PeerConnection
    @JsonKey(includeFromJson: false, includeToJson: false)
    RTCPeerConnection? peerConnection,

    /// DataChannel для передачи файлов и сообщений
    @JsonKey(includeFromJson: false, includeToJson: false)
    RTCDataChannel? dataChannel,

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
