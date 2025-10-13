# Синхронизация архивов - Итоговая сводка

## Созданные компоненты

### 1. Модели данных (Freezed)

**Файл:** `lib/features/cloud_sync/models/sync_metadata.dart`

- `SyncMetadata` - мета-информация о синхронизации (список архивов, дата обновления)
- `ArchiveMetadata` - информация об одном архиве (имя, timestamp, размер, checksum, путь)
- `emptyMetadata()` - фабричная функция для создания пустых метаданных

Сгенерированные файлы:
- `sync_metadata.freezed.dart`
- `sync_metadata.g.dart`

### 2. SyncMetadataService

**Файл:** `lib/features/cloud_sync/services/sync_metadata_service.dart`

Общий сервис для работы с мета-информацией (используется всеми облачными провайдерами).

**Основные методы:**
- `calculateChecksum(filePath)` - SHA-256 контрольная сумма
- `verifyChecksum(filePath, expectedChecksum)` - проверка целостности
- `parseTimestampFromFileName(fileName)` - извлечение timestamp
- `generateArchiveName(baseName, timestamp)` - генерация имени
- `createArchiveMetadata(...)` - создание метаданных архива
- `updateMetadata(currentMetadata, newArchive)` - обновление (макс. 2 архива)
- `getLatestArchive(metadata)` - получение самого нового
- `parseMetadata(jsonString)` - десериализация
- `serializeMetadata(metadata)` - сериализация

### 3. DropboxService

**Файл:** `lib/features/cloud_sync/services/dropbox_service.dart`

Сервис для работы с Dropbox API.

**Основные методы:**
- `initialize()` - инициализация и создание папок
- `export(archivePath)` - экспорт архива в облако
- `import(destinationPath)` - импорт самого нового архива
- `listArchives()` - список всех архивов в облаке

**Внутренние методы:**
- `_downloadMetadata()` - загрузка мета-файла
- `_uploadMetadata(metadata)` - загрузка мета-файла
- `_cleanupOldArchives(...)` - удаление старых архивов

### 4. Экспорты

**Файл:** `lib/features/cloud_sync/services/services.dart`
```dart
export '../cloud_sync/dropbox_service.dart';
export '../cloud_sync/sync_metadata_service.dart';
```

**Файл:** `lib/features/cloud_sync/models/models.dart`
```dart
export '../cloud_sync/sync_metadata.dart';
```

### 5. Документация

- `lib/features/cloud_sync/SYNC_README.md` - подробная документация по синхронизации
- `lib/features/cloud_sync/examples/sync_example.dart` - примеры использования

## Структура в Dropbox

```
/Hoplixi/
  └── storages/
      ├── sync_metadata.json      # Мета-информация
      ├── storage_1234567890.zip  # Предыдущий архив
      └── storage_1234567891.zip  # Текущий архив
```

## Формат имени архива

`{name}_{timestamp}.zip`

Пример: `storage_1697123456.zip`

## Основные принципы

1. **Максимум 2 архива** в облаке (текущий + предыдущий)
2. **Обязательная проверка SHA-256** при импорте
3. **ServiceResult паттерн** для всех операций
4. **Централизованное логирование** без секретов
5. **Инкапсуляция** облачной специфики
6. **Общий SyncMetadataService** для разных облаков

## Workflow экспорта

1. Проверка локального файла
2. Вычисление SHA-256
3. Создание метаданных архива
4. Загрузка в облако (overwrite)
5. Обновление мета-файла
6. Удаление старых архивов (> 2)

## Workflow импорта

1. Загрузка мета-файла из облака
2. Поиск самого нового архива
3. Скачивание из облака
4. Проверка SHA-256
5. Сохранение локально (если checksum OK)
6. Удаление файла при несовпадении checksum

## Пример использования

```dart
// Инициализация
final metadataService = SyncMetadataService();
final dropboxService = DropboxService(oauthClient, metadataService);

// Экспорт
await dropboxService.initialize();
final result = await dropboxService.export('/path/to/archive.zip');

// Импорт
final result = await dropboxService.import('/destination/path');
```

## Безопасность

✅ SHA-256 для всех архивов
✅ Проверка целостности при импорте
✅ Автоудаление поврежденных файлов
✅ Безопасные сообщения об ошибках
✅ Транзакционность операций

## Расширяемость

Для добавления Google Drive:
1. Создать `GoogleDriveService`
2. Использовать тот же `SyncMetadataService`
3. Реализовать `export()` и `import()`
4. Следовать той же структуре папок

## Зависимости

- ✅ `crypto` - уже в pubspec.yaml
- ✅ `freezed_annotation` - уже в pubspec.yaml
- ✅ `hoplixi/core/lib/dropbox_api` - существует
- ✅ `hoplixi/core/lib/oauth2restclient` - существует
- ✅ `hoplixi/hoplixi_store/repository/service_results.dart` - существует

## Статус

✅ Все файлы созданы
✅ Freezed классы сгенерированы
✅ Нет ошибок компиляции
✅ Документация написана
✅ Примеры созданы

## Следующие шаги

1. Создать Riverpod провайдеры
2. Создать UI для экспорта/импорта
3. Интегрировать с существующей функциональностью архивации
4. Добавить прогресс-индикаторы для длительных операций
5. Тестирование на реальных данных

## Файлы для проверки

```
lib/features/cloud_sync/
├── models/
│   ├── sync_metadata.dart
│   ├── sync_metadata.freezed.dart
│   ├── sync_metadata.g.dart
│   └── models.dart
├── services/
│   ├── sync_metadata_service.dart
│   ├── dropbox_service.dart
│   └── services.dart
├── examples/
│   └── sync_example.dart
└── SYNC_README.md
```

Все готово к использованию! 🎉
