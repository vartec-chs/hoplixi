# Интеграция облачного импорта в ImportScreen

## Обзор

Функциональность облачного импорта позволяет пользователям загружать архивы хранилищ из облачных сервисов (Dropbox, Google Drive и т.д.) с автоматической проверкой целостности данных.

## Архитектура

### Поток данных

```
UI (ImportScreen)
    ↓
AuthModal (выбор провайдера + OAuth)
    ↓
dropboxServiceProvider(clientKey)
    ↓
DropboxService.import(destinationPath)
    ↓
StorageExportService.importStorage(archivePath, password?)
    ↓
Распакованное хранилище
```

### Компоненты

1. **ImportScreen** (`import_screen.dart`)
   - UI для выбора способа импорта
   - Обработка локальных архивов
   - Обработка облачных архивов через AuthModal

2. **AuthModal** (`cloud_sync/widgets/auth_modal.dart`)
   - Выбор облачного провайдера (Dropbox, Google Drive)
   - OAuth авторизация
   - Возвращает `clientKey` для инициализации сервиса

3. **DropboxService** (`cloud_sync/services/dropbox_service.dart`)
   - `initialize()` - проверка/создание структуры папок
   - `import(destinationPath)` - загрузка последнего архива с проверкой checksum

4. **SyncMetadataService** (`cloud_sync/services/sync_metadata_service.dart`)
   - Расчёт и проверка SHA-256 checksum
   - Работа с метаданными синхронизации

## Реализация

### 1. Метод показа диалога выбора облака

```dart
Future<void> _showCloudImportDialog() async {
  if (!mounted) return;

  // Показываем AuthModal для выбора провайдера и авторизации
  final clientKey = await showAuthModal(context);

  if (clientKey == null) {
    // Пользователь отменил или произошла ошибка
    logDebug('Авторизация отменена или не удалась', tag: 'ImportScreen');
    return;
  }

  if (!mounted) return;

  // Выполняем импорт из облака
  await _performCloudImport(clientKey);
}
```

### 2. Метод выполнения импорта

```dart
Future<void> _performCloudImport(String clientKey) async {
  setState(() {
    _isImporting = true;
    _progress = 0.0;
    _importedStoragePath = null;
  });

  try {
    // 1. Получаем сервис Dropbox через провайдер
    final dropboxService = await ref.read(
      dropboxServiceProvider(clientKey).future,
    );

    // 2. Инициализируем Dropbox (проверка/создание структуры)
    final initResult = await dropboxService.initialize();
    if (!initResult.success) {
      ToastHelper.error(
        title: 'Ошибка инициализации',
        description: initResult.message,
      );
      return;
    }

    // 3. Загружаем архив из облака
    final destinationDir = await AppPaths.appStoragePath;
    final importResult = await dropboxService.import(destinationDir);
    
    if (!importResult.success || importResult.data == null) {
      ToastHelper.error(
        title: 'Ошибка импорта',
        description: importResult.message,
      );
      return;
    }

    final downloadedArchivePath = importResult.data!;

    // 4. Запрашиваем пароль (если нужен)
    String? password;
    if (mounted) {
      password = await _showPasswordDialog();
    }

    // 5. Распаковываем архив
    final service = ref.read(storageExportServiceProvider);
    final extractResult = await service.importStorage(
      archivePath: downloadedArchivePath,
      destinationDir: destinationDir,
      password: password?.isNotEmpty == true ? password : null,
    );

    if (extractResult.success && extractResult.data != null) {
      setState(() {
        _importedStoragePath = extractResult.data;
      });
      ToastHelper.success(
        title: 'Успешно',
        description: 'Хранилище импортировано из облака',
      );
    }
  } catch (e, st) {
    logError('Исключение при импорте из облака', error: e, stackTrace: st);
    ToastHelper.error(
      title: 'Ошибка',
      description: 'Произошла ошибка при импорте из облака',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isImporting = false;
      });
    }
  }
}
```

### 3. Диалог ввода пароля

```dart
Future<String?> _showPasswordDialog() async {
  final passwordController = TextEditingController();
  
  final password = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Пароль архива'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Если архив защищён паролем, введите его:'),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Пароль (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Пропустить'),
        ),
        TextButton(
          onPressed: () {
            final pwd = passwordController.text.trim();
            Navigator.of(context).pop(pwd.isNotEmpty ? pwd : null);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );

  passwordController.dispose();
  return password;
}
```

### 4. UI кнопка импорта из облака

```dart
if (_importedStoragePath == null && !_isImporting) ...[
  SmoothButton(
    isFullWidth: true,
    label: 'Импорт из архива',
    onPressed: _selectedArchivePath == null
        ? _pickArchive
        : _performImport,
    icon: Icon(
      _selectedArchivePath == null
          ? Icons.folder_zip
          : Icons.upload,
    ),
  ),
  const SizedBox(height: 12),
  SmoothButton(
    isFullWidth: true,
    label: 'Импорт из облака',
    onPressed: _showCloudImportDialog,
    icon: const Icon(Icons.cloud_download),
    type: SmoothButtonType.outlined,
  ),
],
```

## Процесс импорта

