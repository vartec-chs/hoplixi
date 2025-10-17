# LocalMetaCrudService - CRUD сервис для LocalMeta

## Описание

`LocalMetaCrudService` — это синглтон сервис для управления `LocalMeta` записями с автоматическим кэшированием в памяти и перманентным хранилищем на диске.

### Особенности

- **Синглтон паттерн**: автоматическое управление единственным экземпляром
- **Кэширование в памяти**: все данные загружаются при инициализации
- **Перманентное хранилище**: автоматическое сохранение в JSON файл
- **Поиск по полям**: оптимизированный поиск по разным критериям
- **Логирование**: все операции логируются через `AppLogger`
- **Безопасность**: возврат неизменяемых копий списков

## Инициализация

```dart
import 'package:hoplixi/features/password_manager/cloud_sync/services/local_meta_crud_service.dart';

// В main.dart или точке инициализации приложения
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем сервис
  await LocalMetaCrudService.instance.initialize();
  
  runApp(const MyApp());
}
```

## Использование

### Создание (CREATE)

```dart
final service = LocalMetaCrudService.instance;

// Создание одной записи
final newMeta = LocalMeta(
  id: 'uuid-1',
  dbId: 'db-123',
  dbName: 'Passwords',
  deviceId: 'device-456',
);

final result = await service.create(newMeta);

if (result.success) {
  print('Запись создана: ${result.data?.id}');
} else {
  print('Ошибка: ${result.message}');
}

// Создание нескольких записей
final items = [
  LocalMeta(id: 'id-1', dbId: 'db-1', dbName: 'DB1', deviceId: 'dev-1'),
  LocalMeta(id: 'id-2', dbId: 'db-2', dbName: 'DB2', deviceId: 'dev-2'),
];

final multiResult = await service.createMultiple(items);
print('Добавлено: ${multiResult.message}');
```

### Чтение (READ)

```dart
final service = LocalMetaCrudService.instance;

// Получение всех записей
final all = await service.getAll();
print('Всего записей: ${all.length}');

// Получение по ID
final byId = await service.getById('uuid-1');
if (byId != null) {
  print('Найдено: ${byId.dbName}');
}

// Получение по dbId
final byDbId = await service.getByDbId('db-123');

// Получение по deviceId
final byDeviceId = await service.getByDeviceId('device-456');

// Получение по dbName
final byDbName = await service.getByDbName('Passwords');

// Поиск с фильтром (содержит подстроку)
final searchResults = await service.search(
  dbId: 'db-',
  dbName: 'Pass',
  deviceId: 'device',
);

// Получение по диапазону дат экспорта
final exportRange = await service.getByExportDateRange(
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
);

// Получение записей, которые никогда не экспортировались
final neverExported = await service.getNeverExported();
```

### Обновление (UPDATE)

```dart
final service = LocalMetaCrudService.instance;

// Обновление всей записи
final updated = LocalMeta(
  id: 'uuid-1',
  dbId: 'db-123',
  dbName: 'Passwords Updated',
  deviceId: 'device-456',
  lastExportAt: DateTime.now(),
);

final result = await service.update(updated);

// Обновление времени последнего экспорта
final exportResult = await service.updateLastExportAt('uuid-1');

// Обновление времени последнего импорта
final importResult = await service.updateLastImportedAt('uuid-1');
```

### Удаление (DELETE)

```dart
final service = LocalMetaCrudService.instance;

// Удаление одной записи
final delResult = await service.delete('uuid-1');

if (delResult.success) {
  print('Запись удалена: ${delResult.data?.dbName}');
}

// Удаление нескольких записей
final multiDelResult = await service.deleteMultiple(['id-1', 'id-2', 'id-3']);

// Удаление всех записей
final allDelResult = await service.deleteAll();
```

## Статистика и Утилиты

```dart
final service = LocalMetaCrudService.instance;

// Получение размера кэша
final size = service.cacheSize;
print('Записей в памяти: $size');

// Проверка инициализации
if (service.isInitialized) {
  print('Сервис готов к работе');
}

// Получение детальной статистики
final stats = await service.getStatistics();
// {
//   'totalCount': 5,
//   'neverExported': 2,
//   'neverImported': 1,
//   'lastExportAt': '2025-10-17T10:30:00.000Z',
//   'lastImportedAt': '2025-10-17T09:15:00.000Z',
//   'uniqueDatabases': 3,
//   'uniqueDevices': 2,
// }

// Сброс и переинициализация
await service.reset();
```

