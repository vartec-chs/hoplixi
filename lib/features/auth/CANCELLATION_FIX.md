# Исправление проблемы с повторной авторизацией после отмены

## Проблема

После отмены авторизации (закрытие браузера без авторизации) все последующие попытки авторизации завершались ошибкой:
```
Exception: Авторизация отменена или не удалась. Попробуйте еще раз.
```

## Причина

При отмене авторизации HTTP сервер (`HttpServer`) оставался открытым и продолжал ожидать входящие запросы в цикле `await for (final request in _server!)`. Это приводило к:

1. **Блокировка порта** - сервер продолжал слушать порт 8080
2. **Зависший цикл** - `await for` продолжал работать в фоне
3. **Конфликт при повторной попытке** - новая попытка не могла создать сервер на том же порту
4. **Неочищенное состояние** - `codeVerifier` и другие переменные не сбрасывались

## Решение

### 1. Добавлен механизм отмены через Completer

**Файл:** `oauth2_provider.dart`

```dart
// Глобальный Completer для отмены авторизации
Completer<void>? _cancellationCompleter;
```

Этот `Completer` позволяет явно отменить ожидание авторизации извне.

### 2. Использование Future.any для гонки между авторизацией и отменой

```dart
// Ждём либо успешной авторизации, либо отмены, либо тайм-аута (5 минут)
final result = await Future.any([
  serverFuture,
  _cancellationCompleter!.future.then((_) => null),
]).timeout(
  const Duration(minutes: 5),
  onTimeout: () {
    debugPrint('Authorization timeout - user likely cancelled');
    return null;
  },
);
```

Теперь авторизация завершается при первом из трёх событий:
- ✅ Успешная авторизация (callback с кодом)
- ❌ Явная отмена через `cancelAuthorization()`
- ⏱️ Тайм-аут 5 минут

### 3. Статический метод для отмены авторизации

```dart
/// Отменить текущую авторизацию
static Future<void> cancelAuthorization() async {
  debugPrint('Cancelling authorization...');
  
  // Завершаем Completer для отмены
  if (_cancellationCompleter != null && !_cancellationCompleter!.isCompleted) {
    _cancellationCompleter!.complete();
  }
  
  // Закрываем сервер
  await _server?.close(force: true);
  _server = null;
  
  debugPrint('Authorization cancelled and server closed');
}
```

Метод:
1. Завершает `Completer` (триггерит завершение `Future.any`)
2. Принудительно закрывает сервер (`force: true`)
3. Очищает ссылку на сервер

### 4. Интеграция в AuthorizationNotifier

**Файл:** `authorization_notifier_provider.dart`

```dart
/// Отмена авторизации
Future<void> cancel() async {
  logInfo('Authorization cancelled', tag: _tag);

  final currentReturnPath = state.returnPath ?? '/';

  // Отменяем OAuth2 авторизацию (закрываем сервер)
  await OAuth2ProviderF.cancelAuthorization();

  state = AuthState.cancelled(returnPath: currentReturnPath);

  // Сбрасываем состояние после небольшой задержки
  Future.delayed(const Duration(milliseconds: 500), () {
    if (state is AuthStateCancelled) {
      state = const AuthState.idle();
    }
  });
}
```

Теперь метод:
- Асинхронный (`Future<void>`)
- Вызывает `OAuth2ProviderF.cancelAuthorization()` перед изменением состояния
- Гарантирует закрытие сервера

### 5. Обновление UI

**Файл:** `authorization_progress_screen.dart`

```dart
Widget _buildCancelButton(ThemeData theme) {
  return SmoothButton(
    label: 'Отменить',
    onPressed: () async {
      await ref.read(authorizationProvider.notifier).cancel();
    },
    icon: const Icon(Icons.close),
    type: SmoothButtonType.outlined,
  );
}
```

Кнопка отмены теперь асинхронна и ждёт полного закрытия сервера.

## Поток выполнения

### До исправления (❌ проблема)

```
Пользователь → Кнопка "Отменить" → state = cancelled
                                         ↓
                               HTTP сервер продолжает работать
                                         ↓
                               Порт 8080 занят
                                         ↓
                          Новая попытка → Ошибка биндинга порта
```

### После исправления (✅ работает)

```
Пользователь → Кнопка "Отменить" → OAuth2ProviderF.cancelAuthorization()
                                         ↓
                              _cancellationCompleter.complete()
                                         ↓
                              Future.any завершается с null
                                         ↓
                              _server?.close(force: true)
                                         ↓
                              Порт 8080 освобождён
                                         ↓
                              state = cancelled → idle
                                         ↓
                          Новая попытка → ✅ Успешно
```

## Дополнительные улучшения

### 1. Генерация нового codeVerifier

```dart
String get _authUrl {
  // Всегда генерируем новый codeVerifier для каждой попытки авторизации
  codeVerifier = PKCE.generateCodeVerifier();
  // ...
}
```

Каждая попытка авторизации получает новый PKCE challenge, что соответствует спецификации OAuth2.

### 2. Тайм-аут 5 минут

Если пользователь закроет браузер и не отменит авторизацию явно, через 5 минут сервер автоматически закроется:

```dart
.timeout(
  const Duration(minutes: 5),
  onTimeout: () {
    debugPrint('Authorization timeout - user likely cancelled');
    return null;
  },
)
```

### 3. Force close сервера

```dart
await _server?.close(force: true);
```

`force: true` гарантирует немедленное закрытие всех активных соединений без ожидания их завершения.

## Тестирование

### Сценарий 1: Отмена авторизации

1. ✅ Открыть модалку выбора провайдера
2. ✅ Выбрать провайдер (откроется браузер)
3. ✅ Нажать "Отменить" на экране прогресса
4. ✅ Вернуться на предыдущий экран
5. ✅ Повторить п.1-2 → авторизация должна работать

### Сценарий 2: Тайм-аут

1. ✅ Выбрать провайдер
2. ✅ Закрыть браузер без авторизации
3. ✅ Подождать 5 минут
4. ✅ Повторить авторизацию → должна работать

### Сценарий 3: Быстрая повторная попытка

1. ✅ Выбрать провайдер
2. ✅ Нажать "Отменить"
3. ✅ Сразу повторить авторизацию → должна работать без задержки

## Изменённые файлы

1. `lib/core/lib/oauth2restclient/src/provider/oauth2_provider.dart`
   - Добавлен `_cancellationCompleter`
   - Изменён `loginFromDesktop()` для поддержки отмены
   - Добавлен статический метод `cancelAuthorization()`
   - Добавлен тайм-аут 5 минут

2. `lib/features/auth/providers/authorization_notifier_provider.dart`
   - Метод `cancel()` стал асинхронным
   - Добавлен вызов `OAuth2ProviderF.cancelAuthorization()`

3. `lib/features/auth/screens/authorization_progress_screen.dart`
   - Кнопка отмены использует `await` при вызове `cancel()`

## Выводы

Проблема была связана с неправильным управлением жизненным циклом HTTP сервера. Решение:

1. ✅ Явный механизм отмены через `Completer`
2. ✅ Принудительное закрытие сервера при отмене
3. ✅ Очистка всех ресурсов перед новой попыткой
4. ✅ Тайм-аут для автоматической очистки
5. ✅ Асинхронная отмена с ожиданием закрытия сервера

Теперь пользователь может отменять и повторять авторизацию любое количество раз без перезапуска приложения.
