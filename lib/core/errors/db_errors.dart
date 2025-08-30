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
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InvalidPasswordError;

  const factory DatabaseError.databaseNotFound({
    required String path,
    @Default('DB_NOT_FOUND') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = DatabaseNotFoundError;

  const factory DatabaseError.databaseAlreadyExists({
    required String path,
    @Default('DB_ALREADY_EXISTS') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = DatabaseAlreadyExistsError;

  const factory DatabaseError.connectionFailed({
    required String details,
    @Default('DB_CONNECTION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = ConnectionFailedError;

  const factory DatabaseError.operationFailed({
    required String operation,
    required String details,
    @Default('DB_OPERATION_FAILED') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = OperationFailedError;

  const factory DatabaseError.pathNotAccessible({
    required String path,
    @Default('DB_PATH_NOT_ACCESSIBLE') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = PathNotAccessibleError;

  const factory DatabaseError.unknown({
    required String details,
    @Default('DB_UNKNOWN_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = UnknownDatabaseError;

  const factory DatabaseError.keyError({
    required String details,
    @Default('DB_KEY_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = KeyError;

  const factory DatabaseError.secureStorageError({
    required String details,
    @Default('DB_SECURE_STORAGE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = SecureStorageError;

  const factory DatabaseError.closeError({
    required String details,
    @Default('DB_CLOSE_ERROR') String code,
    String? message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = CloseError;

  // Helper methods
  String get displayMessage {
    return when(
      invalidPassword: (code, message, data, _, _) => message,
      databaseNotFound: (path, code, message, data, _, _) =>
          message ?? 'База данных не найдена: $path',
      databaseAlreadyExists: (path, code, message, data, _, _) =>
          message ?? 'База данных уже существует: $path',
      connectionFailed: (details, code, message, data, _, _) =>
          message ?? 'Ошибка подключения к базе данных: $details',
      operationFailed: (operation, details, code, message, data, _, _) =>
          message ?? 'Ошибка операции "$operation": $details',
      pathNotAccessible: (path, code, message, data, _, _) =>
          message ?? 'Путь недоступен: $path',
      unknown: (details, code, message, data, _, _) =>
          message ?? 'Неизвестная ошибка: $details',
      keyError: (details, code, message, data, _, _) =>
          message ?? 'Ошибка работы с ключами: $details',
      secureStorageError: (details, code, message, data, _, _) =>
          message ?? 'Ошибка защищенного хранилища: $details',
      closeError: (details, code, message, data, _, _) =>
          message ?? 'Ошибка закрытия базы данных: $details',
    );
  }

  @override
  String get code => when(
    invalidPassword: (code, message, data, _, _) => code,
    databaseNotFound: (path, code, message, data, _, _) => code,
    databaseAlreadyExists: (path, code, message, data, _, _) => code,
    connectionFailed: (details, code, message, data, _, _) => code,
    operationFailed: (operation, details, code, message, data, _, _) => code,
    pathNotAccessible: (path, code, message, data, _, _) => code,
    unknown: (details, code, message, data, _, _) => code,
    keyError: (details, code, message, data, _, _) => code,
    secureStorageError: (details, code, message, data, _, _) => code,
    closeError: (details, code, message, data, _, _) => code,
  );

  @override
  Map<String, dynamic>? get data => when(
    invalidPassword: (code, message, data, _, _) => data,
    databaseNotFound: (path, code, message, data, _, _) => data,
    databaseAlreadyExists: (path, code, message, data, _, _) => data,
    connectionFailed: (details, code, message, data, _, _) => data,
    operationFailed: (operation, details, code, message, data, _, _) => data,
    pathNotAccessible: (path, code, message, data, _, _) => data,
    unknown: (details, code, message, data, _, _) => data,
    keyError: (details, code, message, data, _, _) => data,
    secureStorageError: (details, code, message, data, _, _) => data,
    closeError: (details, code, message, data, _, _) => data,
  );

  @override
  String? get message => when(
    invalidPassword: (code, message, data, _, _) => message,
    databaseNotFound: (path, code, message, data, _, _) => message,
    databaseAlreadyExists: (path, code, message, data, _, _) => message,
    connectionFailed: (details, code, message, data, _, _) => message,
    operationFailed: (operation, details, code, message, data, _, _) => message,
    pathNotAccessible: (path, code, message, data, _, _) => message,
    unknown: (details, code, message, data, _, _) => message,
    keyError: (details, code, message, data, _, _) => message,
    secureStorageError: (details, code, message, data, _, _) => message,
    closeError: (details, code, message, data, _, _) => message,
  );
}
