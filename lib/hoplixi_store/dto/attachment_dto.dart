import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_dto.freezed.dart';
part 'attachment_dto.g.dart';

enum AttachmentType { fromPath, fromData }

/// DTO для создания attachment из файла на диске (храним путь)
@freezed
abstract class CreateAttachmentFromPath with _$CreateAttachmentFromPath {
  const factory CreateAttachmentFromPath({
    required String name,
    String? description,
    required String filePath,
    required String mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) = _CreateAttachmentFromPath;

  factory CreateAttachmentFromPath.fromJson(Map<String, dynamic> json) =>
      _$CreateAttachmentFromPathFromJson(json);
}

/// DTO для создания attachment из маленького файла (храним данные в БД)
@freezed
abstract class CreateAttachmentFromData with _$CreateAttachmentFromData {
  const factory CreateAttachmentFromData({
    required String name,
    String? description,
    required List<int> fileData,
    required String mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) = _CreateAttachmentFromData;

  factory CreateAttachmentFromData.fromJson(Map<String, dynamic> json) =>
      _$CreateAttachmentFromDataFromJson(json);
}

/// DTO для обновления attachment из файла на диске
@freezed
abstract class UpdateAttachmentFromPath with _$UpdateAttachmentFromPath {
  const factory UpdateAttachmentFromPath({
    required String id,
    String? name,
    String? description,
    String? filePath,
    String? mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) = _UpdateAttachmentFromPath;

  factory UpdateAttachmentFromPath.fromJson(Map<String, dynamic> json) =>
      _$UpdateAttachmentFromPathFromJson(json);
}

/// DTO для обновления attachment из маленького файла
@freezed
abstract class UpdateAttachmentFromData with _$UpdateAttachmentFromData {
  const factory UpdateAttachmentFromData({
    required String id,
    String? name,
    String? description,
    List<int>? fileData,
    String? mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) = _UpdateAttachmentFromData;

  factory UpdateAttachmentFromData.fromJson(Map<String, dynamic> json) =>
      _$UpdateAttachmentFromDataFromJson(json);
}

/// DTO для получения attachment из файла на диске
@freezed
abstract class AttachmentFromPathDto with _$AttachmentFromPathDto {
  const factory AttachmentFromPathDto({
    required String id,
    required String name,

    String? description,
    required String filePath,
    required String mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessed,
  }) = _AttachmentFromPathDto;

  factory AttachmentFromPathDto.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromPathDtoFromJson(json);
}

/// DTO для получения attachment из маленького файла
@freezed
abstract class AttachmentFromDataDto with _$AttachmentFromDataDto {
  const factory AttachmentFromDataDto({
    required String id,
    required String name,
    String? description,
    required List<int> fileData,
    required String mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessed,
  }) = _AttachmentFromDataDto;

  factory AttachmentFromDataDto.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromDataDtoFromJson(json);
}

/// DTO для карточки attachment (без контента)
@freezed
abstract class AttachmentCardDto with _$AttachmentCardDto {
  const factory AttachmentCardDto({
    required String id,
    required String name,
    String? description,
    required String mimeType,
    AttachmentType? type,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? otpId,
    String? noteId,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessed,
  }) = _AttachmentCardDto;

  factory AttachmentCardDto.fromJson(Map<String, dynamic> json) =>
      _$AttachmentCardDtoFromJson(json);
}
