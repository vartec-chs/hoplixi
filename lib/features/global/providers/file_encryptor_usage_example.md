# FileEncryptorProvider - Примеры использования

## Обзор

`FileEncryptorProvider` - это центральный менеджер для работы с шифрованием файлов в приложении Hoplixi. Он предоставляет следующие возможности:

- Шифрование и дешифрование файлов
- Автоматическое отслеживание расшифрованных временных файлов
- Централизованная очистка временных файлов
- **Автоматическое удаление файлов при срабатывании таймера неактивности**
- Управление состоянием шифрования

## Интеграция с AppLifecycleProvider

`FileEncryptorProvider` автоматически отслеживает состояние `AppLifecycleNotifier` и удаляет все временные файлы, когда:

- Таймер неактивности достигает нуля
- Приложение очищает данные (logout, timeout и т.д.)

**Это происходит автоматически**, никаких дополнительных действий не требуется:

```dart
// В FileEncryptorNotifier.build()
ref.listen<AppLifecycleStateData>(
  appLifecycleProvider,
  (previous, next) {
    // Автоматически удаляем файлы при очистке данных
    if (next.dataCleared && (previous?.dataCleared != true)) {
      cleanup(); // Все временные файлы удаляются
    }
  },
);
```

### Сценарии автоматической очистки

1. **Пользователь свернул приложение** → Запускается таймер неактивности
2. **Таймер достиг нуля** → `AppLifecycleNotifier` очищает данные
3. **FileEncryptorNotifier автоматически** → Удаляет все расшифрованные файлы
4. **Результат** → Никаких временных файлов не остаётся в системе

## Основные методы

### 1. Инициализация

Провайдер должен быть инициализирован перед использованием:

```dart
// В виджете или другом провайдере
final manager = ref.read(fileEncryptorProvider.notifier);
await manager.initialize();

// Проверка успешной инициализации
if (manager.isInitialized) {
  // Готов к использованию
} else {
  print('Ошибка: ${manager.errorMessage}');
}
```

### 2. Шифрование файла

```dart
final manager = ref.read(fileEncryptorProvider.notifier);

final success = await manager.encryptFile(
  input: File('/path/to/original.pdf'),
  output: File('/path/to/encrypted.enc'),
  fileId: 'doc_${uuid.v4()}',
  fileExtension: 'pdf',
  onProgress: (progress) {
    print('Прогресс: ${progress.progressPercent}%');
  },
);

if (success) {
  print('Файл успешно зашифрован');
} else {
  print('Ошибка шифрования');
}
```

### 3. Дешифрование с автоматическим отслеживанием

```dart
final manager = ref.read(fileEncryptorProvider.notifier);

// Файл автоматически добавляется в список для очистки
final extension = await manager.decryptFile(
  input: File('/path/to/encrypted.enc'),
  output: File('/tmp/decrypted_temp'),
  useOriginalExtension: true,
  trackForCleanup: true, // по умолчанию true
  onProgress: (progress) {
    print('Расшифровка: ${progress.progressPercent}%');
  },
);

if (extension != null) {
  print('Файл расшифрован с расширением: $extension');
  // Используем файл...
} else {
  print('Ошибка дешифрования');
}
```

### 4. Дешифрование БЕЗ отслеживания

Если файл не временный и не требует автоматической очистки:

```dart
final extension = await manager.decryptFile(
  input: encryptedFile,
  output: permanentFile,
  trackForCleanup: false, // НЕ отслеживать
);
```

### 5. Удаление конкретного файла

```dart
final manager = ref.read(fileEncryptorProvider.notifier);

final removed = await manager.removeDecryptedFile('/tmp/specific_file.pdf');
if (removed) {
  print('Файл удален');
}
```

### 6. Очистка всех временных файлов

```dart
final manager = ref.read(fileEncryptorProvider.notifier);

// Удаляет все отслеживаемые расшифрованные файлы
final deletedCount = await manager.cleanup();
print('Удалено файлов: $deletedCount');
```

### 7. Просмотр отслеживаемых файлов

```dart
final manager = ref.read(fileEncryptorProvider.notifier);

final files = manager.decryptedFiles;
print('Отслеживаемых файлов: ${files.length}');
for (final path in files) {
  print('- $path');
}
```

## Использование в UI виджетах

### Пример: Просмотр зашифрованного документа

