import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Тип сообщения в чате
enum MessageType {
  /// Обычное текстовое сообщение
  text,

  /// Системное уведомление
  system,

  /// Уведомление о передаче файла
  fileTransfer,
}

/// Отправитель сообщения
enum MessageSender {
  /// Сообщение от текущего пользователя
  me,

  /// Сообщение от удаленного устройства
  peer,

  /// Системное сообщение
  system,
}

/// Модель сообщения в чате LocalSend
@freezed
abstract class LocalSendMessage with _$LocalSendMessage {
  const factory LocalSendMessage({
    /// Уникальный идентификатор сообщения
    required String id,

    /// Отправитель сообщения
    required MessageSender sender,

    /// Имя пользователя-отправителя
    required String username,

    /// Текст сообщения
    required String text,

    /// Временная метка создания сообщения
    required DateTime timestamp,

    /// Тип сообщения
    @Default(MessageType.text) MessageType type,

    /// Дополнительные метаданные сообщения
    Map<String, dynamic>? metadata,
  }) = _LocalSendMessage;

  factory LocalSendMessage.fromJson(Map<String, dynamic> json) =>
      _$LocalSendMessageFromJson(json);

  /// Создает текстовое сообщение от текущего пользователя
  factory LocalSendMessage.fromMe({
    required String id,
    required String username,
    required String text,
    DateTime? timestamp,
  }) {
    return LocalSendMessage(
      id: id,
      sender: MessageSender.me,
      username: username,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.text,
    );
  }

  /// Создает текстовое сообщение от удаленного устройства
  factory LocalSendMessage.fromPeer({
    required String id,
    required String username,
    required String text,
    DateTime? timestamp,
  }) {
    return LocalSendMessage(
      id: id,
      sender: MessageSender.peer,
      username: username,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.text,
    );
  }

  /// Создает системное сообщение
  factory LocalSendMessage.system({
    required String id,
    required String text,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LocalSendMessage(
      id: id,
      sender: MessageSender.system,
      username: 'system',
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.system,
      metadata: metadata,
    );
  }

  /// Создает сообщение из Map (для совместимости с существующим кодом)
  factory LocalSendMessage.fromMap(Map<String, dynamic> map) {
    final fromString = map['from'] as String? ?? 'peer';
    final sender = switch (fromString) {
      'me' => MessageSender.me,
      'system' => MessageSender.system,
      _ => MessageSender.peer,
    };

    final type = sender == MessageSender.system
        ? MessageType.system
        : MessageType.text;

    DateTime timestamp;
    try {
      final tsString = map['ts'] as String?;
      timestamp = tsString != null ? DateTime.parse(tsString) : DateTime.now();
    } catch (e) {
      timestamp = DateTime.now();
    }

    return LocalSendMessage(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sender: sender,
      username: map['username']?.toString() ?? 'Unknown',
      text: map['text']?.toString() ?? '',
      timestamp: timestamp,
      type: type,
    );
  }
}

/// Расширения для удобства работы с LocalSendMessage
extension LocalSendMessageExtension on LocalSendMessage {
  /// Преобразует сообщение в Map для отправки через DataChannel
  Map<String, dynamic> toDataChannelMap() {
    return {
      'id': id,
      'username': username,
      'text': text,
      'ts': timestamp.toIso8601String(),
    };
  }

  /// Преобразует сообщение в Map для совместимости с существующим кодом
  Map<String, dynamic> toCompatibilityMap() {
    return {
      'from': sender.name,
      'id': id,
      'username': username,
      'text': text,
      'ts': timestamp.toIso8601String(),
    };
  }

  /// Проверяет, является ли сообщение от текущего пользователя
  bool get isFromMe => sender == MessageSender.me;

  /// Проверяет, является ли сообщение системным
  bool get isSystemMessage => sender == MessageSender.system;

  /// Возвращает отформатированное время
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
