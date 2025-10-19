import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/services/dropbox/import_service.dart';

part 'cloud_sync_state.freezed.dart';

/// Состояние процесса экспорта
@freezed
class ExportState with _$ExportState {
  const factory ExportState.idle() = ExportStateIdle;
  const factory ExportState.inProgress({
    required double progress,
    required String message,
  }) = ExportStateInProgress;
  const factory ExportState.success({
    required String fileName,
    required int exportTime,
  }) = ExportStateSuccess;
  const factory ExportState.failure(String error) = ExportStateFailure;
}

/// Состояние процесса импорта
@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportStateIdle;
  const factory ImportState.checking() = ImportStateChecking;
  const factory ImportState.newVersionAvailable({
    required CloudVersionInfo versionInfo,
  }) = ImportStateNewVersionAvailable;
  const factory ImportState.noNewVersion() = ImportStateNoNewVersion;
  const factory ImportState.downloading({
    required double progress,
    required String message,
  }) = ImportStateDownloading;
  const factory ImportState.extracting({
    required double progress,
    required String message,
  }) = ImportStateExtracting;
  const factory ImportState.success({required String importedFolderPath}) =
      ImportStateSuccess;
  const factory ImportState.failure(String error) = ImportStateFailure;
}
