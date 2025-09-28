import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend_beta/models/message.dart';
import 'package:hoplixi/features/localsend_beta/providers/webrtc_provider.dart';

const _logTag = 'MessageProvider';

/// Provider для управления сообщениями
final messageProvider =
    AsyncNotifierProvider.autoDispose<MessageNotifier, List<LocalSendMessage>>(
      MessageNotifier.new,
    );

/// Notifier для управления сообщениями
class MessageNotifier extends AsyncNotifier<List<LocalSendMessage>> {
  final List<LocalSendMessage> _messages = [];
  StreamSubscription<LocalSendMessage>? _messageSubscription;

  @override
  Future<List<LocalSendMessage>> build() async {
    final webrtcService = ref.read(webrtcServiceProvider);

    // Подписываемся на входящие сообщения
    _messageSubscription = webrtcService.incomingMessages.listen(
      _onMessageReceived,
    );

    ref.onDispose(() {
      _messageSubscription?.cancel();
    });

    return _messages;
  }

  /// Добавляет сообщение в список
  void addMessage(LocalSendMessage message) {
    _messages.add(message);
    state = AsyncData(List.from(_messages));

    logInfo(
      'Сообщение добавлено',
      tag: _logTag,
      data: {
        'type': message.type.name,
        'senderId': message.senderId,
        'isOutgoing': message.senderId == _getCurrentDeviceId(),
      },
    );
  }

  /// Очищает все сообщения
  void clearMessages() {
    _messages.clear();
    state = const AsyncData([]);
    logInfo('Сообщения очищены', tag: _logTag);
  }

  /// Получает все сообщения для определенного соединения
  List<LocalSendMessage> getMessagesForConnection(String connectionId) {
    // В реальном приложении можно фильтровать сообщения по connectionId
    // Сейчас возвращаем все сообщения
    return _messages;
  }

  /// Обрабатывает входящие сообщения
  void _onMessageReceived(LocalSendMessage message) {
    addMessage(message);
  }

  /// Получает ID текущего устройства (заглушка)
  String? _getCurrentDeviceId() {
    // В реальном приложении нужно получить ID текущего устройства
    // Для упрощения возвращаем null
    return null;
  }
}
