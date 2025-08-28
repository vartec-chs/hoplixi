import 'package:hoplixi/encrypted_database/dto/db_dto.dart';
import 'package:hoplixi/encrypted_database/db_state.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

/// Интерфейс для управления подключением к базе данных
abstract class IDatabaseConnectionService {
  /// Создает новое подключение к базе данных
  Future<T> createConnection<T>({
    required String path,
    required String password,
  });

  /// Проверяет подключение к базе данных
  Future<bool> verifyConnection<T>({
    required T database,
    required String password,
  });

  /// Инициализирует метаданные базы данных
  Future<void> initializeDatabaseMetadata<T>({
    required T database,
    required String name,
    required String description,
    required Map<String, String> passwordData,
  });

  /// Закрывает подключение к базе данных
  Future<void> closeConnection<T>(T? database);
}

/// Интерфейс для валидации операций с базой данных
abstract class IDatabaseValidationService {
  /// Валидирует параметры создания базы данных
  void validateCreateDatabaseParams({
    required String name,
    required String masterPassword,
  });

  /// Валидирует параметры открытия базы данных
  void validateOpenDatabaseParams({
    required String path,
    required String masterPassword,
  });

  /// Проверяет, что база данных не существует (для создания)
  Future<void> validateDatabaseCreation(String dbPath);

  /// Проверяет, что база данных существует (для открытия)
  Future<void> validateDatabaseExists(String path);

  /// Проверяет и создает директорию, если она не существует
  Future<void> ensureDirectoryExists(String path);
}

/// Интерфейс для работы с историей баз данных
abstract class IDatabaseHistoryService {
  /// Записывает доступ к базе данных
  Future<void> recordDatabaseAccess({
    required String path,
    required String name,
    String? description,
    String? masterPassword,
    bool saveMasterPassword = false,
  });

  /// Обновляет время последнего доступа
  Future<void> updateLastAccessed(String path);

  /// Получает все базы данных
  Future<List<DatabaseEntry>> getAllDatabases();

  /// Получает информацию о базе данных
  Future<DatabaseEntry?> getDatabaseInfo(String path);

  /// Удаляет базу данных из истории
  Future<void> removeFromHistory(String path);

  /// Очищает всю историю
  Future<void> clearHistory();

  /// Устанавливает/снимает отметку избранное
  Future<void> setFavorite(String path, bool isFavorite);

  /// Сохраняет мастер-пароль
  Future<void> saveMasterPassword(String path, String masterPassword);

  /// Удаляет сохраненный пароль
  Future<void> removeSavedPassword(String path);

  /// Получает избранные базы данных
  Future<List<DatabaseEntry>> getFavoriteDatabases();

  /// Получает недавно использованные базы данных
  Future<List<DatabaseEntry>> getRecentDatabases({int limit = 10});

  /// Получает базы данных с сохраненными паролями
  Future<List<DatabaseEntry>> getDatabasesWithSavedPasswords();

  /// Пытается выполнить автологин
  Future<String?> tryAutoLogin(String path);

  /// Получает статистику
  Future<Map<String, dynamic>> getStatistics();

  /// Выполняет обслуживание
  Future<void> performMaintenance();
}

/// Основной интерфейс для управления зашифрованными базами данных
abstract class IEncryptedDatabaseManager {
  /// Текущая база данных
  dynamic get database;

  /// Проверяет, открыта ли база данных
  bool get hasOpenDatabase;

  /// Создает новую базу данных
  Future<DatabaseState> createDatabase(CreateDatabaseDto dto);

  /// Открывает существующую базу данных
  Future<DatabaseState> openDatabase(OpenDatabaseDto dto);

  /// Закрывает текущую базу данных
  Future<DatabaseState> closeDatabase();

  /// Пытается открыть базу данных с автологином
  Future<DatabaseState?> openWithAutoLogin(String path);

  /// Умное открытие базы данных
  Future<DatabaseState?> smartOpen(String path, [String? providedPassword]);

  /// Проверяет возможность автологина
  Future<bool> canAutoLogin(String path);

  /// Выбор файла базы данных через диалог
  Future<String?> pickDatabaseFile();

  /// Освобождает ресурсы
  Future<void> dispose();

  // Методы для работы с историей
  Future<void> updateDatabaseLastAccessed(String path);
  Future<List<DatabaseEntry>> getAllDatabases();
  Future<DatabaseEntry?> getDatabaseInfo(String path);
  Future<void> removeDatabaseFromHistory(String path);
  Future<void> clearDatabaseHistory();
  Future<void> setDatabaseFavorite(String path, bool isFavorite);
  Future<void> saveMasterPassword(String path, String masterPassword);
  Future<void> removeSavedMasterPassword(String path);
  Future<List<DatabaseEntry>> getFavoriteDatabases();
  Future<List<DatabaseEntry>> getRecentDatabases({int limit = 10});
  Future<List<DatabaseEntry>> getDatabasesWithSavedPasswords();
  Future<String?> tryAutoLogin(String path);
  Future<Map<String, dynamic>> getDatabaseHistoryStatistics();
  Future<void> performDatabaseHistoryMaintenance();
}
