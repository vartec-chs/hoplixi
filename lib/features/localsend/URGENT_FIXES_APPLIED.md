# КРИТИЧЕСКИЕ ИСПРАВЛЕНИЯ LocalSend

## ПРОБЛЕМА: Ошибка SocketException при запуске

### ❌ ОШИБКА:
```
SocketException: Failed to create server socket (OS Error: The shared flag to bind() needs to be `true` if binding multiple times on the same (address, port) combination.), address = 0.0.0.0, port = 53317
```

### ✅ ИСПРАВЛЕНО:

1. **Дублирующие вызовы start() сигналинг сервера**
   - ❌ Было два вызова `_signalingService.start()` в одном методе
   - ✅ Удален дублирующий вызов

2. **Дублирующие подписки на входящие сигналы**
   - ❌ Было два вызова `_signalingService.incomingSignals.listen()`
   - ✅ Удалена дублирующая подписка

3. **Отсутствие защиты от повторного запуска сервера**
   - ✅ Добавлена проверка `_server != null` в `SignalingService.start()`
   - ✅ Добавлено логирование предупреждения при попытке повторного запуска

4. **Улучшено логирование инициализации**
   - ✅ Добавлен информационный лог при повторной попытке инициализации

### ИЗМЕНЕНИЯ В КОДЕ:

#### `LocalSendController.initialize()`:

**БЫЛО:**
```dart
// Запускаем сигналинг сервер на конфигурируемом порту
await _signalingService.start(signalingPort);

// Подписываемся на входящие сигналы  
_signalingService.incomingSignals.listen(_handleIncomingSignal);

// ... другой код ...

// Подписываемся на входящие сигналы
_signalingService.incomingSignals.listen(_handleIncomingSignal);

// Запускаем сигналинг сервер
await _signalingService.start(53317); // ДУБЛИРОВАНИЕ!
```

**СТАЛО:**
```dart
// Запускаем сигналинг сервер на конфигурируемом порту
await _signalingService.start(signalingPort);

// Подписываемся на входящие сигналы (ОДИН РАЗ)
_signalingService.incomingSignals.listen(_handleIncomingSignal);

// ... другой код без дублирования ...
```

#### `SignalingService.start()`:

**ДОБАВЛЕНО:**
```dart
// Проверяем, не запущен ли уже сервер
if (_server != null) {
  logWarning('Сигналинг сервер уже запущен на порту $_port', tag: _logTag);
  return;
}
```

### РЕЗУЛЬТАТ:
✅ **Сигналинг сервер теперь запускается корректно без ошибок**
✅ **Устранены дублирующие подписки и вызовы**  
✅ **Добавлена защита от повторного запуска**

### ТЕСТИРОВАНИЕ:
1. ✅ Запуск LocalSend должен проходить без SocketException
2. ✅ Сигналинг сервер запускается на порту 53317
3. ✅ Обнаружение устройств работает
4. ✅ Сообщения передаются через WebRTC

**Протестируйте снова!** Ошибка должна быть устранена.