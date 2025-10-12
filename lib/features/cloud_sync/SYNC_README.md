# Модуль синхронизации архивов (Archive Sync)

## Описание

Сервисы для синхронизации архивов хранилищ с облачными провайдерами (Dropbox, Google Drive). Поддерживает автоматическое управление версиями, проверку целостности и универсальную мета-информацию.

## Архитектура

```
┌─────────────────────┐
│   DropboxService    │  ← Специфичный для провайдера
│  (cloud-specific)   │
└──────────┬──────────┘
           │
           │ uses
           ▼
┌─────────────────────┐
│ SyncMetadataService │  ← Общий для всех облаков
│   (cloud-agnostic)  │
└─────────────────────┘
```

## Компоненты

### 1. SyncMetadataService

Общий сервис для работы с мета-информацией синхронизации. Используется всеми облачными провайдерами.

**Ключевые методы:**
- `calculateChecksum(filePath)` - вычисление SHA-256 контрольной суммы
- `verifyChecksum(filePath, expectedChecksum)` - проверка контрольной суммы
- `parseTimestampFromFileName(fileName)` - извлечение timestamp из имени файла
- `generateArchiveName(baseName, timestamp)` - генерация имени архива
- `createArchiveMetadata(...)` - создание метаданных для архива
- `updateMetadata(currentMetadata, newArchive)` - обновление метаданных (хранит макс. 2 архива)
- `getLatestArchive(metadata)` - получение самого нового архива

**Модели данных:**

```dart
// Мета-информация о синхронизации
@freezed
abstract class SyncMetadata with _$SyncMetadata {
  const factory SyncMetadata({
    required List<ArchiveMetadata> archives,  // Макс. 2 архива
    required DateTime lastUpdated,
    @Default(1) int version,
  }) = _SyncMetadata;
}

// Мета-информация об архиве
@freezed
abstract class ArchiveMetadata with _$ArchiveMetadata {
  const factory ArchiveMetadata({
    required String fileName,       // storage_1234567890.zip
    required int timestamp,         // Unix timestamp
    required int size,              // Размер в байтах
    required String checksum,       // SHA-256
    required DateTime uploadedAt,
    required String cloudPath,      // Путь в облаке
  }) = _ArchiveMetadata;
}
```

### 2. DropboxService

Сервис для работы с Dropbox API. Инкапсулирует работу с Dropbox и использует `SyncMetadataService` для мета-информации.

**Структура в Dropbox:**
```
/Hoplixi/
  └── storages/
      ├── sync_metadata.json      # Мета-информация
      ├── storage_1234567890.zip  # Предыдущий архив
      └── storage_1234567891.zip  # Текущий архив
```

**Основные методы:**

#### `initialize()`
Инициализирует подключение к Dropbox и создает необходимые папки.

```dart
final result = await dropboxService.initialize();
if (result.success) {
  // Готово к использованию
}
```

#### `export(archivePath)`
Экспортирует архив в Dropbox.

**Процесс:**
1. Проверяет существование локального файла
2. Вычисляет контрольную сумму
3. Создает метаданные архива
4. Загружает архив в облако
5. Обновляет мета-файл
6. Удаляет старые архивы (оставляет только 2)

```dart
final result = await dropboxService.export('/path/to/storage_1234567890.zip');
if (result.success) {
  final cloudPath = result.data; // Путь в облаке
}
```

**Формат имени архива:** `{name}_{timestamp}.zip`
- `name` - базовое имя (например, "storage")
- `timestamp` - Unix timestamp в секундах

#### `import(destinationPath)`
Импортирует самый новый архив из Dropbox.

**Процесс:**
1. Загружает мета-информацию
2. Находит самый новый архив
3. Скачивает его из облака
4. Проверяет контрольную сумму
5. Сохраняет локально (если checksum корректен)

```dart
final result = await dropboxService.import('/path/to/destination');
if (result.success) {
  final filePath = result.data; // Путь к скачанному файлу
  // Файл готов к использованию
}
```

**Важно:** Если контрольная сумма не совпадает, файл удаляется и возвращается ошибка.

#### `listArchives()`
Получает список всех архивов в облаке.

```dart
final result = await dropboxService.listArchives();
if (result.success) {
  final archives = result.data; // List<ArchiveMetadata>
  for (final archive in archives) {
    print('${archive.fileName}: ${archive.size} bytes');
  }
}
```

## Использование

### Пример: Полный цикл экспорта и импорта

