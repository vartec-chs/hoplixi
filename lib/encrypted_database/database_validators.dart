import 'services/database_validation_service.dart';

/// Валидаторы для операций с базой данных
///
/// УСТАРЕЛ: Используйте DatabaseValidationService для новых проектов
/// Этот класс сохранен для обратной совместимости
@Deprecated('Используйте DatabaseValidationService вместо DatabaseValidators')
class DatabaseValidators {
  static final DatabaseValidationService _service = DatabaseValidationService();

  /// Проверяет, что база данных не существует (для создания)
  static Future<void> validateDatabaseCreation(String dbPath) async {
    await _service.validateDatabaseCreation(dbPath);
  }

  /// Проверяет, что база данных существует (для открытия)
  static Future<void> validateDatabaseExists(String path) async {
    await _service.validateDatabaseExists(path);
  }

  /// Проверяет и создает директорию, если она не существует
  static Future<void> ensureDirectoryExists(String path) async {
    await _service.ensureDirectoryExists(path);
  }

  /// Валидирует параметры создания базы данных
  static void validateCreateDatabaseParams({
    required String name,
    required String masterPassword,
  }) {
    _service.validateCreateDatabaseParams(
      name: name,
      masterPassword: masterPassword,
    );
  }

  /// Валидирует параметры открытия базы данных
  static void validateOpenDatabaseParams({
    required String path,
    required String masterPassword,
  }) {
    _service.validateOpenDatabaseParams(
      path: path,
      masterPassword: masterPassword,
    );
  }
}
