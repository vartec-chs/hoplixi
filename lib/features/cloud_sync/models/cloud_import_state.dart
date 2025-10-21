import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_exceptions.dart';

part 'cloud_import_state.freezed.dart';

@freezed
sealed class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportStateIdle;
  const factory ImportState.checking(String message) = ImportStateChecking;
  const factory ImportState.importing({
    required double progress,
    required String message,
    DateTime? startedAt,
  }) = ImportStateImporting;
  const factory ImportState.fileProgress({
    required String progress,
    required String message,
  }) = ImportStateFileProgress;
  // opening
 
  const factory ImportState.success({
    required String fileName,
    required int importTime,
  }) = ImportStateSuccess;
  const factory ImportState.failure(ImportException error) = ImportStateFailure;
  const factory ImportState.warning(String message) = ImportStateWarning;
  const factory ImportState.info(String action) = ImportStateInfo;
  const factory ImportState.canceled() = ImportStateCanceled;
}
