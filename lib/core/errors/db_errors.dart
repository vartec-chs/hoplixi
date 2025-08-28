import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_errors.freezed.dart';

@freezed
class DatabaseError with _$DatabaseError implements Exception {
  const DatabaseError._();

  const factory DatabaseError.invalidPassword({
    @Default('DB_INVALID_PASSWORD') String code,
    @Default('Неверный пароль для базы данных') String message,
    Map<String, dynamic>? data,
  }) = InvalidPasswordError;

  const factory DatabaseError.databaseNotFound({
    required String path,
    @Default('DB_NOT_FOUND') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = DatabaseNotFoundError;

  const factory DatabaseError.databaseAlreadyExists({
    required String path,
    @Default('DB_ALREADY_EXISTS') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = DatabaseAlreadyExistsError;

  const factory DatabaseError.connectionFailed({
    required String details,
    @Default('DB_CONNECTION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = ConnectionFailedError;

  const factory DatabaseError.operationFailed({
    required String operation,
    required String details,
    @Default('DB_OPERATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = OperationFailedError;

  const factory DatabaseError.pathNotAccessible({
    required String path,
    @Default('DB_PATH_NOT_ACCESSIBLE') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = PathNotAccessibleError;

  const factory DatabaseError.unknown({
    required String details,
    @Default('DB_UNKNOWN_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = UnknownDatabaseError;

  const factory DatabaseError.keyError({
    required String details,
    @Default('DB_KEY_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = KeyError;

  const factory DatabaseError.secureStorageError({
    required String details,
    @Default('DB_SECURE_STORAGE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
  }) = SecureStorageError;

  // Helper methods
  String get displayMessage {
    return when(
      invalidPassword: (code, message, data) => message,
      databaseNotFound: (path, code, message, data) =>
          message ?? 'База данных не найдена: $path',
      databaseAlreadyExists: (path, code, message, data) =>
          message ?? 'База данных уже существует: $path',
      connectionFailed: (details, code, message, data) =>
          message ?? 'Ошибка подключения к базе данных: $details',
      operationFailed: (operation, details, code, message, data) =>
          message ?? 'Ошибка операции "$operation": $details',
      pathNotAccessible: (path, code, message, data) =>
          message ?? 'Путь недоступен: $path',
      unknown: (details, code, message, data) =>
          message ?? 'Неизвестная ошибка: $details',
      keyError: (details, code, message, data) =>
          message ?? 'Ошибка работы с ключами: $details',
      secureStorageError: (details, code, message, data) =>
          message ?? 'Ошибка защищенного хранилища: $details',
    );
  }

  @override
  String get code => when(
    invalidPassword: (code, message, data) => code,
    databaseNotFound: (path, code, message, data) => code,
    databaseAlreadyExists: (path, code, message, data) => code,
    connectionFailed: (details, code, message, data) => code,
    operationFailed: (operation, details, code, message, data) => code,
    pathNotAccessible: (path, code, message, data) => code,
    unknown: (details, code, message, data) => code,
    keyError: (details, code, message, data) => code,
    secureStorageError: (details, code, message, data) => code,
  );

  @override
  Map<String, dynamic>? get data => when(
    invalidPassword: (code, message, data) => data,
    databaseNotFound: (path, code, message, data) => data,
    databaseAlreadyExists: (path, code, message, data) => data,
    connectionFailed: (details, code, message, data) => data,
    operationFailed: (operation, details, code, message, data) => data,
    pathNotAccessible: (path, code, message, data) => data,
    unknown: (details, code, message, data) => data,
    keyError: (details, code, message, data) => data,
    secureStorageError: (details, code, message, data) => data,
  );

  @override
  String? get message => when(
    invalidPassword: (code, message, data) => message,
    databaseNotFound: (path, code, message, data) => message,
    databaseAlreadyExists: (path, code, message, data) => message,
    connectionFailed: (details, code, message, data) => message,
    operationFailed: (operation, details, code, message, data) => message,
    pathNotAccessible: (path, code, message, data) => message,
    unknown: (details, code, message, data) => message,
    keyError: (details, code, message, data) => message,
    secureStorageError: (details, code, message, data) => message,
  );
}
