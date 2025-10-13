import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_sync_data.g.dart';
part 'cloud_sync_data.freezed.dart';

@freezed
abstract class CloudSyncDataItem with _$CloudSyncDataItem {
  const factory CloudSyncDataItem({
    required String id,
    required String name,
    required String path,
    required String checksum,
    DateTime? exportedAt,
    DateTime? importedAt,
  }) = _CloudSyncDataItem;

  factory CloudSyncDataItem.fromJson(Map<String, dynamic> json) =>
      _$CloudSyncDataItemFromJson(json);
}
