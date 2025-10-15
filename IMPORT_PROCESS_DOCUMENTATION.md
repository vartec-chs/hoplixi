# Документация: Процесс импорта хранилища из облака

## Обзор

Процесс импорта хранилища из Dropbox был разделён на несколько этапов для улучшения UX и управляемости.

## Архитектура

### Основные компоненты

1. **ImportDropboxService** (`lib/features/password_manager/new_cloud_sync/services/import_service.dart`)
   - `checkForNewVersion()` - проверяет наличие новой версии в облаке
   - `downloadArchive()` - скачивает архив с прогрессом
   - `replaceDatabase()` - распаковывает и заменяет БД

2. **CloudSyncNotifier** (`lib/features/password_manager/new_cloud_sync/providers/cloud_sync_provider.dart`)
   - `checkForNewVersion()` - инициирует проверку и создаёт сессию импорта
   - Уведомляет dashboard о необходимости навигации

3. **ImportSessionNotifier** (`lib/features/password_manager/new_cloud_sync/providers/import_session_provider.dart`)
   - Управляет состоянием сессии импорта
   - `executeImport()` - выполняет полный цикл импорта
   - `openWithPassword()` - открывает БД с паролем от пользователя

4. **ProcessImportedStoreScreen** (`lib/features/password_manager/new_cloud_sync/screens/process_imported_store.dart`)
   - UI экран процесса импорта
   - Показывает прогресс, текущий этап
   - Запрашивает пароль если не сохранён

### Модели данных

1. **CloudVersionInfo** - информация о версии в облаке
   ```dart
   - timestamp: DateTime
   - fileName: String
   - cloudPath: String
   - isNewer: bool
   - fileSize: int?
   ```

2. **ImportSessionState** - состояние сессии импорта
   ```dart
   - metadata: DatabaseMetaForSync
   - versionInfo: CloudVersionInfo?
   - downloadPath: String?
   - importedDbPath: String?
   - progress: double (0.0 - 1.0)
   - currentStep: ImportStep
   - message: String
   - error: String?
   - clientKey: String
   - encryptionKeyArchive: String?
   ```

3. **ImportStep** enum - этапы процесса
   ```dart
   - checking    // Проверка новой версии
   - downloading // Скачивание архива
   - replacing   // Замена БД
   - opening     // Открытие БД
   - completed   // Завершено
   - error       // Ошибка
   ```

## Процесс импорта

### 1. Автоматическая проверка при открытии БД

```dart
// hoplixi_store_providers.dart
if (isCloudSyncEnabled && metadata != null) {
  ref.read(cloudSyncProvider.notifier)
     .checkForNewVersion(metadata: metadata);
}
```

### 2. Обнаружение новой версии

`CloudSyncNotifier.checkForNewVersion()`:
- Авторизуется в Dropbox
- Вызывает `ImportDropboxService.checkForNewVersion()`
- Если найдена новая версия → создаёт `ImportSessionState`
- Устанавливает состояние `CloudSyncState.success()`

### 3. Навигация на экран импорта

```dart
// dashboard_screen.dart
ref.listen(cloudSyncProvider, (previous, next) {
  if (wasImporting && message.contains('Найдена новая версия')) {
    context.push(AppRoutes.processImportedStore);
  }
});
```

### 4. Выполнение импорта

`ProcessImportedStoreScreen` автоматически запускает:

```dart
ref.read(importSessionProvider.notifier).executeImport();
```

Этапы:
1. **Checking** (0-20%) - Проверка версии
2. **Downloading** (20-60%) - Скачивание архива
3. **Replacing** (60-90%) - Закрытие старой БД, распаковка новой
4. **Opening** (90-100%) - Получение пароля и открытие

### 5. Получение пароля

Провайдер пытается получить сохранённый пароль через `DatabaseHistoryServiceV2`:

```dart
final historyService = await manager.getHistoryService();
final entry = await historyService.getEntryByPath(dbPath);
final password = entry.masterPassword;
```

Если пароль не найден:
- UI показывает поле ввода пароля
- Пользователь вводит пароль
- Вызывается `openWithPassword(password, dbPath)`

### 6. Завершение

После успешного импорта:
- Состояние → `ImportStep.completed`
- Автоматическая навигация на dashboard (2 сек задержка)

## Использование

### Ручной запуск проверки

```dart
await ref.read(cloudSyncProvider.notifier).checkForNewVersion(
  metadata: metadata,
  encryptionKeyArchive: null,
);
```

### Доступ к состоянию сессии

```dart
final session = ref.watch(importSessionProvider);
if (session != null) {
  print('Прогресс: ${session.progress}');
  print('Этап: ${session.currentStep}');
  print('Сообщение: ${session.message}');
}
```

### Сброс сессии

```dart
ref.read(importSessionProvider.notifier).reset();
```

## Маршрутизация

Добавлен маршрут в `lib/app/router/routes_path.dart`:

```dart
static const String processImportedStore = '/process-imported-store';
```

Регистрация в `lib/app/router/routes.dart`:

```dart
GoRoute(
  path: AppRoutes.processImportedStore,
  builder: (context, state) => const ProcessImportedStoreScreen(),
)
```

## Обработка ошибок

Все ошибки логируются через `logError()` и устанавливают:
- `ImportStep.error`
- `error` message в состоянии
- UI показывает кнопки "Повторить" и "Отменить"

## Логирование

Тег для логов: `ImportSessionNotifier`, `CloudSyncProvider`, `ImportDropboxService`

Примеры:
```dart
logInfo('Начата новая сессия импорта', tag: _tag);
logError('Ошибка при импорте', error: e, stackTrace: st);
```

## Тестирование

Для тестирования:
1. Включите автосинхронизацию в настройках
2. Создайте экспорт в облако
3. Откройте БД → автоматически запустится проверка
4. Если есть новая версия → откроется экран импорта

## Миграция со старого подхода

Старый метод `importFromDropbox` помечен как `@Deprecated`:
```dart
@Deprecated('Используйте checkForNewVersion и navigate к процессу импорта')
Future<void> importFromDropbox(...)
```

Рекомендуется использовать новый подход с разделением на этапы.
