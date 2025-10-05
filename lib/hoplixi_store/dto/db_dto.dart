import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/hoplixi_store/dto/attachment_dto.dart';
import 'dart:typed_data';
import '../enums/entity_types.dart';

part 'db_dto.freezed.dart';

@freezed
abstract class CreateDatabaseDto with _$CreateDatabaseDto {
  const factory CreateDatabaseDto({
    required String name,
    @Default(null) String? description,
    required String masterPassword,
    String? customPath,
    @Default(false) bool saveMasterPassword,
    @Default(false) bool isFavorite,
  }) = _CreateDatabaseDto;
}

@freezed
abstract class OpenDatabaseDto with _$OpenDatabaseDto {
  const factory OpenDatabaseDto({
    required String path,
    required String masterPassword,
    @Default(false) bool saveMasterPassword,
  }) = _OpenDatabaseDto;
}

@freezed
abstract class AutoLoginDto with _$AutoLoginDto {
  const factory AutoLoginDto({
    required String path,
    @Default(true) bool updateLastAccessed,
  }) = _AutoLoginDto;
}

@freezed
abstract class QuickOpenDto with _$QuickOpenDto {
  const factory QuickOpenDto({
    required String path,
    String? providedPassword,
    @Default(true) bool tryAutoLogin,
    @Default(true) bool updateLastAccessed,
  }) = _QuickOpenDto;
}

// Password DTOs
@freezed
abstract class CreatePasswordDto with _$CreatePasswordDto {
  const factory CreatePasswordDto({
    required String name,
    String? description,
    required String password,
    String? url,
    String? notes,
    String? login,
    String? email,
    String? categoryId,
    @Default(false) bool isFavorite,
  }) = _CreatePasswordDto;
}

// card password dto
@freezed
abstract class CardPasswordDto with _$CardPasswordDto {
  const factory CardPasswordDto({
    required String id,
    required String name,
    String? description,
    String? login,
    String? email,
    List<CardPasswordCategoryDto>? categories,
    List<CardPasswordTagDto>? tags,
    int? usedCount,
    @Default(false) bool isFavorite,
    @Default(false)
    bool isFrequentlyUsed, // Флаг для часто используемых паролей
  }) = _CardPasswordDto;
}

@freezed
abstract class UpdatePasswordDto with _$UpdatePasswordDto {
  const factory UpdatePasswordDto({
    required String id,
    String? name,
    String? description,
    String? password,
    String? url,
    String? notes,
    String? login,
    String? email,
    String? categoryId,
    bool? isFavorite,
    DateTime? lastAccessed,
  }) = _UpdatePasswordDto;
}

// Note DTOs
@freezed
abstract class CreateNoteDto with _$CreateNoteDto {
  const factory CreateNoteDto({
    required String title,
    String? description,
    required String deltaJson,
    required String content,
    String? categoryId,
    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
    List<CreateAttachmentFromData>? attachments,
  }) = _CreateNoteDto;
}

@freezed
abstract class UpdateNoteDto with _$UpdateNoteDto {
  const factory UpdateNoteDto({
    required String id,
    String? title,
    String? description,
    String? deltaJson,
    String? content,
    String? categoryId,
    bool? isFavorite,
    bool? isPinned,
    DateTime? lastAccessed,
  }) = _UpdateNoteDto;
}

@freezed
abstract class CardNoteDto with _$CardNoteDto {
  const factory CardNoteDto({
    required String id,
    required String title,
    String? description,
    String? content, // Short content preview 200 chars
    CardCategoryDto? category,
    List<CardTagDto>? tags,
    bool? isFavorite,
    bool? isPinned,
    DateTime? lastAccessed,
  }) = _CardNoteDto;
}

@freezed
abstract class CardCategoryDto with _$CardCategoryDto {
  const factory CardCategoryDto({
    required String name,
    @Default('FFFFFF') String color,
  }) = _CardCategoryDto;
}

/// Tag DTOs for CardPassword and CardOtp
/// Used to avoid circular dependency issues
@freezed
abstract class CardTagDto with _$CardTagDto {
  const factory CardTagDto({
    required String name,
    @Default('FFFFFF') String color,
  }) = _CardTagDto;
}

