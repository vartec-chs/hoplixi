# Исправление ошибки ref.listen в TransceiverScreen

## Проблема

Ошибка Flutter Riverpod:
```
'package:flutter_riverpod/src/core/consumer.dart': Failed assertion: line 492 pos 7: 
'debugDoingBuild': ref.listen can only be used within the build method of a ConsumerWidget
```

## Причина

`ref.listen` использовался в методе `_listenToConnectionChanges()`, который вызывался из `_initializeConnection()`. Согласно правилам Riverpod, `ref.listen` можно использовать только внутри `build` метода ConsumerWidget.

## Решение

### 1. Убрали отдельный метод `_listenToConnectionChanges()`

**Было:**
```dart
void _listenToConnectionChanges(String connectionId) {
  ref.listen(currentConnectionProvider, (previous, next) {
    // Обработка изменений
  });
}

// Вызывалось из _initializeConnection()
_listenToConnectionChanges(connectionId);
```

### 2. Переместили `ref.listen` в `build` метод

**Стало:**
```dart
@override
Widget build(BuildContext context) {
  final currentConnection = ref.watch(currentConnectionProvider);
  
  // Отслеживание изменений соединения
  ref.listen(currentConnectionProvider, (previous, next) {
    if (_connectionId != null && next?.connectionId == _connectionId) {
      switch (next?.state) {
        case WebRTCConnectionState.connected:
          ToastHelper.success(/* ... */);
          break;
        case WebRTCConnectionState.failed:
          ToastHelper.error(/* ... */);
          break;
        // ...
      }
    }
  });
  
  // ...остальной код build метода
}
```

### 3. Добавили автоинициализацию через `addPostFrameCallback`

Поскольку `initState` больше не вызывает `_initializeConnection()`, добавили автоинициализацию в `build` методе:

```dart
// Автоинициализация подключения при первой загрузке
if (!_hasInitialized && widget.deviceInfo != null) {
  _hasInitialized = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeConnection();
  });
}
```

## Ключевые правила Riverpod

1. **`ref.listen`** можно использовать только в `build` методе ConsumerWidget
2. **`ref.watch`** для реактивного отслеживания изменений состояния  
3. **`ref.read`** для однократного чтения значения (не в build методе)
4. **`addPostFrameCallback`** для выполнения действий после построения виджета

## Результат

- ✅ Ошибка исправлена
- ✅ `ref.listen` корректно работает в `build` методе
- ✅ Автоинициализация соединения при загрузке экрана
- ✅ Реактивные уведомления об изменениях состояния соединения
- ✅ Код соответствует best practices Riverpod

Теперь система корректно отслеживает изменения состояния WebRTC соединения и показывает соответствующие уведомления пользователю.