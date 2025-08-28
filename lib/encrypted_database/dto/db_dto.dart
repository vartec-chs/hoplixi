import 'package:freezed_annotation/freezed_annotation.dart';

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
