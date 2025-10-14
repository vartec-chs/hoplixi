import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_sync_state.freezed.dart';

/// Состояние прогресса синхронизации
@freezed
abstract class CloudSyncProgress with _$CloudSyncProgress {
  const factory CloudSyncProgress({
    @Default(0.0) double progress,
    @Default('') String message,
    @Default('') String fileProgress,
  }) = _CloudSyncProgress;
}

/// Состояние синхронизации с облаком
@freezed
abstract class CloudSyncState with _$CloudSyncState {
  const factory CloudSyncState.idle() = _Idle;
  
  const factory CloudSyncState.exporting({
    required CloudSyncProgress progress,
  }) = _Exporting;
  
  const factory CloudSyncState.importing({
    required CloudSyncProgress progress,
  }) = _Importing;
  
  const factory CloudSyncState.success({
    required String message,
  }) = _Success;
  
  const factory CloudSyncState.error({
    required String message,
  }) = _Error;
}
