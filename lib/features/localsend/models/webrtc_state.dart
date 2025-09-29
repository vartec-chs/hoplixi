import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'webrtc_state.freezed.dart';

@freezed
abstract class WebrtcState with _$WebrtcState {
  const factory WebrtcState({
    required RTCPeerConnectionState pcState, // состояние PeerConnection
    required RTCIceConnectionState iceState, // состояние ICE соединения
    required RTCDataChannelState dcState, // состояние DataChannel
    required List<Map<String, dynamic>> messages,
    required bool isConnected,
  }) = _WebrtcState;

  factory WebrtcState.initial() => const WebrtcState(
    pcState: RTCPeerConnectionState.RTCPeerConnectionStateNew,
    iceState: RTCIceConnectionState.RTCIceConnectionStateNew,
    dcState: RTCDataChannelState.RTCDataChannelClosed,
    messages: [],
    isConnected: false,
  );
}

/// Расширения для RTCPeerConnectionState
extension RTCPeerConnectionStateExtension on RTCPeerConnectionState {
  /// Отображаемое название состояния
  String get displayName {
    switch (this) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return 'Новое соединение';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return 'Подключение...';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return 'Подключено';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return 'Отключено';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return 'Ошибка';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return 'Закрыто';
    }
  }

  /// Иконка для состояния
  String get icon {
    switch (this) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return '⚪';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return '🟡';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return '🟢';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return '🟠';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return '🔴';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return '⚫';
    }
  }

  /// Является ли состояние активным
  bool get isActive {
    return this == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
        this == RTCPeerConnectionState.RTCPeerConnectionStateConnecting;
  }

  /// Является ли состояние успешным
  bool get isSuccess =>
      this == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// Является ли состояние ошибочным
  bool get isError =>
      this == RTCPeerConnectionState.RTCPeerConnectionStateFailed;
}

/// Расширения для RTCIceConnectionState
extension RTCIceConnectionStateExtension on RTCIceConnectionState {
  /// Отображаемое название состояния
  String get displayName {
    switch (this) {
      case RTCIceConnectionState.RTCIceConnectionStateNew:
        return 'ICE: Новое';
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        return 'ICE: Проверка...';
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return 'ICE: Подключено';
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        return 'ICE: Завершено';
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        return 'ICE: Ошибка';
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return 'ICE: Отключено';
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        return 'ICE: Закрыто';
      default:
        return 'ICE: Неизвестно';
    }
  }

  /// Иконка для состояния
  String get icon {
    switch (this) {
      case RTCIceConnectionState.RTCIceConnectionStateNew:
        return '⚪';
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        return '🔄';
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return '🟢';
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        return '✅';
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        return '🔴';
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return '🟠';
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        return '⚫';
      default:
        return '❓';
    }
  }

  /// Является ли состояние активным
  bool get isActive {
    return this == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        this == RTCIceConnectionState.RTCIceConnectionStateChecking ||
        this == RTCIceConnectionState.RTCIceConnectionStateCompleted;
  }

  /// Является ли состояние успешным
  bool get isSuccess {
    return this == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        this == RTCIceConnectionState.RTCIceConnectionStateCompleted;
  }

  /// Является ли состояние ошибочным
  bool get isError => this == RTCIceConnectionState.RTCIceConnectionStateFailed;
}

/// Расширения для RTCDataChannelState
extension RTCDataChannelStateExtension on RTCDataChannelState {
  /// Отображаемое название состояния
  String get displayName {
    switch (this) {
      case RTCDataChannelState.RTCDataChannelConnecting:
        return 'Канал: Подключение...';
      case RTCDataChannelState.RTCDataChannelOpen:
        return 'Канал: Открыт';
      case RTCDataChannelState.RTCDataChannelClosing:
        return 'Канал: Закрытие...';
      case RTCDataChannelState.RTCDataChannelClosed:
        return 'Канал: Закрыт';
    }
  }

  /// Иконка для состояния
  String get icon {
    switch (this) {
      case RTCDataChannelState.RTCDataChannelConnecting:
        return '🟡';
      case RTCDataChannelState.RTCDataChannelOpen:
        return '🟢';
      case RTCDataChannelState.RTCDataChannelClosing:
        return '🟠';
      case RTCDataChannelState.RTCDataChannelClosed:
        return '⚫';
    }
  }

  /// Является ли канал открытым для отправки данных
  bool get canSend => this == RTCDataChannelState.RTCDataChannelOpen;

  /// Является ли состояние активным
  bool get isActive =>
      this == RTCDataChannelState.RTCDataChannelOpen ||
      this == RTCDataChannelState.RTCDataChannelConnecting;
}

/// Расширения для WebrtcState
extension WebrtcStateExtension on WebrtcState {
  /// Общее отображаемое состояние соединения
  String get overallStatus {
    if (isConnected && dcState.canSend) {
      return 'Подключено и готово';
    } else if (isConnected) {
      return 'Подключено, ожидание канала';
    } else if (pcState.isActive || iceState.isActive) {
      return 'Подключение...';
    } else if (pcState.isError || iceState.isError) {
      return 'Ошибка подключения';
    } else {
      return 'Не подключено';
    }
  }

  /// Общая иконка состояния
  String get overallIcon {
    if (isConnected && dcState.canSend) {
      return '🟢';
    } else if (isConnected) {
      return '🟡';
    } else if (pcState.isActive || iceState.isActive) {
      return '🔄';
    } else if (pcState.isError || iceState.isError) {
      return '🔴';
    } else {
      return '⚪';
    }
  }

  /// Готов ли к отправке сообщений
  bool get isReadyToSend => isConnected && dcState.canSend;

  /// Есть ли сообщения
  bool get hasMessages => messages.isNotEmpty;

  /// Количество сообщений
  int get messageCount => messages.length;

  /// Последнее сообщение (если есть)
  Map<String, dynamic>? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  /// Сообщения от текущего пользователя
  List<Map<String, dynamic>> get myMessages =>
      messages.where((msg) => msg['from'] == 'me').toList();

  /// Сообщения от peer
  List<Map<String, dynamic>> get peerMessages =>
      messages.where((msg) => msg['from'] == 'peer').toList();

  /// Системные сообщения
  List<Map<String, dynamic>> get systemMessages =>
      messages.where((msg) => msg['from'] == 'system').toList();

  /// Детальная информация о состоянии
  String get detailedStatus {
    return '''
PeerConnection: ${pcState.displayName} ${pcState.icon}
ICE: ${iceState.displayName} ${iceState.icon}
DataChannel: ${dcState.displayName} ${dcState.icon}
Подключено: ${isConnected ? 'Да' : 'Нет'}
Сообщений: $messageCount
Готов к отправке: ${isReadyToSend ? 'Да' : 'Нет'}
'''
        .trim();
  }

  /// Краткая сводка для UI
  String get statusSummary {
    final status = overallStatus;
    final icon = overallIcon;
    final msgCount = hasMessages ? ' ($messageCount)' : '';
    return '$icon $status$msgCount';
  }
}