```dart
class DocumentViewerWidget extends ConsumerWidget {
  final String encryptedFilePath;
  
  const DocumentViewerWidget({
    required this.encryptedFilePath,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: _decryptAndShow(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return const Text('Ошибка дешифрования');
        }
        
        // Показываем расшифрованный файл
        return FileViewer(filePath: snapshot.data!);
      },
    );
  }
  
  Future<String?> _decryptAndShow(WidgetRef ref) async {
    final manager = ref.read(fileEncryptorProvider.notifier);
    
    // Инициализируем, если не инициализирован
    if (!manager.isInitialized) {
      await manager.initialize();
    }
    
    if (!manager.isInitialized) {
      return null;
    }
    
    // Создаем временный файл
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}');
    
    // Дешифруем с автоматическим отслеживанием
    final extension = await manager.decryptFile(
      input: File(encryptedFilePath),
      output: tempFile,
      trackForCleanup: true, // Будет удален при cleanup()
    );
    
    return extension != null ? tempFile.path : null;
  }
}
```

### Пример: Очистка при выходе из экрана

```dart
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  @override
  void dispose() {
    // Очищаем все временные файлы при выходе
    ref.read(fileEncryptorProvider.notifier).cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI экрана...
    return Scaffold(
      appBar: AppBar(title: const Text('Документы')),
      body: DocumentsList(),
    );
  }
}
```

## Автоматическая очистка

Провайдер автоматически очищает файлы при dispose:

```dart
// В FileEncryptorNotifier.build()
ref.onDispose(() {
  cleanup(); // Автоматически при уничтожении провайдера
});
```

## Отслеживание состояния

```dart
class FileManagerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileEncryptorProvider);
    
    return Column(
      children: [
        Text('Инициализирован: ${state.isInitialized}'),
        Text('Отслеживаемых файлов: ${state.decryptedFiles.length}'),
        if (state.errorMessage != null)
          Text('Ошибка: ${state.errorMessage}', 
               style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

## Best Practices

1. **Всегда инициализируйте перед использованием:**
   ```dart
   if (!manager.isInitialized) {
     await manager.initialize();
   }
   ```

2. **Используйте trackForCleanup для временных файлов:**
   ```dart
   // Для временных файлов - отслеживать
   await manager.decryptFile(..., trackForCleanup: true);
   
   // Для постоянных файлов - НЕ отслеживать
   await manager.decryptFile(..., trackForCleanup: false);
   ```

3. **Вызывайте cleanup() в критических точках:**
   - При выходе из экрана
   - При закрытии документа
   - При логауте пользователя
   - При переполнении временного хранилища

4. **Проверяйте результаты операций:**
   ```dart
   final success = await manager.encryptFile(...);
   if (!success) {
     // Обработка ошибки
     ToastHelper.error('Не удалось зашифровать файл');
   }
   ```

5. **Используйте onProgress для долгих операций:**
   ```dart
   await manager.encryptFile(
     ...,
     onProgress: (progress) {
       // Обновить UI прогресс-бара
       setState(() {
         _progress = progress.progressPercent;
       });
     },
   );
   ```

## Интеграция с сервисами

```dart
class AttachmentService {
  final Ref _ref;
  
  AttachmentService(this._ref);
  
  Future<ServiceResult<void>> saveAttachment({
    required File file,
    required String passwordId,
  }) async {
    try {
      final manager = _ref.read(fileEncryptorProvider.notifier);
      
      if (!manager.isInitialized) {
        await manager.initialize();
      }
      
      if (!manager.isInitialized) {
        return ServiceResult.error(
          message: manager.errorMessage ?? 'Ошибка инициализации',
        );
      }
      
      final fileId = const Uuid().v4();
      final extension = path.extension(file.path).replaceFirst('.', '');
      final encryptedFile = File('/encrypted/$fileId.enc');
      
      final success = await manager.encryptFile(
        input: file,
        output: encryptedFile,
        fileId: fileId,
        fileExtension: extension,
      );
      
      if (!success) {
        return ServiceResult.error(message: 'Ошибка шифрования файла');
      }
      
      // Сохранить метаданные в БД...
      
      return ServiceResult.success();
    } catch (e, st) {
      logError('Ошибка сохранения вложения', error: e, stackTrace: st);
      return ServiceResult.error(message: 'Ошибка сохранения');
    }
  }
  
