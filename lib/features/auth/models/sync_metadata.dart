import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_metadata.freezed.dart';
part 'sync_metadata.g.dart';

/// Метаданные синхронизации архива хранилища
/// Содержит информацию о загруженных архивах для корректной синхронизации
@freezed
abstract class SyncMetadata with _$SyncMetadata {
  const factory SyncMetadata({
    /// Список архивов в облаке (максимум 2)
    required List<ArchiveMetadata> archives,

    /// Дата последнего обновления метаданных
    required DateTime lastUpdated,

    /// Версия формата метаданных
    @Default(1) int version,
  }) = _SyncMetadata;

  factory SyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataFromJson(json);
}

/// Метаданные одного архива
@freezed
abstract class ArchiveMetadata with _$ArchiveMetadata {
  const factory ArchiveMetadata({
    /// Имя файла архива (например: storage_1234567890.zip)
    required String fileName,

    /// Unix timestamp из имени файла
    required int timestamp,

    /// Размер файла в байтах
    required int size,

    /// Контрольная сумма (SHA-256)
    required String checksum,

    /// Дата загрузки в облако
    required DateTime uploadedAt,

    /// Путь к файлу в облаке
    required String cloudPath,
  }) = _ArchiveMetadata;

  factory ArchiveMetadata.fromJson(Map<String, dynamic> json) =>
      _$ArchiveMetadataFromJson(json);
}

/// Пустые метаданные для инициализации
SyncMetadata emptyMetadata() {
  return SyncMetadata(archives: [], lastUpdated: DateTime.now(), version: 1);
}
