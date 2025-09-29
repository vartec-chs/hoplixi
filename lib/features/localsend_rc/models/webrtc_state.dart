import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/localsend_rc/models/webrtc_error.dart';

part 'webrtc_state.freezed.dart';
part 'webrtc_state.g.dart';

/// Состояния WebRTC соединения
enum WebRTCConnectionState {
  /// Не инициализировано
  idle,

  /// Инициализация
  initializing,

  /// Подключение
  connecting,

  /// Подключено
  connected,

  /// Отключение
  disconnecting,

  /// Отключено
  disconnected,

  /// Ошибка подключения
  failed,

  /// Переподключение
  reconnecting,
}

/// Расширения для работы с состояниями WebRTC
extension WebRTCConnectionStateExtension on WebRTCConnectionState {
  /// Является ли состояние активным (подключение в процессе или установлено)
  bool get isActive {
    switch (this) {
      case WebRTCConnectionState.connecting:
      case WebRTCConnectionState.connected:
      case WebRTCConnectionState.reconnecting:
        return true;
      default:
        return false;
    }
  }

  /// Является ли состояние конечным (успех или неудача)
  bool get isTerminal {
    switch (this) {
      case WebRTCConnectionState.connected:
      case WebRTCConnectionState.failed:
      case WebRTCConnectionState.disconnected:
        return true;
      default:
        return false;
    }
  }

  /// Можно ли инициировать переподключение
  bool get canReconnect {
    switch (this) {
      case WebRTCConnectionState.failed:
      case WebRTCConnectionState.disconnected:
        return true;
      default:
        return false;
    }
  }

  /// Отображаемое название состояния
  String get displayName {
    switch (this) {
      case WebRTCConnectionState.idle:
        return 'Не активно';
      case WebRTCConnectionState.initializing:
        return 'Инициализация...';
      case WebRTCConnectionState.connecting:
        return 'Подключение...';
      case WebRTCConnectionState.connected:
        return 'Подключено';
      case WebRTCConnectionState.disconnecting:
        return 'Отключение...';
      case WebRTCConnectionState.disconnected:
        return 'Отключено';
      case WebRTCConnectionState.failed:
        return 'Ошибка подключения';
      case WebRTCConnectionState.reconnecting:
        return 'Переподключение...';
    }
  }

  /// Иконка для состояния
  String get icon {
    switch (this) {
      case WebRTCConnectionState.idle:
        return '⚪';
      case WebRTCConnectionState.initializing:
        return '🔄';
      case WebRTCConnectionState.connecting:
        return '🟡';
      case WebRTCConnectionState.connected:
        return '🟢';
      case WebRTCConnectionState.disconnecting:
        return '🟠';
      case WebRTCConnectionState.disconnected:
        return '⚫';
      case WebRTCConnectionState.failed:
        return '🔴';
      case WebRTCConnectionState.reconnecting:
        return '🔄';
    }
  }
}

/// Детализированное состояние WebRTC соединения
@freezed
abstract class WebRTCConnectionStatus with _$WebRTCConnectionStatus {
  const factory WebRTCConnectionStatus({
    /// Текущее состояние соединения
    required WebRTCConnectionState state,

    /// Ошибка подключения (если есть)
    WebRTCError? error,

    /// Время последнего изменения состояния
    DateTime? lastStateChange,

    /// Количество попыток переподключения
    @Default(0) int reconnectAttempts,

    /// Длительность подключения (для подключенного состояния)
    Duration? connectionDuration,

    /// Время начала подключения
    DateTime? connectionStartTime,

    /// Дополнительные данные состояния
    Map<String, dynamic>? metadata,
  }) = _WebRTCConnectionStatus;

  factory WebRTCConnectionStatus.fromJson(Map<String, dynamic> json) =>
      _$WebRTCConnectionStatusFromJson(json);
}

/// Расширения для WebRTCConnectionStatus
extension WebRTCConnectionStatusExtension on WebRTCConnectionStatus {
  /// Создать новое состояние с обновленным статусом
  WebRTCConnectionStatus copyWithState(
    WebRTCConnectionState newState, {
    WebRTCError? error,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();

    return copyWith(
      state: newState,
      error: error,
      lastStateChange: now,
      connectionStartTime: newState == WebRTCConnectionState.connecting
          ? now
          : connectionStartTime,
      connectionDuration:
          newState == WebRTCConnectionState.connected &&
              connectionStartTime != null
          ? now.difference(connectionStartTime!)
          : connectionDuration,
      metadata: metadata,
    );
  }

  /// Увеличить счетчик попыток переподключения
  WebRTCConnectionStatus incrementReconnectAttempts() {
    return copyWith(reconnectAttempts: reconnectAttempts + 1);
  }

  /// Сбросить счетчик попыток переподключения
  WebRTCConnectionStatus resetReconnectAttempts() {
    return copyWith(reconnectAttempts: 0);
  }

  /// Получить время с последнего изменения состояния
  Duration? get timeSinceLastChange {
    if (lastStateChange == null) return null;
    return DateTime.now().difference(lastStateChange!);
  }

  /// Проверить, есть ли активная ошибка
  bool get hasError => error != null;

  /// Получить человекочитаемое описание состояния
  String get description {
    final baseDescription = state.displayName;

    if (hasError) {
      return '$baseDescription: ${error!.message}';
    }

    if (state == WebRTCConnectionState.connected &&
        connectionDuration != null) {
      final duration = connectionDuration!;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$baseDescription (${minutes}м ${seconds}с)';
    }

    if (reconnectAttempts > 0) {
      return '$baseDescription (попытка $reconnectAttempts)';
    }

    return baseDescription;
  }
}
