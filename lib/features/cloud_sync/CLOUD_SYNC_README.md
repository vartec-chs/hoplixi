# Cloud Sync Import/Export Documentation

## Обзор

Модуль облачной синхронизации обеспечивает двустороннюю синхронизацию баз данных между локальным устройством и облачным хранилищем (Dropbox). Синхронизация включает механизмы блокировки для предотвращения конфликтов при одновременном редактировании.

## Архитектура

### Основные компоненты

1. **CloudExportProvider** - провайдер для экспорта БД в облако
2. **CloudImportProvider** - провайдер для импорта БД из облака
3. **ImportDropboxService** - сервис для работы с Dropbox API
4. **LocalMetaCrudService** - сервис для управления метаданными синхронизации
5. **LocalMeta** - модель метаданных локальной базы данных

### Структура данных

#### LocalMeta

```dart
class LocalMeta {
  String dbId;              // ID базы данных
  bool enabled;             // Включена ли синхронизация
  String dbName;            // Имя базы данных
  String deviceId;          // ID устройства
  ProviderType providerType; // Тип облачного провайдера
  bool editingEnabled;      // Разрешено ли редактирование
  DateTime? lastExportAt;   // Дата последнего экспорта
  DateTime? lastImportedAt; // Дата последнего импорта
}
```

#### CloudVersionInfo

```dart
class CloudVersionInfo {
  DateTime timestamp;       // Временная метка версии
  String fileName;          // Имя файла в облаке
  String cloudPath;         // Путь к файлу в облаке
  bool isNewer;            // Является ли версия более новой
  int? fileSize;           // Размер файла
}
```

## Процесс экспорта

### CloudExportProvider

**Шаги экспорта:**

1. **Получение ключа клиента**
   - Поиск токена OAuth2 по типу провайдера
   - Авторизация с токеном

2. **Инициализация подключения к Dropbox**
   - Создание экземпляра Dropbox API клиента
   - Проверка соединения

3. **Обеспечение структуры папок**
   - Создание корневой папки `/Hoplixi/storages`
   - Создание папки для хранилища `{dbName}_{dbId}`

4. **Создание архива**
   - Архивирование папки БД в zip
   - Временное хранение в локальной папке

5. **Загрузка в облако**
   - Имя файла: `{timestamp}.zip`
   - Путь: `/Hoplixi/storages/{dbName}_{dbId}/{timestamp}.zip`
   - Отслеживание прогресса

6. **Завершение**
   - Обновление `lastExportAt` в LocalMeta
   - Удаление временного архива
   - Установка состояния Success

## Процесс импорта

### CloudImportProvider

**Шаги импорта:**

1. **Получение ключа клиента**
   - Аналогично экспорту

2. **Инициализация подключения к Dropbox**
   - Аналогично экспорту

3. **Проверка наличия новой версии**
   - Получение списка файлов в папке хранилища
   - Сравнение временных меток с `lastExportAt`
   - Если новой версии нет → выход с состоянием Info

4. **Проверка файла блокировки (.lock)**
   - Проверка существования `.lock` файла в папке хранилища
   
5. **Обработка блокировки**

   **Случай 1: .lock файл НЕ существует**
   - Попытка создать `.lock` файл с информацией об устройстве
   - Содержимое: `{deviceInfo}|{timestamp}`
   - Если успешно:
     - `editingEnabled = true` → Устройство получает право редактирования
     - Скачивание и замена БД
   - Если не успешно (кто-то успел создать раньше):
     - `editingEnabled = false`
     - Скачивание и замена БД

   **Случай 2: .lock файл существует**
   - `editingEnabled = false` → Только чтение
   - Скачивание и замена БД

6. **Обновление LocalMeta**
   - Установка `editingEnabled` флага
   - Обновление `lastImportedAt`

7. **Скачивание архива**
   - Скачивание самого свежего `.zip` файла
   - Сохранение в локальную папку
   - Отслеживание прогресса

8. **Удаление текущей базы данных**
   - Вызов `deleteCurrentDatabase` из `DatabaseAsyncNotifier`
   - Полное удаление файлов и папки текущей БД
   - Очистка записей из истории

9. **Замена базы данных**
   - Распаковка архива в чистую папку
   - Установка новых файлов БД
   - Переоткрытие БД (опционально)

10. **Завершение**
    - Установка состояния Success
    - Логирование результата

## Механизм блокировки

### Назначение

Файл `.lock` предотвращает одновременное редактирование базы данных несколькими устройствами, что может привести к конфликтам данных.

### Логика работы

1. **Первое устройство**
   - Создает `.lock` файл при импорте
   - Получает право редактирования (`editingEnabled = true`)
   - Может экспортировать изменения

2. **Последующие устройства**
   - Видят существующий `.lock` файл
   - Работают в режиме только чтения (`editingEnabled = false`)
   - Могут только импортировать изменения

3. **Снятие блокировки**
   - Вручную через UI
   - Автоматически при удалении `.lock` файла в облаке
   - После тайм-аута (если реализовано)

### Формат .lock файла

```text
{hostname} ({platform})|{timestamp_microseconds}
```

Пример:

```text
DESKTOP-ABC123 (windows)|1698765432123456
```

## Состояния провайдеров

### ExportState

