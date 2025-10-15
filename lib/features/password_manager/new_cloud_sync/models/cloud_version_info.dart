import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_version_info.freezed.dart';
part 'cloud_version_info.g.dart';

/// Информация о версии базы данных в облаке
@freezed
abstract class CloudVersionInfo with _$CloudVersionInfo {
  const factory CloudVersionInfo({
    /// Временная метка версии в облаке
    required DateTime timestamp,

    /// Имя файла в облаке
    required String fileName,

    /// Полный путь к файлу в облаке
    required String cloudPath,

    /// Является ли версия более новой чем локальная
    required bool isNewer,

    /// Размер файла в байтах (если доступен)
    int? fileSize,
  }) = _CloudVersionInfo;

  factory CloudVersionInfo.fromJson(Map<String, dynamic> json) =>
      _$CloudVersionInfoFromJson(json);
}
