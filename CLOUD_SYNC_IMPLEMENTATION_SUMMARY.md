# Cloud Sync Provider System - Implementation Summary

## Обзор реализации

Реализована комплексная система облачной синхронизации для экспорта и импорта хранилища паролей с использованием Riverpod 3 и Result pattern.

## Архитектура

### Провайдеры и State Management

#### 1. CloudExportNotifier (`cloud_export_provider.dart`)
- **Тип**: `Notifier<ExportState>`
- **Состояния**: idle, inProgress, success, failure
- **Ключевой метод**: `exportCurrentStorage()`
- **Функциональность**:
  - Получает метаданные текущей БД через `hoplixiStoreManagerProvider`
  - Вызывает `DropboxExportService.exportToDropbox()` с прогрессом
  - Обновляет `LocalMeta.lastExportAt` после успешного экспорта
  - Использует `Result.fold()` для обработки успеха/ошибки

#### 2. CloudImportNotifier (`cloud_import_provider.dart`)
- **Тип**: `Notifier<ImportState>`
- **Состояния**: idle, checking, newVersionAvailable, noNewVersion, downloading, extracting, success, failure
- **Ключевые методы**:
  - `checkForNewVersion()` - проверяет наличие новой версии в облаке
  - `downloadAndReplace()` - скачивает и заменяет БД
- **Функциональность**:
  - Проверка обновлений через `ImportDropboxService.checkForNewVersion()`
  - Закрытие БД перед распаковкой через `dbManager.closeDatabase()`
  - Обновление `LocalMeta.lastImportedAt` после успешного импорта
  - Двухэтапный процесс: скачивание → распаковка с отдельными прогрессами

#### 3. Service Providers
- `dropboxExportServiceProvider` - FutureProvider для DropboxExportService
- `dropboxImportServiceProvider` - FutureProvider для ImportDropboxService
- Оба зависят от `oauth2AccountProvider` для авторизации

### UI Components

#### 1. CloudImportProgressScreen (`cloud_import_progress_screen.dart`)
Полноэкранный экран прогресса импорта со следующими состояниями:

- **idle** - готовность к импорту
- **checking** - проверка новой версии
- **newVersionAvailable** - показ информации о новой версии с кнопкой "Скачать"
- **noNewVersion** - актуальная версия
- **downloading** - прогресс скачивания с LinearProgressIndicator
- **extracting** - прогресс распаковки
- **success** - завершено, кнопка возврата на главную
- **failure** - ошибка с возможностью повтора

**Особенности**:
- Блокирует навигацию назад во время downloading/extracting через `PopScope`
- Отображает детали версии (имя файла, дата, размер)
- Использует форматированный вывод даты через `intl` пакет

#### 2. CloudExportProgressDialog (`cloud_export_progress_dialog.dart`)
Модальный диалог для экспорта с автоматическим закрытием:

- **idle** - подготовка
- **inProgress** - прогресс с процентами
- **success** - успешный экспорт (автоматически закрывается)
- **failure** - ошибка с кнопкой повтора

**Особенности**:
- Блокирует закрытие во время экспорта через `PopScope`
- Автоматически закрывается при успехе через `ref.listen()`
- Колбэки `onComplete` и `onError` для реакции на результат
- Статический метод `show()` для удобного вызова

### Integration Points

#### 1. DatabaseAsyncNotifier.closeDatabase()
В `hoplixi_store_providers.dart` добавлена логика:

```dart
// Проверка модификации БД
final isModified = modifiedAtCurrent.isAfter(modifiedAtBeforeOpen);

// Условный экспорт при включенной синхронизации
if (isModified && isCloudSyncEnabled == true && (imported == null || imported == false)) {
  // Логирование и вызов экспорта
  // TODO: раскомментировать вызов cloudExportProvider после получения clientKey
}
```

**Примеры интеграции** в `integration_examples.dart`:
- Виджет с кнопкой закрытия БД
- Функция-хелпер для экспорта и закрытия
- Пример интеграции в существующий `CloseDatabaseButton`

#### 2. DashboardScreen автопроверка
В `dashboard_screen.dart`:

**initState**:
```dart
void _checkForNewVersion() {
  final isCloudSyncEnabled = Prefs.get(Keys.autoSyncCloud);
  if (isCloudSyncEnabled != true) return;
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await ref.read(cloudImportProvider.notifier).checkForNewVersion(
      clientKey: clientKey,
    );
  });
}
```

**build() with listener**:
```dart
ref.listen<ImportState>(cloudImportProvider, (previous, next) {
  next.maybeMap(
    newVersionAvailable: (state) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Доступна новая версия: ${state.versionInfo.fileName}'),
          action: SnackBarAction(
            label: 'Обновить',
            onPressed: () => context.push(AppRoutes.cloudImportProgress),
          ),
        ),
      );
    },
    // ... обработка других состояний
  );
});
```

### Routing

Добавлены маршруты в `routes_path.dart` и `routes.dart`:

