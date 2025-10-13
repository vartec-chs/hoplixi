## Hoplixi — Быстрый онбординг для AI
Flutter пароль-менеджер: локально зашифрованная SQLite (SQLCipher + Drift) + сервисный слой + Riverpod v3 Notifier API. Секреты или расшифрованные данные никогда не попадают в логи.

### Архитектура и потоки данных
1. UI (`lib/features/...`) общается только с Riverpod Notifier/AsyncNotifier/StreamNotifier провайдерами (`<domain><Role>Provider`).
2. Нотифайеры делегируют действия сервисам в `lib/hoplixi_store/repository/*_service.dart`, которые возвращают `ServiceResult<T>` (`lib/hoplixi_store/repository/service_results.dart`).
3. Сервисы валидируют входные ID, логируют через `core/logger/app_logger.dart`, оформляют транзакции и никогда не пробрасывают исключения наружу.
4. DAO из `lib/hoplixi_store/dao` инкапсулируют запросы Drift (`lib/hoplixi_store/hoplixi_store.dart`), а SQL триггеры истории (`lib/hoplixi_store/sql/triggers.dart`) автоматически ведут аудит паролей/нот/otp.

### Шифрование и хранение
- Для полей с секретами используйте `lib/core/lib/box_db/crypto_box.dart` (AES-GCM с auto nonce). Новые зашифрованные столбцы держат `{payload, nonce, mac}`.
- Низкоуровневое файловое хранилище (`lib/core/lib/box_db_new/*`) отдельно от Drift; `simple_box.dart` считается deprecated.
- Все ID генерируются как UUID v4; plaintext нельзя логировать или возвращать в `ServiceResult.message`.

### UI и общие паттерны
- Общие виджеты лежат в `lib/common/` (`SmoothButton`, `PasswordField`, `SliderButton`); придерживайтесь их вместо Material по умолчанию.
- Навигация управляется GoRouter в `lib/router`; новые экраны регистрируются там, переходы централизованы.
- Toast/ошибки показываются через `ToastHelper` (`core/utils/toastification.dart`), а глобальные сообщения — `ScaffoldMessengerManager` (`lib/core/utils/scaffold_messenger_manager`).

### Расширение доменных сущностей
1. Таблица → `lib/hoplixi_store/tables/<entity>.dart`.
2. DAO → `lib/hoplixi_store/dao/<entity>_dao.dart` (следовать примерам PasswordsDao/TotpsDao по сложным фильтрам и stream'ам).
3. Добавить в `@DriftDatabase` в `lib/hoplixi_store/hoplixi_store.dart` и обновить связанные триггеры при необходимости.
4. Сервис → `lib/hoplixi_store/repository/<entity>_service.dart`; смотрите `password_service.dart` и `totp_service.dart` для транзакций и работы с тегами/категориями.

### Рабочие процессы разработчика
- Генерация: после изменений Drift/Freezed/DTO запустите `build_runner.bat` (выполняет `dart run build_runner build --delete-conflicting-outputs`).
- Тесты: `flutter test --no-pub` (unit/feature тесты живут в `test/features/...`).
- Запуск: `flutter run -d windows` для десктопа, `flutter build apk` или `flutter build windows` для релиза, `release.bat` собирает production-пакет.
- Следите за SQLCipher зависимостями: DB инициализируется через сервисы, UI не должен открывать соединения напрямую.

### Логирование и соблюдение безопасности
- Используйте только `logInfo/logDebug/logError` с тэгом компонента; никакие пароли/OTP/secret payload не выводятся и не передаются наружу.
- При работе с тегами/иконками/вложениями опирайтесь на Metadata сервис (`lib/hoplixi_store/repository/metadata_service.dart`) вместо прямых DAO вызовов.

## Замечания

- При создании freezed классов используйте аннотацию `@freezed`, и добавляйте классу abstract class, а не обычный класс. Это необходимо для корректной работы генерации кода и обеспечения неизменяемости объектов.

### Чек перед коммитом
[] Структура UI → Notifier → Service → DAO соблюдена; нет прямых DAO вызовов из UI.
[] Все публичные операции возвращают `ServiceResult` и оборачивают ошибки.
[] `build_runner` прогнан только если менялись таблицы/Freezed/генерируемый код; нет устаревших `*.g.dart`.
[] Логи и сообщения проверены на отсутствие секретов.

### MCP Servers
- Для получения актуальной документации библиотек обращайтесь к MCP серверу context7.
- Для сложных многошаговых сценариев используйте SequentialThinking MCP (гарантия порядка, удержание долгих задач, метрики).

Нужны дополнительные примеры (новый сервис/триггер/провайдер) — сформулируйте сущность и цель и укажите ближайший аналог в коде.
