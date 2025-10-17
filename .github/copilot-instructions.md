## Hoplixi — Coding Playbook
- Flutter пароль-менеджер (`lib/main.dart` → `App`) использует Riverpod 3, GoRouter и Drift+SQLCipher; все секреты остаются локальными и не пишутся в логи.
- Глобальные настройки, темы и маршруты находятся в `lib/app/...` (`router_provider.dart`, `routes.dart`, `theme/index.dart`); обновляя навигацию, регистрируйте экраны и провайдеры в этих файлах.
- UI-модули живут в `lib/features/<domain>/`; компоненты общего назначения берите из `lib/common/` (напр. `SmoothButton`, `PasswordField`, `SliderButton`).

### Data & Error Handling
- `lib/hoplixi_store/hoplixi_store.dart` описывает Drift-схему; любые новые таблицы регистрируйте там и синхронизируйте с `lib/hoplixi_store/sql/triggers.dart` для аудита.
- DAOs располагаются в `lib/hoplixi_store/dao/`; сервисы поверх них — в `lib/hoplixi_store/repository/`, возвращают `Result<T, E>` (см. `lib/core/utils/result_pattern/`). В legacy-сервисах (`password_service.dart`) всё ещё встречается `ServiceResult` — при доработках переводите на `Result`.
- Используйте `hoplixi_store/utils/uuid_generator.dart` для идентификаторов и `core/lib/box_db_new/` для работы с зашифрованными полями.
- Логирование делайте через `core/logger/app_logger.dart` (`logInfo/logDebug/logError` с тегом компонента); не выводите в логи сырой текст секретов.

### State & Providers
- Провайдеры для БД и сервисов объявлены в `lib/hoplixi_store/providers/service_providers.dart` и `hoplixi_store_providers.dart`; UI-слои подписываются только на эти провайдеры.
- Состояние экранов оформляйте через Notifier/AsyncNotifier/StreamNotifier (`lib/features/...`), возвращая `Result` в сервисах и преобразуя в UI-состояния.
- Для уведомлений и ошибок используйте `core/utils/toastification.dart`, `core/utils/scaffold_messenger_manager/`, а также `ToastManager` из `lib/core/utils/toast/toast_manager.dart`.

### Security & Platform Concerns
- SQLCipher и пути БД управляются сервисами (`hoplixi_store_manager.dart`, `core/lib/box_db_new/storage_manager.dart`); UI не открывает соединения напрямую.
- При работе с вложениями и экспортом опирайтесь на `features/password_manager/dashboard/...` и `features/password_manager/cloud_sync/` (есть план-конспекты и README для протоколов).
- Любые сетевые или файловые операции должны переводить ошибки в `AppError/DbError/...` (см. `lib/app/errors/`).

### Extending Domain Functionality
- Новая сущность: таблица в `lib/hoplixi_store/tables/`, DAO, сервис и провайдер; ориентируйтесь на `passwords_*` и `totps_*` файлы. Не забудьте обновить enum/константы в `lib/hoplixi_store/enums/` и `DATABASE_SCHEMA.md`.
- Добавляя экран, зарегистрируйте маршрут в `lib/app/router/routes.dart`, провайдеры в соответствующем feature-модуле и не обходите сервисный слой.
- Для миграций и аудита проверяйте `assets/MIGRATION_GUIDE.md` и `lib/hoplixi_store/sql/`.

### Developer Workflow
- Запускайте генерацию кода через `build_runner.bat` (обёртка над `dart run build_runner build --delete-conflicting-outputs`).
- Тесты: `flutter test --no-pub`, прицельные тесты расположены в `test/features/...`.
- Локальный запуск: `flutter run -d windows`; релиз — `flutter build apk`, `flutter build windows` или `release.bat` (fastforge пакет).
- Логи приложения пишутся в `core/logger/file_manager.dart`; для очистки/экспорта используйте соответствующие сервисы (см. `features/settings/screens/settings_screen.dart`).


### Last Checks Before Commit
- Убедитесь, что цепочка UI → Provider → Service → DAO соблюдена и нет прямых вызовов DAO из UI.
- Проверьте, что новые операции возвращают `Result<T, E>` и что ошибки конвертируются в типизированные `AppError`/`DbError`.
- После генерации нет «грязных» `*.g.dart`/`*.freezed.dart`, а логи не содержат секретов.

### Замечания

- При создании freezed классов используйте аннотацию `@freezed`, и добавляйте классу abstract class, а не обычный класс. Это необходимо для корректной работы генерации кода и обеспечения неизменяемости объектов.

### Вспомогательная информация
abstract class
Ключевые особенности:
- Нельзя создать экземпляр напрямую (new).
- Можно наследовать или реализовывать (extends / implements).
- Может содержать абстрактные методы, которые должны быть реализованы в наследниках.
- Может использоваться как базовый класс для расширения иерархий.

sealed class
Ключевые особенности:
- Также нельзя создавать экземпляр напрямую.
- Ключевое отличие: наследоваться можно только внутри того же файла.
- Вне этого файла sealed класс считается закрытым для расширения.
- Используется для ограниченных иерархий типов (как enum, но с гибкостью классов).
- Отлично работает с switch и pattern matching.

### MCP Servers

- Для получения актуальной документации библиотек обращайтесь к MCP серверу context7.
- Для сложных многошаговых сценариев используйте SequentialThinking MCP (гарантия порядка, удержание долгих задач, метрики).

Нужны дополнительные примеры (новый сервис/триггер/провайдер) — сформулируйте сущность и цель и укажите ближайший аналог в коде.

