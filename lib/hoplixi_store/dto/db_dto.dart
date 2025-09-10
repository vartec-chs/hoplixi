import 'package:freezed_annotation/freezed_annotation.dart';
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
    required String content,
    String? categoryId,
    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
  }) = _CreateNoteDto;
}

@freezed
abstract class UpdateNoteDto with _$UpdateNoteDto {
  const factory UpdateNoteDto({
    required String id,
    String? title,
    String? description,
    String? content,
    String? categoryId,
    bool? isFavorite,
    bool? isPinned,
    DateTime? lastAccessed,
  }) = _UpdateNoteDto;
}

// TOTP DTOs
@freezed
abstract class CreateTotpDto with _$CreateTotpDto {
  const factory CreateTotpDto({
    String? passwordId,
    required String name,
    String? description,
    @Default(OtpType.totp) OtpType type,
    String? issuer,
    String? accountName,
    required String secret, // Will be encrypted internally
    @Default('SHA1') String algorithm,
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
    String? name,
    String? description,
    OtpType? type,
    String? issuer,
    String? accountName,
    String? secret, // Will be encrypted internally
    String? algorithm,
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
