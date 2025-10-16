# Исправление проблемы повторной авторизации после отмены

## Проблема

При отмене авторизации пользователем все последующие попытки авторизации возвращали ошибку "Авторизация прервана пользователем" до перезапуска приложения.

## Причины

1. **Кэширование `codeVerifier`**: В `OAuth2ProviderF` переменная `codeVerifier` использовала оператор `??=`, что означало, что она создавалась только один раз и переиспользовалась для всех последующих попыток
2. **Незакрытый HTTP сервер**: В Desktop версии сервер мог оставаться открытым после отмены
3. **Нечёткие сообщения об ошибках**: Не было различия между отменой и реальными ошибками авторизации

## Исправления

### 1. OAuth2Provider (`oauth2_provider.dart`)

#### Генерация нового codeVerifier
```dart
// ДО:
String get _authUrl {
  codeVerifier ??= PKCE.generateCodeVerifier();  // ❌ Создавался только один раз
  ...
}

// ПОСЛЕ:
String get _authUrl {
  codeVerifier = PKCE.generateCodeVerifier();  // ✅ Создаётся каждый раз
  ...
}
```

#### Закрытие предыдущего сервера
```dart
// ДО:
Future<OAuth2Token?> loginFromDesktop(...) async {
  try {
    var uri = Uri.parse(_authUrl);
    await launchUrl(uri);
    
    await _server?.close();  // ❌ Закрывался после launchUrl
    _server = await HttpServer.bind(host, port);
    ...
}

// ПОСЛЕ:
Future<OAuth2Token?> loginFromDesktop(...) async {
  try {
    // Закрываем предыдущий сервер, если он был открыт
    await _server?.close();  // ✅ Закрывается ДО начала новой попытки
    _server = null;
    
    var uri = Uri.parse(_authUrl);
    await launchUrl(uri);
    
    _server = await HttpServer.bind(host, port);
    ...
}
```

### 2. BaseOAuthProviderService (`base_oauth_provider_service.dart`)

#### Улучшенная обработка ошибок
```dart
// ДО:
if (token == null) {
  return ServiceResult.failure('Авторизация прервана пользователем');
}

// ПОСЛЕ:
if (token == null) {
  logInfo('Authorization cancelled or failed for ${provider.name}', tag: tag);
  return ServiceResult.failure(
    'Авторизация отменена или не удалась. Попробуйте еще раз.',
  );
}
```

#### Детальные сообщения об ошибках
```dart
catch (e, stack) {
  String errorMessage = 'Ошибка авторизации';
  if (e.toString().contains('cancelled')) {
    errorMessage = 'Авторизация отменена пользователем';
  } else if (e.toString().contains('network')) {
    errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
  } else {
    errorMessage = 'Ошибка авторизации: ${e.toString()}';
  }
  
  return ServiceResult.failure(errorMessage);
}
```

### 3. Дополнительное логирование

Добавлено логирование для отладки:
- Начало процесса авторизации
- Успешное завершение с ключом клиента
- Отмена авторизации
- Детальные ошибки

## Результат

Теперь после отмены авторизации:

1. ✅ **Новый PKCE код** генерируется при каждой попытке
2. ✅ **HTTP сервер закрывается** перед новой попыткой
3. ✅ **Понятные сообщения** об отмене и возможности повторить
4. ✅ **Повторная авторизация работает** без перезапуска приложения

## Тестирование

Проверьте следующие сценарии:

- [ ] Отмена авторизации → повторная попытка → успех
- [ ] Отмена авторизации → отмена → повторная попытка → успех
- [ ] Успешная авторизация с первой попытки
- [ ] Ошибка сети → повторная попытка после восстановления
- [ ] Проверка на Desktop (Windows/macOS/Linux)
- [ ] Проверка на Mobile (Android/iOS)

## Логи для отладки

При проблемах проверяйте логи с тегом `BaseOAuthProviderService`:
- "Starting authorization for..." - начало
- "Authorization cancelled or failed..." - отмена
- "Authorization successful..., key: ..." - успех
- "Failed to authorize..." - ошибка