### Шаг 1: Выбор облачного провайдера
1. Пользователь нажимает "Импорт из облака"
2. Открывается `AuthModal` с выбором провайдера
3. Пользователь выбирает провайдер (например, Dropbox)
4. Выполняется OAuth авторизация
5. `AuthModal` возвращает `clientKey`

### Шаг 2: Инициализация сервиса
1. Используя `clientKey`, получаем экземпляр `DropboxService` через провайдер
2. Вызываем `initialize()` для проверки/создания структуры папок в Dropbox
3. Структура: `/Hoplixi/storages/` с `sync_metadata.json` и архивами

### Шаг 3: Загрузка архива
1. Вызываем `DropboxService.import(destinationPath)`
2. Сервис:
   - Загружает `sync_metadata.json`
   - Находит самый новый архив по timestamp
   - Скачивает архив в локальную директорию
   - Проверяет checksum (SHA-256)
   - Возвращает путь к загруженному архиву

### Шаг 4: Распаковка архива
1. Запрашиваем пароль у пользователя (опционально)
2. Используем `StorageExportService.importStorage()`
3. Распаковываем архив в целевую директорию
4. Если пароль неверный или архив повреждён - показываем ошибку

### Шаг 5: Завершение
1. Сохраняем путь к импортированному хранилищу
2. Показываем сообщение об успехе
3. Пользователь может открыть хранилище или закрыть экран

## Обработка ошибок

### Возможные ошибки и решения

| Ошибка | Причина | Решение |
|--------|---------|---------|
| Авторизация отменена | Пользователь закрыл AuthModal | Просто выходим, ничего не делаем |
| Ошибка инициализации | Нет доступа к Dropbox / проблемы с OAuth | Проверить токен, переавторизоваться |
| Архивов не найдено | В облаке нет файлов | Показать предупреждение, предложить экспорт |
| Checksum не совпадает | Файл повреждён при загрузке | Показать ошибку, предложить повторить |
| Неверный пароль | Пользователь ввёл неверный пароль | Показать ошибку, предложить повторить ввод |
| Ошибка распаковки | Архив повреждён / неверный формат | Показать ошибку с деталями |

### Логирование

```dart
// Успешные операции
logInfo('Импорт из облака завершён успешно', 
  tag: 'ImportScreen',
  data: {'clientKey': clientKey, 'storagePath': path}
);

// Ошибки
logError('Ошибка при импорте из облака',
  tag: 'ImportScreen',
  error: e,
  stackTrace: st,
  data: {'clientKey': clientKey}
);

// Отладка
logDebug('Авторизация отменена или не удалась', 
  tag: 'ImportScreen'
);
```

## Безопасность

### Защита данных
- ✅ Пароли архивов не логируются
- ✅ OAuth токены управляются через `OAuth2RestClient`
- ✅ Checksum проверка гарантирует целостность данных
- ✅ Временные файлы удаляются после распаковки

### Проверки
1. **Checksum verification**: SHA-256 проверка при импорте
2. **Password protection**: Опциональная защита паролем
3. **OAuth security**: Безопасная авторизация через провайдеров
4. **File validation**: Проверка формата и структуры архива

## Пример использования

### Сценарий 1: Успешный импорт
```
1. Пользователь: нажимает "Импорт из облака"
2. Система: показывает AuthModal
3. Пользователь: выбирает Dropbox → авторизуется
4. Система: получает clientKey, инициализирует DropboxService
5. Система: загружает последний архив (storage_1697123456.zip)
6. Система: проверяет checksum ✓
7. Система: спрашивает пароль
8. Пользователь: вводит пароль (или пропускает)
9. Система: распаковывает архив ✓
10. Результат: хранилище готово к открытию
```

### Сценарий 2: Архив защищён паролем (неверный пароль)
```
1-7. (как в сценарии 1)
8. Пользователь: вводит неверный пароль
9. Система: пытается распаковать ✗
10. Система: показывает ошибку "Неверный пароль"
11. Пользователь: может повторить импорт с правильным паролем
```

### Сценарий 3: Нет архивов в облаке
```
1-4. (как в сценарии 1)
5. Система: не находит архивов в /Hoplixi/storages/
6. Система: показывает предупреждение "В облаке не найдено архивов"
7. Пользователь: может перейти к экспорту
```

## Зависимости

### Провайдеры
- `dropboxServiceProvider(clientKey)` - создаёт DropboxService
- `storageExportServiceProvider` - сервис распаковки архивов

### Сервисы
- `DropboxService` - работа с Dropbox API
- `SyncMetadataService` - метаданные и checksum
- `StorageExportService` - распаковка архивов

### UI компоненты
- `AuthModal` - выбор провайдера и OAuth
- `SmoothButton` - кастомные кнопки
- `ToastHelper` - уведомления

## Дальнейшие улучшения

### Запланированные функции
1. **Список архивов**: Показывать все доступные архивы для выбора
2. **Google Drive**: Добавить поддержку Google Drive
3. **Progress indicators**: Детальный прогресс загрузки/распаковки
4. **Автоматический импорт**: Синхронизация при запуске приложения
5. **Конфликты**: Обработка конфликтов версий
6. **Кеширование**: Кеширование метаданных для быстрого доступа

### Оптимизации
- Параллельная загрузка и распаковка
- Инкрементальный импорт (только изменения)
- Сжатие на лету для экономии трафика
- Фоновая синхронизация
