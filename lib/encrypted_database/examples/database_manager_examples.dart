import 'package:hoplixi/encrypted_database/encrypted_database_manager.dart';
import 'package:hoplixi/encrypted_database/dto/db_dto.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

/// Примеры использования EncryptedDatabaseManager с интеграцией записи истории БД
class DatabaseManagerExamples {
  final EncryptedDatabaseManager _manager = EncryptedDatabaseManager();

  /// Пример создания новой базы данных
  Future<void> createNewDatabaseExample() async {
    try {
      // Инициализируем менеджер
     

      // Создаем новую базу данных
      final createDto = CreateDatabaseDto(
        name: 'MyPasswordDB',
        masterPassword: 'super_secure_password_123',
        description: 'База данных для хранения паролей',
        customPath: null, // Используем путь по умолчанию
      );

      final result = await _manager.createDatabase(createDto);
      print('База данных создана: ${result.path}');

      // Информация автоматически сохраняется в историю
      final allDatabases = await _manager.getAllDatabases();
      print('Всего баз данных в истории: ${allDatabases.length}');
    } catch (e) {
      print('Ошибка при создании базы данных: $e');
    }
  }

  /// Пример открытия существующей базы данных
  Future<void> openExistingDatabaseExample() async {
    try {
      final openDto = OpenDatabaseDto(
        path: '/path/to/existing/database.db',
        masterPassword: 'existing_password',
      );

      final result = await _manager.openDatabase(openDto);
      print('База данных открыта: ${result.path}');

      // Информация автоматически обновляется в истории
      final dbInfo = await _manager.getDatabaseInfo(openDto.path);
      print('Последний доступ: ${dbInfo?.lastAccessed}');
    } catch (e) {
      print('Ошибка при открытии базы данных: $e');
    }
  }

  /// Пример работы с историей баз данных
  Future<void> workWithDatabaseHistoryExample() async {
    try {
      // Получаем все базы данных
      final allDatabases = await _manager.getAllDatabases();
      print('Все базы данных (${allDatabases.length}):');
      for (final db in allDatabases) {
        print('- ${db.name} (${db.path}) - ${db.lastAccessed}');
      }

      // Получаем недавние базы данных
      final recentDatabases = await _manager.getRecentDatabases(limit: 5);
      print('\nНедавние базы данных (${recentDatabases.length}):');
      for (final db in recentDatabases) {
        print('- ${db.name} - ${db.lastAccessed}');
      }

      // Получаем избранные базы данных
      final favoriteDatabases = await _manager.getFavoriteDatabases();
      print('\nИзбранные базы данных (${favoriteDatabases.length}):');
      for (final db in favoriteDatabases) {
        print('- ${db.name}');
      }
    } catch (e) {
      print('Ошибка при работе с историей: $e');
    }
  }

  /// Пример управления избранными базами данных
  Future<void> manageFavoriteDatabasesExample() async {
    try {
      const dbPath = '/path/to/database.db';

      // Добавляем в избранное
      await _manager.setDatabaseFavorite(dbPath, true);
      print('База данных добавлена в избранное');

      // Проверяем, что добавилась
      final dbInfo = await _manager.getDatabaseInfo(dbPath);
      print('Статус избранного: ${dbInfo?.isFavorite}');

      // Удаляем из избранного
      await _manager.setDatabaseFavorite(dbPath, false);
      print('База данных удалена из избранного');
    } catch (e) {
      print('Ошибка при управлении избранными: $e');
    }
  }

  /// Пример работы с сохраненными паролями (осторожно!)
  Future<void> manageSavedPasswordsExample() async {
    try {
      const dbPath = '/path/to/database.db';
      const masterPassword = 'secret_password';

      // Сохраняем мастер-пароль (только если пользователь явно согласился!)
      await _manager.saveMasterPassword(dbPath, masterPassword);
      print('Мастер-пароль сохранен');

      // Проверяем, что пароль сохранен
      final dbInfo = await _manager.getDatabaseInfo(dbPath);
      print('Пароль сохранен: ${dbInfo?.isMasterPasswordSaved}');
      print(
        'Сохраненный пароль: ${dbInfo?.masterPassword}',
      ); // Осторожно с логированием!

      // Удаляем сохраненный пароль
      await _manager.removeSavedMasterPassword(dbPath);
      print('Сохраненный пароль удален');
    } catch (e) {
      print('Ошибка при работе с паролями: $e');
    }
  }

  /// Пример очистки истории
  Future<void> clearHistoryExample() async {
    try {
      // Удаляем конкретную базу данных из истории
      const dbPath = '/path/to/unwanted/database.db';
      await _manager.removeDatabaseFromHistory(dbPath);
      print('База данных удалена из истории');

      // Полная очистка истории (осторожно!)
      // await _manager.clearDatabaseHistory();
      // print('Вся история очищена');
    } catch (e) {
      print('Ошибка при очистке истории: $e');
    }
  }

