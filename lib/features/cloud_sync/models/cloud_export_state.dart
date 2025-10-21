import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_exceptions.dart';

part 'cloud_export_state.freezed.dart';

@freezed
sealed class ExportState with _$ExportState {
  const factory ExportState.idle() = ExportStateIdle;
  const factory ExportState.checking(String message) = ExportStateChecking;
  const factory ExportState.exporting({
    required double progress,
    required String message,
    DateTime? startedAt,
  }) = ExportStateExporting;
  const factory ExportState.fileProgress({
    required String progress,
    required String message,
  }) = ExportStateFileProgress;
  const factory ExportState.success({
    required String fileName,
    required int exportTime,
  }) = ExportStateSuccess;
  const factory ExportState.failure(ExportException error) = ExportStateFailure;
  const factory ExportState.warning(String message) = ExportStateWarning;
  const factory ExportState.info(String action) = ExportStateInfo;
  const factory ExportState.canceled() = ExportStateCanceled;
}
