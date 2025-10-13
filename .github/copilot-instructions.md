## Hoplixi — Быстрый онбординг для AI
Flutter пароль-менеджер на SQLCipher + Drift + Riverpod v3. Все секреты шифруются локально и никогда не попадают в логи.

### Архитектура и данные
- UI в `lib/features/...` работает только через провайдеры (`<Domain><Role>Provider`) на базе Notifier/AsyncNotifier/StreamNotifier.
- Провайдеры вызывают сервисы `lib/hoplixi_store/repository/*.dart`, которые оборачивают операции в `ServiceResult<T>` и логируют через `core/logger/app_logger.dart`.
- Сервисы обращаются к DAO (`lib/hoplixi_store/dao`) и `hoplixi_store.dart`; SQL триггеры из `lib/hoplixi_store/sql/` ведут аудит изменений.
- UUID v4 (`hoplixi_store/utils/uuid_generator.dart`) обязательны для идентификаторов; секреты не возвращаются наружу и не логируются.
- Для полей с секретами используйте новые примитивы `core/lib/box_db_new/`.

### UI и взаимодействие
- Общие компоненты (`SmoothButton`, `PasswordField`, `SliderButton`) лежат в `lib/common/` и предпочтительны вместо чистого Material.
- Навигация централизована в GoRouter (`lib/router`); новые экраны регистрируются там и подписываются на провайдеры.
- Уведомления и ошибки выводите через `core/utils/toastification.dart` и `core/utils/scaffold_messenger_manager/`.

### Расширение доменных сущностей
1. Таблица: `lib/hoplixi_store/tables/<entity>.dart`, затем зарегистрировать в `@DriftDatabase` (`hoplixi_store.dart`).
2. DAO: `lib/hoplixi_store/dao/<entity>_dao.dart`, ориентируясь на `passwords_dao.dart`/`totps_dao.dart` для потоков и фильтров.
3. Сервис: `lib/hoplixi_store/repository/<entity>_service.dart`, оборачивая транзакции и проверки в `ServiceResult`.
4. При необходимости обновить триггеры (`lib/hoplixi_store/sql/triggers.dart`) и истории.

### Логирование и безопасность
- Используйте `logInfo/logDebug/logError` с тегом компонента; исключения не пробрасываются наружу, а переводятся в `ServiceResult.failure`.
- UI получает только безопасные сообщения без plaintext секретов; истории и метаданные ведутся триггерами Drift.

### Рабочие процессы
- Генерация: `build_runner.bat` (запускает `dart run build_runner build --delete-conflicting-outputs`) после изменений Drift/Freezed/DTO.
- Тесты: `flutter test --no-pub` (`test/features/...`).
- Запуск: `flutter run -d windows`; релизные сборки `flutter build apk`, `flutter build windows`, `release.bat` собирает пакет.
- Инициализацию SQLCipher и подключений выполняют сервисы; UI не открывает соединения с БД напрямую.

### Чек перед коммитом
- [ ] Цепочка UI → Provider → Service → DAO соблюдена, прямых DAO вызовов из UI нет.
- [ ] Все публичные операции возвращают `ServiceResult` и корректно переводят ошибки.
- [ ] После генерации нет устаревших `*.g.dart`/`*.freezed.dart`.
- [ ] Логи и пользовательские сообщения проверены на отсутствие секретов.

## Замечания

- При создании freezed классов используйте аннотацию `@freezed`, и добавляйте классу abstract class, а не обычный класс. Это необходимо для корректной работы генерации кода и обеспечения неизменяемости объектов.

## MCP Servers

- Для получения актуальной документации библиотек обращайтесь к MCP серверу context7.
- Для сложных многошаговых сценариев используйте SequentialThinking MCP (гарантия порядка, удержание долгих задач, метрики).

Нужны дополнительные примеры (новый сервис/триггер/провайдер) — сформулируйте сущность и цель и укажите ближайший аналог в коде.

