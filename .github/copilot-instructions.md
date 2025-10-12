## Hoplixi – Быстрые инструкции для AI агентов
Flutter пароль-менеджер: локально зашифрованная SQLite (SQLCipher + Drift) + сервисный слой + Riverpod v3 (Notifier API only). Секреты никогда не логируем.

### Архитектурный срез
1. Поток данных: UI -> Riverpod Notifier **(не DAO!)** -> Service (`lib/hoplixi_store/repository/*_service.dart`) -> DAO (`lib/hoplixi_store/dao`) -> Drift (SQLCipher).
2. `ServiceResult<T>` (`repository/service_results.dart`) единственный наружный контракт (success/message/data). Исключения перехватываются внутри сервиса с логированием.
3. История изменений (пароли/ноты/otp) поддерживается SQL триггерами (`hoplixi_store/sql/triggers.dart`) пересоздаётся при миграции (`hoplixi_store.dart`).
4. Шифрование полей/секретов: см. `core/lib/box_db/crypto_box.dart` (AES-GCM + auto nonce) и чтение/валидация в DAO/box. Для новых секретных колонок повторить контейнер {payload, nonce, mac}.
5. Низкоуровневое файловое хранилище (вне Drift) – `simple_box.dart` (deprecated) / сегментированные боксы (если появятся) с checksum + auto compaction; не смешивать с паролями (основные сущности идут через Drift).
6. При создании Freezed моделей использовать abstract class + mixin (не `with _$Class`), чтобы избежать проблем с наследованием.

### Паттерн сервиса (пример)
```dart
final r = await ref.read(totpServiceProvider).getTotpById(id);
if (!r.success) ToastHelper.error(title: 'Ошибка', description: r.message); else use(r.data);
```
В сервисах: валидация входных ID (существуют ли категории/теги), работа транзакциями при связках (см. `PasswordService.deletePassword`), автоматическая история через триггеры – не дублировать вручную.

### Добавление новой сущности
1. Таблица: `hoplixi_store/tables/<entity>.dart`.
2. DAO: `hoplixi_store/dao/<entity>_dao.dart`.
3. Включить в `@DriftDatabase` (`hoplixi_store.dart`).
4. Кодоген: `build_runner.bat`.
5. Сервис: `hoplixi_store/repository/<entity>_service.dart` (ориентироваться на `password_service.dart` / `totp_service.dart`).
6. При необходимости: триггеры истории (+ обновление `sql/triggers.dart`).

### Riverpod / UI
- Только Notifier / AsyncNotifier / StreamNotifier. Имена провайдеров: `<domain><Role>Provider`.
- UI использует кастомные контролы из `lib/common/` (`SmoothButton`, `PasswordField`, `SliderButton`).
- Новые экраны регистрировать в `lib/router/` (GoRouter, анимации централизованы).

### Логирование и ошибки
- Использовать `logInfo/logDebug/logError` (`core/logger/app_logger.dart`), tag указывать (например 'PasswordService'). Не логировать расшифрованные секреты / пароли / OTP.
- UI уведомления через `ToastHelper` (`core/utils/toastification.dart`).
- Сообщения в `ServiceResult` – безопасные и краткие.

### Шифрование / ключи
- UUID v4 для всех новых ID.
- AES-GCM: при шифровании создавать auto nonce (`encryptUtf8WithAutoNonce`) и сохранять вместе с mac.
- Никогда не писать plaintext в логгер или `ServiceResult.message`.

### Кодоген, сборка, релиз
- Любое изменение таблиц / Freezed / сериализации → `build_runner.bat` (или `dart run build_runner build --delete-conflicting-outputs`). Не коммитить устаревший `*.g.dart`.
- Desktop/Android сборки: `flutter build windows` / `flutter build apk`. Прод-обёртка: `release.bat`.
- Web осознанно отключён – не включать.

### Запрещено
- Прямой доступ UI/Notifier к DAO.
- Сырые SQL вне Drift (кроме централизованных триггеров).
- Логирование секретов / обход шифрования / хранение plaintext.
- Legacy Riverpod Consumer* API.

### Быстрый чек перед коммитом
[] build_runner успешен (запускать только после изменений в таблицах/Freezed, в других случаях не трогать!!)
[] Все новые операции возвращают `ServiceResult`
[] Нет прямых DAO вызовов из UI/Notifier
[] Провайдеры используют Notifier API

Нужен пример (новый сервис/триггер/провайдер) – сформулируйте сущность и цель, можно ссылаясь на ближайший аналог.

### MCP Servers

- To obtain accurate data about libraries, use mcp server context7;
- Use an MCP server for the SequentialThinking model when you need reliable, ordered orchestration of multi-step reasoning — e.g., to manage long-running, stateful chains of inference, coordinate parallel subtasks, or persist and resume multi-turn workflows.
Also use it when you need centralized routing, authentication, load-balancing and observability (logging/metrics) for many clients or models so ordering, fault tolerance and scalable performance are maintained.
