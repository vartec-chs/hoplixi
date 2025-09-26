# SendFileWithResume Connection Fix

## Проблема
Файлы не отправлялись через `sendFileWithResume` с ошибкой "Нет соединения с устройством", хотя WebRTC соединение было установлено и текстовые сообщения отправлялись корректно.

## Корень проблемы
В методе `sendFileWithResume` использовалась неправильная логика поиска WebRTC соединения:

### Было (НЕПРАВИЛЬНО):
```dart
final connections = _ref.read(webrtcConnectionsProvider);
final connection = connections[deviceId];  // ❌ Поиск по deviceId как ключу
```

### Проблема:
- `webrtcConnectionsProvider` индексирует соединения по `connectionId` (UUID)
- `deviceId` - это ID устройства, не ключ в Map соединений
- `connections[deviceId]` всегда возвращал `null`, даже при наличии активного соединения

## Решение

### Исправлено (ПРАВИЛЬНО):
```dart
final webrtcConnections = _ref.read(webrtcConnectionsProvider);
final connection = webrtcConnections.values
    .where(
      (conn) =>
          conn.remoteDeviceId == deviceId &&
          conn.state == WebRTCConnectionState.connected,
    )
    .firstOrNull;
```

### Дополнительные улучшения:
1. **Раздельная проверка**: Отдельные проверки для соединения и DataChannel
2. **Улучшенное логирование**: Добавлен `connectionId` в логи для диагностики  
3. **Информативные ошибки**: Различные сообщения для разных типов ошибок

### Логика проверок:
```dart
if (connection == null) {
  // Нет активного WebRTC соединения
  return false;
}

if (connection.dataChannel == null) {
  // Соединение есть, но DataChannel не готов
  return false;
}
```

## Результат
- Метод `sendFileWithResume` теперь правильно находит активное WebRTC соединение
- Используется та же логика поиска, что в `sendTextMessage` 
- Файлы должны передаваться через установленный WebRTC DataChannel
- Улучшена диагностика с подробными логами

## Статус: ИСПРАВЛЕНО ✅

Теперь передача файлов через `sendFileWithResume` должна работать корректно, используя правильно найденное WebRTC соединение.