```dart
sealed class ExportState {
  idle()           // Ожидание
  exporting()      // Процесс экспорта
  success()        // Успешно завершено
  failure()        // Ошибка
}
```

### ImportState

```dart
sealed class ImportState {
  idle()           // Ожидание
  checking()       // Проверка условий
  importing()      // Процесс импорта
  fileProgress()   // Прогресс скачивания файла
  success()        // Успешно завершено
  failure()        // Ошибка
  warning()        // Предупреждение
  info()           // Информация (напр. "нет новой версии")
  canceled()       // Отменено
}
```

## Обработка ошибок

### ExportException

```dart
sealed class ExportException {
  network()        // Ошибки сети
  auth()          // Ошибки авторизации
  storage()       // Ошибки хранилища
  validation()    // Ошибки валидации
  warning()       // Предупреждения
  permission()    // Ошибки прав доступа
  unknown()       // Неизвестные ошибки
}
```

### ImportException

```dart
sealed class ImportException {
  network()        // Ошибки сети
  auth()          // Ошибки авторизации
  locking()       // Ошибки блокировки
  storage()       // Ошибки хранилища
  validation()    // Ошибки валидации
  warning()       // Предупреждения
  permission()    // Ошибки прав доступа
  unknown()       // Неизвестные ошибки
}
```

## Использование в UI

### Экспорт

```dart
final exportProvider = ref.watch(cloudExportProvider);

// Запуск экспорта
await ref.read(cloudExportProvider.notifier).export(
  databaseMeta,
  pathToDbFolder,
);

// Отслеживание состояния
exportProvider.when(
  data: (state) => state.when(
    idle: () => Text('Готов к экспорту'),
    exporting: (progress, message, startedAt) => 
      LinearProgressIndicator(value: progress),
    success: (fileName, exportTime) => 
      Text('Экспорт завершён: $fileName'),
    failure: (error) => Text('Ошибка: ${error.toString()}'),
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Ошибка: $e'),
);
```

### Импорт

```dart
final importProvider = ref.watch(cloudImportProvider);

// Запуск импорта
await ref.read(cloudImportProvider.notifier).import(databaseMeta);

// Отслеживание состояния
importProvider.when(
  data: (state) => state.when(
    idle: () => Text('Готов к импорту'),
    checking: (message) => Text('Проверка: $message'),
    importing: (progress, message, startedAt) => 
      LinearProgressIndicator(value: progress),
    fileProgress: (progress, message) => 
      Text('$message: $progress'),
    success: (fileName, importTime) => 
      Text('Импорт завершён: $fileName'),
    failure: (error) => Text('Ошибка: ${error.toString()}'),
    info: (action) => Text('Инфо: $action'),
    warning: (message) => Text('Предупреждение: $message'),
    canceled: () => Text('Отменено'),
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Ошибка: $e'),
);
```

## Проверка права редактирования

```dart
final localMetaService = await ref.read(localMetaCrudProvider.future);
final metaResult = localMetaService.getByDbId(dbId);

if (metaResult.isSuccess) {
  final meta = metaResult.dataOrNull!;
  if (meta.editingEnabled) {
    // Разрешить редактирование
  } else {
    // Режим только чтения
  }
}
```

## Структура папок в Dropbox

```text
/Hoplixi/
  └── storages/
      ├── MyDatabase_abc123/
      │   ├── .lock
      │   ├── 1698765432000000.zip
      │   └── 1698765433000000.zip
      └── AnotherDB_def456/
          ├── .lock
          └── 1698765434000000.zip
```

## Логирование

Все операции логируются с использованием `AppLogger`:

```dart
logInfo('Сообщение', tag: 'CloudImportProvider', data: {...});
logError('Ошибка', tag: 'CloudImportProvider', error: e, stackTrace: st);
logWarning('Предупреждение', tag: 'CloudImportProvider');
```

## Безопасность

1. **OAuth2 авторизация** - все запросы к Dropbox авторизованы
2. **Шифрование БД** - локальная БД защищена SQLCipher
3. **Блокировка редактирования** - предотвращает конфликты данных
4. **Валидация метаданных** - проверка целостности перед импортом

## Тестирование

### Unit тесты

```dart
// Тесты для CloudImportProvider
test('should set editingEnabled=true when lock does not exist', () async {
  // ...
});

test('should set editingEnabled=false when lock exists', () async {
  // ...
});

test('should exit early when no new version', () async {
  // ...
});
```

### Integration тесты

```dart
// Тесты полного цикла импорт-экспорт
testWidgets('should export and import database successfully', (tester) async {
  // ...
});
```

## Ограничения и известные проблемы

1. **Размер файла** - Dropbox API имеет лимиты на размер загружаемых файлов
2. **Сетевые ошибки** - требуется обработка таймаутов и разрывов соединения
3. **Конфликты** - при одновременном создании `.lock` возможна race condition
4. **Версионирование** - хранятся все версии, нет автоочистки старых

## Будущие улучшения

1. Автоматическая очистка старых версий
2. Дельта-синхронизация (только изменения)
3. Поддержка других облачных провайдеров (Google Drive, OneDrive)
4. Разрешение конфликтов при редактировании
5. Тайм-аут для `.lock` файлов
6. Сжатие архивов с выбором уровня компрессии
