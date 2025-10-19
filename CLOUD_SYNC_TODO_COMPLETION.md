# Завершение TODO для облачной синхронизации

## Выполненные задачи

### 1. ✅ Получение реального clientKey из OAuth2

**Создан провайдер**: `lib/features/password_manager/cloud_sync/providers/active_client_key_provider.dart`

**Принцип работы**:
- Получает метаданные текущей открытой БД
- Находит LocalMeta запись по dbId
- Определяет providerType (dropbox, yandex, google, microsoft)
- Преобразует providerType в clientKey через маппинг:
  - `ProviderType.dropbox` → `'dropbox'`
  - `ProviderType.yandex` → `'yandex_disk'`
  - `ProviderType.google` → `'google_drive'`
  - `ProviderType.microsoft` → `'onedrive'`

**Использование**:
```dart
// В async контексте
final clientKey = await ref.read(activeClientKeyProvider.future);
if (clientKey != null) {
  // Используем clientKey для операций
}
```

### 2. ✅ Раскомментирован экспорт при закрытии БД

**Файл**: `lib/hoplixi_store/providers/hoplixi_store_providers.dart`

**Изменения** (строки 220-260):
- Раскомментирована логика автоматического экспорта
- Добавлено получение clientKey через `activeClientKeyProvider`
- Экспорт запускается в фоне через `unawaited()` чтобы не блокировать закрытие БД
- Добавлена обработка ошибок с логированием
- Если clientKey не найден, логируется предупреждение и закрытие продолжается

**Поведение**:
- При закрытии БД проверяется: была ли она изменена (`isModified`)
- Проверяется настройка `autoSyncCloud` из `Prefs`
- Если условия выполнены — запускается экспорт в облако
- Экспорт выполняется асинхронно, не блокируя UI

**Добавлены импорты**:
```dart
import 'package:hoplixi/features/password_manager/cloud_sync/providers/cloud_export_provider.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/active_client_key_provider.dart';
```

### 3. ✅ Реализован функционал retry

#### CloudExportNotifier (`cloud_export_provider.dart`)

**Добавлены поля**:
```dart
String? _lastClientKey;
String? _lastEncryptionKeyArchive;
```

**Добавлен метод**:
```dart
Future<void> retry() async {
  if (_lastClientKey != null) {
    await exportCurrentStorage(
      clientKey: _lastClientKey!,
      encryptionKeyArchive: _lastEncryptionKeyArchive,
    );
  } else {
    logWarning('Нет сохранённых параметров для retry', tag: _tag);
  }
}
```

**Принцип работы**:
- При каждом вызове `exportCurrentStorage()` параметры сохраняются
- Кнопка "Повторить" вызывает `retry()`, который повторяет последнюю операцию

#### CloudImportNotifier (`cloud_import_provider.dart`)

**Добавлены поля**:
```dart
String? _lastClientKey;
CloudVersionInfo? _lastVersionInfo;
```

**Добавлены методы**:
```dart
Future<void> retryCheckVersion() async {
  if (_lastClientKey != null) {
    await checkForNewVersion(clientKey: _lastClientKey!);
  } else {
    logWarning('Нет сохранённых параметров для retry', tag: _tag);
  }
}

Future<void> retryDownloadAndReplace() async {
  if (_lastClientKey != null && _lastVersionInfo != null) {
    await downloadAndReplace(
      clientKey: _lastClientKey!,
      versionInfo: _lastVersionInfo!,
    );
  } else {
    logWarning('Нет сохранённых параметров для retry', tag: _tag);
  }
}
```

**Принцип работы**:
- При вызове `checkForNewVersion()` сохраняется `clientKey`
- При вызове `downloadAndReplace()` сохраняются `clientKey` и `versionInfo`
- Есть два метода retry для разных сценариев

### 4. ✅ Обновлены UI компоненты

#### CloudImportProgressScreen

**Файл**: `lib/features/password_manager/cloud_sync/screens/cloud_import_progress_screen.dart`

**Изменения**:
- Добавлен импорт `active_client_key_provider.dart`
- В кнопке "Скачать и установить" (строка 182):
  - Получение clientKey через `activeClientKeyProvider`
  - Проверка наличия clientKey с отображением SnackBar при ошибке
- В кнопке "Повторить" при ошибке (строка 464):
  - Вызов `ref.read(cloudImportProvider.notifier).retryDownloadAndReplace()`

#### CloudExportProgressDialog

**Файл**: `lib/features/password_manager/cloud_sync/widgets/cloud_export_progress_dialog.dart`

**Изменения**:
- В кнопке "Повторить" при ошибке (строка 239):
  - Вызов `ref.read(cloudExportProvider.notifier).retry()`
  - Удалён вызов `reset()` и `pop()` — диалог остаётся открытым для отслеживания повторной попытки

