# Hoplixi — Быстрый онбординг для AI

Пароль-менеджер на Flutter: локально зашифрованная SQLite (SQLCipher + Drift) + сервисный слой + Riverpod v3 Notifier API. Секреты или расшифрованные данные НИКОГДА не пишутся в логи и не возвращаются наружу напрямую.

## Оглавление

1. Архитектурное ядро
2. Быстрый старт (Quick Start)
3. Result Pattern — примеры
4. Добавление новой сущности (Entity Lifecycle)
5. Добавление нового экрана / маршрута
6. Пример сервиса и провайдера
7. Логирование и безопасность
8. Чеклист перед коммитом
9. Частые ошибки и анти-паттерны
10. MCP Servers и расширенные сценарии
11. Запрос дополнительных примеров

## 1. Архитектурное ядро

- Все операции возвращают `Result<T, E>` (sealed классы через freezed) вместо устаревшего `ServiceResult`.
- Ошибки типизированы: `AppError`, `DbError`, `CryptoError`, `ImportExportError`, `SyncError` и др. Railway-oriented flow: либо Ok, либо Err.
- UI слой работает только через провайдеры (`<Domain><Role>Provider`) на базе `Notifier` / `AsyncNotifier` / `StreamNotifier` (Riverpod v3). Нет прямых вызовов DAO из UI.
- Провайдеры вызывают сервисы `lib/hoplixi_store/repository/*.dart`, которые:
  - инкапсулируют логику,
  - конвертируют исключения/ошибки в доменные `Result`,
  - логируют через `core/logger/app_logger.dart` (без секретов).
- Сервисы используют DAO (`lib/hoplixi_store/dao/`) и схему `hoplixi_store.dart`. Аудит через SQL триггеры `lib/hoplixi_store/sql/`.
- UUID v4 (`lib/hoplixi_store/utils/uuid_generator.dart`) — обязательный формат идентификаторов для новых записей.
- Для шифруемых полей используйте примитивы из `core/lib/box_db_new/` (никакой ручной криптографии в UI).

## 2. Быстрый старт (Quick Start)

1. Запуск кодогенерации: запустите `build_runner.bat` (обертка над `dart run build_runner build --delete-conflicting-outputs`).
2. Старт приложения локально (пример для Windows): `flutter run -d windows`.
3. Тесты: `flutter test --no-pub` (прицельные тесты лежат в `test/features/...`).
4. После добавления freezed классов или drift схемы — снова запустите кодогенерацию.
5. Перед добавлением новой сущности прочитайте `assets/MIGRATION_GUIDE.md` и обновите `DATABASE_SCHEMA.md` (если есть; иначе добавьте/расширьте документирование схемы).

## 3. Result Pattern — примеры

Минимальный пример создания Result через freezed:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T, E> with _$Result<T, E> {
  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E error) = Err<T, E>;
}

// Использование в сервисе
Future<Result<User, AppError>> getUser(String id) async {
  try {
    final row = await _dao.findUser(id);
    if (row == null) {
      return const Result.err(AppError.notFound('user')); // Пример доменной ошибки
    }
    return Result.ok(row.toDomain());
  } catch (e, st) {
    logError('UserService', 'getUser failed', e, st);
    return Result.err(AppError.unexpected(e));
  }
}
```

Разбор в UI провайдере:
```dart
final userProvider = AsyncNotifierProvider<UserNotifier, AsyncValue<User>>(() => UserNotifier());

class UserNotifier extends AsyncNotifier<AsyncValue<User>> {
  @override
  Future<AsyncValue<User>> build() async {
    final service = ref.read(userServiceProvider);
    final result = await service.getUser(ref.read(selectedUserIdProvider));
    return result.map(
      ok: (u) => AsyncValue.data(u),
      err: (e) => AsyncValue.error(e, StackTrace.current),
    );
  }
}
```

## 4. Добавление новой сущности (Entity Lifecycle)

Шаги (ориентируйтесь на `passwords_*`, `totps_*`):

1. Drift таблица: обновите `lib/hoplixi_store/hoplixi_store.dart` (или вынесенную секцию в `tables/`).
2. Триггеры аудита: синхронизируйте с `lib/hoplixi_store/sql/triggers.dart` (добавьте INSERT/UPDATE/DELETE аудит при необходимости).
3. DAO: создайте файл в `lib/hoplixi_store/dao/` (`<entity>_dao.dart`). Интерфейс: CRUD + поисковые операции. Без UI логики.
4. Модель домена: `@freezed` дата-класс в `lib/hoplixi_store/models/` (если папка отсутствует — создайте). Только публичные поля без секретов в расшифрованном виде.
5. Сервис: `lib/hoplixi_store/repository/<entity>_service.dart`. Конвертация исключений → `Result`, логирование.
6. Провайдеры: зарегистрируйте сервис в `lib/hoplixi_store/providers/service_providers.dart` или профильный файл. Экранные провайдеры — в `lib/features/<domain>/...`.
7. Enum/константы: если нужны — обновите `lib/hoplixi_store/enums/`.
8. Документация: обновите `DATABASE_SCHEMA.md` и при необходимости README домена.
9. Тесты: добавьте unit тесты DAO (используя тестовую зашифрованную БД) и сервисов.
10. Запустите кодогенерацию и тесты.

## 5. Добавление нового экрана / маршрута

1. Создайте экран в `lib/features/<domain>/screens/`.
2. Состояние: `Notifier`/`AsyncNotifier` в `lib/features/<domain>/providers/`.
3. Маршрут: добавьте в `lib/app/router/routes.dart` (и при необходимости в `router_provider.dart`).
4. DI: экран подписывается на уже объявленные сервисные провайдеры — не вызывает DAO.
5. UI-компоненты: используйте `lib/common/` (например, `SmoothButton`, `PasswordField`).
6. Ошибки → Toastification / ScaffoldMessenger / `ToastManager`.

## 6. Пример сервиса и провайдера

```dart
// lib/hoplixi_store/repository/my_entity_service.dart
class MyEntityService {
  final MyEntityDao _dao;
  MyEntityService(this._dao);

