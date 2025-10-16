# Архитектура авторизации OAuth2

## Обзор

Новая архитектура авторизации построена на основе Riverpod и Freezed для управления состоянием процесса авторизации с четкими этапами и блокировкой навигации.

## Ключевые компоненты

### 1. **AuthState** (`models/auth_state.dart`)

Freezed модель состояния авторизации с 6 состояниями:

- `idle` - начальное состояние
- `validatingToken` - проверка существующего токена
- `authorizing` - процесс новой авторизации
- `success` - успешная авторизация
- `failure` - ошибка авторизации
- `cancelled` - отмена пользователем

Каждое состояние содержит:
- `credential` - конфигурация провайдера
- `returnPath` - путь для возврата после завершения
- `error` / `message` - дополнительная информация

### 2. **AuthorizationNotifier** (`providers/authorization_notifier_provider.dart`)

Главный провайдер управления авторизацией:

```dart
final authorizationProvider = NotifierProvider<AuthorizationNotifier, AuthState>
```

**Методы:**
- `startAuthorization()` - запуск процесса авторизации
- `cancel()` - отмена авторизации
- `reset()` - сброс в idle
- `retry()` - повторная попытка после ошибки

**Логика работы:**
1. Сначала проверяется существующий токен (`validateAndUseExistingToken`)
2. Если токен валиден - создается клиент без полной авторизации
3. Если токена нет/невалиден - запускается полная авторизация через браузер

### 3. **OAuth2AccountService** (обновлен)

Добавлен метод `validateAndUseExistingToken()`:
- Ищет существующий токен по суффиксу провайдера
- Пытается создать клиент с этим токеном
- Возвращает `ServiceResult<String>` с ключом клиента или ошибкой

### 4. **AuthorizationProgressScreen** (`screens/authorization_progress_screen.dart`)

Экран прогресса авторизации:
- Показывает текущий этап процесса
- Отображает индикаторы загрузки
- Предоставляет кнопку отмены
- При ошибке - кнопки "Назад" и "Повторить"
- Автоматически слушает изменения состояния и выполняет редиректы

### 5. **AuthModal** (новая версия `auth_modal_new.dart`)

Модальное окно выбора провайдера:
- Принимает `returnPath` как обязательный параметр
- При выборе провайдера:
  - Закрывает модальное окно
  - Запускает `AuthorizationNotifier.startAuthorization()`
  - Переходит на `AuthorizationProgressScreen`

**Использование:**
```dart
final clientKey = await showAuthModal(
  context,
  returnPath: '/dashboard',
);
```

### 6. **Router обновления**

#### `router_provider.dart`
Добавлена логика блокировки навигации во время авторизации:
```dart
final authState = ref.read(authorizationProvider);
if (authState.isLoading && currentPath != authorizationProgress) {
  return AppRoutes.authorizationProgress;
}
```

#### `router_refresh_provider.dart`
Добавлено прослушивание изменений `authorizationProvider` для обновления router при смене состояния авторизации.

## Процесс авторизации

### Сценарий 1: Валидный существующий токен

```
User selects provider
    ↓
AuthModal closed
    ↓
AuthorizationNotifier.startAuthorization()
    ↓
Navigate to AuthorizationProgressScreen
    ↓
State: validatingToken
    ↓
validateAndUseExistingToken() → SUCCESS
    ↓
State: success
    ↓
Navigate to returnPath
```

### Сценарий 2: Новая авторизация

```
User selects provider
    ↓
AuthModal closed
    ↓
AuthorizationNotifier.startAuthorization()
    ↓
Navigate to AuthorizationProgressScreen
    ↓
State: validatingToken
    ↓
No valid token found
    ↓
State: authorizing
    ↓
OAuth2 flow in browser
    ↓
State: success / failure
    ↓
Navigate to returnPath / Show retry
```

### Сценарий 3: Отмена пользователем

```
During validatingToken or authorizing
    ↓
User clicks "Отменить"
    ↓
AuthorizationNotifier.cancel()
    ↓
State: cancelled
    ↓
Navigate to returnPath
```

### Сценарий 4: Ошибка авторизации

```
During authorization
    ↓
Error occurs
    ↓
State: failure
    ↓
User sees error message
    ↓
Options: "Назад" or "Повторить"
    ↓
Retry → startAuthorization() again
Cancel → navigate to returnPath
```

## Интеграция в существующий код

### Где вызывать авторизацию?

Везде, где раньше использовался `OAuth2AccountService.authorize()`, теперь:

```dart
// Старый способ
final result = await service.authorize(credential);

// Новый способ
final clientKey = await showAuthModal(
  context,
  returnPath: context.currentRoute,
);
```

### Пример использования в feature

```dart
// В экране синхронизации
Future<void> _startSync() async {
  final clientKey = await showAuthModal(
    context,
    returnPath: AppRoutes.settings,
  );
  
  if (clientKey != null) {
    // Клиент создан и готов к использованию
    await _performSync(clientKey);
  }
}
```

## Преимущества новой архитектуры

1. **Явное управление состоянием** - все этапы авторизации отслеживаются
2. **Блокировка навигации** - пользователь не может уйти с экрана во время авторизации
3. **Переиспользование токенов** - сначала проверка существующего токена
4. **Улучшенный UX** - индикаторы прогресса, понятные сообщения об ошибках
5. **Возможность отмены** - пользователь может прервать процесс
6. **Повторные попытки** - легко повторить после ошибки
7. **Централизованная логика** - вся логика авторизации в одном месте
8. **Типобезопасность** - Freezed гарантирует корректность состояний

## TODO для интеграции

- [ ] Обновить старые вызовы `authorize()` на `showAuthModal()`
- [ ] Удалить старый `auth_modal.dart` после тестирования
- [ ] Добавить unit тесты для `AuthorizationNotifier`
- [ ] Добавить интеграционные тесты для flow авторизации
- [ ] Добавить логирование важных событий
- [ ] Рассмотреть добавление аналитики для отслеживания успешности авторизации
