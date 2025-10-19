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