```dart
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/cloud_sync/services/services.dart';

// 1. Инициализация сервисов
final metadataService = SyncMetadataService();
final dropboxService = DropboxService(oauthClient, metadataService);

// 2. Инициализация Dropbox
final initResult = await dropboxService.initialize();
if (!initResult.success) {
  ToastHelper.error(title: 'Ошибка инициализации', description: initResult.message);
  return;
}

// 3. Экспорт архива
final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final archiveName = 'storage_$timestamp.zip';
final archivePath = '/path/to/$archiveName';

final exportResult = await dropboxService.export(archivePath);
if (exportResult.success) {
  ToastHelper.success(
    title: 'Успешно',
    description: 'Архив экспортирован: ${exportResult.data}',
  );
} else {
  ToastHelper.error(title: 'Ошибка экспорта', description: exportResult.message);
}

// 4. Импорт архива (на другом устройстве)
final importResult = await dropboxService.import('/path/to/destination');
if (importResult.success) {
  final downloadedPath = importResult.data;
  ToastHelper.success(
    title: 'Успешно',
    description: 'Архив импортирован',
  );
  // Распаковать и использовать downloadedPath
} else {
  ToastHelper.error(title: 'Ошибка импорта', description: importResult.message);
}
```

### Использование с Riverpod

```dart
// Provider для DropboxService
final dropboxServiceProvider = Provider<DropboxService>((ref) {
  final client = ref.watch(oauth2ClientProvider);
  final metadataService = SyncMetadataService();
  return DropboxService(client, metadataService);
});

// В виджете
class SyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropboxService = ref.read(dropboxServiceProvider);
    
    return SmoothButton(
      label: 'Экспорт в Dropbox',
      icon: const Icon(Icons.cloud_upload),
      onPressed: () async {
        final archivePath = await _createArchive();
        final result = await dropboxService.export(archivePath);
        
        if (result.success) {
          ToastHelper.success(title: 'Архив загружен в облако');
        } else {
          ToastHelper.error(
            title: 'Ошибка',
            description: result.message,
          );
        }
      },
    );
  }
}
```

## Паттерн ServiceResult

Все методы возвращают `ServiceResult<T>`:

```dart
ServiceResult<String> {
  success: bool,    // true если успешно
  message: String?, // Сообщение об ошибке или успехе
  data: T?,         // Данные результата
}
```

## Логирование

Все операции логируются с соответствующим уровнем:
- `logInfo` - важные события (экспорт, импорт завершены)
- `logDebug` - детали процесса (загрузка файла, парсинг)
- `logError` - ошибки с stackTrace

**Важно:** Секреты, пароли и конфиденциальные данные НЕ логируются.

## Ограничения

1. **Максимум 2 архива** в облаке одновременно (текущий + предыдущий)
2. **Формат имени строгий**: `{name}_{timestamp}.zip`
3. **Обязательная проверка checksum** при импорте
4. **Один мета-файл** на все архивы

## Расширение для других облаков

Для добавления Google Drive или других провайдеров:

1. Создать `GoogleDriveService` аналогично `DropboxService`
2. Использовать тот же `SyncMetadataService`
3. Реализовать методы `export()` и `import()`
4. Следовать той же структуре папок и мета-файлов

```dart
class GoogleDriveService {
  final GoogleDriveApi _driveApi;
  final SyncMetadataService _metadataService;
  
  // Аналогичная реализация
  Future<ServiceResult<String>> export(String archivePath) { ... }
  Future<ServiceResult<String>> import(String destinationPath) { ... }
}
```

## Безопасность

- ✅ Контрольные суммы (SHA-256) для всех архивов
- ✅ Проверка существования файлов перед операциями
- ✅ Автоматическая очистка поврежденных загрузок
- ✅ Безопасные сообщения об ошибках (без раскрытия путей/секретов)
- ✅ Транзакционность операций (откат при ошибке)

## Структура файлов

```
lib/features/cloud_sync/
├── models/
│   ├── sync_metadata.dart          # Freezed модели для мета-информации
│   ├── sync_metadata.freezed.dart
│   └── sync_metadata.g.dart
├── services/
│   ├── sync_metadata_service.dart  # Общий сервис мета-информации
│   ├── dropbox_service.dart        # Dropbox-специфичный сервис
│   └── services.dart               # Экспорт всех сервисов
└── SYNC_README.md                  # Эта документация
```

## Зависимости

- `crypto` - для вычисления SHA-256
- `freezed_annotation` - для моделей данных
- `hoplixi/core/lib/dropbox_api` - Dropbox API wrapper
- `hoplixi/core/lib/oauth2restclient` - OAuth2 REST client
- `hoplixi/hoplixi_store/repository/service_results.dart` - ServiceResult паттерн