## Примеры использования в Провайдерах

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/local_meta.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/services/local_meta_crud_service.dart';

part 'cloud_sync_providers.g.dart';

@riverpod
Future<List<LocalMeta>> allLocalMetas(AllLocalMetasRef ref) async {
  final service = LocalMetaCrudService.instance;
  return service.getAll();
}

@riverpod
Future<LocalMeta?> localMetaById(LocalMetaByIdRef ref, String id) async {
  final service = LocalMetaCrudService.instance;
  return service.getById(id);
}

@riverpod
Future<List<LocalMeta>> searchLocalMeta(
  SearchLocalMetaRef ref,
  String? dbId,
  String? dbName,
  String? deviceId,
) async {
  final service = LocalMetaCrudService.instance;
  return service.search(
    dbId: dbId,
    dbName: dbName,
    deviceId: deviceId,
  );
}

@riverpod
Future<Map<String, dynamic>> localMetaStats(LocalMetaStatsRef ref) async {
  final service = LocalMetaCrudService.instance;
  return service.getStatistics();
}
```

## Примеры использования в UI

```dart
import 'package:hoplixi/features/password_manager/cloud_sync/services/local_meta_crud_service.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/local_meta.dart';

class LocalMetaListScreen extends StatefulWidget {
  @override
  State<LocalMetaListScreen> createState() => _LocalMetaListScreenState();
}

class _LocalMetaListScreenState extends State<LocalMetaListScreen> {
  late final LocalMetaCrudService _service;

  @override
  void initState() {
    super.initState();
    _service = LocalMetaCrudService.instance;
  }

  void _createNew() async {
    final newMeta = LocalMeta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dbId: 'db-new',
      dbName: 'New Database',
      deviceId: 'current-device',
    );

    final result = await _service.create(newMeta);
    
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Создано: ${result.message}')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${result.message}')),
      );
    }
  }

  void _search(String query) async {
    final results = await _service.search(dbName: query);
    setState(() {
      // обновляем UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LocalMeta')),
      body: FutureBuilder<List<LocalMeta>>(
        future: _service.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.dbName),
                subtitle: Text(item.deviceId),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _service.delete(item.id);
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Архитектура хранилища

Данные хранятся в JSON файле по пути:
```
<ApplicationDocumentsDirectory>/local_meta_cache.json
```

Структура файла:
```json
[
  {
    "id": "uuid-1",
    "dbId": "db-123",
    "dbName": "Passwords",
    "deviceId": "device-456",
    "lastExportAt": "2025-10-17T10:30:00.000Z",
    "lastImportedAt": null
  },
  {
    "id": "uuid-2",
    "dbId": "db-124",
    "dbName": "Notes",
    "deviceId": "device-457",
    "lastExportAt": null,
    "lastImportedAt": "2025-10-17T09:15:00.000Z"
  }
]
```

## Логирование

Все операции логируются с тегом `LocalMetaCrudService`. Примеры:

```
ℹ️ Инициализация LocalMetaCrudService
ℹ️ Создание новой записи LocalMeta [id: uuid-1, dbId: db-123]
ℹ️ Данные загружены из файла [count: 5]
ℹ️ Получение записи по dbId [dbId: db-123]
✅ Запись LocalMeta создана [id: uuid-1]
```

## Обработка ошибок

Все методы возвращают `LocalMetaResult` или `List`, которые не выбрасывают исключения:

```dart
final result = await service.create(meta);

// Проверяем успех операции
if (!result.success) {
  // Показываем сообщение об ошибке
  print('Ошибка: ${result.message}');
}
```

## Производительность

- **Инициализация**: O(n) - один раз при запуске приложения
- **Чтение**: O(n) - линейный поиск в памяти (быстро для обычных размеров)
- **Запись/Удаление**: O(n) + IO - добавляется операция записи на диск
- **Поиск**: O(n) - фильтрация в памяти

Для наборов данных < 10000 записей сервис показывает отличную производительность.