#### DashboardScreen

**Файл**: `lib/features/password_manager/dashboard/screens/dashboard_screen.dart`

**Изменения**:
- Добавлен импорт `active_client_key_provider.dart`
- В методе `_checkForNewVersion()` (строка 55):
  - Получение clientKey через `activeClientKeyProvider`
  - Проверка наличия clientKey перед вызовом `checkForNewVersion()`

## Архитектурные решения

### Маппинг ProviderType → clientKey

**Проблема**: В `LocalMeta` хранится `providerType` (enum), но для OAuth2 нужен `clientKey` (string).

**Решение**: Создана функция `_getClientKeyFromProvider()` в `active_client_key_provider.dart`, которая преобразует enum в строковый ключ.

**Обоснование**:
- Не требуется изменение схемы БД
- Соответствует naming convention провайдеров в OAuth2AccountService
- Централизованная логика маппинга в одном месте

### Хранение параметров для retry

**Проблема**: Как повторить операцию после ошибки без передачи параметров через UI?

**Решение**: Провайдеры сохраняют параметры последнего вызова в приватных полях.

**Обоснование**:
- Минимальные изменения в Freezed state (не требуется добавление полей)
- Простая реализация retry без дублирования логики
- Чистый UI-код без необходимости хранения параметров в widget state

### Асинхронный экспорт при закрытии БД

**Проблема**: Экспорт может быть длительным, блокируя закрытие БД.

**Решение**: Использование `unawaited()` для запуска экспорта в фоне.

**Обоснование**:
- Не блокирует UI
- Закрытие БД происходит быстро
- Если экспорт упадёт — это не прервёт работу приложения
- Логирование ошибок позволяет отследить проблемы

## Файлы с изменениями

1. ✅ `lib/features/password_manager/cloud_sync/providers/active_client_key_provider.dart` — **создан**
2. ✅ `lib/features/password_manager/cloud_sync/providers/cloud_export_provider.dart` — добавлены поля и метод retry
3. ✅ `lib/features/password_manager/cloud_sync/providers/cloud_import_provider.dart` — добавлены поля и методы retry
4. ✅ `lib/features/password_manager/cloud_sync/screens/cloud_import_progress_screen.dart` — обновлены кнопки
5. ✅ `lib/features/password_manager/cloud_sync/widgets/cloud_export_progress_dialog.dart` — обновлена кнопка retry
6. ✅ `lib/features/password_manager/dashboard/screens/dashboard_screen.dart` — обновлен `_checkForNewVersion()`
7. ✅ `lib/hoplixi_store/providers/hoplixi_store_providers.dart` — раскомментирован экспорт

## Статус компиляции

✅ **Все файлы облачной синхронизации компилируются без ошибок**

## Следующие шаги

1. **Тестирование**:
   - Проверить автоматический экспорт при закрытии БД
   - Протестировать retry функциональность в UI
   - Убедиться, что clientKey корректно получается из activeClientKeyProvider

2. **Документация**:
   - Обновить `CLOUD_SYNC_IMPLEMENTATION_SUMMARY.md` с новыми деталями
   - Добавить примеры использования activeClientKeyProvider

3. **Потенциальные улучшения**:
   - Добавить индикатор фонового экспорта при закрытии БД
   - Реализовать отмену retry операции
   - Добавить счётчик попыток retry с максимальным лимитом

## Примеры использования

### Получение clientKey в любом месте приложения

```dart
// В async контексте
final clientKey = await ref.read(activeClientKeyProvider.future);
if (clientKey != null) {
  print('Active clientKey: $clientKey');
} else {
  print('Облачная синхронизация не настроена');
}

// В Widget с Consumer
ref.listen(activeClientKeyProvider, (previous, next) {
  next.whenData((clientKey) {
    if (clientKey != null) {
      // Доступен clientKey
    }
  });
});
```

### Retry после ошибки экспорта

```dart
// В CloudExportProgressDialog
FilledButton.icon(
  onPressed: () {
    ref.read(cloudExportProvider.notifier).retry();
  },
  icon: const Icon(Icons.refresh),
  label: const Text('Повторить'),
),
```

### Retry после ошибки импорта

```dart
// В CloudImportProgressScreen
FilledButton.icon(
  onPressed: () {
    ref.read(cloudImportProvider.notifier).retryDownloadAndReplace();
  },
  icon: const Icon(Icons.refresh),
  label: const Text('Повторить'),
),
```

## Заключение

Все три TODO завершены:

1. ✅ Реальный clientKey получается из OAuth2 через activeClientKeyProvider
2. ✅ Экспорт при закрытии БД раскомментирован и активен
3. ✅ Retry функциональность полностью реализована в провайдерах и UI

Система облачной синхронизации готова к тестированию и использованию.
