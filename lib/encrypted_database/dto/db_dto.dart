import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_dto.freezed.dart';


@freezed
abstract class CreateDatabaseDto with _$CreateDatabaseDto {
  const factory CreateDatabaseDto({
    required String name,
    @Default(null) String? description,
    required String masterPassword,
    String? customPath,
  }) = _CreateDatabaseDto;
}

@freezed
abstract class OpenDatabaseDto with _$OpenDatabaseDto {
  const factory OpenDatabaseDto({
    required String path,
    required String masterPassword,
  }) = _OpenDatabaseDto;
}
