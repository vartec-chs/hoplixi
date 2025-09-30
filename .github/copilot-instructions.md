## Hoplixi – Инструкции для AI агентов (актуализировано)
Flutter пароль-менеджер: локальная зашифрованная SQLite (SQLCipher + Drift), сервисно-ориентированная архитектура, Riverpod v3 (Notifier API only), строгий слой сервисов и кастомные UI-компоненты.

### 1. Архитектурное ядро
- `lib/hoplixi_store/`: Drift таблицы, DAO, сервисы, результаты (`service_results.dart`), SQL-триггеры истории.
- `lib/box_db/`: низкоуровневое шифрование (`crypto_box.dart`, `simple_box.dart`, `utils.dart`).
- `lib/features/*`: доменные модули (пример: `password_manager`, `totp`, `setup`, `home`).
- `lib/common/`: обязательные UI-компоненты (`button.dart`, `password_field.dart`, `text_field.dart`, `slider_button.dart`).
- `lib/core/`: логгер (`app_logger.dart`), тема, preferences, secure storage, toast (`toastification.dart`).
- `lib/router/`: GoRouter + анимации. Новые экраны регистрировать здесь.

### 2. Ключевой поток данных
UI -> (Providers Riverpod) -> Service -> DAO -> Drift/SQLCipher.
UI никогда напрямую к DAO. Ошибки и статусы наружу только через `ServiceResult<T>`.

Пример использования:
```dart
final r = await ref.read(totpServiceProvider).getTotpById(id);
if (!r.success) ToastHelper.error(r.message); else use(r.data);
```

### 3. ServiceResult контракт
`class ServiceResult<T>{ final bool success; final String? message; final T? data; }`
- Не выбрасывать исключения наружу; логировать и возвращать `success:false`.
- Сообщения – пользовательски безопасные, без чувствительных деталей.

### 4. Шифрование и безопасность
- Перед записью шифруем: см. сервисы и `crypto_box.dart` (`encryptUtf8WithAutoNonce`) → { nonce, cipher, tag }.
- Валидация/дешифровка: `simple_box.dart`.
- Для новых секретных полей повторить паттерн (nonce + auth tag). НИКОГДА не логировать plaintext.
- UUID v4 для всех первичных ключей.

### 5. Генерация / кодоген
- Изменили Drift таблицу / Freezed / JSON → запуск `build_runner.bat` (или `dart run build_runner build --delete-conflicting-outputs`).
- Не коммитить, если генерация не актуальна.

### 6. Riverpod правила
- Только Notifier / AsyncNotifier / StreamNotifier. Не добавлять ConsumerWidget / legacy API.
- Провайдеры живут внутри своей фичи или в общей папке, следуя существующим именованиям (`*_provider.dart`).

### 7. UI / дизайн
- Кнопки: `SmoothButton`; подтверждение действия (удаление/опасное) → `SliderButton`.
- Поля ввода: `TextField` / `PasswordField` из `common/`.
- Цвета/темы: `core/theme/colors.dart`, состояние темы через `themeProvider`.
- Responsive брейкпоинты: MOBILE ≤450, TABLET 451–1000, DESKTOP ≥1001.

### 8. Добавление новой сущности (данные)
1. Таблица: `hoplixi_store/tables/<entity>.dart`.
2. DAO: `hoplixi_store/dao/<entity>_dao.dart`.
3. Подключить в `hoplixi_store.dart` (@DriftDatabase).
4. Кодоген.
5. Сервис: `hoplixi_store/services/<entity>_service.dart` по шаблону (`password_service.dart`, `totp_service.dart`).
6. При необходимости обновить SQL-триггеры истории.

### 9. Создание фичи
Структура: `features/<name>/` (widgets, screens, providers, services usage). Роут добавить в `router/`. Использовать существующие названия для единообразия.

### 10. Логирование и ошибки
- Использовать `logInfo/logError/logDebug` из `app_logger.dart`; не писать секреты/пароли/TOTP.
- Пользовательские уведомления: `ToastHelper` (`toastification.dart`).
- В сервисе перехватить исключение, залогировать минимум контекста, вернуть `ServiceResult`.

### 11. Сборка и релиз
- Локально: сначала кодоген.
- Windows: `flutter build windows`; Android: `flutter build apk`.
- Скрипт релиза: `release.bat` (обёртка прод-сборки).
- Web намеренно отключён (не пытаться включать).

### 12. Что НЕ делать
- Не обращаться к DAO из UI / провайдера напрямую.
- Не писать сырые SQL вне Drift (кроме триггеров/редких сложных кейсов).
- Не логировать расшифрованный секрет / пароль / seed.
- Не добавлять legacy Riverpod API / Consumer*.
- Не обходить шифрование / не хранить plaintext.

### 13. MCP Servers (для агентов)
- Для поиска библиотек Dart/Flutter использовать dart mcp server.
- Для оркестрации сложных многошаговых reasoning – SequentialThinking через MCP (context7).

### 14. Быстрый чеклист перед коммитом
- [ ] Запущен build_runner без ошибок
- [ ] Все новые данные идут через сервис и `ServiceResult`
- [ ] Провайдеры используют Notifier API

Если нужен пример (новый сервис / провайдер / триггер) – запросите явно, укажите цель и сущность.