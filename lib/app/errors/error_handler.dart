import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/app/errors/db_errors.dart';

/// Централизованный обработчик ошибок
///
/// Предоставляет методы для обработки различных типов ошибок
/// с автоматическим логированием и преобразованием в понятные пользователю сообщения
class ErrorHandler {
  /// Обрабатывает ошибку операции с базой данных
  static DatabaseError handleDatabaseOperation({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final String tag = 'ErrorHandler';
    final Map<String, dynamic> logData = {
      'operation': operation,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    // Логируем ошибку
    logError(
      'Ошибка операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: logData,
    );

    // Если ошибка уже является DatabaseError, возвращаем как есть
    if (error is DatabaseError) {
      return error;
    }

    // Преобразуем различные типы ошибок в DatabaseError
    if (error is StateError) {
      return DatabaseError.operationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Ошибка состояния при выполнении операции "$operation"',
        data: logData,
      );
    }

    if (error is ArgumentError) {
      return DatabaseError.operationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Неверные аргументы для операции "$operation"',
        data: logData,
      );
    }

    if (error is FormatException) {
      return DatabaseError.operationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Ошибка формата данных в операции "$operation"',
        data: logData,
      );
    }

    // Для всех остальных ошибок
    return DatabaseError.operationFailed(
      operation: operation,
      details: error.toString(),
      message: 'Неизвестная ошибка при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки безопасного хранилища
  static DatabaseError handleSecureStorageError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final String tag = 'ErrorHandler';
    final Map<String, dynamic> logData = {
      'operation': operation,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка безопасного хранилища в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: logData,
    );

    return DatabaseError.secureStorageError(
      details: error.toString(),
      message:
          'Ошибка безопасного хранилища при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки работы с ключами
  static DatabaseError handleKeyError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final String tag = 'ErrorHandler';
    final Map<String, dynamic> logData = {
      'operation': operation,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка работы с ключами в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: logData,
    );

    return DatabaseError.keyError(
      details: error.toString(),
      message: 'Ошибка работы с ключами при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Безопасно выполняет операцию с обработкой ошибок
  static Future<T> safeExecute<T>({
    required String operation,
    required Future<T> Function() function,
    String? context,
    Map<String, dynamic>? additionalData,
    T? fallbackValue,
  }) async {
    try {
      logDebug(
        'Выполнение операции "$operation"${context != null ? " в контексте $context" : ""}',
        tag: 'ErrorHandler',
        data: {
          'operation': operation,
          if (context != null) 'context': context,
          ...?additionalData,
        },
      );

      final result = await function();

      logDebug(
        'Операция "$operation" выполнена успешно',
        tag: 'ErrorHandler',
        data: {'operation': operation, if (context != null) 'context': context},
      );

      return result;
    } catch (error, stackTrace) {
      final dbError = handleDatabaseOperation(
        operation: operation,
        error: error,
        context: context,
        additionalData: additionalData,
        stackTrace: stackTrace,
      );

      if (fallbackValue != null) {
        logWarning(
          'Использование fallback значения для операции "$operation"',
          tag: 'ErrorHandler',
          data: {
            'operation': operation,
            'fallbackValue': fallbackValue.toString(),
          },
        );
        return fallbackValue;
      }

      throw dbError;
    }
  }

  /// Безопасно выполняет операцию с обработкой ошибок (синхронная версия)
  static T safeExecuteSync<T>({
    required String operation,
    required T Function() function,
    String? context,
    Map<String, dynamic>? additionalData,
    T? fallbackValue,
  }) {
    try {
      logDebug(
        'Выполнение синхронной операции "$operation"${context != null ? " в контексте $context" : ""}',
        tag: 'ErrorHandler',
        data: {
          'operation': operation,
          if (context != null) 'context': context,
          ...?additionalData,
        },
      );

      final result = function();

      logDebug(
        'Синхронная операция "$operation" выполнена успешно',
        tag: 'ErrorHandler',
        data: {'operation': operation, if (context != null) 'context': context},
      );

      return result;
    } catch (error, stackTrace) {
      final dbError = handleDatabaseOperation(
        operation: operation,
        error: error,
        context: context,
        additionalData: additionalData,
        stackTrace: stackTrace,
      );

      if (fallbackValue != null) {
        logWarning(
          'Использование fallback значения для синхронной операции "$operation"',
          tag: 'ErrorHandler',
          data: {
            'operation': operation,
            'fallbackValue': fallbackValue.toString(),
          },
        );
        return fallbackValue;
      }

      throw dbError;
    }
  }

  /// Получает понятное пользователю сообщение об ошибке
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DatabaseError) {
      return error.displayMessage;
    }

    if (error is StateError) {
      return 'Ошибка состояния приложения. Попробуйте перезапустить приложение.';
    }

    if (error is ArgumentError) {
      return 'Неверные параметры операции. Проверьте введенные данные.';
    }

    if (error is FormatException) {
      return 'Ошибка формата данных. Проверьте корректность введенной информации.';
    }

    // Для всех остальных ошибок
    return 'Произошла неожиданная ошибка. Попробуйте повторить операцию.';
  }

  /// Логирует успешное выполнение операции
  static void logSuccess({
    required String operation,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    logInfo(
      'Операция "$operation" выполнена успешно${context != null ? " в контексте $context" : ""}',
      tag: 'ErrorHandler',
      data: {
        'operation': operation,
        'success': true,
        if (context != null) 'context': context,
        ...?additionalData,
      },
    );
  }

  /// Логирует начало выполнения операции
  static void logOperationStart({
    required String operation,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    logDebug(
      'Начало операции "$operation"${context != null ? " в контексте $context" : ""}',
      tag: 'ErrorHandler',
      data: {
        'operation': operation,
        'phase': 'start',
        if (context != null) 'context': context,
        ...?additionalData,
      },
    );
  }
}
