import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

/// Примеры использования DatabaseHistoryService с HoplixiStoreManager
class DatabaseHistoryExamples {
  /// Пример создания базы данных с сохранением в историю
  static Future<void> createDatabaseExample() async {
    final manager = HoplixiStoreManager();

    try {
      // Создаем новую базу данных
      final createDto = CreateDatabaseDto(
        name: 'my_database',
        masterPassword: 'secure_password_123',
        description: 'Моя тестовая база данных',
        saveMasterPassword: true, // Сохраняем пароль в истории
      );

      final result = await manager.createDatabase(createDto);
      print('База данных создана: ${result.status}');

      // История автоматически обновится через _recordDatabaseEntry
    } catch (e) {
      print('Ошибка создания БД: $e');
    }
  }

  /// Пример открытия базы данных с обновлением истории
  static Future<void> openDatabaseExample() async {
    final manager = HoplixiStoreManager();

    try {
      // Открываем существующую базу данных
      final openDto = OpenDatabaseDto(
        path: '/path/to/database.hpx',
        masterPassword: 'secure_password_123',
        saveMasterPassword: false, // Не сохраняем пароль
      );

      final result = await manager.openDatabase(openDto);
      print('База данных открыта: ${result.status}');

      // История автоматически обновится
    } catch (e) {
      print('Ошибка открытия БД: $e');
    }
  }

  /// Пример работы с историей
  static Future<void> historyManagementExample() async {
    final manager = HoplixiStoreManager();

    // Получаем всю историю
    final history = await manager.getDatabaseHistory();
    print('Всего записей в истории: ${history.length}');

    for (final entry in history) {
      print('БД: ${entry.name} (${entry.path})');
      print('  Последний доступ: ${entry.lastAccessed}');
      print('  Сохранен пароль: ${entry.saveMasterPassword}');
      print('  Описание: ${entry.description ?? "Нет описания"}');
    }

    // Получаем записи с сохраненными паролями
    final entriesWithPasswords = await manager
        .getDatabaseHistoryWithSavedPasswords();
    print('\\nБазы с сохраненными паролями: ${entriesWithPasswords.length}');

    // Получаем статистику
    final stats = await manager.getDatabaseHistoryStats();
    print('\\nСтатистика истории:');
    print('  Всего записей: ${stats['totalEntries']}');
    print('  С паролями: ${stats['entriesWithSavedPasswords']}');
    print('  Самая старая: ${stats['oldestEntry']}');
    print('  Самая новая: ${stats['newestEntry']}');
  }

  /// Пример очистки истории
  static Future<void> historyCleanupExample() async {
    final manager = HoplixiStoreManager();

    // Удаляем конкретную запись
    await manager.removeDatabaseHistoryEntry('/path/to/old/database.hpx');
    print('Запись удалена из истории');

    // Полностью очищаем историю (осторожно!)
    // await manager.clearDatabaseHistory();
    // print('История полностью очищена');
  }

  /// Пример получения информации о конкретной базе данных
  static Future<void> getDatabaseInfoExample() async {
    final manager = HoplixiStoreManager();

    final dbPath = '/path/to/database.hpx';
    final entry = await manager.getDatabaseHistoryEntry(dbPath);

    if (entry != null) {
      print('Информация о БД:');
      print('  Название: ${entry.name}');
      print('  Путь: ${entry.path}');
      print('  Описание: ${entry.description ?? "Нет описания"}');
      print('  Создана: ${entry.createdAt}');
      print('  Последний доступ: ${entry.lastAccessed}');
      print('  Пароль сохранен: ${entry.saveMasterPassword}');

      if (entry.saveMasterPassword && entry.masterPassword != null) {
        print('  Сохраненный пароль: [СКРЫТ]');
      }
    } else {
      print('База данных не найдена в истории');
    }
  }

  /// Пример работы с прямым доступом к сервису истории
  static Future<void> directHistoryServiceExample() async {
    final manager = HoplixiStoreManager();

    // Прямой доступ к сервису истории для продвинутых операций
    final historyService = manager.historyService;

    // Записываем информацию о базе данных вручную
    await historyService.recordDatabaseAccess(
      path: '/custom/path/database.hpx',
      name: 'Моя пользовательская БД',
      description: 'Созданная вручную запись',
      masterPassword: null, // Не сохраняем пароль
      saveMasterPassword: false,
    );

    // Обновляем информацию о существующей базе данных
    await historyService.updateDatabaseInfo(
      path: '/custom/path/database.hpx',
      name: 'Обновленное название',
      description: 'Обновленное описание',
    );

    print('Пользовательская запись добавлена и обновлена');
  }

  /// Пример обработки освобождения ресурсов
  static Future<void> resourceManagementExample() async {
    final manager = HoplixiStoreManager();

    try {
      // Работаем с базой данных...
      await openDatabaseExample();

      // Работаем с историей...
      await historyManagementExample();
    } finally {
      // Обязательно освобождаем ресурсы
      await manager.dispose();
      print('Ресурсы менеджера освобождены');
    }
  }
}
