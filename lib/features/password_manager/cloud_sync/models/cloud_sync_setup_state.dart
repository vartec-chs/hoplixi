import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/local_meta.dart';

part 'cloud_sync_setup_state.freezed.dart';

/// Состояния экрана настройки облачной синхронизации
@freezed
abstract class CloudSyncSetupState with _$CloudSyncSetupState {
  /// Загрузка (начальная проверка)
  const factory CloudSyncSetupState.loading() = _Loading;

  /// Синхронизация не настроена - призыв к действию
  const factory CloudSyncSetupState.notConfigured({
    required String dbId,
    required String dbName,
  }) = _NotConfigured;

  /// Синхронизация уже настроена - показать информацию
  const factory CloudSyncSetupState.alreadyConfigured({
    required LocalMeta meta,
  }) = _AlreadyConfigured;

  /// Процесс настройки (авторизация)
  const factory CloudSyncSetupState.setupInProgress() = _SetupInProgress;

  /// Настройка завершена - поздравление
  const factory CloudSyncSetupState.setupCompleted({
    required ProviderType providerType,
    required String dbName,
  }) = _SetupCompleted;

  /// Ошибка
  const factory CloudSyncSetupState.error({
    required String message,
    String? dbId,
  }) = _Error;
}
