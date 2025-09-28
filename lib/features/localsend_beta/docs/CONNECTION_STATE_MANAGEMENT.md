# Улучшенная система управления состояниями WebRTC соединений

## Проблема

Первоначальная реализация не корректно обрабатывала асинхронные изменения состояний WebRTC соединений. Устройства могли подключаться с задержкой, но UI не отражал промежуточные состояния правильно.

## Решение

### 1. Расширенный CurrentConnectionNotifier

```dart
class CurrentConnectionNotifier extends Notifier<WebRTCConnection?> {
  // Методы для проверки состояний
  bool get isConnecting => state?.state == WebRTCConnectionState.connecting;
  bool get isConnected => state?.state == WebRTCConnectionState.connected;
  bool get isFailed => state?.state == WebRTCConnectionState.failed;
  bool get isDisconnected => state?.state == WebRTCConnectionState.disconnected;
  
  // Обновление состояния конкретного соединения
  void updateConnectionState(String connectionId, WebRTCConnectionState newState) {
    if (state?.connectionId == connectionId) {
      state = state!.copyWith(state: newState);
    }
  }
  
  // Текстовые и цветовые представления состояний
  String get connectionStatusText { ... }
  ConnectionStatusColor get connectionStatusColor { ... }
}
```

### 2. Улучшенная обработка событий в WebRTCConnectionNotifier

```dart
void _onConnectionStateChanged(WebRTCConnection connection) {
  // Обновляем список соединений
  final currentConnections = _webrtcService.activeConnections;
  state = AsyncData(currentConnections);

  // Обновляем текущее соединение если оно совпадает
  final currentConnectionNotifier = ref.read(currentConnectionProvider.notifier);
  if (currentConnectionNotifier.isCurrentConnection(connection.connectionId)) {
    currentConnectionNotifier.updateConnectionState(connection.connectionId, connection.state);
  }

  // Автоматически устанавливаем как текущее при успешном подключении
  if (connection.state == WebRTCConnectionState.connected && 
      !currentConnectionNotifier.hasActiveConnection) {
    _setCurrentConnection(connection);
  }

  // Убираем из текущего при разрыве соединения
  if ((connection.state == WebRTCConnectionState.disconnected ||
       connection.state == WebRTCConnectionState.failed ||
       connection.state == WebRTCConnectionState.disconnecting) &&
      currentConnectionNotifier.isCurrentConnection(connection.connectionId)) {
    currentConnectionNotifier.clearConnection();
  }
}
```

### 3. Улучшенная инициализация соединения в TransceiverScreen

```dart
Future<void> _initializeConnection() async {
  if (_isConnecting || widget.deviceInfo == null) return;

  setState(() => _isConnecting = true);

  try {
    // Инициируем соединение
    final connectionId = await webrtcNotifier.connectToDevice(
      localDeviceId: selfDevice.id,
      targetDevice: widget.deviceInfo!,
    );

    if (connectionId != null) {
      setState(() => _connectionId = connectionId);
      
      // Показываем состояние ожидания
      ToastHelper.info(
        title: 'Подключение к ${widget.deviceInfo!.name}',
        description: 'Ожидание установки соединения...',
      );
      
      // Начинаем слушать изменения состояния
      _listenToConnectionChanges(connectionId);
    }
  } catch (e) {
    // Обработка ошибок
  } finally {
    setState(() => _isConnecting = false);
  }
}
```

### 4. Реактивное отслеживание изменений состояния

```dart
void _listenToConnectionChanges(String connectionId) {
  ref.listen(currentConnectionProvider, (previous, next) {
    if (next?.connectionId == connectionId) {
      switch (next?.state) {
        case WebRTCConnectionState.connected:
          ToastHelper.success(
            title: 'Подключено к ${widget.deviceInfo!.name}',
            description: 'Теперь можно отправлять файлы и сообщения',
          );
          break;
        case WebRTCConnectionState.failed:
          ToastHelper.error(
            title: 'Не удалось подключиться',
            description: 'Проверьте сетевое подключение',
          );
          break;
        case WebRTCConnectionState.disconnected:
          if (previous?.state == WebRTCConnectionState.connected) {
            ToastHelper.info(title: 'Соединение разорвано');
          }
          break;
      }
    }
  });
}
```

## Ключевые улучшения

### 1. **Правильное отслеживание состояний**
- Все изменения состояний WebRTC соединений теперь правильно отражаются в UI
- Промежуточные состояния (connecting, disconnecting) корректно отображаются

### 2. **Асинхронная обработка**
- Система корректно обрабатывает задержки в установлении соединения
- Пользователь видит процесс подключения в реальном времени

### 3. **Автоматическое управление текущим соединением**
- При успешном подключении соединение автоматически становится текущим
- При разрыве соединения оно автоматически убирается из текущего

### 4. **Улучшенная обратная связь**
- Пользователь получает уведомления о каждом изменении состояния
- Различные типы уведомлений (info, success, error) для разных состояний

### 5. **Отладочные возможности**
- Добавлен демо-виджет для тестирования различных состояний соединения
- Подробное логирование всех изменений состояний

## Пример использования

```dart
// В UI компоненте
Consumer(
  builder: (context, ref, child) {
    final currentConnection = ref.watch(currentConnectionProvider);
    
    return ConnectionStatusWidget(
      deviceInfo: deviceInfo,
      isConnecting: currentConnection?.state == WebRTCConnectionState.connecting,
      connection: currentConnection,
    );
  },
)

// Проверка состояния для включения/отключения кнопок
final isConnected = currentConnection?.state == WebRTCConnectionState.connected;
SmoothButton(
  onPressed: isConnected ? _sendMessage : null,
  label: 'Отправить сообщение',
)
```

## Состояния соединения

1. **initializing** - Соединение инициализируется
2. **connecting** - Ожидание подключения (может длиться до 30 сек)
3. **connected** - Соединение установлено, можно передавать данные
4. **disconnecting** - Соединение разрывается
5. **disconnected** - Соединение разорвано
6. **failed** - Ошибка установления соединения

## Цветовая схема индикаторов

- 🟠 **Оранжевый** - initializing, connecting
- 🟢 **Зеленый** - connected
- ⚫ **Серый** - disconnecting, disconnected
- 🔴 **Красный** - failed

Эта система обеспечивает надежную и предсказуемую работу с WebRTC соединениями, правильно обрабатывая все асинхронные события и предоставляя пользователю полную информацию о состоянии соединения.