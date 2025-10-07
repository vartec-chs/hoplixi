import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Пример модели данных с freezed
@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
