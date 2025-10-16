# OAuth2 Authentication Services

Рефакторинг системы аутентификации OAuth2 для улучшения поддерживаемости и расширяемости.

## Структура модуля

```
lib/features/auth/
├── config/
│   └── oauth2_provider_config.dart      # Конфигурация scopes для всех провайдеров
├── services/
│   ├── base_oauth_provider_service.dart # Базовый класс для провайдеров
│   ├── token_auth_service.dart          # Сервис работы с существующими токенами
│   ├── oauth2_account_service.dart      # Главный координатор авторизации
│   ├── oauth2_services.dart             # Общий экспорт всех сервисов
│   └── providers/
│       ├── dropbox_auth_service.dart    # Специализированный сервис Dropbox
│       ├── yandex_auth_service.dart     # Специализированный сервис Yandex
│       ├── google_auth_service.dart     # Специализированный сервис Google
│       └── microsoft_auth_service.dart  # Специализированный сервис Microsoft
```

## Описание компонентов

### OAuth2ProviderConfig
Централизованное хранение scopes для каждого облачного провайдера:
- `dropboxScopes` - разрешения для Dropbox API
- `yandexScopes` - разрешения для Yandex Disk API
- `googleScopes` - разрешения для Google Drive API
- `microsoftScopes` - разрешения для Microsoft OneDrive API

### BaseOAuthProviderService
Абстрактный базовый класс, содержащий:
- Общую логику refresh токенов
- Логику relogin при истечении срока действия
- Создание OAuth2RestClient
- Обработку ошибок авторизации

Все специализированные сервисы наследуют этот класс.

### Специализированные сервисы провайдеров
Каждый провайдер имеет свой сервис:
- **DropboxAuthService** - авторизация через Dropbox
- **YandexAuthService** - авторизация через Yandex
- **GoogleAuthService** - авторизация через Google
- **MicrosoftAuthService** - авторизация через Microsoft OneDrive

Каждый сервис:
- Настраивает специфичные параметры провайдера
- Определяет redirectUri (десктоп/мобильный)
- Использует соответствующие scopes из конфигурации
- Делегирует общую логику базовому классу

### TokenAuthService
Управляет авторизацией с использованием существующих токенов:
- Проверяет срок действия токена
- Выполняет refresh при необходимости
- Создаёт и кэширует OAuth2RestClient
- Возвращает `ServiceResult` с результатом операции

### OAuth2AccountService
Главный координатор системы авторизации:
- Инициализирует все специализированные сервисы
- Предоставляет единый метод `authorize()` для всех типов провайдеров
- Проверяет наличие существующих токенов перед новой авторизацией
- Управляет кэшем OAuth2RestClient

## Принципы работы

### 1. Новая авторизация
```dart
final result = await oauth2Service.authorize(
  credential,
  onError: (error) => print(error),
);
```

Последовательность:
1. `OAuth2AccountService` определяет тип провайдера
2. Проверяет наличие существующего токена в БД
3. Если токен есть - пытается использовать через `TokenAuthService`
4. Если токена нет или он невалиден - вызывает специализированный сервис
5. Специализированный сервис создаёт провайдера с настройками
6. Выполняется OAuth2 flow через браузер
7. Полученный токен сохраняется и создаётся клиент

### 2. Авторизация с существующим токеном
```dart
final tokenInfo = TokenInfo(key: tokenId, token: tokenOAuth);
final result = await oauth2Service.authorizeWithToken(tokenInfo);
```

Последовательность:
1. `TokenAuthService` проверяет срок действия токена
2. Если токен истёк - выполняет `forceRelogin`
3. Если forceRelogin не удался - пытается `refreshToken`
4. Создаёт `OAuth2RestClient` с актуальным токеном
5. Кэширует клиента в `OAuth2AccountService`

### 3. Обработка ошибок
Все операции возвращают `ServiceResult<T>`:
```dart
if (result.success) {
  final key = result.data!;
  final client = oauth2Service.getClient(key);
} else {
  print('Error: ${result.message}');
}
```

## Преимущества новой архитектуры

1. **Разделение ответственности** - каждый класс имеет чёткую роль
2. **Переиспользование кода** - общая логика в базовом классе
3. **Легкость расширения** - добавление нового провайдера требует только нового сервиса
4. **Упрощённое тестирование** - можно тестировать каждый компонент отдельно
5. **Читаемость** - основной файл сократился с ~600 до ~120 строк
6. **Централизованная конфигурация** - все scopes в одном месте
7. **Типобезопасность** - чёткие сигнатуры методов

## Добавление нового провайдера

1. Добавить scopes в `OAuth2ProviderConfig`
2. Создать `NewProviderAuthService extends BaseOAuthProviderService`
3. Реализовать метод `authorizeWithNewProvider`
4. Добавить новый case в `OAuth2AccountService.authorize()`
5. Экспортировать новый сервис в `oauth2_services.dart`

## Миграция существующего кода

Публичный API `OAuth2AccountService` остался прежним:
- `authorize(credential)` - работает как раньше
- `authorizeWithToken(tokenInfo)` - работает как раньше
- `getClient(key)` - без изменений
- `account` getter - без изменений
- `clients` getter - без изменений

Внутренние методы (`authorizeWithDropbox`, `authorizeWithYandex` и т.д.) удалены, т.к. теперь всё идёт через `authorize()`.
