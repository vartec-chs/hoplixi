import 'package:hoplixi/core/logger/app_logger.dart';
import 'secure_storage_errors.dart';

/// Централизованный обработчик ошибок для модуля безопасного хранилища
///
/// Предоставляет методы для обработки различных типов ошибок
/// с автоматическим логированием и преобразованием в понятные пользователю сообщения
class SecureStorageErrorHandler {
  static const String _tag = 'SecureStorageErrorHandler';

  /// Обрабатывает ошибку операции шифрования
  static SecureStorageError handleEncryptionError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'encryption',
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка шифрования в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    return SecureStorageError.encryptionFailed(
      operation: operation,
      details: error.toString(),
      message: 'Ошибка шифрования при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибку операции расшифрования
  static SecureStorageError handleDecryptionError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'decryption',
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка расшифрования в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    return SecureStorageError.decryptionFailed(
      operation: operation,
      details: error.toString(),
      message: 'Ошибка расшифрования при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки работы с ключами
  static SecureStorageError handleKeyError({
    required String operation,
    required dynamic error,
    String? storageKey,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'key_management',
      if (storageKey != null) 'storageKey': storageKey,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка работы с ключами в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    if (storageKey != null) {
      return SecureStorageError.keyValidationFailed(
        storageKey: storageKey,
        details: error.toString(),
        message: 'Ошибка работы с ключом для хранилища "$storageKey"',
        data: logData,
      );
    }

    return SecureStorageError.keyGenerationFailed(
      details: error.toString(),
      message: 'Ошибка генерации ключа шифрования',
      data: logData,
    );
  }

  /// Обрабатывает ошибки доступа к файлам
  static SecureStorageError handleFileError({
    required String operation,
    required dynamic error,
    String? filePath,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'file_access',
      if (filePath != null) 'filePath': filePath,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка доступа к файлу в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    if (filePath != null) {
      return SecureStorageError.fileAccessFailed(
        operation: operation,
        path: filePath,
        details: error.toString(),
        message: 'Ошибка доступа к файлу при операции "$operation"',
        data: logData,
      );
    }

    return SecureStorageError.operationFailed(
      operation: operation,
      details: error.toString(),
      message: 'Ошибка файловой операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки валидации
  static SecureStorageError handleValidationError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'validation',
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка валидации в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    return SecureStorageError.validationFailed(
      operation: operation,
      details: error.toString(),
      message: 'Ошибка валидации при операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки сериализации
  static SecureStorageError handleSerializationError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      'errorType': 'serialization',
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка сериализации в операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    return SecureStorageError.serializationFailed(
      operation: operation,
      details: error.toString(),
      message: 'Ошибка сериализации при операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает общие ошибки операций
  static SecureStorageError handleOperationError({
    required String operation,
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': operation,
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка операции "$operation"${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    // Если ошибка уже является SecureStorageError, возвращаем как есть
    if (error is SecureStorageError) {
      return error;
    }

    // Анализируем тип ошибки и преобразуем в соответствующий SecureStorageError
    if (error is StateError) {
      return SecureStorageError.operationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Ошибка состояния при выполнении операции "$operation"',
        data: logData,
      );
    }

    if (error is ArgumentError) {
      return SecureStorageError.validationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Неверные аргументы для операции "$operation"',
        data: logData,
      );
    }

    if (error is FormatException) {
      return SecureStorageError.serializationFailed(
        operation: operation,
        details: error.toString(),
        message: 'Ошибка формата данных в операции "$operation"',
        data: logData,
      );
    }

    // Для всех остальных ошибок
    return SecureStorageError.operationFailed(
      operation: operation,
      details: error.toString(),
      message: 'Неизвестная ошибка при выполнении операции "$operation"',
      data: logData,
    );
  }

  /// Обрабатывает ошибки инициализации
  static SecureStorageError handleInitializationError({
    required dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> logData = {
      'operation': 'initialization',
      'errorType': 'initialization',
      if (context != null) 'context': context,
      ...?additionalData,
    };

    logError(
      'Ошибка инициализации защищенного хранилища${context != null ? " в контексте $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      tag: _tag,
      data: logData,
    );

    if (error is SecureStorageError) {
      return error;
    }

    return SecureStorageError.initializationFailed(
      details: error.toString(),
      message: 'Ошибка инициализации защищенного хранилища',
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
        'Начало выполнения операции "$operation"${context != null ? " в контексте $context" : ""}',
        tag: _tag,
        data: {
          'operation': operation,
          if (context != null) 'context': context,
          ...?additionalData,
        },
      );

      final result = await function();

      logDebug(
        'Операция "$operation" выполнена успешно',
        tag: _tag,
        data: {
          'operation': operation,
          'success': true,
          if (context != null) 'context': context,
        },
      );

      return result;
    } catch (error, stackTrace) {
      final secureStorageError = handleOperationError(
        operation: operation,
        error: error,
        context: context,
        additionalData: additionalData,
        stackTrace: stackTrace,
      );

      if (fallbackValue != null) {
        logWarning(
          'Использование fallback значения для операции "$operation"',
          tag: _tag,
          data: {
            'operation': operation,
            'fallbackValue': fallbackValue.toString(),
          },
        );
        return fallbackValue;
      }

      throw secureStorageError;
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
        'Начало выполнения синхронной операции "$operation"${context != null ? " в контексте $context" : ""}',
        tag: _tag,
        data: {
          'operation': operation,
          if (context != null) 'context': context,
          ...?additionalData,
        },
      );

      final result = function();

      logDebug(
        'Синхронная операция "$operation" выполнена успешно',
        tag: _tag,
        data: {
          'operation': operation,
          'success': true,
          if (context != null) 'context': context,
        },
      );

      return result;
    } catch (error, stackTrace) {
      final secureStorageError = handleOperationError(
        operation: operation,
        error: error,
        context: context,
        additionalData: additionalData,
        stackTrace: stackTrace,
      );

      if (fallbackValue != null) {
        logWarning(
          'Использование fallback значения для синхронной операции "$operation"',
          tag: _tag,
          data: {
            'operation': operation,
            'fallbackValue': fallbackValue.toString(),
          },
        );
        return fallbackValue;
      }

      throw secureStorageError;
    }
  }

  /// Получает понятное пользователю сообщение об ошибке
  static String getUserFriendlyMessage(dynamic error) {
    if (error is SecureStorageError) {
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
      tag: _tag,
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
      tag: _tag,
      data: {
        'operation': operation,
        'phase': 'start',
        if (context != null) 'context': context,
        ...?additionalData,
      },
    );
  }

  /// Логирует окончание выполнения операции
  static void logOperationEnd({
    required String operation,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    logDebug(
      'Окончание операции "$operation"${context != null ? " в контексте $context" : ""}',
      tag: _tag,
      data: {
        'operation': operation,
        'phase': 'end',
        if (context != null) 'context': context,
        ...?additionalData,
      },
    );
  }

  /// Анализирует ошибку и определяет, требует ли она особого внимания
  static SecurityAnalysis analyzeError(SecureStorageError error) {
    return SecurityAnalysis(
      error: error,
      requiresImmediateAttention: error.requiresImmediateAttention,
      isSecurityRelated: error.isSecurityRelated,
      severity: error.severity,
      securityType: error.securityType,
      recommendedActions: _getRecommendedActions(error),
      shouldNotifyUser: _shouldNotifyUser(error),
    );
  }

  /// Получает рекомендуемые действия для исправления ошибки
  static List<String> _getRecommendedActions(SecureStorageError error) {
    return error.when(
      encryptionFailed: (operation, details, code, message, data) => [
        'Проверьте целостность ключей шифрования',
        'Попробуйте перезапустить приложение',
        'Обратитесь в службу поддержки, если проблема повторяется',
      ],
      decryptionFailed: (operation, details, code, message, data) => [
        'Проверьте правильность пароля',
        'Убедитесь, что файлы не были повреждены',
        'Восстановите данные из резервной копии, если проблема повторяется',
      ],
      keyGenerationFailed: (details, code, message, data) => [
        'Проверьте доступное место на диске',
        'Убедитесь, что приложение имеет необходимые разрешения',
        'Перезапустите приложение',
      ],
      keyNotFound: (storageKey, code, message, data) => [
        'Убедитесь, что хранилище было правильно инициализировано',
        'Проверьте, не были ли удалены ключи безопасности',
        'Возможно потребуется повторная настройка безопасности',
      ],
      keyValidationFailed: (storageKey, details, code, message, data) => [
        'Проверьте целостность системы безопасности',
        'Убедитесь, что файлы не были изменены извне',
        'Обратитесь в службу поддержки - возможно нарушение безопасности',
      ],
      fileAccessFailed: (operation, path, details, code, message, data) => [
        'Проверьте права доступа к файлам',
        'Убедитесь, что диск не заполнен',
        'Проверьте, не заблокированы ли файлы другими процессами',
      ],
      fileNotFound: (path, code, message, data) => [
        'Убедитесь, что файл не был удален',
        'Проверьте правильность пути к файлу',
        'Восстановите файл из резервной копии',
      ],
      fileCorrupted: (path, details, code, message, data) => [
        'Восстановите файл из резервной копии',
        'Проверьте диск на наличие ошибок',
        'Обратитесь в службу поддержки для восстановления данных',
      ],
      initializationFailed: (details, code, message, data) => [
        'Перезапустите приложение',
        'Проверьте доступное место на диске',
        'Убедитесь, что приложение имеет необходимые разрешения',
      ],
      operationFailed: (operation, details, code, message, data) => [
        'Попробуйте повторить операцию',
        'Проверьте подключение к сети (если требуется)',
        'Перезапустите приложение, если проблема повторяется',
      ],
      serializationFailed: (operation, details, code, message, data) => [
        'Проверьте корректность данных',
        'Убедитесь, что формат данных не изменился',
        'Обновите приложение до последней версии',
      ],
      validationFailed: (operation, details, code, message, data) => [
        'Проверьте корректность введенных данных',
        'Убедитесь, что все обязательные поля заполнены',
        'Проверьте формат введенной информации',
      ],
      cacheError: (operation, details, code, message, data) => [
        'Очистите кэш приложения',
        'Перезапустите приложение',
        'Проверьте доступное место на диске',
      ],
      securityBreach: (details, code, message, data) => [
        'НЕМЕДЛЕННО смените все пароли',
        'Проверьте устройство на наличие вредоносного ПО',
        'Обратитесь в службу безопасности',
        'Восстановите данные из проверенной резервной копии',
      ],
      unknown: (details, code, message, data) => [
        'Попробуйте повторить операцию',
        'Перезапустите приложение',
        'Обратитесь в службу поддержки с деталями ошибки',
      ],
    );
  }

  /// Определяет, нужно ли уведомлять пользователя об ошибке
  static bool _shouldNotifyUser(SecureStorageError error) {
    return error.severity == SecuritySeverity.high ||
        error.severity == SecuritySeverity.critical ||
        error.isSecurityRelated;
  }
}

/// Результат анализа ошибки безопасности
class SecurityAnalysis {
  final SecureStorageError error;
  final bool requiresImmediateAttention;
  final bool isSecurityRelated;
  final SecuritySeverity severity;
  final SecurityErrorType securityType;
  final List<String> recommendedActions;
  final bool shouldNotifyUser;

  const SecurityAnalysis({
    required this.error,
    required this.requiresImmediateAttention,
    required this.isSecurityRelated,
    required this.severity,
    required this.securityType,
    required this.recommendedActions,
    required this.shouldNotifyUser,
  });

  @override
  String toString() {
    return 'SecurityAnalysis('
        'error: ${error.code}, '
        'severity: $severity, '
        'securityType: $securityType, '
        'requiresAttention: $requiresImmediateAttention, '
        'isSecurityRelated: $isSecurityRelated, '
        'shouldNotifyUser: $shouldNotifyUser'
        ')';
  }
}
