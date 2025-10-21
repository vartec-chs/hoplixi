import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_sync_exceptions.freezed.dart';

@freezed
class ExportException with _$ExportException {
  const factory ExportException.network(String message, {String? details}) =
      ExportNetworkException;
  const factory ExportException.auth(String message) = ExportAuthException;
  const factory ExportException.storage(String message) =
      ExportStorageException;
  const factory ExportException.validation(String field, String message) =
      ExportValidationException;

  const factory ExportException.warning(String message) =
      ExportWarningException;
  const factory ExportException.permission(String action) =
      ExportPermissionException;
  const factory ExportException.unknown(String message, {Object? cause}) =
      ExportUnknownException;
}

@freezed
class ImportException with _$ImportException {
  const factory ImportException.network(String message, {String? details}) =
      ImportNetworkException;
  const factory ImportException.auth(String message) = ImportAuthException;
  const factory ImportException.locking(String message) =
      ImportLockingException;
  const factory ImportException.storage(String message) =
      ImportStorageException;
  const factory ImportException.validation(String field, String message) =
      ImportValidationException;

  const factory ImportException.warning(String message) =
      ImportWarningException;
  const factory ImportException.permission(String action) =
      ImportPermissionException;
  const factory ImportException.unknown(String message, {Object? cause}) =
      ImportUnknownException;
}