  Future<Result<MyEntity, AppError>> create(MyEntityDraft draft) async {
    try {
      final id = generateUuidV4();
      final row = draft.toCompanion(id);
      await _dao.insert(row);
      return Result.ok(row.toDomain());
    } on DriftException catch (e, st) {
      logError('MyEntityService', 'create drift error', e, st);
      return Result.err(DbError.write(e.message));
    } catch (e, st) {
      logError('MyEntityService', 'create unexpected', e, st);
      return Result.err(AppError.unexpected(e));
    }
  }
}

// Провайдер сервиса
final myEntityServiceProvider = Provider<MyEntityService>((ref) {
  final dao = ref.watch(myEntityDaoProvider);
  return MyEntityService(dao);
});

// Экранный провайдер
final myEntityCreateNotifierProvider = AsyncNotifierProvider<MyEntityCreateNotifier, AsyncValue<MyEntity>>(
  () => MyEntityCreateNotifier(),
);

class MyEntityCreateNotifier extends AsyncNotifier<AsyncValue<MyEntity>> {
  @override
  Future<AsyncValue<MyEntity>> build() async => const AsyncValue<MyEntity>.loading();

  Future<void> submit(MyEntityDraft draft) async {
    final service = ref.read(myEntityServiceProvider);
    state = const AsyncValue.loading();
    final result = await service.create(draft);
    state = result.map(
      ok: (e) => AsyncValue.data(e),
      err: (err) => AsyncValue.error(err, StackTrace.current),
    );
  }
}
```

## 7. Логирование и безопасность

- Используйте `logInfo/logDebug/logError` из `core/logger/app_logger.dart` с тегом компонента.
- Никогда не логируйте: пароли, ключи, расшифрованные секреты, токены.
- Для сложных операций (импорт/экспорт, синхронизация) логируйте этапы, но не payload.
- Любые ошибки внешних операций приводите к типизированным: например, файловая ошибка → `ImportExportError.io`, сеть → `SyncError.network`.
- В UI отдавайте только безопасные поля. Шифрование/дешифрование остаётся в сервисах/инфраструктуре.

## 8. Чеклист перед коммитом

1. Нет прямых DAO вызовов из UI.
2. Все новые методы возвращают `Result<T, AppError|DbError|...>`.
3. Freezed классы: `@freezed` + abstract sealed, корректные части `part 'x.freezed.dart';`.
4. Кодогенерация выполнена (`build_runner.bat`), нет грязных *.g.dart/*.freezed.dart.
5. Логи не содержат секретов (проверьте файл логов через сервис экспорта).
6. Маршруты/провайдеры зарегистрированы (router + providers).
7. Миграции/триггеры синхронизированы (если менялась схема).
8. Тесты проходят (`flutter test --no-pub`).
9. Ошибки корректно мапятся в UI (Toast / состояния).
10. Обновлены документационные файлы (DATABASE_SCHEMA.md, README домена при необходимости).

## 9. Частые ошибки и анти-паттерны

| Анти-паттерн | Почему плохо | Правильный путь |
|--------------|-------------|-----------------|
| Логирование расшифрованного секрета | Утечка безопасности | Логируйте только метаданные / id |
| Прямой доступ до DAO из виджета | Нарушение слоёв | Используйте сервисный провайдер |
| Возврат `null` вместо `Result.err` | Потеря контекста ошибки | Всегда Err с типом |
| Смешение UI и криптографии | Трудно тестировать, риск утечки | Крипто в инфраструктуре (`box_db_new`) |
| Игнор стека при логировании | Сложная отладка | Передавайте `e, st` в `logError` |

## 10. MCP Servers и расширенные сценарии

- Документация библиотек: запрос через MCP сервер `context7` (получите актуальные сигнатуры и паттерны использования).
- Многошаговые задачи (миграции, рефакторинг сервисов): используйте SequentialThinking MCP — фиксирует план, даёт метрики прогресса.

## 11. Запрос дополнительных примеров

Сформулируйте: (а) тип артефакта — сервис / триггер / провайдер / тест; (б) цель (например: "аудит удаления вложений"), (в) ближайший аналог (например: `passwords_trigger`). Я сгенерирую шаблон.

## Дополнительные замечания о freezed

- Используйте `@freezed` поверх abstract sealed класса.
- Не создавайте экземпляры через конструкторы приватных реализаций — только фабрики.
- После добавления — запускайте билд (иначе ошибка отсутствующих частей).

## Примечание

Документ предназначен для ускорения онбординга AI/разработчиков. При расхождении с более подробным `copilot-instructions.md` — сверяйтесь с ним и обновляйте этот файл.

