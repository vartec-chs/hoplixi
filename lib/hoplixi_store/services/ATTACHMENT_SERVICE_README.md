# AttachmentService

Сервис для работы с вложениями (attachments) в Hoplixi с автоматическим определением стратегии хранения.

## 🎯 Особенности

### Автоматическое определение стратегии хранения

Сервис автоматически определяет, как хранить файл, основываясь на его размере:

- **Файлы ≤ 1 MB** → хранятся в БД как `BLOB` (поле `fileData`)
- **Файлы > 1 MB** → хранится только путь к файлу (поле `filePath`)

Порог можно настроить при создании сервиса:

```dart
final service = AttachmentService(
  database,
  maxSizeForDbStorage: 2 * 1024 * 1024, // 2 MB
);
```

## 📦 Архитектура

```
AttachmentService
    ├── Автоопределение (createAttachmentFromFile)
    ├── Прямое управление
    │   ├── createAttachmentFromBytes (всегда в БД)
    │   └── DAO методы (через AttachmentsDao)
    ├── CRUD операции
    ├── Поиск и фильтрация
    ├── Stream подписки
    └── Проверка целостности (checksum)
```

## 🚀 Основные методы

### 1. Создание вложения из файла (с автоопределением)

```dart
final result = await attachmentService.createAttachmentFromFile(
  filePath: '/path/to/file.pdf',
  name: 'Документ.pdf',
  description: 'Важный документ',
  passwordId: 'password-uuid',  // ИЛИ
  // otpId: 'otp-uuid',         // ИЛИ
  // noteId: 'note-uuid',       // (ровно один!)
);

if (result.success) {
  print('ID вложения: ${result.data}');
  print('Сообщение: ${result.message}');
}
```

**Что делает метод:**
- Проверяет существование файла
- Валидирует родительскую сущность (password/otp/note)
- Определяет MIME-тип файла
- Вычисляет checksum (SHA-256)
- **Автоматически выбирает стратегию хранения:**
  - Маленький файл → сохраняет данные в БД
  - Большой файл → сохраняет только путь

### 2. Создание вложения из данных в памяти

```dart
final imageBytes = await imageFile.readAsBytes();

final result = await attachmentService.createAttachmentFromBytes(
  name: 'avatar.png',
  data: imageBytes,
  mimeType: 'image/png',
  description: 'Аватар пользователя',
  passwordId: passwordId,
);
```

**Использование:**
- Для небольших файлов, уже загруженных в память
- Для генерируемых данных (QR-коды, скриншоты)
- Всегда сохраняет данные в БД

### 3. Получение вложения

#### Карточка (без контента)
```dart
final result = await attachmentService.getAttachmentById(attachmentId);

if (result.success) {
  final card = result.data; // AttachmentCardDto
  print('Имя: ${card.name}');
  print('Размер: ${card.fileSize} байт');
  print('Тип: ${card.type}'); // AttachmentType.fromPath | fromData
}
```

#### С полными данными
```dart
final result = await attachmentService.getAttachmentWithData(attachmentId);

if (result.success) {
  if (result.data is AttachmentFromPathDto) {
    final dto = result.data as AttachmentFromPathDto;
    print('Путь к файлу: ${dto.filePath}');
  } else if (result.data is AttachmentFromDataDto) {
    final dto = result.data as AttachmentFromDataDto;
    print('Размер данных: ${dto.fileData.length} байт');
  }
}
```

#### Получение файла для использования
```dart
final result = await attachmentService.getAttachmentFile(attachmentId);

if (result.success) {
  final file = result.data; // File
  
  // Для вложений с путем - это оригинальный файл
  // Для вложений из БД - создается временный файл
  
  // Использование файла
  await OpenFile.open(file.path);
  // или
  await Share.shareXFiles([XFile(file.path)]);
}
```

### 4. Получение списков вложений

```dart
// Для конкретной сущности
final passwordAttachments = await attachmentService.getPasswordAttachments(passwordId);
final otpAttachments = await attachmentService.getOtpAttachments(otpId);
final noteAttachments = await attachmentService.getNoteAttachments(noteId);

// Все вложения
final allAttachments = await attachmentService.getAllAttachments();

// Поиск
final searchResults = await attachmentService.searchAttachments('договор');

// Недавние
final recentAttachments = await attachmentService.getRecentAttachments(limit: 5);
```

### 5. Удаление

```dart
final result = await attachmentService.deleteAttachment(attachmentId);

if (result.success) {
  print('Вложение удалено');
}
```

**Важно:** При удалении родительской сущности (password/otp/note) вложения удаляются автоматически через `ON DELETE CASCADE`.

### 6. Статистика

```dart
// Общее количество
final totalCount = await attachmentService.getAttachmentsCount();

// Для конкретной сущности
final passwordAttCount = await attachmentService.getPasswordAttachmentsCount(passwordId);
final otpAttCount = await attachmentService.getOtpAttachmentsCount(otpId);
final noteAttCount = await attachmentService.getNoteAttachmentsCount(noteId);
```

### 7. Stream подписки (Reactive)

```dart
// Для UI с реактивным обновлением
final passwordAttachmentsStream = attachmentService.watchPasswordAttachments(passwordId);

// В виджете
StreamBuilder<List<AttachmentCardDto>>(
  stream: passwordAttachmentsStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final attachment = snapshot.data![index];
          return ListTile(
            title: Text(attachment.name),
            subtitle: Text('${attachment.fileSize} байт'),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
);
```

### 8. Проверка целостности файла

```dart
final result = await attachmentService.verifyAttachmentIntegrity(attachmentId);

if (result.success && result.data == true) {
  print('Файл не поврежден');
} else {
  print('Файл поврежден или изменен!');
}
```

## 🔐 Валидация и безопасность

