# Cloud Sync Progress Dialog

## Описание

`CloudSyncProgressDialog` — модальное окно для отображения прогресса синхронизации с облачными сервисами (экспорт/импорт хранилищ).

## Особенности

- **Автоматическое отображение**: Диалог автоматически появляется при начале синхронизации на главном экране
- **Блокировка закрытия**: Пользователь не может закрыть диалог во время активной синхронизации (экспорт/импорт)
- **Предупреждение**: Показывает предупреждение о том, что нельзя закрывать приложение
- **Прогресс в реальном времени**: Отображает текущий процент выполнения, статус и дополнительную информацию о файле
- **Обработка ошибок**: Показывает ошибки с возможностью закрытия диалога

## Состояния

Диалог реагирует на следующие состояния `CloudSyncState`:

1. **idle** - ожидание синхронизации (редко отображается)
2. **exporting** - активный экспорт в облако
3. **importing** - активный импорт из облака
4. **success** - успешное завершение операции
5. **error** - ошибка при синхронизации

## Интеграция на главном экране

В файле `lib/features/home/home.dart` реализовано автоматическое управление диалогом:

```dart
// Отслеживаем состояние синхронизации с облаком
ref.listen(cloudSyncProvider, (previous, next) {
  next.map(
    idle: (_) {
      // Закрываем диалог если он был открыт
      if (_isSyncDialogShown && ...) {
        _isSyncDialogShown = false;
        _closeSyncDialog();
      }
    },
    exporting: (_) {
      // Показываем диалог при начале экспорта
      if (!_isSyncDialogShown) {
        _isSyncDialogShown = true;
        _showSyncDialog();
      }
    },
    importing: (_) {
      // Показываем диалог при начале импорта
      if (!_isSyncDialogShown) {
        _isSyncDialogShown = true;
        _showSyncDialog();
      }
    },
    success: (_) {
      // Пользователь должен сам закрыть диалог
    },
    error: (_) {
      // Пользователь должен сам закрыть диалог
    },
  );
});
```

## Использование в других экранах

Если нужно показать диалог на другом экране:

```dart
// 1. Импортировать виджет
import 'package:hoplixi/features/home/widgets/cloud_sync_progress_dialog.dart';

// 2. Добавить listener в build методе ConsumerWidget/ConsumerStatefulWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  bool _isSyncDialogShown = false;
  
  ref.listen(cloudSyncProvider, (previous, next) {
    // Логика показа/скрытия диалога (см. пример выше)
  });
  
  return YourWidget();
}
```

## Управление состоянием синхронизации

Для запуска синхронизации используйте `cloudSyncProvider`:

```dart
// В вашем UI коде
final syncNotifier = ref.read(cloudSyncProvider.notifier);

// Запуск экспорта
await syncNotifier.exportToDropbox(
  metadata: databaseMetadata,
  pathToDbFolder: '/path/to/db',
  encryptionKeyArchive: optionalEncryptionKey,
);

// Сброс состояния (вручную вернуть в idle)
syncNotifier.reset();
```

## Архитектура

```
CloudSyncProgressDialog (UI)
    ↓ reads
CloudSyncProvider (State Management)
    ↓ uses
CloudSyncNotifier (Business Logic)
    ↓ calls
Export/Import Services (Data Layer)
```

## Примечания

- Диалог использует `PopScope` с `canPop: false` для предотвращения случайного закрытия
- `barrierDismissible: false` запрещает закрытие по клику вне диалога
- Состояния `success` и `error` требуют ручного закрытия пользователем
- Прогресс показывается в процентах и дополнительными сообщениями
- Анимированная иконка добавляет визуальную обратную связь

## TODO

- [ ] Добавить возможность отмены операции (кнопка Cancel)
- [ ] Сохранение истории синхронизаций
- [ ] Уведомления при завершении фоновой синхронизации
