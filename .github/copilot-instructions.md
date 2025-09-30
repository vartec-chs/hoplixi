dart run build_runner build --delete-conflicting-outputs
## Hoplixi – Сжатые инструкции для AI агентов
Flutter пароль-менеджер: локальная зашифрованная SQLite (SQLCipher + Drift), сервисно-ориентированная архитектура, Riverpod v3 (Notifier API only), UI через кастомные компоненты.

### Структура (опорные директории)
- `lib/hoplixi_store/` таблицы, DAO, сервисы, триггеры, результаты (`service_results.dart`).
- `lib/features/*` доменные модули (пример: `password_manager`, `setup`, `home`).
- `lib/common/` UI компоненты: `button.dart`, `password_field.dart`, `text_field.dart`, `slider_button.dart` (использовать вместо стандартных кнопок/полей).
- `lib/core/` логгер (`app_logger.dart`), preferences, тема, secure storage, утилиты (`toastification.dart`).
- `lib/router/` маршруты (GoRouter + анимации).
- `lib/box_db/` низкоуровневое шифрование/контейнеры (`simple_box.dart`, `crypto_box.dart`, `utils.dart`).

### Ключевые правила
1. UI НЕ обращается к DAO – только через сервисы в `hoplixi_store/services/*` (см. `totp_service.dart`).
2. Возврат из сервисов через `ServiceResult` / производные (не бросать исключения наружу):
```dart
final r = await totpService.getTotpById(id);
if (!r.success) ToastHelper.error(r.message); else use(r.data);
```
3. Никаких логов чувствительных данных (пароли, секреты, расшифрованный текст). Использовать `logInfo/logError` с минимальным контекстом.
4. После изменения таблиц / Freezed / JSON: выполнить `build_runner.bat` (иначе генерация упадёт при сборке).
5. Riverpod: только Notifier API (не добавлять ConsumerWidget). Провайдеры – в фиче либо общей папке, соблюдая существующий стиль.
6. UUID v4 для всех PK. История изменений поддерживается SQL-триггерами – при расширении схемы обновить `sql/triggers.dart`.
7. Web отключён умышленно (не пытаться включать). Поддерживаем: Windows, Android (остальное экспериментально).

### Шифрование / хранение
- Высокоуровневые сущности: данные шифруются до записи (см. использование в сервисах + box_db). 
- Низкоуровневые операции: `crypto_box.dart` (`encryptUtf8WithAutoNonce`) возвращает map со шифртекстом и метаданными (`nonce`, `cipher`, `tag` – см. проверки в `simple_box.dart`).
- При добавлении новых полей с секретами – повторить паттерн nonce + auth tag, не логировать промежуточные значения.

### Добавление новой сущности
1. Таблица: `hoplixi_store/tables/*.dart`.
2. DAO: `hoplixi_store/dao/*_dao.dart`.
3. Включить в `hoplixi_store.dart` (@DriftDatabase).
4. Генерация: `build_runner.bat`.
5. Сервис по образцу (`password_service.dart` / `totp_service.dart`), возвращая `ServiceResult`.
6. Обновить триггеры истории при необходимости.

### UI паттерны
- Кнопки: `SmoothButton` (тип + размер), подтверждение удаления: `SliderButton`.
- Поля ввода: `TextField` / `PasswordField` из `common/`.
- Темы: через `themeProvider`; цвета – `core/theme/colors.dart`.
- Респонсив: брейкпоинты MOBILE ≤450, TABLET 451–1000, DESKTOP ≥1001.

### Локальная сборка / релиз
- Генерация кода (обязательно перед коммитом): `build_runner.bat`.
- Windows: `flutter build windows`; Android: `flutter build apk`; прод-скрипт: `release.bat`.

### Пример ServiceResult (из `service_results.dart`)
```dart
class ServiceResult<T>{ final bool success; final String? message; final T? data; }
```

### MCP Servers

- To obtain accurate data about libraries, use mcp server context7;
- Use an MCP server for the SequentialThinking model when you need reliable, ordered orchestration of multi-step reasoning — e.g., to manage long-running, stateful chains of inference, coordinate parallel subtasks, or persist and resume multi-turn workflows.
Also use it when you need centralized routing, authentication, load-balancing and observability (logging/metrics) for many clients or models so ordering, fault tolerance and scalable performance are maintained.

### Riverpod Providers

Unmodifiable:	Provider	FutureProvider	StreamProvider
Modifiable:	  NotifierProvider	AsyncNotifierProvider	StreamNotifierProvider

### Что НЕ делать
- Не писать прямые SQL вне Drift кроме случаев, когда это действительно необходимо например триггеров и подобных а также сложных запросов.
- Не обходить сервисы ради «быстрых» DAO вызовов.
- Не логировать расшифрованный секрет / пароль.
- Не добавлять Consumer*/legacy Riverpod API.

Если правило неочевидно – ищите аналог в существующих сервисах и повторяйте стиль.

---
Сообщите, если нужны примеры для конкретной новой сущности, миграции или провайдера – расширю раздел.