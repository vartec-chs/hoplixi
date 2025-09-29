import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend_rc/models/message.dart';
import 'package:uuid/uuid.dart';

/// Провайдер для управления историей сообщений конкретного соединения
final messageHistoryProvider = AsyncNotifierProvider.family
    .autoDispose<MessageHistoryNotifier, List<LocalSendMessage>, String>(
      MessageHistoryNotifier.new,
    );

/// Нотификатор для управления историей сообщений
class MessageHistoryNotifier extends AsyncNotifier<List<LocalSendMessage>> {
  static const _logTag = 'MessageHistoryNotifier';
  MessageHistoryNotifier(this._remoteUri);

  final String _remoteUri;

  /// URI удаленного устройства (ключ для семейства провайдеров)
  String get remoteUri => _remoteUri;

  /// Максимальное количество сообщений в истории
  static const int _maxMessages = 1000;

  @override
  FutureOr<List<LocalSendMessage>> build() {
    logInfo(
      'Инициализация истории сообщений',
      tag: _logTag,
      data: {'remoteUri': remoteUri},
    );

    ref.onDispose(() {
      final currentMessages = state.when(
        data: (messages) => messages,
        loading: () => <LocalSendMessage>[],
        error: (_, __) => <LocalSendMessage>[],
      );
      logInfo(
        'Очистка истории сообщений',
        tag: _logTag,
        data: {'remoteUri': remoteUri, 'messageCount': currentMessages.length},
      );
    });

    return <LocalSendMessage>[];
  }

  /// Добавляет новое сообщение в историю
  void addMessage(LocalSendMessage message) {
    logInfo(
      'Добавление сообщения в историю',
      tag: _logTag,
      data: {
        'messageId': message.id,
        'sender': message.sender.name,
        'textLength': message.text.length,
        'remoteUri': remoteUri,
      },
    );

    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    final newMessages = List<LocalSendMessage>.from(currentMessages);

    // Проверяем, не существует ли уже сообщение с таким ID
    final existingIndex = newMessages.indexWhere((msg) => msg.id == message.id);
    if (existingIndex >= 0) {
      // Обновляем существующее сообщение
      newMessages[existingIndex] = message;
      logInfo(
        'Обновлено существующее сообщение',
        tag: _logTag,
        data: {'messageId': message.id},
      );
    } else {
      // Добавляем новое сообщение
      newMessages.add(message);
    }

    // Ограничиваем размер истории
    if (newMessages.length > _maxMessages) {
      final removedCount = newMessages.length - _maxMessages;
      newMessages.removeRange(0, removedCount);

      logInfo(
        'Ограничение размера истории',
        tag: _logTag,
        data: {
          'removedCount': removedCount,
          'remainingCount': newMessages.length,
        },
      );
    }

    // Сортируем по времени создания
    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    state = AsyncData(newMessages);
  }

  /// Добавляет сообщение от текущего пользователя
  void addMyMessage({
    required String username,
    required String text,
    String? id,
  }) {
    final messageId = id ?? const Uuid().v4();
    final message = LocalSendMessage.fromMe(
      id: messageId,
      username: username,
      text: text,
    );

    addMessage(message);
  }

  /// Добавляет сообщение от удаленного устройства
  void addPeerMessage({
    required String username,
    required String text,
    String? id,
    DateTime? timestamp,
  }) {
    final messageId = id ?? const Uuid().v4();
    final message = LocalSendMessage.fromPeer(
      id: messageId,
      username: username,
      text: text,
      timestamp: timestamp,
    );

    addMessage(message);
  }

  /// Добавляет системное сообщение
  void addSystemMessage({
    required String text,
    String? id,
    Map<String, dynamic>? metadata,
  }) {
    final messageId = id ?? const Uuid().v4();
    final message = LocalSendMessage.system(
      id: messageId,
      text: text,
      metadata: metadata,
    );

    addMessage(message);
  }

  /// Добавляет сообщение из Map (для совместимости с существующим кодом)
  void addMessageFromMap(Map<String, dynamic> messageMap) {
    try {
      final message = LocalSendMessage.fromMap(messageMap);
      addMessage(message);
    } catch (e, st) {
      logError(
        'Ошибка при добавлении сообщения из Map',
        error: e,
        stackTrace: st,
        tag: _logTag,
        data: {'messageMap': messageMap},
      );
    }
  }

  /// Очищает всю историю сообщений
  void clearHistory() {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    logInfo(
      'Очистка истории сообщений',
      tag: _logTag,
      data: {'clearedCount': currentMessages.length, 'remoteUri': remoteUri},
    );

    state = const AsyncData(<LocalSendMessage>[]);
  }

  /// Удаляет сообщение по ID
  void removeMessage(String messageId) {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    final newMessages = currentMessages
        .where((msg) => msg.id != messageId)
        .toList();

    if (newMessages.length != currentMessages.length) {
      logInfo(
        'Удаление сообщения',
        tag: _logTag,
        data: {'messageId': messageId},
      );

      state = AsyncData(newMessages);
    }
  }

  /// Возвращает все сообщения определенного типа
  List<LocalSendMessage> getMessagesByType(MessageType type) {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    return currentMessages.where((msg) => msg.type == type).toList();
  }

  /// Возвращает все сообщения от определенного отправителя
  List<LocalSendMessage> getMessagesBySender(MessageSender sender) {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    return currentMessages.where((msg) => msg.sender == sender).toList();
  }

  /// Возвращает последнее сообщение
  LocalSendMessage? get lastMessage {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    return currentMessages.isEmpty ? null : currentMessages.last;
  }

  /// Возвращает количество непрочитанных сообщений (от peers)
  int get unreadPeerMessagesCount {
    // В простой реализации считаем все сообщения от peer как непрочитанные
    // В будущем можно добавить поле isRead в модель сообщения
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    return currentMessages
        .where((msg) => msg.sender == MessageSender.peer)
        .length;
  }

  /// Возвращает статистику сообщений
  MessageHistoryStats get stats {
    final currentMessages = state.when(
      data: (messages) => messages,
      loading: () => <LocalSendMessage>[],
      error: (_, __) => <LocalSendMessage>[],
    );
    final totalCount = currentMessages.length;
    final myMessagesCount = currentMessages
        .where((msg) => msg.sender == MessageSender.me)
        .length;
    final peerMessagesCount = currentMessages
        .where((msg) => msg.sender == MessageSender.peer)
        .length;
    final systemMessagesCount = currentMessages
        .where((msg) => msg.sender == MessageSender.system)
        .length;

    return MessageHistoryStats(
      totalMessages: totalCount,
      myMessages: myMessagesCount,
      peerMessages: peerMessagesCount,
      systemMessages: systemMessagesCount,
      lastMessageTime: lastMessage?.timestamp,
    );
  }
}

/// Статистика истории сообщений
class MessageHistoryStats {
  final int totalMessages;
  final int myMessages;
  final int peerMessages;
  final int systemMessages;
  final DateTime? lastMessageTime;

  const MessageHistoryStats({
    required this.totalMessages,
    required this.myMessages,
    required this.peerMessages,
    required this.systemMessages,
    this.lastMessageTime,
  });

  @override
  String toString() {
    return 'MessageHistoryStats(total: $totalMessages, my: $myMessages, peer: $peerMessages, system: $systemMessages)';
  }
}