/// TOTP DTOs
@freezed
abstract class CreateTotpDto with _$CreateTotpDto {
  const factory CreateTotpDto({
    String? passwordId,
    @Default(OtpType.totp) OtpType type,
    String? issuer,
    String? accountName,
    required String secret, // Will be encrypted internally
    @Default(AlgorithmOtp.SHA1) AlgorithmOtp algorithm,
    @Default(6) int digits,
    @Default(30) int period,
    int? counter, // Only for HOTP
    String? categoryId,
    @Default(false) bool isFavorite,
  }) = _CreateTotpDto;
}

@freezed
abstract class UpdateTotpDto with _$UpdateTotpDto {
  const factory UpdateTotpDto({
    required String id,
    String? passwordId,
    OtpType? type,
    String? issuer,
    String? accountName,
    String? secret, // Will be encrypted internally
    AlgorithmOtp? algorithm,
    int? digits,
    int? period,
    int? counter,
    String? categoryId,
    bool? isFavorite,
    DateTime? lastAccessed,
  }) = _UpdateTotpDto;
}

// Category DTOs
@freezed
abstract class CreateCategoryDto with _$CreateCategoryDto {
  const factory CreateCategoryDto({
    required String name,
    String? description,
    String? iconId,
    @Default('FFFFFF') String color,
    required CategoryType type,
  }) = _CreateCategoryDto;
}

@freezed
abstract class CardPasswordCategoryDto with _$CardPasswordCategoryDto {
  const factory CardPasswordCategoryDto({
    required String name,
    @Default('FFFFFF') String color,
  }) = _CardPasswordCategoryDto;
}

@freezed
abstract class UpdateCategoryDto with _$UpdateCategoryDto {
  const factory UpdateCategoryDto({
    required String id,
    String? name,
    String? description,
    String? iconId,
    String? color,
    CategoryType? type,
    @Default(false) bool clearIcon, // Флаг для очистки иконки
  }) = _UpdateCategoryDto;
}

// Tag DTOs
@freezed
abstract class CreateTagDto with _$CreateTagDto {
  const factory CreateTagDto({
    required String name,
    String? color,
    required TagType type,
  }) = _CreateTagDto;
}

@freezed
abstract class CardPasswordTagDto with _$CardPasswordTagDto {
  const factory CardPasswordTagDto({required String name, String? color}) =
      _CardPasswordTagDto;
}

@freezed
abstract class UpdateTagDto with _$UpdateTagDto {
  const factory UpdateTagDto({
    required String id,
    String? name,
    String? color,
    TagType? type,
  }) = _UpdateTagDto;
}

// Icon DTOs
@freezed
abstract class CreateIconDto with _$CreateIconDto {
  const factory CreateIconDto({
    required String name,
    required IconType type,
    required Uint8List data,
  }) = _CreateIconDto;
}

@freezed
abstract class UpdateIconDto with _$UpdateIconDto {
  const factory UpdateIconDto({
    required String id,
    String? name,
    IconType? type,
    Uint8List? data,
  }) = _UpdateIconDto;
}

// Attachment DTOs
@freezed
abstract class CreateAttachmentDto with _$CreateAttachmentDto {
  const factory CreateAttachmentDto({
    required String name,
    String? description,
    required String filePath,
    required String mimeType,
    required int fileSize,
    String? checksum,
    String? passwordId,
    String? totpId,
    String? noteId,
  }) = _CreateAttachmentDto;
}

@freezed
abstract class UpdateAttachmentDto with _$UpdateAttachmentDto {
  const factory UpdateAttachmentDto({
    required String id,
    String? name,
    String? description,
    String? filePath,
    String? mimeType,
    int? fileSize,
    String? checksum,
    String? passwordId,
    String? totpId,
    String? noteId,
  }) = _UpdateAttachmentDto;
}

// OTP Card DTOs
@freezed
abstract class CardOtpDto with _$CardOtpDto {
  const factory CardOtpDto({
    required String id,
    String? issuer,
    String? accountName,
    required OtpType type,
    required AlgorithmOtp algorithm,
    required int digits,
    required int period,
    int? counter,
    List<CardOtpCategoryDto>? categories,
    List<CardOtpTagDto>? tags,
    @Default(false) bool isFavorite,
    bool? hasPasswordLink,
  }) = _CardOtpDto;
}

@freezed
abstract class CardOtpCategoryDto with _$CardOtpCategoryDto {
  const factory CardOtpCategoryDto({
    required String name,
    @Default('FFFFFF') String color,
  }) = _CardOtpCategoryDto;
}

@freezed
abstract class CardOtpTagDto with _$CardOtpTagDto {
  const factory CardOtpTagDto({required String name, String? color}) =
      _CardOtpTagDto;
}
