import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/auth/models/models.dart';

part 'local_meta.freezed.dart';
part 'local_meta.g.dart';

@freezed
sealed class LocalMeta with _$LocalMeta {
  const factory LocalMeta({
    required String dbId,
    required bool enabled,
    required String dbName,
    required String deviceId,
    required ProviderType providerType,
    DateTime? lastExportAt,
    DateTime? lastImportedAt,
  }) = _LocalMeta;

  factory LocalMeta.fromJson(Map<String, dynamic> json) =>
      _$LocalMetaFromJson(json);
}
