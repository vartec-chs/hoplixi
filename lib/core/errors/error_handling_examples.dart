import 'package:hoplixi/core/errors/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/encrypted_database/encrypted_database_manager.dart';
import 'package:hoplixi/encrypted_database/dto/db_dto.dart';

/// Примеры использования улучшенной системы обработки ошибок
class ErrorHandlingExamples {
  /// Пример 1: Безопасное выполнение операции с fallback
  static Future<List<String>> safeGetDatabaseList() async {
    return await ErrorHandler.safeExecute(
      operation: 'getDatabaseList',
      context: 'ErrorHandlingExamples',
      function: () async {
        // Симуляция получения списка баз данных
        final manager = EncryptedDatabaseManager();
        final databases = await manager.getAllDatabases();
        return databases.map((db) => db.name).toList();
      },
      fallbackValue: <String>[], // Возвращаем пустой список в случае ошибки
    );
  }

  /// Пример 2: Операция с кастомной обработкой ошибок
  static Future<bool> tryOpenDatabase(String path, String password) async {
    try {
      ErrorHandler.logOperationStart(
        operation: 'openDatabase',
        context: 'ErrorHandlingExamples',
        additionalData: {'path': path},
      );

      final manager = EncryptedDatabaseManager();
      final dto = OpenDatabaseDto(path: path, masterPassword: password);
      await manager.openDatabase(dto);

      ErrorHandler.logSuccess(
        operation: 'openDatabase',
        context: 'ErrorHandlingExamples',
        additionalData: {'path': path},
      );

      return true;
    } catch (e, stackTrace) {
      final dbError = ErrorHandler.handleDatabaseOperation(
        operation: 'openDatabase',
        error: e,
        context: 'ErrorHandlingExamples',
        additionalData: {'path': path},
        stackTrace: stackTrace,
      );

      // Логируем специфичную информацию об ошибке
      if (dbError is InvalidPasswordError) {
        logWarning(
          'Неверный пароль для базы данных',
          tag: 'ErrorHandlingExamples',
          data: {'path': path},
        );
      } else if (dbError is DatabaseNotFoundError) {
        logWarning(
          'База данных не найдена',
          tag: 'ErrorHandlingExamples',
          data: {'path': path},
        );
      }

      return false;
    }
  }

  /// Пример 3: Обработка ошибок secure storage
  static Future<void> handleSecureStorageOperation() async {
    try {
      // Симуляция операции с secure storage
      throw Exception('Ошибка доступа к ключу');
    } catch (e, stackTrace) {
      final secureError = ErrorHandler.handleSecureStorageError(
        operation: 'readSecureKey',
        error: e,
        context: 'ErrorHandlingExamples',
        stackTrace: stackTrace,
      );

      logError(
        'Обработана ошибка secure storage',
        error: secureError,
        tag: 'ErrorHandlingExamples',
      );

      // Здесь можно предпринять восстановительные действия
      // например, пересоздать ключ или показать диалог пользователю
    }
  }

  /// Пример 4: Групповая обработка операций
  static Future<Map<String, dynamic>> performBatchOperations() async {
    final results = <String, dynamic>{};

    // Операция 1: Получение списка баз данных
    results['databases'] = await ErrorHandler.safeExecute(
      operation: 'getAllDatabases',
      context: 'BatchOperations',
      function: () async {
        final manager = EncryptedDatabaseManager();
        return await manager.getAllDatabases();
      },
      fallbackValue: [],
    );

    // Операция 2: Получение статистики
    results['statistics'] = await ErrorHandler.safeExecute(
      operation: 'getStatistics',
      context: 'BatchOperations',
      function: () async {
        final manager = EncryptedDatabaseManager();
        return await manager.getDatabaseHistoryStatistics();
      },
      fallbackValue: <String, dynamic>{},
    );

    // Операция 3: Проверка состояния
    results['hasOpenDatabase'] = ErrorHandler.safeExecuteSync(
      operation: 'checkOpenDatabase',
      context: 'BatchOperations',
      function: () {
        final manager = EncryptedDatabaseManager();
        return manager.hasOpenDatabase;
      },
      fallbackValue: false,
    );

    return results;
  }

