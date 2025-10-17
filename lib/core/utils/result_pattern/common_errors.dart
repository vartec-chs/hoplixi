import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_errors.freezed.dart';

/// Базовые типы ошибок для использования в Hoplixi.
/// Эти типы покрывают наиболее распространённые сценарии ошибок.

/// Ошибки приложения общего назначения
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network(String message, {String? details}) =
      NetworkError;
  const factory AppError.notFound(String resource) = NotFoundError;
  const factory AppError.validation(String field, String message) =
      ValidationError;
  const factory AppError.permission(String action) = PermissionError;
  const factory AppError.unknown(String message, {Object? cause}) =
      UnknownError;
  const factory AppError.timeout(String operation) = TimeoutError;
  const factory AppError.cancelled(String operation) = CancelledError;

  const AppError._();

  /// Преобразование в понятное пользователю сообщение
  String toUserMessage() => when(
    network: (msg, details) => 'Ошибка сети: $msg',
    notFound: (res) => '$res не найден',
    validation: (field, msg) => 'Ошибка в поле $field: $msg',
    permission: (action) => 'Нет прав для: $action',
    unknown: (msg, cause) => 'Неизвестная ошибка: $msg',
    timeout: (op) => 'Превышено время ожидания: $op',
    cancelled: (op) => 'Операция отменена: $op',
  );

  /// Техническое сообщение для логирования
  String toLogMessage() => when(
    network: (msg, details) =>
        'Network error: $msg${details != null ? " ($details)" : ""}',
    notFound: (res) => 'Resource not found: $res',
    validation: (field, msg) => 'Validation error in $field: $msg',
    permission: (action) => 'Permission denied for: $action',
    unknown: (msg, cause) =>
        'Unknown error: $msg${cause != null ? " (cause: $cause)" : ""}',
    timeout: (op) => 'Timeout: $op',
    cancelled: (op) => 'Cancelled: $op',
  );
}

/// Ошибки базы данных
@freezed
sealed class DbError with _$DbError {
  const factory DbError.notFound(String message) = DbNotFoundError;
  const factory DbError.query(String message, {String? sql}) = DbQueryError;
  const factory DbError.insert(String message, {String? details}) =
      DbInsertError;
  const factory DbError.update(String message, {String? details}) =
      DbUpdateError;
  const factory DbError.delete(String message, {String? details}) =
      DbDeleteError;
  const factory DbError.constraint(String constraint, String message) =
      DbConstraintError;
  const factory DbError.connection(String message) = DbConnectionError;
  const factory DbError.transaction(String message) = DbTransactionError;
  const factory DbError.unknown(String message, {Object? cause}) =
      DbUnknownError;

  const DbError._();

  /// Преобразование в понятное пользователю сообщение
  String toUserMessage() => when(
    notFound: (_) => 'Запись не найдена',
    query: (msg, sql) => 'Ошибка при получении данных',
    insert: (msg, details) => 'Не удалось сохранить данные',
    update: (msg, details) => 'Не удалось обновить данные',
    delete: (msg, details) => 'Не удалось удалить данные',
    constraint: (constraint, msg) => 'Нарушение ограничений данных',
    connection: (msg) => 'Ошибка подключения к базе данных',
    transaction: (msg) => 'Ошибка транзакции',
    unknown: (msg, cause) => 'Ошибка базы данных',
  );

  /// Техническое сообщение для логирования (БЕЗ СЕКРЕТОВ!)
  String toLogMessage() => when(
    notFound: (msg) => 'DB not found: $msg',
    query: (msg, sql) =>
        'DB query error: $msg${sql != null ? " (SQL redacted)" : ""}',
    insert: (msg, details) =>
        'DB insert error: $msg${details != null ? " ($details)" : ""}',
    update: (msg, details) =>
        'DB update error: $msg${details != null ? " ($details)" : ""}',
    delete: (msg, details) =>
        'DB delete error: $msg${details != null ? " ($details)" : ""}',
    constraint: (constraint, msg) => 'DB constraint error: $constraint - $msg',
    connection: (msg) => 'DB connection error: $msg',
    transaction: (msg) => 'DB transaction error: $msg',
    unknown: (msg, cause) =>
        'DB unknown error: $msg${cause != null ? " (cause: $cause)" : ""}',
  );
}

/// Ошибки криптографии и шифрования
@freezed
sealed class CryptoError with _$CryptoError {
  const factory CryptoError.invalidKey(String message) = InvalidKeyError;
  const factory CryptoError.encryption(String message) = EncryptionError;
  const factory CryptoError.decryption(String message) = DecryptionError;
  const factory CryptoError.invalidFormat(String message) = InvalidFormatError;
  const factory CryptoError.keyDerivation(String message) = KeyDerivationError;
  const factory CryptoError.unknown(String message, {Object? cause}) =
      CryptoUnknownError;

  const CryptoError._();

