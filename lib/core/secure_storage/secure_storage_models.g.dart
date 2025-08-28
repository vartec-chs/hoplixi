// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_storage_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StorageFileConfig _$StorageFileConfigFromJson(Map<String, dynamic> json) =>
    _StorageFileConfig(
      fileName: json['fileName'] as String,
      displayName: json['displayName'] as String,
      encryptionEnabled: json['encryptionEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$StorageFileConfigToJson(_StorageFileConfig instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'displayName': instance.displayName,
      'encryptionEnabled': instance.encryptionEnabled,
    };

_DatabaseEntry _$DatabaseEntryFromJson(Map<String, dynamic> json) =>
    _DatabaseEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$DatabaseEntryToJson(_DatabaseEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'lastAccessed': instance.lastAccessed.toIso8601String(),
      'description': instance.description,
    };

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  sessionId: json['sessionId'] as String,
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  refreshToken: json['refreshToken'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'refreshToken': instance.refreshToken,
      'metadata': instance.metadata,
    };

_FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) =>
    _FileMetadata(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      checksum: json['checksum'] as String,
      encryptionAlgorithm:
          json['encryptionAlgorithm'] as String? ?? 'AES-256-GCM',
      pbkdf2Iterations: (json['pbkdf2Iterations'] as num?)?.toInt() ?? 100000,
    );

Map<String, dynamic> _$FileMetadataToJson(_FileMetadata instance) =>
    <String, dynamic>{
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'checksum': instance.checksum,
      'encryptionAlgorithm': instance.encryptionAlgorithm,
      'pbkdf2Iterations': instance.pbkdf2Iterations,
    };