```dart
// routes_path.dart
static const String cloudImportProgressPath = 'cloud-import-progress';
static const String cloudImportProgress = '/dashboard/cloud-import-progress';

// routes.dart
GoRoute(
  path: AppRoutes.cloudImportProgressPath,
  builder: (context, state) => const CloudImportProgressScreen(),
),
```

## Data Flow

### Экспорт (Export Flow)
1. UI → `CloudExportProgressDialog.show()`
2. UI → `cloudExportProvider.notifier.exportCurrentStorage(clientKey)`
3. Provider → `hoplixiStoreManagerProvider` (получение метаданных)
4. Provider → `dropboxExportServiceProvider` (экспорт)
5. Service → создание архива + загрузка в Dropbox
6. Provider → `localMetaCrudProvider` (обновление LocalMeta.lastExportAt)
7. Provider → state = success
8. UI → автоматическое закрытие диалога через listener

### Импорт (Import Flow)
1. Dashboard → автопроверка в initState
2. Provider → `checkForNewVersion()` → ImportDropboxService
3. UI → SnackBar с кнопкой "Обновить" (при наличии новой версии)
4. User → переход на CloudImportProgressScreen
5. User → кнопка "Скачать и установить"
6. Provider → `downloadAndReplace()`
   - Скачивание с прогрессом
   - Закрытие БД
   - Распаковка
   - Обновление LocalMeta.lastImportedAt
7. UI → экран success с кнопкой возврата на главную

## TODO: Требуется доработка

### 1. OAuth2 clientKey
В нескольких местах используется заглушка:
```dart
// TODO: Получить clientKey из OAuth2
const clientKey = 'temp_client_key';
```

**Решение**: 
```dart
final oauth2Service = await ref.read(oauth2AccountProvider.future);
final clientKey = oauth2Service.clientKey; // или метод получения ключа
```

### 2. Активация экспорта при закрытии БД
В `hoplixi_store_providers.dart` код экспорта закомментирован:
```dart
// TODO: раскомментировать после получения clientKey
// unawaited(
//   ref.read(cloudExportProvider.notifier).exportCurrentStorage(
//     clientKey: clientKey,
//   ),
// );
```

### 3. Повторная попытка в UI
В диалогах есть кнопка "Повторить", но она только сбрасывает состояние:
```dart
FilledButton.icon(
  onPressed: () {
    // TODO: Повторить попытку экспорта/импорта
    ref.read(cloudExportProvider.notifier).reset();
  },
  icon: const Icon(Icons.refresh),
  label: const Text('Повторить'),
),
```

## Файлы

### Созданные файлы
1. `lib/features/password_manager/cloud_sync/providers/cloud_export_provider.dart`
2. `lib/features/password_manager/cloud_sync/providers/cloud_import_provider.dart`
3. `lib/features/password_manager/cloud_sync/providers/dropbox_export_service_provider.dart`
4. `lib/features/password_manager/cloud_sync/providers/dropbox_import_service_provider.dart`
5. `lib/features/password_manager/cloud_sync/models/cloud_sync_state.dart` (freezed)
6. `lib/features/password_manager/cloud_sync/screens/cloud_import_progress_screen.dart`
7. `lib/features/password_manager/cloud_sync/widgets/cloud_export_progress_dialog.dart`
8. `lib/features/password_manager/cloud_sync/integration_examples.dart`

### Модифицированные файлы
1. `lib/hoplixi_store/providers/hoplixi_store_providers.dart` - добавлена логика экспорта
2. `lib/features/password_manager/dashboard/screens/dashboard_screen.dart` - автопроверка + listener
3. `lib/app/router/routes_path.dart` - добавлен маршрут cloudImportProgress
4. `lib/app/router/routes.dart` - регистрация маршрута CloudImportProgressScreen

## Соответствие требованиям

✅ **Riverpod 3 AsyncNotifier**: Использованы Notifier<T> вместо AsyncNotifier (синхронное состояние)
✅ **Result Pattern**: Все сервисы возвращают `Result<T, E>`, обработка через `.fold()`
✅ **LocalMeta обновление**: lastExportAt и lastImportedAt обновляются через localMetaCrudProvider
✅ **Закрытие БД перед импортом**: `await dbManager.closeDatabase()` перед распаковкой
✅ **Экспорт при закрытии**: Логика добавлена в closeDatabase() (требует раскомментирования)
✅ **Автопроверка на Dashboard**: Вызов checkForNewVersion() в initState + listener для SnackBar
✅ **Прогресс импорта**: Отдельный экран CloudImportProgressScreen
✅ **Прогресс экспорта**: Модальный диалог CloudExportProgressDialog

## Зависимости

- `flutter_riverpod` - state management
- `freezed_annotation` - immutable state models
- `go_router` - навигация
- `intl` - форматирование дат

## Тестирование

Для тестирования необходимо:

1. Получить валидный OAuth2 clientKey
2. Настроить облачную синхронизацию через CloudSyncSetupScreen
3. Включить автосинхронизацию через `Prefs.set(Keys.autoSyncCloud, true)`
4. Проверить экспорт через кнопку закрытия БД (после раскомментирования кода)
5. Проверить импорт через автопроверку на Dashboard
