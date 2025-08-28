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
    String? masterPassword,
    @Default(false) bool isFavorite,
    @Default(false) bool isMasterPasswordSaved,
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

/// Типы проблем безопасности
enum SecurityIssueType {
  invalidKey,
  corruptedFile,
  corruptedSignature,
  missingSignature,
  keyMismatch,
}

/// Уровни серьезности проблем безопасности
enum SecurityIssueSeverity { low, medium, high, critical }

/// Модель проблемы безопасности
@freezed
abstract class SecurityIssue with _$SecurityIssue {
  const factory SecurityIssue({
    required SecurityIssueType type,
    required String storageKey,
    required String description,
    required SecurityIssueSeverity severity,
    DateTime? detectedAt,
  }) = _SecurityIssue;

  factory SecurityIssue.fromJson(Map<String, dynamic> json) =>
      _$SecurityIssueFromJson(json);
}

/// Результаты диагностики безопасности
@freezed
abstract class SecurityDiagnostics with _$SecurityDiagnostics {
  const factory SecurityDiagnostics({
    required int totalStorages,
    required int validKeys,
    required int invalidKeys,
    required int intactFiles,
    required int corruptedFiles,
    required List<SecurityIssue> issues,
    required DateTime scanTime,
  }) = _SecurityDiagnostics;

  factory SecurityDiagnostics.fromJson(Map<String, dynamic> json) =>
      _$SecurityDiagnosticsFromJson(json);
}
