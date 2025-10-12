# Интеграция облачного экспорта в ExportConfirmScreen

## Изменения

Добавлена функциональность экспорта архивов в облако (Dropbox) на экран подтверждения экспорта.

## Реализация

### 1. Используется паттерн AuthModal

```dart
// Показываем AuthModal для выбора провайдера и авторизации
final clientKey = await showAuthModal(context);

if (clientKey == null) {
  // Пользователь отменил или произошла ошибка
  return;
}

// Выполняем экспорт в облако
await _performCloudExport(clientKey);
```

### 2. Workflow экспорта в облако

```
1. Пользователь создает локальный архив
   ↓
2. Нажимает "Загрузить в облако"
   ↓
3. Открывается AuthModal
   ↓
4. Пользователь выбирает провайдер (Dropbox, Google Drive и т.д.)
   ↓
5. Если есть несколько credentials - выбирает нужный
   ↓
6. Выполняется OAuth авторизация
   ↓
7. AuthModal возвращает clientKey
   ↓
8. Инициализируется dropboxServiceProvider(clientKey)
   ↓
9. Вызывается dropboxService.initialize()
   ↓
10. Вызывается dropboxService.export(archivePath)
   ↓
11. Архив загружается в облако
   ↓
12. Показывается уведомление об успехе
```

### 3. Метод _performCloudExport

```dart
Future<void> _performCloudExport(String clientKey) async {
  // 1. Получаем сервис через провайдер
  final dropboxService = await ref.read(
    dropboxServiceProvider(clientKey).future,
  );

  // 2. Инициализируем (создаем папки в Dropbox)
  final initResult = await dropboxService.initialize();
  if (!initResult.success) {
    ToastHelper.error(...);
    return;
  }

  // 3. Экспортируем архив
  final exportResult = await dropboxService.export(_exportedArchivePath!);
  
  if (exportResult.success) {
    ToastHelper.success(...);
  } else {
    ToastHelper.error(...);
  }
}
```

### 4. UI изменения

**Добавлена кнопка "Загрузить в облако":**
- Показывается только после успешного создания локального архива
- Отключается во время загрузки (`_isUploadingToCloud`)
- Показывает индикатор прогресса во время загрузки
- Кнопка "Готово" также отключается во время загрузки

```dart
SmoothButton(
  isFullWidth: true,
  label: _isUploadingToCloud 
      ? 'Загрузка в облако...' 
      : 'Загрузить в облако',
  onPressed: _isUploadingToCloud ? null : _showCloudExportDialog,
  icon: _isUploadingToCloud
      ? CircularProgressIndicator(...)
      : Icon(Icons.cloud_upload),
)
```

## Преимущества реализации

1. **Переиспользование AuthModal** - не нужно дублировать логику выбора провайдера
2. **Автоматическая авторизация** - пользователь авторизуется через AuthModal
3. **Множественные провайдеры** - легко добавить Google Drive, OneDrive и т.д.
4. **Множественные credentials** - поддержка нескольких аккаунтов для одного провайдера
5. **Управление версиями** - DropboxService автоматически хранит только 2 архива
6. **Проверка целостности** - SHA-256 checksum при экспорте

## Логирование

Все операции логируются:

```dart
logInfo('Начало экспорта в облако', 
  tag: 'ExportConfirmScreen',
  data: {'clientKey': clientKey, 'archivePath': _exportedArchivePath},
);

logInfo('Архив успешно экспортирован в облако',
  tag: 'ExportConfirmScreen',
  data: {
    'clientKey': clientKey,
    'cloudPath': exportResult.data,
    'archiveName': p.basename(_exportedArchivePath!),
  },
);
```

## Обработка ошибок

- ✅ Проверка наличия локального архива
- ✅ Обработка отмены авторизации
- ✅ Проверка успешности инициализации Dropbox
- ✅ Try-catch с логированием stackTrace
- ✅ Пользовательские уведомления (ToastHelper)
- ✅ Восстановление UI состояния (finally блок)

## Пример использования

```dart
// 1. Пользователь создает архив
await _performExport(); // Создает локальный архив

// 2. Пользователь нажимает "Загрузить в облако"
await _showCloudExportDialog(); // Показывает AuthModal

// 3. AuthModal возвращает clientKey после авторизации
// 4. Автоматически вызывается _performCloudExport(clientKey)
// 5. Архив загружается в Dropbox
```

## Зависимости

- `dropboxServiceProvider` - провайдер для DropboxService
- `showAuthModal` - функция показа модального окна авторизации
- `SyncMetadataService` - автоматически используется DropboxService
- `ServiceResult` паттерн - для обработки результатов

## Будущие улучшения

- [ ] Добавить прогресс-бар для загрузки в облако
- [ ] Добавить возможность выбора конкретного архива для загрузки
- [ ] Показывать список архивов в облаке
- [ ] Добавить импорт из облака на этом же экране
- [ ] Поддержка Google Drive (создать GoogleDriveService)
