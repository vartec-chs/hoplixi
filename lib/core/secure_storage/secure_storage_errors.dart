import 'package:freezed_annotation/freezed_annotation.dart';

part 'secure_storage_errors.freezed.dart';

@freezed
class SecureStorageError with _$SecureStorageError implements Exception {
  const SecureStorageError._();

  const factory SecureStorageError.encryptionFailed({
    required String operation,
    required String details,
    @Default('SS_ENCRYPTION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = EncryptionFailedError;

  const factory SecureStorageError.decryptionFailed({
    required String operation,
    required String details,
    @Default('SS_DECRYPTION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = DecryptionFailedError;

  const factory SecureStorageError.keyGenerationFailed({
    required String details,
    @Default('SS_KEY_GENERATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = KeyGenerationFailedError;

  const factory SecureStorageError.keyNotFound({
    required String storageKey,
    @Default('SS_KEY_NOT_FOUND') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = KeyNotFoundError;

  const factory SecureStorageError.keyValidationFailed({
    required String storageKey,
    required String details,
    @Default('SS_KEY_VALIDATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = KeyValidationFailedError;

  const factory SecureStorageError.fileAccessFailed({
    required String operation,
    required String path,
    required String details,
    @Default('SS_FILE_ACCESS_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = FileAccessFailedError;

  const factory SecureStorageError.fileNotFound({
    required String path,
    @Default('SS_FILE_NOT_FOUND') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = FileNotFoundError;

  const factory SecureStorageError.fileCorrupted({
    required String path,
    required String details,
    @Default('SS_FILE_CORRUPTED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = FileCorruptedError;

  const factory SecureStorageError.initializationFailed({
    required String details,
    @Default('SS_INITIALIZATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = InitializationFailedError;

  const factory SecureStorageError.operationFailed({
    required String operation,
    required String details,
    @Default('SS_OPERATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = OperationFailedError;

  const factory SecureStorageError.serializationFailed({
    required String operation,
    required String details,
    @Default('SS_SERIALIZATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = SerializationFailedError;

  const factory SecureStorageError.validationFailed({
    required String operation,
    required String details,
    @Default('SS_VALIDATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = ValidationFailedError;

  const factory SecureStorageError.cacheError({
    required String operation,
    required String details,
    @Default('SS_CACHE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = CacheError;

  const factory SecureStorageError.securityBreach({
    required String details,
    @Default('SS_SECURITY_BREACH') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = SecurityBreachError;

  const factory SecureStorageError.unknown({
    required String details,
    @Default('SS_UNKNOWN_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = UnknownSecureStorageError;

  // Helper methods
  String get displayMessage {
    return when(
      encryptionFailed: (operation, details, code, message, data) =>
          message ??
          'Ошибка шифрования при выполнении операции "$operation": $details',
      decryptionFailed: (operation, details, code, message, data) =>
          message ??
          'Ошибка расшифрования при выполнении операции "$operation": $details',
      keyGenerationFailed: (details, code, message, data) =>
          message ?? 'Ошибка генерации ключа: $details',
      keyNotFound: (storageKey, code, message, data) =>
          message ?? 'Ключ шифрования не найден для хранилища: $storageKey',
      keyValidationFailed: (storageKey, details, code, message, data) =>
          message ??
          'Ошибка валидации ключа для хранилища "$storageKey": $details',
      fileAccessFailed: (operation, path, details, code, message, data) =>
          message ??
          'Ошибка доступа к файлу при операции "$operation" ($path): $details',
      fileNotFound: (path, code, message, data) =>
          message ?? 'Файл не найден: $path',
      fileCorrupted: (path, details, code, message, data) =>
          message ?? 'Файл поврежден ($path): $details',
      initializationFailed: (details, code, message, data) =>
          message ?? 'Ошибка инициализации защищенного хранилища: $details',
      operationFailed: (operation, details, code, message, data) =>
          message ?? 'Ошибка выполнения операции "$operation": $details',
      serializationFailed: (operation, details, code, message, data) =>
          message ?? 'Ошибка сериализации при операции "$operation": $details',
      validationFailed: (operation, details, code, message, data) =>
          message ?? 'Ошибка валидации при операции "$operation": $details',
      cacheError: (operation, details, code, message, data) =>
          message ?? 'Ошибка кэша при операции "$operation": $details',
      securityBreach: (details, code, message, data) =>
          message ?? 'Нарушение безопасности: $details',
      unknown: (details, code, message, data) =>
          message ?? 'Неизвестная ошибка: $details',
    );
  }

  String get code => when(
    encryptionFailed: (operation, details, code, message, data) => code,
    decryptionFailed: (operation, details, code, message, data) => code,
    keyGenerationFailed: (details, code, message, data) => code,
    keyNotFound: (storageKey, code, message, data) => code,
    keyValidationFailed: (storageKey, details, code, message, data) => code,
    fileAccessFailed: (operation, path, details, code, message, data) => code,
    fileNotFound: (path, code, message, data) => code,
    fileCorrupted: (path, details, code, message, data) => code,
    initializationFailed: (details, code, message, data) => code,
    operationFailed: (operation, details, code, message, data) => code,
    serializationFailed: (operation, details, code, message, data) => code,
    validationFailed: (operation, details, code, message, data) => code,
    cacheError: (operation, details, code, message, data) => code,
    securityBreach: (details, code, message, data) => code,
    unknown: (details, code, message, data) => code,
  );

  Map<String, dynamic>? get data => when(
    encryptionFailed: (operation, details, code, message, data) => data,
    decryptionFailed: (operation, details, code, message, data) => data,
    keyGenerationFailed: (details, code, message, data) => data,
    keyNotFound: (storageKey, code, message, data) => data,
    keyValidationFailed: (storageKey, details, code, message, data) => data,
    fileAccessFailed: (operation, path, details, code, message, data) => data,
    fileNotFound: (path, code, message, data) => data,
    fileCorrupted: (path, details, code, message, data) => data,
    initializationFailed: (details, code, message, data) => data,
    operationFailed: (operation, details, code, message, data) => data,
    serializationFailed: (operation, details, code, message, data) => data,
    validationFailed: (operation, details, code, message, data) => data,
    cacheError: (operation, details, code, message, data) => data,
    securityBreach: (details, code, message, data) => data,
    unknown: (details, code, message, data) => data,
  );

  String? get message => when(
    encryptionFailed: (operation, details, code, message, data) => message,
    decryptionFailed: (operation, details, code, message, data) => message,
    keyGenerationFailed: (details, code, message, data) => message,
    keyNotFound: (storageKey, code, message, data) => message,
    keyValidationFailed: (storageKey, details, code, message, data) => message,
    fileAccessFailed: (operation, path, details, code, message, data) =>
        message,
    fileNotFound: (path, code, message, data) => message,
    fileCorrupted: (path, details, code, message, data) => message,
    initializationFailed: (details, code, message, data) => message,
    operationFailed: (operation, details, code, message, data) => message,
    serializationFailed: (operation, details, code, message, data) => message,
    validationFailed: (operation, details, code, message, data) => message,
    cacheError: (operation, details, code, message, data) => message,
    securityBreach: (details, code, message, data) => message,
    unknown: (details, code, message, data) => message,
  );

  /// Определяет тип безопасности ошибки
  SecurityErrorType get securityType => when(
    encryptionFailed: (operation, details, code, message, data) =>
        SecurityErrorType.cryptographic,
    decryptionFailed: (operation, details, code, message, data) =>
        SecurityErrorType.cryptographic,
    keyGenerationFailed: (details, code, message, data) =>
        SecurityErrorType.cryptographic,
    keyNotFound: (storageKey, code, message, data) =>
        SecurityErrorType.keyManagement,
    keyValidationFailed: (storageKey, details, code, message, data) =>
        SecurityErrorType.keyManagement,
    fileAccessFailed: (operation, path, details, code, message, data) =>
        SecurityErrorType.fileSystem,
    fileNotFound: (path, code, message, data) => SecurityErrorType.fileSystem,
    fileCorrupted: (path, details, code, message, data) =>
        SecurityErrorType.integrity,
    initializationFailed: (details, code, message, data) =>
        SecurityErrorType.system,
    operationFailed: (operation, details, code, message, data) =>
        SecurityErrorType.operational,
    serializationFailed: (operation, details, code, message, data) =>
        SecurityErrorType.serialization,
    validationFailed: (operation, details, code, message, data) =>
        SecurityErrorType.validation,
    cacheError: (operation, details, code, message, data) =>
        SecurityErrorType.cache,
    securityBreach: (details, code, message, data) =>
        SecurityErrorType.security,
    unknown: (details, code, message, data) => SecurityErrorType.unknown,
  );

  /// Определяет критичность ошибки
  SecuritySeverity get severity => when(
    encryptionFailed: (operation, details, code, message, data) =>
        SecuritySeverity.high,
    decryptionFailed: (operation, details, code, message, data) =>
        SecuritySeverity.high,
    keyGenerationFailed: (details, code, message, data) =>
        SecuritySeverity.critical,
    keyNotFound: (storageKey, code, message, data) => SecuritySeverity.critical,
    keyValidationFailed: (storageKey, details, code, message, data) =>
        SecuritySeverity.critical,
    fileAccessFailed: (operation, path, details, code, message, data) =>
        SecuritySeverity.medium,
    fileNotFound: (path, code, message, data) => SecuritySeverity.medium,
    fileCorrupted: (path, details, code, message, data) =>
        SecuritySeverity.high,
    initializationFailed: (details, code, message, data) =>
        SecuritySeverity.critical,
    operationFailed: (operation, details, code, message, data) =>
        SecuritySeverity.medium,
    serializationFailed: (operation, details, code, message, data) =>
        SecuritySeverity.low,
    validationFailed: (operation, details, code, message, data) =>
        SecuritySeverity.medium,
    cacheError: (operation, details, code, message, data) =>
        SecuritySeverity.low,
    securityBreach: (details, code, message, data) => SecuritySeverity.critical,
    unknown: (details, code, message, data) => SecuritySeverity.medium,
  );

  /// Проверяет, требует ли ошибка немедленного внимания
  bool get requiresImmediateAttention => severity == SecuritySeverity.critical;

  /// Проверяет, является ли ошибка связанной с безопасностью
  bool get isSecurityRelated => [
    SecurityErrorType.cryptographic,
    SecurityErrorType.keyManagement,
    SecurityErrorType.integrity,
    SecurityErrorType.security,
  ].contains(securityType);
}

/// Типы ошибок безопасности
enum SecurityErrorType {
  cryptographic,
  keyManagement,
  fileSystem,
  integrity,
  system,
  operational,
  serialization,
  validation,
  cache,
  security,
  unknown,
}

/// Уровни критичности ошибок безопасности
enum SecuritySeverity { low, medium, high, critical }