  /// Пример выбора базы данных из файловой системы
  Future<void> pickDatabaseFileExample() async {
    try {
      // Открываем диалог выбора файла
      final selectedPath = await _manager.pickDatabaseFile();

      if (selectedPath != null) {
        print('Выбран файл: $selectedPath');

        // Проверяем, есть ли эта база в истории
        final dbInfo = await _manager.getDatabaseInfo(selectedPath);
        if (dbInfo != null) {
          print('База данных найдена в истории:');
          print('- Название: ${dbInfo.name}');
          print('- Последний доступ: ${dbInfo.lastAccessed}');
          print('- Пароль сохранен: ${dbInfo.isMasterPasswordSaved}');

          // Можно попробовать открыть с сохраненным паролем
          if (dbInfo.isMasterPasswordSaved && dbInfo.masterPassword != null) {
            final openDto = OpenDatabaseDto(
              path: selectedPath,
              masterPassword: dbInfo.masterPassword!,
            );

            try {
              await _manager.openDatabase(openDto);
              print('База данных успешно открыта с сохраненным паролем');
            } catch (e) {
              print('Не удалось открыть с сохраненным паролем: $e');
            }
          }
        } else {
          print('База данных не найдена в истории. Это новая база данных.');
        }
      } else {
        print('Выбор файла отменен');
      }
    } catch (e) {
      print('Ошибка при выборе файла: $e');
    }
  }

  /// Пример работы напрямую со StorageServiceLocator
  Future<void> directStorageExample() async {
    try {
      // Создаем запись базы данных вручную
      final customDatabase = DatabaseEntry(
        id: 'custom_db_001',
        name: 'Кастомная БД',
        path: '/custom/path/to/database.db',
        lastAccessed: DateTime.now(),
        description: 'Создана вручную через StorageServiceLocator',
        isFavorite: true,
        isMasterPasswordSaved: false,
      );

      // Сохраняем через StorageServiceLocator
      await StorageServiceLocator.addDatabase(customDatabase);
      print('Кастомная база данных добавлена');

      // Получаем статистику хранилища
      final stats = await StorageServiceLocator.getStorageStatistics();
      print('Статистика хранилища:');
      print('- Общий размер: ${stats['totalSize']} байт');
      print('- Количество БД: ${stats['databaseStorage']['count']}');

      // Выполняем обслуживание хранилища
      await StorageServiceLocator.performMaintenance();
      print('Обслуживание хранилища выполнено');
    } catch (e) {
      print('Ошибка при работе с хранилищем: $e');
    }
  }

  /// Комплексный пример: полный цикл работы с базой данных
  Future<void> fullWorkflowExample() async {
    try {
      print('=== Полный цикл работы с базой данных ===');

      // 1. Инициализируем менеджер
     
      print('✓ Менеджер инициализирован');

      // 2. Создаем новую базу данных
      final createDto = CreateDatabaseDto(
        name: 'WorkflowTestDB',
        masterPassword: 'workflow_password_123',
        description: 'Тестовая база для демонстрации workflow',
      );

      final createResult = await _manager.createDatabase(createDto);
      print('✓ База данных создана: ${createResult.name}');

      // 3. Закрываем базу данных
      await _manager.closeDatabase();
      print('✓ База данных закрыта');

      // 4. Открываем базу данных снова
      final openDto = OpenDatabaseDto(
        path: createResult.path!,
        masterPassword: 'workflow_password_123',
      );

      final openResult = await _manager.openDatabase(openDto);
      print('✓ База данных открыта повторно');

      // 5. Добавляем в избранное
      await _manager.setDatabaseFavorite(createResult.path!, true);
      print('✓ База данных добавлена в избранное');

      // 6. Получаем информацию из истории
      final dbInfo = await _manager.getDatabaseInfo(createResult.path!);
      print('✓ Информация о БД получена:');
      print('  - Название: ${dbInfo?.name}');
      print('  - Путь: ${dbInfo?.path}');
      print('  - Избранная: ${dbInfo?.isFavorite}');
      print('  - Последний доступ: ${dbInfo?.lastAccessed}');

      // 7. Получаем список всех баз данных
      final allDatabases = await _manager.getAllDatabases();
      print('✓ Всего баз данных в истории: ${allDatabases.length}');

      // 8. Закрываем и очищаем ресурсы
      await _manager.closeDatabase();
      await _manager.dispose();
      print('✓ Ресурсы очищены');

      print('=== Workflow завершен успешно ===');
    } catch (e) {
      print('❌ Ошибка в workflow: $e');
    }
  }
}

/// Пример инициализации в main.dart
class MainInitializationExample {
  static Future<void> initializeInMain() async {
    // Этот код должен быть добавлен в main.dart

    // 1. Инициализируем StorageServiceLocator (обычно в main.dart)
    // final container = ProviderContainer();
    // StorageServiceLocator.initialize(container);

    // 2. Инициализируем хранилище
    // await StorageServiceLocator.initializeStorage();

    // 3. Создаем менеджер базы данных
    // final dbManager = EncryptedDatabaseManager();
    // await dbManager.initialize();

    print('Пример кода для main.dart:');
    print('''
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // Инициализируем сервис-локатор
  StorageServiceLocator.initialize(container);
  
  // Инициализируем хранилище
  await StorageServiceLocator.initializeStorage();
  
  runApp(UncontrolledProviderScope(
    container: container, 
    child: MyApp()
  ));
}
''');
  }
}