  /// Пример 5: Обработка ошибок в UI провайдере
  static Future<String> handleUserAction(String action) async {
    try {
      switch (action) {
        case 'create':
          // Симуляция создания базы данных
          await Future.delayed(Duration(seconds: 1));
          return 'База данных создана успешно';

        case 'open':
          // Симуляция открытия базы данных
          throw DatabaseError.invalidPassword();

        case 'backup':
          // Симуляция резервного копирования
          throw Exception('Недостаточно места на диске');

        default:
          throw ArgumentError('Неизвестное действие: $action');
      }
    } catch (e) {
      // Возвращаем понятное пользователю сообщение
      return ErrorHandler.getUserFriendlyMessage(e);
    }
  }

  /// Пример 6: Логирование с маскированием чувствительных данных
  static void logSensitiveOperation(String password, String keyData) {
    // Неправильно - логируем чувствительные данные
    // logInfo('Операция с паролем: $password');

    // Правильно - маскируем чувствительные данные
    logInfo(
      'Операция с паролем выполнена',
      tag: 'ErrorHandlingExamples',
      data: {
        'passwordLength': password.length,
        'hasPassword': password.isNotEmpty,
        'keyDataMasked': '***${keyData.length} bytes***',
      },
    );
  }

  /// Пример 7: Обработка различных типов ошибок
  static String categorizeError(dynamic error) {
    if (error is DatabaseError) {
      return error.when(
        invalidPassword: (code, message, data) => 'Ошибка аутентификации',
        databaseNotFound: (path, code, message, data) => 'Файл не найден',
        databaseAlreadyExists: (path, code, message, data) =>
            'Файл уже существует',
        connectionFailed: (details, code, message, data) =>
            'Ошибка подключения',
        operationFailed: (operation, details, code, message, data) =>
            'Ошибка операции',
        pathNotAccessible: (path, code, message, data) => 'Доступ запрещен',
        unknown: (details, code, message, data) => 'Неизвестная ошибка',
        keyError: (details, code, message, data) => 'Ошибка ключей',
        secureStorageError: (details, code, message, data) =>
            'Ошибка хранилища',
      );
    }

    if (error is StateError) {
      return 'Ошибка состояния';
    }

    if (error is ArgumentError) {
      return 'Неверные аргументы';
    }

    return 'Общая ошибка';
  }

  /// Пример 8: Восстановление после ошибок
  static Future<bool> recoverFromError(DatabaseError error) async {
    return await ErrorHandler.safeExecute(
      operation: 'errorRecovery',
      context: 'ErrorHandlingExamples',
      function: () async {
        return error.when(
          invalidPassword: (code, message, data) async {
            // Можем предложить пользователю ввести пароль заново
            logInfo('Предлагаем повторный ввод пароля', tag: 'ErrorRecovery');
            return false; // Требуется действие пользователя
          },
          databaseNotFound: (path, code, message, data) async {
            // Можем предложить создать новую базу данных
            logInfo(
              'Предлагаем создать новую базу данных',
              tag: 'ErrorRecovery',
            );
            return false; // Требуется действие пользователя
          },
          connectionFailed: (details, code, message, data) async {
            // Можем попробовать переподключиться
            logInfo('Попытка переподключения', tag: 'ErrorRecovery');
            await Future.delayed(Duration(seconds: 1));
            return true; // Автоматическое восстановление
          },
          operationFailed: (operation, details, code, message, data) async {
            // Зависит от типа операции
            logInfo(
              'Анализ возможности повтора операции',
              tag: 'ErrorRecovery',
              data: {'operation': operation},
            );
            return operation.contains(
              'read',
            ); // Операции чтения можно повторить
          },
          pathNotAccessible: (path, code, message, data) async {
            // Можем предложить выбрать другое место
            logInfo(
              'Предлагаем выбрать другое расположение',
              tag: 'ErrorRecovery',
            );
            return false; // Требуется действие пользователя
          },
          unknown: (details, code, message, data) async => false,
          keyError: (details, code, message, data) async {
            // Можем попробовать пересоздать ключи
            logInfo('Попытка восстановления ключей', tag: 'ErrorRecovery');
            return true; // Попробуем автоматическое восстановление
          },
          secureStorageError: (details, code, message, data) async {
            // Можем попробовать переинициализировать хранилище
            logInfo('Переинициализация secure storage', tag: 'ErrorRecovery');
            return true; // Автоматическое восстановление
          },
          databaseAlreadyExists: (path, code, message, data) async => false,
        );
      },
      fallbackValue: false,
    );
  }
}
