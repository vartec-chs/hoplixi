# Документация: Логика очереди до инициализации приложения

## Описание проблемы

В некоторых случаях сообщения SnackBar могут вызываться до того, как UI приложения полностью инициализирован. Это может привести к потере сообщений или ошибкам при попытке их отображения.

## Решение

Реализована система двойной очереди, которая сохраняет сообщения до инициализации приложения и отображает их после готовности UI.

## Архитектура

### 1. SnackBarQueueManager

Абстрактный класс теперь включает дополнительные методы:

```dart
abstract class SnackBarQueueManager {
  // Основные методы очереди
  void enqueue(SnackBarData data);
  SnackBarData? dequeue();
  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
  void clear();
  
  // Методы для управления состоянием инициализации
  void setInitialized(bool initialized);
  bool get isInitialized;
  
  // Обработка очереди после инициализации
  List<SnackBarData> flushPendingQueue();
}
```

### 2. DefaultSnackBarQueueManager

Реализация с двойной очередью:

- **_queue**: Основная очередь для обработки сообщений
- **_pendingQueue**: Очередь для сообщений до инициализации
- **_isInitialized**: Флаг состояния инициализации

#### Логика работы:

1. **До инициализации**: Все сообщения попадают в `_pendingQueue`
2. **После инициализации**: Сообщения из `_pendingQueue` перемещаются в `_queue`
3. **Новые сообщения**: После инициализации идут сразу в `_queue`

### 3. ScaffoldMessengerManager

Обновлен для поддержки новой логики:

#### Ключевые изменения:

```dart
static void initializeApp() {
  if (!_isInitializedApp) {
    _isInitializedApp = true;
    
    // Уведомляем менеджер очереди о том, что приложение инициализировано
    instance._queueManager.setInitialized(true);
    
    // Обрабатываем отложенные сообщения
    instance._processPendingMessages();
  }
}

void showSnackBar(SnackBarData data) {
  _queueManager.enqueue(data);
  
  // Обрабатываем очередь только если приложение инициализировано
  if (_isInitializedApp) {
    _processQueue();
  }
}
```

## Использование

### 1. Базовое использование

```dart
void main() {
  // Сообщения до инициализации (сохраняются в pending очереди)
  ScaffoldMessengerManager.instance.showError('Ошибка инициализации');
  ScaffoldMessengerManager.instance.showInfo('Загрузка данных...');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: ScaffoldMessengerManager.globalKey,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    
    // Инициализируем приложение - отложенные сообщения будут показаны
    ScaffoldMessengerManager.initializeApp();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Это сообщение будет показано сразу
            ScaffoldMessengerManager.instance.showSuccess('Готово!');
          },
          child: Text('Показать сообщение'),
        ),
      ),
    );
  }
}
```

### 2. Проверка состояния очереди

```dart
final manager = ScaffoldMessengerManager.instance;

// Проверки состояния
bool isInitialized = manager.isAppInitialized;
int queueLength = manager.queueLength;
int pendingCount = manager.pendingMessagesCount;
int totalCount = manager.totalMessagesCount;
bool hasPending = manager.hasPendingMessages;

print('Инициализировано: $isInitialized');
print('В основной очереди: $queueLength');
print('Отложенных: $pendingCount');
print('Всего: $totalCount');
```

## API Методы

### ScaffoldMessengerManager

#### Новые свойства:
- `isAppInitialized` - проверить инициализировано ли приложение
- `pendingMessagesCount` - количество отложенных сообщений
- `hasPendingMessages` - есть ли отложенные сообщения
- `totalMessagesCount` - общее количество сообщений

#### Статические методы:
- `initializeApp()` - инициализация приложения и обработка отложенных сообщений

### DefaultSnackBarQueueManager

#### Дополнительные свойства:
- `pendingLength` - количество сообщений в pending очереди
- `hasPendingMessages` - есть ли сообщения в pending очереди
- `totalLength` - общее количество сообщений в обеих очередях

## Преимущества

1. **Отсутствие потерь сообщений**: Все сообщения сохраняются независимо от времени вызова
2. **Автоматическая обработка**: После инициализации сообщения автоматически отображаются
3. **Прозрачность**: API остается неизменным для пользователей
4. **Мониторинг**: Возможность отслеживать состояние очередей
5. **Гибкость**: Легко настроить и расширить

## Тестирование

Для тестирования можно использовать `PreInitializationExample` из файла примеров:

```dart
PreInitializationExample.demonstratePreInitBehavior();
```

Этот пример покажет весь жизненный цикл сообщений в консоли.

## Рекомендации

1. Всегда вызывайте `ScaffoldMessengerManager.initializeApp()` после готовности UI
2. Используйте свойства мониторинга для отладки
3. При необходимости очистки используйте `clearSnackBarQueue()` - он очистит обе очереди
4. Для критически важных сообщений проверяйте `isAppInitialized` перед добавлением

## Совместимость

Изменения полностью обратно совместимы. Существующий код будет работать без изменений, но для получения преимуществ новой функциональности нужно вызвать `initializeApp()`.
