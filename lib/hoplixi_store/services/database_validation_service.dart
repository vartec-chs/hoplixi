import 'dart:io';
import 'package:hoplixi/app/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Реализация сервиса валидации базы данных
class DatabaseValidationService {
  static void validateCreateDatabaseParams({
    required String name,
    required String masterPassword,
  }) {
    if (name.trim().isEmpty) {
      throw const DatabaseError.operationFailed(
        operation: 'validateCreateDatabase',
        details: 'Empty database name',
        message: 'Имя базы данных не может быть пустым',
      );
    }

    if (masterPassword.trim().isEmpty) {
      throw const DatabaseError.operationFailed(
        operation: 'validateCreateDatabase',
        details: 'Empty master password',
        message: 'Мастер-пароль не может быть пустым',
      );
    }

    if (masterPassword.length < 4) {
      throw const DatabaseError.operationFailed(
        operation: 'validateCreateDatabase',
        details: 'Password too short',
        message: 'Мастер-пароль должен содержать минимум 4 символа',
      );
    }
  }

  static void validateOpenDatabaseParams({
    required String path,
    required String masterPassword,
  }) {
    if (path.trim().isEmpty) {
      throw const DatabaseError.operationFailed(
        operation: 'validateOpenDatabase',
        details: 'Empty database path',
        message: 'Путь к базе данных не может быть пустым',
      );
    }

    if (masterPassword.trim().isEmpty) {
      throw const DatabaseError.operationFailed(
        operation: 'validateOpenDatabase',
        details: 'Empty master password',
        message: 'Мастер-пароль не может быть пустым',
      );
    }
  }

  static Future<void> validateDatabaseCreation(String dbPath) async {
    if (File(dbPath).existsSync()) {
      logWarning(
        'База данных уже существует',
        tag: 'DatabaseValidationService',
        data: {'path': dbPath},
      );
      throw DatabaseError.databaseAlreadyExists(path: dbPath);
    }
  }

  static Future<void> validateDatabaseExists(String path) async {
    if (!File(path).existsSync()) {
      logWarning(
        'База данных не найдена',
        tag: 'DatabaseValidationService',
        data: {'path': path},
      );
      throw DatabaseError.databaseNotFound(path: path);
    }
  }

  static Future<void> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      logInfo(
        'Создание директории',
        tag: 'DatabaseValidationService',
        data: {'path': path},
      );
      await directory.create(recursive: true);
    }
  }
}
