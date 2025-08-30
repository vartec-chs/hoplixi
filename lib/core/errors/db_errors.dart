import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_errors.freezed.dart';

@freezed
abstract class DatabaseError with _$DatabaseError implements Exception {
  const DatabaseError._();

  const factory DatabaseError.invalidPassword({
    @Default('DB_INVALID_PASSWORD') String code,
    @Default('Неверный пароль для базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = InvalidPasswordError;

  const factory DatabaseError.databaseNotFound({
    required String path,
    @Default('DB_NOT_FOUND') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = DatabaseNotFoundError;

  const factory DatabaseError.databaseAlreadyExists({
    required String path,
    @Default('DB_ALREADY_EXISTS') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = DatabaseAlreadyExistsError;

  const factory DatabaseError.connectionFailed({
    required String details,
    @Default('DB_CONNECTION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = ConnectionFailedError;

  const factory DatabaseError.operationFailed({
    required String operation,
    required String details,
    @Default('DB_OPERATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = OperationFailedError;

  const factory DatabaseError.pathNotAccessible({
    required String path,
    @Default('DB_PATH_NOT_ACCESSIBLE') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = PathNotAccessibleError;

  const factory DatabaseError.unknown({
    required String details,
    @Default('DB_UNKNOWN_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = UnknownDatabaseError;

  const factory DatabaseError.keyError({
    required String details,
    @Default('DB_KEY_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = KeyError;

  const factory DatabaseError.secureStorageError({
    required String details,
    @Default('DB_SECURE_STORAGE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = SecureStorageError;

  const factory DatabaseError.closeError({
    required String details,
    @Default('DB_CLOSE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
  }) = CloseError;

  // Helper methods
  String get displayMessage {
    return when(
      invalidPassword: (code, message, data, _) => message,
      databaseNotFound: (path, code, message, data, _) =>
          message ?? 'База данных не найдена: $path',
      databaseAlreadyExists: (path, code, message, data, _) =>
          message ?? 'База данных уже существует: $path',
      connectionFailed: (details, code, message, data, _) =>
          message ?? 'Ошибка подключения к базе данных: $details',
      operationFailed: (operation, details, code, message, data, _) =>
          message ?? 'Ошибка операции "$operation": $details',
      pathNotAccessible: (path, code, message, data, _) =>
          message ?? 'Путь недоступен: $path',
      unknown: (details, code, message, data, _) =>
          message ?? 'Неизвестная ошибка: $details',
      keyError: (details, code, message, data, _) =>
          message ?? 'Ошибка работы с ключами: $details',
      secureStorageError: (details, code, message, data, _) =>
          message ?? 'Ошибка защищенного хранилища: $details',
      closeError: (details, code, message, data, _) =>
          message ?? 'Ошибка закрытия базы данных: $details',
    );
  }

  @override
  String get code => when(
    invalidPassword: (code, message, data, _) => code,
    databaseNotFound: (path, code, message, data, _) => code,
    databaseAlreadyExists: (path, code, message, data, _) => code,
    connectionFailed: (details, code, message, data, _) => code,
    operationFailed: (operation, details, code, message, data, _) => code,
    pathNotAccessible: (path, code, message, data, _) => code,
    unknown: (details, code, message, data, _) => code,
    keyError: (details, code, message, data, _) => code,
    secureStorageError: (details, code, message, data, _) => code,
    closeError: (details, code, message, data, _) => code,
  );

  @override
  Map<String, dynamic>? get data => when(
    invalidPassword: (code, message, data, _) => data,
    databaseNotFound: (path, code, message, data, _) => data,
    databaseAlreadyExists: (path, code, message, data, _) => data,
    connectionFailed: (details, code, message, data, _) => data,
    operationFailed: (operation, details, code, message, data, _) => data,
    pathNotAccessible: (path, code, message, data, _) => data,
    unknown: (details, code, message, data, _) => data,
    keyError: (details, code, message, data, _) => data,
    secureStorageError: (details, code, message, data, _) => data,
    closeError: (details, code, message, data, _) => data,
  );

  @override
  String? get message => when(
    invalidPassword: (code, message, data, _) => message,
    databaseNotFound: (path, code, message, data, _) => message,
    databaseAlreadyExists: (path, code, message, data, _) => message,
    connectionFailed: (details, code, message, data, _) => message,
    operationFailed: (operation, details, code, message, data, _) => message,
    pathNotAccessible: (path, code, message, data, _) => message,
    unknown: (details, code, message, data, _) => message,
    keyError: (details, code, message, data, _) => message,
    secureStorageError: (details, code, message, data, _) => message,
    closeError: (details, code, message, data, _) => message,
  );
}
