import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Тип сообщения в LocalSend
enum MessageType {
  /// Текстовое сообщение
  text,

  /// Системное сообщение (уведомления о соединении и т.д.)
  system,
}

/// Сообщение между устройствами
@freezed
abstract class LocalSendMessage with _$LocalSendMessage {
  const factory LocalSendMessage({
    /// Уникальный идентификатор сообщения
    required String id,

    /// ID устройства-отправителя
    required String senderId,

    /// ID устройства-получателя
    required String receiverId,

    /// Тип сообщения
    required MessageType type,

    /// Текст сообщения
    required String content,

    /// Временная метка отправки
    required DateTime timestamp,

    /// Статус доставки сообщения
    @Default(MessageDeliveryStatus.sending) MessageDeliveryStatus status,

    /// Дополнительные метаданные
    Map<String, dynamic>? metadata,
  }) = _LocalSendMessage;

  factory LocalSendMessage.fromJson(Map<String, dynamic> json) =>
      _$LocalSendMessageFromJson(json);

  /// Создает новое текстовое сообщение
  factory LocalSendMessage.text({
    required String senderId,
    required String receiverId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return LocalSendMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Создает системное сообщение
  factory LocalSendMessage.system({
    required String senderId,
    required String receiverId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return LocalSendMessage(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.system,
      content: content,
      timestamp: DateTime.now(),
      status: MessageDeliveryStatus
          .delivered, // Системные сообщения считаются сразу доставленными
      metadata: metadata,
    );
  }
}

/// Статус доставки сообщения
enum MessageDeliveryStatus {
  /// Сообщение отправляется
  sending,

  /// Сообщение отправлено
  sent,

  /// Сообщение доставлено
  delivered,

  /// Ошибка отправки
  failed,
}

/// Расширения для удобства работы с сообщениями
extension LocalSendMessageExtension on LocalSendMessage {
  /// Проверяет, является ли сообщение исходящим для данного устройства
  bool isOutgoing(String currentDeviceId) => senderId == currentDeviceId;

  /// Проверяет, является ли сообщение входящим для данного устройства
  bool isIncoming(String currentDeviceId) => receiverId == currentDeviceId;

  /// Проверяет, успешно ли доставлено сообщение
  bool get isDelivered => status == MessageDeliveryStatus.delivered;

  /// Проверяет, есть ли ошибка доставки
  bool get hasFailed => status == MessageDeliveryStatus.failed;

  /// Возвращает иконку статуса доставки
  String get statusIcon {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return '⏳';
      case MessageDeliveryStatus.sent:
        return '✓';
      case MessageDeliveryStatus.delivered:
        return '✓✓';
      case MessageDeliveryStatus.failed:
        return '❌';
    }
  }

  /// Форматирует время отправки для отображения
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'сейчас';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
