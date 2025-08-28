import 'package:freezed_annotation/freezed_annotation.dart';

part 'secure_storage_models.freezed.dart';
part 'secure_storage_models.g.dart';

/// Конфигурация для файла хранилища
@freezed
abstract class StorageFileConfig with _$StorageFileConfig {
  const factory StorageFileConfig({
    required String fileName,
    required String displayName,
    @Default(true) bool encryptionEnabled,
  }) = _StorageFileConfig;

  factory StorageFileConfig.fromJson(Map<String, dynamic> json) =>
      _$StorageFileConfigFromJson(json);
}

/// Пример модели для списка ранее открытых БД
@freezed
abstract class DatabaseEntry with _$DatabaseEntry {
  const factory DatabaseEntry({
    required String id,
    required String name,
    required String path,
    required DateTime lastAccessed,
    String? description,
  }) = _DatabaseEntry;

  factory DatabaseEntry.fromJson(Map<String, dynamic> json) =>
      _$DatabaseEntryFromJson(json);
}

/// Пример модели для сессии авторизации
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String sessionId,
    required String userId,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? refreshToken,
    Map<String, dynamic>? metadata,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}

/// Метаданные о зашифрованном файле
@freezed
abstract class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    required String version,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String checksum,
    @Default('AES-256-GCM') String encryptionAlgorithm,
    @Default(100000) int pbkdf2Iterations,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
}

