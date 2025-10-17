import 'package:device_info_plus/device_info_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_meta.freezed.dart';
part 'local_meta.g.dart';

@freezed
sealed class LocalMeta with _$LocalMeta {
  const factory LocalMeta({
    required String id,
    required String dbId,
    required String dbName,
    required String deviceId,
    DateTime? lastExportAt,
    DateTime? lastImportedAt,
  }) = _LocalMeta;

  factory LocalMeta.fromJson(Map<String, dynamic> json) =>
      _$LocalMetaFromJson(json);
}