  /// Преобразование в понятное пользователю сообщение
  String toUserMessage() => when(
    invalidKey: (_) => 'Неверный ключ шифрования',
    encryption: (_) => 'Ошибка при шифровании данных',
    decryption: (_) => 'Ошибка при расшифровке данных',
    invalidFormat: (_) => 'Неверный формат зашифрованных данных',
    keyDerivation: (_) => 'Ошибка при создании ключа',
    unknown: (msg, _) => 'Ошибка криптографии',
  );

  /// Техническое сообщение для логирования (БЕЗ КЛЮЧЕЙ И СЕКРЕТОВ!)
  String toLogMessage() => when(
    invalidKey: (msg) => 'Invalid key (details redacted)',
    encryption: (msg) => 'Encryption error: $msg',
    decryption: (msg) => 'Decryption error: $msg',
    invalidFormat: (msg) => 'Invalid format: $msg',
    keyDerivation: (msg) => 'Key derivation error: $msg',
    unknown: (msg, cause) =>
        'Crypto unknown error: $msg${cause != null ? " (cause redacted)" : ""}',
  );
}

/// Ошибки импорта/экспорта
@freezed
sealed class ImportExportError with _$ImportExportError {
  const factory ImportExportError.invalidFormat(String message) =
      ImportInvalidFormatError;
  const factory ImportExportError.parsing(String message) = ParsingError;
  const factory ImportExportError.validation(String message) =
      ImportValidationError;
  const factory ImportExportError.fileAccess(String message) = FileAccessError;
  const factory ImportExportError.unknown(String message, {Object? cause}) =
      ImportExportUnknownError;

  const ImportExportError._();

  /// Преобразование в понятное пользователю сообщение
  String toUserMessage() => when(
    invalidFormat: (msg) => 'Неверный формат файла: $msg',
    parsing: (msg) => 'Ошибка при чтении файла: $msg',
    validation: (msg) => 'Данные не прошли проверку: $msg',
    fileAccess: (msg) => 'Не удалось получить доступ к файлу: $msg',
    unknown: (msg, _) => 'Ошибка импорта/экспорта: $msg',
  );

  /// Техническое сообщение для логирования
  String toLogMessage() => when(
    invalidFormat: (msg) => 'Invalid format: $msg',
    parsing: (msg) => 'Parsing error: $msg',
    validation: (msg) => 'Validation error: $msg',
    fileAccess: (msg) => 'File access error: $msg',
    unknown: (msg, cause) =>
        'Import/Export unknown error: $msg${cause != null ? " (cause: $cause)" : ""}',
  );
}

/// Ошибки синхронизации
@freezed
sealed class SyncError with _$SyncError {
  const factory SyncError.network(String message) = SyncNetworkError;
  const factory SyncError.authentication(String message) = AuthenticationError;
  const factory SyncError.conflict(String message) = ConflictError;
  const factory SyncError.serverError(String message, {int? statusCode}) =
      ServerError;
  const factory SyncError.unknown(String message, {Object? cause}) =
      SyncUnknownError;

  const SyncError._();

  /// Преобразование в понятное пользователю сообщение
  String toUserMessage() => when(
    network: (msg) => 'Ошибка сети при синхронизации: $msg',
    authentication: (_) => 'Ошибка аутентификации',
    conflict: (msg) => 'Конфликт данных при синхронизации: $msg',
    serverError: (msg, code) =>
        'Ошибка сервера${code != null ? " ($code)" : ""}: $msg',
    unknown: (msg, _) => 'Ошибка синхронизации: $msg',
  );

  /// Техническое сообщение для логирования
  String toLogMessage() => when(
    network: (msg) => 'Sync network error: $msg',
    authentication: (msg) => 'Sync authentication error (details redacted)',
    conflict: (msg) => 'Sync conflict: $msg',
    serverError: (msg, code) =>
        'Sync server error${code != null ? " (HTTP $code)" : ""}: $msg',
    unknown: (msg, cause) =>
        'Sync unknown error: $msg${cause != null ? " (cause: $cause)" : ""}',
  );
}

/// Extension для преобразования общих исключений в типизированные ошибки
extension ErrorConversionExtension on Object {
  /// Преобразовать исключение в AppError
  AppError toAppError([String? context]) {
    if (this is AppError) return this as AppError;
    if (this is DbError) {
      return AppError.unknown(context ?? 'Database error', cause: this);
    }
    return AppError.unknown(context ?? toString(), cause: this);
  }

  /// Преобразовать исключение в DbError
  DbError toDbError([String? context]) {
    if (this is DbError) return this as DbError;
    return DbError.unknown(context ?? toString(), cause: this);
  }

  /// Преобразовать исключение в CryptoError
  CryptoError toCryptoError([String? context]) {
    if (this is CryptoError) return this as CryptoError;
    return CryptoError.unknown(context ?? toString(), cause: this);
  }
}
