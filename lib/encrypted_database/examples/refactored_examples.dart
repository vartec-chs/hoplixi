import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/encrypted_database/index.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

/// Пример использования рефакторенного модуля encrypted_database
///
/// Демонстрирует новую архитектуру с использованием:
/// - Dependency Injection
/// - Интерфейсов для тестируемости
/// - Улучшенной обработки ошибок
/// - Структурированного логирования

class DatabaseExampleScreen extends ConsumerWidget {
  const DatabaseExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseState = ref.watch(databaseStateV2Provider);
    final databaseNotifier = ref.read(databaseStateV2Provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Database Manager V2 Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(databaseState),
            const SizedBox(height: 20),
            _buildActionButtons(context, databaseNotifier),
            const SizedBox(height: 20),
            _buildHistorySection(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(DatabaseState state) {
    Color statusColor;
    String statusText;

    switch (state.status) {
      case DatabaseStatus.closed:
        statusColor = Colors.grey;
        statusText = 'Закрыта';
        break;
      case DatabaseStatus.open:
        statusColor = Colors.green;
        statusText = 'Открыта';
        break;
      case DatabaseStatus.loading:
        statusColor = Colors.blue;
        statusText = 'Загрузка...';
        break;
      case DatabaseStatus.error:
        statusColor = Colors.red;
        statusText = 'Ошибка';
        break;
      case DatabaseStatus.locked:
        statusColor = Colors.orange;
        statusText = 'Заблокирована';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус базы данных',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(statusText),
              ],
            ),
            if (state.name != null) ...[
              const SizedBox(height: 8),
              Text('Имя: ${state.name}'),
            ],
            if (state.path != null) ...[
              const SizedBox(height: 4),
              Text('Путь: ${state.path}', style: const TextStyle(fontSize: 12)),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ошибка: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DatabaseStateV2Notifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => _showCreateDatabaseDialog(context, notifier),
          child: const Text('Создать новую БД'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _showOpenDatabaseDialog(context, notifier),
          child: const Text('Открыть БД'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _pickAndOpenDatabase(notifier),
          child: const Text('Выбрать файл БД'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => notifier.closeDatabase(),
          child: const Text('Закрыть БД'),
        ),
      ],
    );
  }

  Widget _buildHistorySection(WidgetRef ref) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'История баз данных',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<DatabaseEntry>>(
                  future: ref.read(databaseManagerV2Provider).getAllDatabases(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Ошибка: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final databases = snapshot.data ?? [];

                    if (databases.isEmpty) {
                      return const Center(
                        child: Text('Нет сохраненных баз данных'),
                      );
                    }

                    return ListView.builder(
                      itemCount: databases.length,
                      itemBuilder: (context, index) {
                        final db = databases[index];
                        return _buildDatabaseListItem(db, ref);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatabaseListItem(DatabaseEntry db, WidgetRef ref) {
    final notifier = ref.read(databaseStateV2Provider.notifier);

    return ListTile(
      title: Text(db.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(db.path),
          Text(
            'Последний доступ: ${_formatDateTime(db.lastAccessed)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (db.isFavorite)
            const Icon(Icons.favorite, color: Colors.red, size: 16),
          if (db.isMasterPasswordSaved)
            const Icon(Icons.key, color: Colors.blue, size: 16),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openDatabaseFromHistory(db, notifier),
          ),
        ],
      ),
    );
  }

  void _showCreateDatabaseDialog(
    BuildContext context,
    DatabaseStateV2Notifier notifier,
  ) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать новую базу данных'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя базы данных',
                hintText: 'MyDatabase',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Мастер-пароль'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (опционально)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final dto = CreateDatabaseDto(
                name: nameController.text.trim(),
                masterPassword: passwordController.text,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );

              notifier
                  .createDatabase(dto)
                  .then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('База данных создана успешно'),
                      ),
                    );
                  })
                  .catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showOpenDatabaseDialog(
    BuildContext context,
    DatabaseStateV2Notifier notifier,
  ) {
    final pathController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Открыть базу данных'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'Путь к файлу базы данных',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Мастер-пароль'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final dto = OpenDatabaseDto(
                path: pathController.text.trim(),
                masterPassword: passwordController.text,
              );

              notifier
                  .openDatabase(dto)
                  .then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('База данных открыта успешно'),
                      ),
                    );
                  })
                  .catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
            },
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  void _pickAndOpenDatabase(DatabaseStateV2Notifier notifier) async {
    try {
      final path = await notifier.pickDatabaseFile();
      if (path != null) {
        // Пытаемся умное открытие (сначала автологин)
        final success = await notifier.smartOpen(path);
        if (!success) {
          // Если автологин не сработал, показываем диалог для ввода пароля
          // Здесь можно показать диалог для ввода пароля
        }
      }
    } catch (error) {
      // Обработка ошибок
    }
  }

  void _openDatabaseFromHistory(
    DatabaseEntry db,
    DatabaseStateV2Notifier notifier,
  ) async {
    try {
      // Пытаемся умное открытие
      final success = await notifier.smartOpen(db.path);
      if (!success) {
        // Если не получилось, показываем диалог для пароля
        // Здесь можно показать диалог
      }
    } catch (error) {
      // Обработка ошибок
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Пример использования сервисов напрямую (для тестирования)
class DatabaseServiceExample {
  final ICryptoService _cryptoService;
  final IDatabaseValidationService _validationService;
  final IDatabaseConnectionService _connectionService;
  final IDatabaseHistoryService _historyService;

  DatabaseServiceExample({
    required ICryptoService cryptoService,
    required IDatabaseValidationService validationService,
    required IDatabaseConnectionService connectionService,
    required IDatabaseHistoryService historyService,
  }) : _cryptoService = cryptoService,
       _validationService = validationService,
       _connectionService = connectionService,
       _historyService = historyService;

  /// Пример прямого использования криптографического сервиса
  Future<void> demonstrateCryptoService() async {
    // Генерация соли
    final salt = _cryptoService.generateSecureSalt();
    print('Generated salt: $salt');

    // Хеширование пароля
    const password = 'MySecurePassword123';
    final hash = _cryptoService.hashPassword(password, salt);
    print('Password hash: $hash');

    // Проверка пароля
    final isValid = _cryptoService.verifyPassword(password, hash, salt);
    print('Password verification: $isValid');

    // Деривация ключа
    final key = _cryptoService.deriveKey(password, salt);
    print('Derived key length: ${key.length}');

    // Очистка чувствительных данных
    _cryptoService.clearSensitiveData(key);
  }

  /// Пример использования сервиса валидации
  Future<void> demonstrateValidationService() async {
    try {
      // Валидация параметров создания БД
      _validationService.validateCreateDatabaseParams(
        name: 'TestDB',
        masterPassword: 'securePassword',
      );
      print('Create database parameters are valid');

      // Валидация параметров открытия БД
      _validationService.validateOpenDatabaseParams(
        path: '/path/to/database.db',
        masterPassword: 'securePassword',
      );
      print('Open database parameters are valid');

      // Создание директории
      await _validationService.ensureDirectoryExists('/path/to/directory');
      print('Directory ensured');
    } catch (e) {
      print('Validation error: $e');
    }
  }

  /// Пример использования сервиса истории
  Future<void> demonstrateHistoryService() async {
    try {
      // Запись доступа к БД
      await _historyService.recordDatabaseAccess(
        path: '/path/to/database.db',
        name: 'My Database',
        description: 'Test database',
      );
      print('Database access recorded');

      // Получение всех БД
      final databases = await _historyService.getAllDatabases();
      print('Found ${databases.length} databases in history');

      // Получение избранных БД
      final favorites = await _historyService.getFavoriteDatabases();
      print('Found ${favorites.length} favorite databases');

      // Получение статистики
      final stats = await _historyService.getStatistics();
      print('Database statistics: $stats');
    } catch (e) {
      print('History service error: $e');
    }
  }
}

/// Пример создания пользовательских реализаций интерфейсов
class MockCryptoService implements ICryptoService {
  @override
  String generateSecureSalt() {
    return 'mock_salt';
  }

  @override
  String hashPassword(String password, String salt) {
    return 'mock_hash_$password\_$salt';
  }

  @override
  Uint8List deriveKey(String password, String salt) {
    return Uint8List.fromList([1, 2, 3, 4, 5]);
  }

  @override
  bool verifyPassword(String password, String hash, String salt) {
    return hashPassword(password, salt) == hash;
  }

  @override
  Map<String, String> generatePasswordData(String password) {
    final salt = generateSecureSalt();
    final hash = hashPassword(password, salt);
    return {'hash': hash, 'salt': salt};
  }

  @override
  void clearSensitiveData(Uint8List? data) {
    // Mock implementation
  }
}

/// Пример использования в тестах
void runExample() {
  // Создание мок-сервисов для тестирования
  final mockCrypto = MockCryptoService();
  final validationService = DatabaseValidationService();
  final connectionService = DatabaseConnectionService(
    cryptoService: mockCrypto,
  );
  final historyService = DatabaseHistoryService();

  // Создание примера с мок-сервисами
  final example = DatabaseServiceExample(
    cryptoService: mockCrypto,
    validationService: validationService,
    connectionService: connectionService,
    historyService: historyService,
  );

  // Демонстрация работы сервисов
  example.demonstrateCryptoService();
  example.demonstrateValidationService();
  example.demonstrateHistoryService();
}