  Future<ServiceResult<File>> getDecryptedAttachment(String fileId) async {
    try {
      final manager = _ref.read(fileEncryptorProvider.notifier);
      
      final encryptedFile = File('/encrypted/$fileId.enc');
      final tempDir = await getTemporaryDirectory();
      final outputFile = File('${tempDir.path}/$fileId');
      
      final extension = await manager.decryptFile(
        input: encryptedFile,
        output: outputFile,
        trackForCleanup: true, // Автоматическая очистка
      );
      
      if (extension == null) {
        return ServiceResult.error(message: 'Ошибка дешифрования');
      }
      
      return ServiceResult.success(data: outputFile);
    } catch (e, st) {
      logError('Ошибка получения вложения', error: e, stackTrace: st);
      return ServiceResult.error(message: 'Ошибка получения файла');
    }
  }
}
```

## Миграция со старого API

### Было (AsyncNotifier):
```dart
final result = await ref.read(fileEncryptorProvider.future);
if (result.success) {
  await result.data.encryptFile(...);
}
```

### Стало (Notifier):
```dart
final manager = ref.read(fileEncryptorProvider.notifier);
await manager.initialize();
await manager.encryptFile(...);
```

## Важные замечания

- ⚠️ **Безопасность**: Никогда не логируйте пути расшифрованных файлов в production
- 🔒 **Очистка**: Всегда вызывайте `cleanup()` перед закрытием БД или логаутом
- 📊 **Мониторинг**: Используйте `state.decryptedFiles.length` для отслеживания количества временных файлов
- 🚀 **Производительность**: Не забывайте про `trackForCleanup: false` для постоянных файлов
- 🔄 **Автоматика**: FileEncryptor автоматически очищает файлы при срабатывании таймера неактивности

## Защита от утечки данных

Благодаря интеграции с `AppLifecycleProvider`, все временные файлы автоматически удаляются при:

1. **Таймауте неактивности** (120 секунд по умолчанию)
2. **Закрытии приложения** (detached state)
3. **Logout пользователя** (через clearAll)
4. **Dispose провайдера**

### Пример полного цикла безопасности

```dart
// 1. Пользователь открыл зашифрованный документ
final manager = ref.read(fileEncryptorProvider.notifier);
await manager.decryptFile(
  input: encryptedFile,
  output: tempFile,
  trackForCleanup: true, // ← Файл отслеживается
);

// 2. Пользователь читает документ...

// 3. Пользователь свернул приложение
// → AppLifecycleNotifier запускает таймер (120 секунд)

// 4. Таймер истёк
// → AppLifecycleNotifier устанавливает dataCleared = true
// → FileEncryptorNotifier автоматически вызывает cleanup()
// → Все временные файлы удалены из файловой системы ✓

// 5. Пользователь возвращается в приложение
// → Приложение требует повторную аутентификацию
// → Никаких расшифрованных данных не осталось в памяти устройства ✓
```

### Мониторинг безопасности

```dart
class SecurityMonitorWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileEncryptorProvider);
    final lifecycleState = ref.watch(appLifecycleProvider);
    
    return Column(
      children: [
        Text('Временных файлов: ${fileState.decryptedFiles.length}'),
        Text('Таймер активен: ${lifecycleState.timerActive}'),
        Text('Осталось времени: ${lifecycleState.remainingTime}s'),
        
        if (fileState.decryptedFiles.isNotEmpty && lifecycleState.timerActive)
          WarningWidget(
            message: 'Внимание! Временные файлы будут удалены через '
                     '${lifecycleState.remainingTime} секунд',
          ),
      ],
    );
  }
}
```

## Тестирование автоматической очистки

```dart
void testAutoCleanup() async {
  final container = ProviderContainer();
  final manager = container.read(fileEncryptorProvider.notifier);
  final lifecycle = container.read(appLifecycleProvider.notifier);
  
  // Инициализируем
  await manager.initialize();
  
  // Дешифруем файл
  await manager.decryptFile(
    input: testEncryptedFile,
    output: testTempFile,
  );
  
  print('Файлов до очистки: ${manager.decryptedFiles.length}'); // 1
  
  // Симулируем срабатывание таймера
  await lifecycle.clearAll();
  
  // Даём время на обработку listener'а
  await Future.delayed(Duration(milliseconds: 100));
  
  print('Файлов после очистки: ${manager.decryptedFiles.length}'); // 0
  
  // Проверяем, что файл удалён из файловой системы
  final fileExists = await testTempFile.exists();
  print('Файл существует: $fileExists'); // false
}
```
