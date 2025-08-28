# 🚀 Быстрый старт: История баз данных

## Инициализация в main.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  StorageServiceLocator.initialize(container);
  await StorageServiceLocator.initializeStorage();
  
  runApp(UncontrolledProviderScope(
    container: container, 
    child: MyApp()
  ));
}
```

## Основное использование

```dart
import 'package:hoplixi/encrypted_database/encrypted_database_manager.dart';
import 'package:hoplixi/encrypted_database/dto/db_dto.dart';

class DatabaseScreen extends StatefulWidget {
  @override
  _DatabaseScreenState createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final EncryptedDatabaseManager _dbManager = EncryptedDatabaseManager();

  @override
  void initState() {
    super.initState();
    _dbManager.initialize();
  }

  // Создание новой базы данных
  Future<void> createDatabase() async {
    final result = await _dbManager.createDatabase(CreateDatabaseDto(
      name: 'MyPasswordDB',
      masterPassword: 'secure_password',
      description: 'База паролей',
    ));
    // Автоматически записывается в историю
  }

  // Открытие с автологином
  Future<void> openWithAutoLogin(String path) async {
    final result = await _dbManager.openWithAutoLogin(path);
    if (result == null) {
      // Требуется ввод пароля
      showPasswordDialog();
    }
  }

  // Получение истории
  Future<void> loadHistory() async {
    final allDatabases = await _dbManager.getAllDatabases();
    final recentDatabases = await _dbManager.getRecentDatabases(limit: 5);
    final favorites = await _dbManager.getFavoriteDatabases();
    
    // Обновляем UI
    setState(() {
      // ...
    });
  }

  @override
  void dispose() {
    _dbManager.dispose();
    super.dispose();
  }
}
```

## Готовые UI компоненты

```dart
import 'package:hoplixi/encrypted_database/ui/database_history_screen.dart';

// В вашем роутинге
Navigator.push(context, MaterialPageRoute(
  builder: (context) => DatabaseHistoryScreen(),
));

// Или экран выбора базы данных
final selectedDatabase = await Navigator.push<DatabaseEntry>(
  context, 
  MaterialPageRoute(builder: (context) => DatabasePickerScreen()),
);
```

## Автологин workflow

```dart
Future<void> openDatabaseSmart(String path) async {
  // 1. Попробовать автологин
  final result = await _dbManager.openWithAutoLogin(path);
  if (result != null) {
    showSuccess('База открыта автоматически!');
    return;
  }

  // 2. Запросить пароль у пользователя
  final password = await showPasswordDialog();
  if (password != null) {
    try {
      await _dbManager.openDatabase(OpenDatabaseDto(
        path: path,
        masterPassword: password,
        saveMasterPassword: await askToSavePassword(), // Спросить у пользователя
      ));
    } catch (e) {
      showError('Неверный пароль');
    }
  }
}
```

## Управление избранными

```dart
Future<void> toggleFavorite(String path) async {
  final dbInfo = await _dbManager.getDatabaseInfo(path);
  if (dbInfo != null) {
    await _dbManager.setDatabaseFavorite(path, !dbInfo.isFavorite);
    loadHistory(); // Обновить UI
  }
}
```

## Статистика

```dart
Future<void> showStatistics() async {
  final stats = await _dbManager.getDatabaseHistoryStatistics();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Статистика'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Всего баз данных: ${stats['total']}'),
          Text('Избранных: ${stats['favorites']}'),
          Text('Использованных сегодня: ${stats['accessedToday']}'),
        ],
      ),
    ),
  );
}
```

## Основные методы

| Метод | Описание |
|-------|----------|
| `getAllDatabases()` | Получить все базы данных |
| `getRecentDatabases(limit: 5)` | Последние N баз данных |
| `getFavoriteDatabases()` | Избранные базы данных |
| `tryAutoLogin(path)` | Получить сохраненный пароль |
| `openWithAutoLogin(path)` | Открыть с автологином |
| `setDatabaseFavorite(path, bool)` | Управление избранными |
| `saveMasterPassword(path, password)` | Сохранить пароль |
| `getDatabaseHistoryStatistics()` | Получить статистику |

---

**Готово! 🎉 Функционал истории баз данных полностью интегрирован.**
