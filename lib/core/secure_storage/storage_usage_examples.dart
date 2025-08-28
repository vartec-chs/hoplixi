import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

/// Примеры использования StorageServiceLocator
class StorageUsageExamples {
  /// Пример работы с базами данных
  static Future<void> databaseExample() async {
    // Добавление новой базы данных
    final newDatabase = DatabaseEntry(
      id: 'db_001',
      name: 'Моя база данных',
      path: '/path/to/database.db',
      lastAccessed: DateTime.now(),
      description: 'Описание базы данных',
    );

    await StorageServiceLocator.addDatabase(newDatabase);

    // Получение базы данных
    final database = await StorageServiceLocator.getDatabase('db_001');
    print('Найдена база данных: ${database?.name}');

    // Получение всех баз данных
    final allDatabases = await StorageServiceLocator.getAllDatabases();
    print('Всего баз данных: ${allDatabases.length}');

    // Обновление времени последнего доступа
    await StorageServiceLocator.updateLastAccessed('db_001');

    // Проверка существования
    final exists = await StorageServiceLocator.containsDatabase('db_001');
    print('База данных существует: $exists');

    // Удаление базы данных
    await StorageServiceLocator.removeDatabase('db_001');
  }

  /// Пример работы с сессиями авторизации
  static Future<void> sessionExample() async {
    // Создание новой сессии
    final session = AuthSession(
      sessionId: 'session_001',
      userId: 'user_123',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: 24)),
      refreshToken: 'refresh_token_here',
      metadata: {'deviceId': 'device_123'},
    );

    await StorageServiceLocator.saveSession(session);

    // Получение сессии
    final retrievedSession = await StorageServiceLocator.getSession(
      'session_001',
    );
    print('Найдена сессия для пользователя: ${retrievedSession?.userId}');

    // Получение активных сессий
    final activeSessions = await StorageServiceLocator.getActiveSessions();
    print('Активных сессий: ${activeSessions.length}');

    // Проверка валидности сессии
    final isValid = await StorageServiceLocator.isSessionValid('session_001');
    print('Сессия валидна: $isValid');

    // Получение текущей сессии
    final currentSession = await StorageServiceLocator.getCurrentSession();
    print('Текущая сессия: ${currentSession?.sessionId}');

    // Очистка просроченных сессий
    await StorageServiceLocator.clearExpiredSessions();
  }

  /// Пример работы с расширенными функциями
  static Future<void> advancedExample() async {
    // Получение статистики
    final stats = await StorageServiceLocator.getStorageStatistics();
    print('Статистика хранилища: $stats');

    // Проверка целостности
    final integrity = await StorageServiceLocator.verifyAllStoragesIntegrity();
    print('Результаты проверки целостности: $integrity');

    // Получение размера хранилища
    final size = await StorageServiceLocator.getStorageSize('database_list');
    print('Размер хранилища баз данных: $size байт');

    // Экспорт данных для резервного копирования
    final exportData = await StorageServiceLocator.exportEncryptedData(
      'database_list',
    );
    print('Данные экспортированы в: ${exportData['exportedAt']}');

    // Выполнение обслуживания
    await StorageServiceLocator.performMaintenance();

    // Очистка кэша
    await StorageServiceLocator.clearCache();
  }

  /// Пример инициализации в приложении
  static Future<void> initializationExample() async {
    // Обычно это делается в main.dart
    // final container = ProviderContainer();
    // StorageServiceLocator.initialize(container);

    // Инициализация хранилища
    await StorageServiceLocator.initializeStorage();

    // Теперь можно использовать все методы
    final databases = await StorageServiceLocator.getAllDatabases();
    print(
      'Приложение инициализировано, найдено баз данных: ${databases.length}',
    );
  }

  /// Пример работы с низкоуровневым хранилищем
  static Future<void> lowLevelExample() async {
    // Прямой доступ к базовому хранилищу для специальных случаев
    final storage = StorageServiceLocator.secureStorage;

    // Можно использовать все методы EncryptedKeyValueStorage напрямую
    await storage.write<Map<String, dynamic>>(
      storageKey: 'custom_storage',
      key: 'my_key',
      data: {'custom': 'data'},
      toJson: (data) => data,
    );

    final customData = await storage.read<Map<String, dynamic>>(
      storageKey: 'custom_storage',
      key: 'my_key',
      fromJson: (json) => json,
    );

    print('Пользовательские данные: $customData');
  }

  /// Пример обработки ошибок
  static Future<void> errorHandlingExample() async {
    try {
      // Попытка получить несуществующую базу данных
      final database = await StorageServiceLocator.getDatabase('non_existent');
      if (database == null) {
        print('База данных не найдена');
      }

      // Проверка инициализации
      final exists = await StorageServiceLocator.containsDatabase('test_id');
      print('Проверка выполнена: $exists');
    } catch (e) {
      if (e is StateError) {
        print('StorageServiceLocator не инициализирован: $e');
      } else {
        print('Ошибка при работе с хранилищем: $e');
      }
    }
  }
}
