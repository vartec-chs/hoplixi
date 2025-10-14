# Реализация отображения прогресса синхронизации

## Что было сделано

### 1. Создан виджет CloudSyncProgressDialog
**Файл**: `lib/features/home/widgets/cloud_sync_progress_dialog.dart`

Модальное окно для отображения прогресса синхронизации с облаком со следующими возможностями:
- ✅ Блокировка закрытия во время активной синхронизации
- ✅ Предупреждение пользователя не закрывать приложение
- ✅ Отображение прогресса в процентах
- ✅ Анимированная иконка для визуальной обратной связи
- ✅ Обработка всех состояний (idle, exporting, importing, success, error)
- ✅ Дополнительная информация о файле (если предоставлена)

### 2. Интеграция на главный экран
**Файл**: `lib/features/home/home.dart`

Добавлен автоматический показ диалога при начале синхронизации:
```dart
ref.listen(cloudSyncProvider, (previous, next) {
  next.map(
    idle: (_) { /* закрываем диалог */ },
    exporting: (_) { /* показываем диалог */ },
    importing: (_) { /* показываем диалог */ },
    success: (_) { /* оставляем открытым */ },
    error: (_) { /* оставляем открытым */ },
  );
});
```

### 3. Исправлена модель CloudSyncState
**Файл**: `lib/features/password_manager/new_cloud_sync/models/cloud_sync_state.dart`

Изменено с `class` на `abstract class` согласно правилам проекта для freezed классов.

### 4. Экспорт виджета
**Файл**: `lib/features/home/widgets/index.dart`

Добавлен экспорт нового виджета для удобного импорта.

## Как это работает

1. **Автоматическое отображение**: Когда `cloudSyncProvider` переходит в состояние `exporting` или `importing`, на главном экране автоматически появляется модальное окно.

2. **Блокировка**: Диалог нельзя закрыть по клику вне окна (`barrierDismissible: false`) или кнопкой "Назад" (`PopScope.canPop: false`).

3. **Прогресс**: Виджет подписывается на `cloudSyncProvider` и отображает актуальное состояние синхронизации.

4. **Завершение**: 
   - При **успехе** показывается зеленая иконка и кнопка "Закрыть"
   - При **ошибке** показывается красная иконка и кнопка "Закрыть"
   - При переходе в **idle** (если это не после success/error) диалог закрывается автоматически

## Использование на других экранах

Если нужно показать диалог синхронизации на другом экране, добавьте аналогичный listener:

```dart
import 'package:hoplixi/features/home/widgets/cloud_sync_progress_dialog.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/cloud_sync_provider.dart';

class YourScreen extends ConsumerStatefulWidget {
  // ...
}

class _YourScreenState extends ConsumerState<YourScreen> {
  bool _isSyncDialogShown = false;

  @override
  Widget build(BuildContext context) {
    // Добавьте listener
    ref.listen(cloudSyncProvider, (previous, next) {
      next.map(
        idle: (_) {
          if (_isSyncDialogShown && 
              previous != null && 
              previous.maybeMap(
                success: (_) => false,
                error: (_) => false,
                orElse: () => true,
              )) {
            _isSyncDialogShown = false;
            Navigator.of(context).pop();
          }
        },
        exporting: (_) {
          if (!_isSyncDialogShown) {
            _isSyncDialogShown = true;
            CloudSyncProgressDialog.show(context);
          }
        },
        importing: (_) {
          if (!_isSyncDialogShown) {
            _isSyncDialogShown = true;
            CloudSyncProgressDialog.show(context);
          }
        },
        success: (_) {},
        error: (_) {},
      );
    });

    return YourWidget();
  }
}
```

## Запуск синхронизации

Для запуска экспорта используйте:

```dart
final syncNotifier = ref.read(cloudSyncProvider.notifier);

await syncNotifier.exportToDropbox(
  metadata: databaseMetadata,
  pathToDbFolder: pathToDbFolder,
  encryptionKeyArchive: optionalKey,
);
```

## Визуальные элементы

- **Иконки**: 
  - Экспорт: `Icons.cloud_upload`
  - Импорт: `Icons.cloud_download`
  - Успех: `Icons.check_circle`
  - Ошибка: `Icons.error_outline`

- **Прогресс-бар**: Линейный индикатор с процентами
- **Предупреждение**: Красный блок с иконкой предупреждения

## Тестирование

Для тестирования:
1. Откройте хранилище
2. Авторизуйтесь в облачном сервисе (Dropbox)
3. Запустите экспорт хранилища
4. Диалог должен автоматически появиться и показывать прогресс
5. При успехе/ошибке появится соответствующий экран с кнопкой закрытия

## Примечания

- Диалог работает только когда пользователь находится на главном экране (или других экранах с добавленным listener)
- Если приложение находится в фоне, диалог может не отображаться
- Состояние синхронизации хранится глобально через `cloudSyncProvider`