### Автоматическая валидация

При создании вложения сервис проверяет:

1. **Существование файла** (для createAttachmentFromFile)
2. **Родительская сущность:**
   - Указана ровно одна сущность (password ИЛИ otp ИЛИ note)
   - Сущность существует в БД
3. **Вычисление checksum** для проверки целостности

### Безопасность

- Все операции логируются без записи содержимого файлов
- Checksum хранится для проверки целостности
- Временные файлы создаются в системном temp-каталоге

## 📊 DTO структуры

### AttachmentCardDto
Легковесная карточка для списков (без контента):
```dart
{
  id: String,
  name: String,
  description: String?,
  mimeType: String,
  type: AttachmentType?,      // fromPath | fromData
  fileSize: int?,
  checksum: String?,
  passwordId: String?,
  otpId: String?,
  noteId: String?,
  createdAt: DateTime,
  modifiedAt: DateTime,
  lastAccessed: DateTime?,
}
```

### AttachmentFromPathDto
Для вложений, хранимых на диске:
```dart
{
  ...все поля AttachmentCardDto,
  filePath: String,           // путь к файлу
}
```

### AttachmentFromDataDto
Для вложений в БД:
```dart
{
  ...все поля AttachmentCardDto,
  fileData: List<int>,        // данные файла (Uint8List в DAO)
}
```

## 🎯 Паттерны использования

### Пример 1: Добавление вложения к паролю

```dart
Future<void> addAttachmentToPassword(String passwordId, String filePath) async {
  final result = await ref.read(attachmentServiceProvider).createAttachmentFromFile(
    filePath: filePath,
    name: path.basename(filePath),
    passwordId: passwordId,
  );
  
  if (result.success) {
    ToastHelper.success('Вложение добавлено');
  } else {
    ToastHelper.error(result.message ?? 'Ошибка добавления');
  }
}
```

### Пример 2: Отображение вложений в UI

```dart
class AttachmentsListWidget extends ConsumerWidget {
  final String passwordId;
  
  const AttachmentsListWidget({required this.passwordId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsStream = ref
      .watch(attachmentServiceProvider)
      .watchPasswordAttachments(passwordId);
    
    return StreamBuilder<List<AttachmentCardDto>>(
      stream: attachmentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final attachments = snapshot.data!;
        if (attachments.isEmpty) {
          return Text('Нет вложений');
        }
        
        return ListView.builder(
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return AttachmentCard(
              attachment: attachment,
              onTap: () => _openAttachment(attachment.id),
              onDelete: () => _deleteAttachment(attachment.id),
            );
          },
        );
      },
    );
  }
  
  Future<void> _openAttachment(String id) async {
    final service = ref.read(attachmentServiceProvider);
    final result = await service.getAttachmentFile(id);
    
    if (result.success) {
      await OpenFile.open(result.data!.path);
    }
  }
  
  Future<void> _deleteAttachment(String id) async {
    final confirmed = await showConfirmDialog(context);
    if (!confirmed) return;
    
    final result = await ref.read(attachmentServiceProvider).deleteAttachment(id);
    if (result.success) {
      ToastHelper.success('Вложение удалено');
    }
  }
}
```

### Пример 3: Загрузка файла с выбором

```dart
Future<void> pickAndAttachFile(String passwordId) async {
  final result = await FilePicker.platform.pickFiles();
  
  if (result == null) return;
  
  final file = result.files.first;
  final filePath = file.path;
  
  if (filePath == null) return;
  
  final attachResult = await ref.read(attachmentServiceProvider).createAttachmentFromFile(
    filePath: filePath,
    name: file.name,
    passwordId: passwordId,
  );
  
  if (attachResult.success) {
    final size = file.size;
    final storageType = size <= AttachmentService.defaultMaxSizeForDbStorage 
      ? 'в базе данных' 
      : 'на диске';
    
    ToastHelper.success('Файл добавлен ($storageType)');
  } else {
    ToastHelper.error(attachResult.message ?? 'Ошибка');
  }
}
```

## 🔧 Настройка порога хранения

По умолчанию файлы ≤ 1 MB хранятся в БД. Изменить можно так:

```dart
// В провайдере
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);
  
  return AttachmentService(
    db.currentDatabase,
    maxSizeForDbStorage: 512 * 1024, // 512 KB
  );
});
```

## ⚠️ Важные замечания

1. **Родительская сущность обязательна** - каждое вложение должно принадлежать password, otp или note
2. **Каскадное удаление** - при удалении родителя вложения удаляются автоматически
3. **Checksum** - всегда вычисляется для проверки целостности
4. **Временные файлы** - для вложений из БД создаются в `Directory.systemTemp`
5. **MIME-тип** - определяется автоматически, но можно указать вручную для `createAttachmentFromBytes`

## 📝 Логирование

Все операции логируются с тегом `AttachmentService`:
- Создание/удаление вложений
- Стратегия хранения (БД vs путь)
- Ошибки валидации и IO
- Проверка целостности

Содержимое файлов **никогда** не логируется.

## 🔄 Интеграция с Riverpod

```dart
// Провайдер сервиса
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);
  return AttachmentService(db.currentDatabase);
});

// Использование в UI
final service = ref.read(attachmentServiceProvider);
final result = await service.createAttachmentFromFile(...);
```

## 🎨 UI компоненты (рекомендации)

Для отображения вложений рекомендуется создать:

1. **AttachmentCard** - карточка вложения с иконкой по MIME-типу
2. **AttachmentsList** - список вложений с возможностью открытия/удаления
3. **AttachmentPicker** - диалог выбора файла с предпросмотром
4. **AttachmentViewer** - просмотр вложения (изображения, PDF и т.д.)

См. примеры в `features/attachments/widgets/` (если созданы).
