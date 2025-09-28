# Система истории сообщений LocalSend

## Обзор

Реализована полная система истории сообщений для LocalSend с использованием Riverpod v3. Система автоматически записывает все входящие и исходящие сообщения в типизированную модель данных и предоставляет удобный API для работы с историей.

## Компоненты

### 1. Модель сообщения (`message.dart`)

```dart
/// Тип сообщения в чате
enum MessageType {
  text,       // Обычное текстовое сообщение
  system,     // Системное уведомление
  fileTransfer, // Уведомление о передаче файла
}

/// Отправитель сообщения
enum MessageSender {
  me,      // Сообщение от текущего пользователя
  peer,    // Сообщение от удаленного устройства
  system,  // Системное сообщение
}

/// Модель сообщения с Freezed
class LocalSendMessage {
  final String id;
  final MessageSender sender;
  final String username;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;
}
```

**Особенности:**
- Неизменяемая модель с Freezed
- Конструкторы-фабрики для разных типов сообщений
- Совместимость с существующим кодом через `fromMap()`
- Автоматическое форматирование времени

### 2. Провайдер истории сообщений (`message_history_provider.dart`)

```dart
/// Провайдер для управления историей сообщений конкретного соединения
final messageHistoryProvider = AsyncNotifierProvider.family
    .autoDispose<MessageHistoryNotifier, List<LocalSendMessage>, String>(
      MessageHistoryNotifier.new,
    );
```

**Возможности:**
- Семейство провайдеров по remoteUri
- Автоматическая очистка при dispose
- Ограничение размера истории (1000 сообщений)
- Автоматическая сортировка по времени
- Дедупликация по ID сообщения

**API методы:**
```dart
// Добавление сообщений
void addMyMessage({required String username, required String text, String? id});
void addPeerMessage({required String username, required String text, String? id, DateTime? timestamp});
void addSystemMessage({required String text, String? id, Map<String, dynamic>? metadata});
void addMessageFromMap(Map<String, dynamic> messageMap); // Совместимость

// Управление историей
void clearHistory();
void removeMessage(String messageId);

// Получение данных
List<LocalSendMessage> getMessagesByType(MessageType type);
List<LocalSendMessage> getMessagesBySender(MessageSender sender);
LocalSendMessage? get lastMessage;
int get unreadPeerMessagesCount;
MessageHistoryStats get stats;
```

### 3. Интеграция с WebRTC (`webrtc_provider.dart`)

Система автоматически записывает все сообщения в историю:

```dart
// При получении сообщения
void _addMessageToHistory(Map<String, dynamic> messageData) {
  try {
    final messageHistoryNotifier = ref.read(
      messageHistoryProvider(_remoteUriOrEmpty).notifier,
    );
    messageHistoryNotifier.addMessageFromMap(messageData);
  } catch (e) {
    logError('Ошибка при добавлении сообщения в историю', error: e, tag: _logTag);
  }
}
```

**Интеграция точки входа:**
- Входящие сообщения через DataChannel автоматически записываются
- Исходящие сообщения через `sendDataChannelJson()` автоматически записываются
- Системные уведомления о состоянии канала записываются
- Fallback сообщения через signaling записываются

### 4. Обновленный ChatTab

UI полностью переработан для использования провайдера истории:

```dart
Widget _buildMessagesList() {
  return Consumer(
    builder: (context, ref, child) {
      final messagesAsync = ref.watch(messageHistoryProvider(widget.remoteUri));
      
      return messagesAsync.when(
        data: (messages) {
          // Отображение списка сообщений
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          );
        },
        loading: () => CircularProgressIndicator(),
        error: (error, _) => ErrorWidget(error),
      );
    },
  );
}
```

## Использование

### Просмотр истории сообщений

```dart
class MessageHistoryPage extends ConsumerWidget {
  final String remoteUri;
  
  const MessageHistoryPage({required this.remoteUri});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messageHistoryProvider(remoteUri));
    
    return messagesAsync.when(
      data: (messages) => ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            title: Text(message.text),
            subtitle: Text(message.formattedTime),
            leading: Icon(
              message.isFromMe ? Icons.send : Icons.inbox,
              color: message.isFromMe ? Colors.blue : Colors.green,
            ),
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Ошибка: $error'),
    );
  }
}
```

### Ручное добавление сообщений

```dart
final messageNotifier = ref.read(messageHistoryProvider(remoteUri).notifier);

// Добавить сообщение от пользователя
messageNotifier.addMyMessage(
  username: 'Алексей',
  text: 'Привет!',
);

// Добавить системное уведомление
messageNotifier.addSystemMessage(
  text: 'Соединение установлено',
  metadata: {'connectionType': 'WebRTC'},
);
```

### Статистика сообщений

```dart
final stats = ref.read(messageHistoryProvider(remoteUri).notifier).stats;
print('Всего сообщений: ${stats.totalMessages}');
print('Моих сообщений: ${stats.myMessages}');
print('Сообщений собеседника: ${stats.peerMessages}');
print('Системных сообщений: ${stats.systemMessages}');
```

## Архитектурные особенности

### 1. Типобезопасность
Вся система полностью типизирована с использованием Freezed, что исключает ошибки времени выполнения.

### 2. Производительность
- AsyncNotifier обеспечивает реактивные обновления UI
- Автоматическая дедупликация предотвращает дублирование сообщений
- Ограничение размера истории предотвращает утечки памяти

### 3. Совместимость
Система полностью совместима с существующим кодом благодаря методу `fromMap()` и сохранению всех существующих интерфейсов.

### 4. Расширяемость
- Легко добавлять новые типы сообщений
- Поддержка метаданных для будущих функций
- Модульная архитектура позволяет легко модифицировать компоненты

### 5. Отказоустойчивость
- Graceful обработка ошибок во всех компонентах
- Автоматическое восстановление состояния при ошибках
- Детальное логирование всех операций

## Будущие улучшения

1. **Постоянное хранение**: Интеграция с SQLite для сохранения истории между сессиями
2. **Поиск по сообщениям**: Добавление полнотекстового поиска
3. **Статус прочтения**: Отслеживание прочитанных/непрочитанных сообщений
4. **Шифрование**: End-to-end шифрование истории сообщений
5. **Синхронизация**: Синхронизация истории между устройствами

Система полностью готова к использованию и легко расширяется для будущих потребностей.