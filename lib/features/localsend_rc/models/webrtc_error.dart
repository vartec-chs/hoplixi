import 'package:freezed_annotation/freezed_annotation.dart';

part 'webrtc_error.freezed.dart';
part 'webrtc_error.g.dart';

/// Типы ошибок WebRTC
enum WebRTCErrorType {
  /// Сетевая ошибка
  networkError,

  /// Ошибка сигналинга
  signalingError,

  /// Ошибка ICE подключения
  iceConnectionFailed,

  /// Ошибка канала данных
  dataChannelError,

  /// Таймаут операции
  timeout,

  /// Ошибка инициализации
  initializationError,

  /// Ошибка создания предложения/ответа
  sdpError,

  /// Неизвестная ошибка
  unknown,
}

/// Расширения для типов ошибок
extension WebRTCErrorTypeExtension on WebRTCErrorType {
  /// Является ли ошибка критической (не подлежит повтору)
  bool get isCritical {
    switch (this) {
      case WebRTCErrorType.initializationError:
      case WebRTCErrorType.sdpError:
        return true;
      case WebRTCErrorType.networkError:
      case WebRTCErrorType.signalingError:
      case WebRTCErrorType.iceConnectionFailed:
      case WebRTCErrorType.dataChannelError:
      case WebRTCErrorType.timeout:
      case WebRTCErrorType.unknown:
        return false;
    }
  }

  /// Можно ли повторить операцию при данной ошибке
  bool get canRetry => !isCritical;

  /// Отображаемое название ошибки
  String get displayName {
    switch (this) {
      case WebRTCErrorType.networkError:
        return 'Сетевая ошибка';
      case WebRTCErrorType.signalingError:
        return 'Ошибка сигналинга';
      case WebRTCErrorType.iceConnectionFailed:
        return 'Ошибка ICE подключения';
      case WebRTCErrorType.dataChannelError:
        return 'Ошибка канала данных';
      case WebRTCErrorType.timeout:
        return 'Превышено время ожидания';
      case WebRTCErrorType.initializationError:
        return 'Ошибка инициализации';
      case WebRTCErrorType.sdpError:
        return 'Ошибка SDP';
      case WebRTCErrorType.unknown:
        return 'Неизвестная ошибка';
    }
  }

  /// Иконка для типа ошибки
  String get icon {
    switch (this) {
      case WebRTCErrorType.networkError:
        return '🌐';
      case WebRTCErrorType.signalingError:
        return '📡';
      case WebRTCErrorType.iceConnectionFailed:
        return '🧊';
      case WebRTCErrorType.dataChannelError:
        return '📊';
      case WebRTCErrorType.timeout:
        return '⏰';
      case WebRTCErrorType.initializationError:
        return '🚫';
      case WebRTCErrorType.sdpError:
        return '📝';
      case WebRTCErrorType.unknown:
        return '❓';
    }
  }
}

/// Модель ошибки WebRTC
@freezed
abstract class WebRTCError with _$WebRTCError {
  const factory WebRTCError({
    /// Тип ошибки
    required WebRTCErrorType type,

    /// Сообщение об ошибке
    required String message,

    /// Время возникновения ошибки
    required DateTime timestamp,

    /// Дополнительные данные об ошибке
    Map<String, dynamic>? details,

    /// Стек вызовов (для отладки)
    String? stackTrace,
  }) = _WebRTCError;

  factory WebRTCError.fromJson(Map<String, dynamic> json) =>
      _$WebRTCErrorFromJson(json);

  /// Создать ошибку сети
  factory WebRTCError.network(String message, {Map<String, dynamic>? details}) {
    return WebRTCError(
      type: WebRTCErrorType.networkError,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку сигналинга
  factory WebRTCError.signaling(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return WebRTCError(
      type: WebRTCErrorType.signalingError,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку ICE подключения
  factory WebRTCError.iceConnection(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return WebRTCError(
      type: WebRTCErrorType.iceConnectionFailed,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку канала данных
  factory WebRTCError.dataChannel(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return WebRTCError(
      type: WebRTCErrorType.dataChannelError,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку таймаута
  factory WebRTCError.timeout(String message, {Map<String, dynamic>? details}) {
    return WebRTCError(
      type: WebRTCErrorType.timeout,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку инициализации
  factory WebRTCError.initialization(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return WebRTCError(
      type: WebRTCErrorType.initializationError,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку SDP
  factory WebRTCError.sdp(String message, {Map<String, dynamic>? details}) {
    return WebRTCError(
      type: WebRTCErrorType.sdpError,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать неизвестную ошибку
  factory WebRTCError.unknown(String message, {Map<String, dynamic>? details}) {
    return WebRTCError(
      type: WebRTCErrorType.unknown,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
  }

  /// Создать ошибку из исключения
  factory WebRTCError.fromException(
    Exception exception, {
    WebRTCErrorType? type,
    Map<String, dynamic>? details,
  }) {
    return WebRTCError(
      type: type ?? WebRTCErrorType.unknown,
      message: exception.toString(),
      timestamp: DateTime.now(),
      details: details,
      stackTrace: StackTrace.current.toString(),
    );
  }
}

/// Расширения для WebRTCError
extension WebRTCErrorExtension on WebRTCError {
  /// Получить полное описание ошибки
  String get fullDescription {
    final typeDescription = type.displayName;
    return '$typeDescription: $message';
  }

  /// Получить пользовательское сообщение об ошибке
  String get userMessage {
    switch (type) {
      case WebRTCErrorType.networkError:
        return 'Проверьте подключение к интернету и попробуйте снова';
      case WebRTCErrorType.signalingError:
        return 'Не удалось установить связь с устройством';
      case WebRTCErrorType.iceConnectionFailed:
        return 'Не удалось установить прямое соединение';
      case WebRTCErrorType.dataChannelError:
        return 'Ошибка передачи данных';
      case WebRTCErrorType.timeout:
        return 'Превышено время ожидания подключения';
      case WebRTCErrorType.initializationError:
        return 'Не удалось инициализировать соединение';
      case WebRTCErrorType.sdpError:
        return 'Ошибка конфигурации соединения';
      case WebRTCErrorType.unknown:
        return 'Произошла неизвестная ошибка';
    }
  }

  /// Можно ли показать техническую информацию пользователю
  bool get canShowTechnicalDetails => details != null && details!.isNotEmpty;

  /// Получить время с момента возникновения ошибки
  Duration get age => DateTime.now().difference(timestamp);
}
