// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'db_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateDatabaseDto {

 String get name; String? get description; String get masterPassword; String? get customPath;
/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateDatabaseDtoCopyWith<CreateDatabaseDto> get copyWith => _$CreateDatabaseDtoCopyWithImpl<CreateDatabaseDto>(this as CreateDatabaseDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateDatabaseDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.customPath, customPath) || other.customPath == customPath));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,masterPassword,customPath);

@override
String toString() {
  return 'CreateDatabaseDto(name: $name, description: $description, masterPassword: $masterPassword, customPath: $customPath)';
}


}

/// @nodoc
abstract mixin class $CreateDatabaseDtoCopyWith<$Res>  {
  factory $CreateDatabaseDtoCopyWith(CreateDatabaseDto value, $Res Function(CreateDatabaseDto) _then) = _$CreateDatabaseDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String masterPassword, String? customPath
});




}
/// @nodoc
class _$CreateDatabaseDtoCopyWithImpl<$Res>
    implements $CreateDatabaseDtoCopyWith<$Res> {
  _$CreateDatabaseDtoCopyWithImpl(this._self, this._then);

  final CreateDatabaseDto _self;
  final $Res Function(CreateDatabaseDto) _then;

/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? masterPassword = null,Object? customPath = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,customPath: freezed == customPath ? _self.customPath : customPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateDatabaseDto].
extension CreateDatabaseDtoPatterns on CreateDatabaseDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateDatabaseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateDatabaseDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateDatabaseDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateDatabaseDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description,  String masterPassword,  String? customPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description,  String masterPassword,  String? customPath)  $default,) {final _that = this;
switch (_that) {
case _CreateDatabaseDto():
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description,  String masterPassword,  String? customPath)?  $default,) {final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath);case _:
  return null;

}
}

}

/// @nodoc


class _CreateDatabaseDto implements CreateDatabaseDto {
  const _CreateDatabaseDto({required this.name, this.description = null, required this.masterPassword, this.customPath});
  

@override final  String name;
@override@JsonKey() final  String? description;
@override final  String masterPassword;
@override final  String? customPath;

/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateDatabaseDtoCopyWith<_CreateDatabaseDto> get copyWith => __$CreateDatabaseDtoCopyWithImpl<_CreateDatabaseDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateDatabaseDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.customPath, customPath) || other.customPath == customPath));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,masterPassword,customPath);

@override
String toString() {
  return 'CreateDatabaseDto(name: $name, description: $description, masterPassword: $masterPassword, customPath: $customPath)';
}


}

/// @nodoc
abstract mixin class _$CreateDatabaseDtoCopyWith<$Res> implements $CreateDatabaseDtoCopyWith<$Res> {
  factory _$CreateDatabaseDtoCopyWith(_CreateDatabaseDto value, $Res Function(_CreateDatabaseDto) _then) = __$CreateDatabaseDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String masterPassword, String? customPath
});




}
/// @nodoc
class __$CreateDatabaseDtoCopyWithImpl<$Res>
    implements _$CreateDatabaseDtoCopyWith<$Res> {
  __$CreateDatabaseDtoCopyWithImpl(this._self, this._then);

  final _CreateDatabaseDto _self;
  final $Res Function(_CreateDatabaseDto) _then;

/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? masterPassword = null,Object? customPath = freezed,}) {
  return _then(_CreateDatabaseDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,customPath: freezed == customPath ? _self.customPath : customPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OpenDatabaseDto {

 String get path; String get masterPassword;
/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenDatabaseDtoCopyWith<OpenDatabaseDto> get copyWith => _$OpenDatabaseDtoCopyWithImpl<OpenDatabaseDto>(this as OpenDatabaseDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenDatabaseDto&&(identical(other.path, path) || other.path == path)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword));
}


@override
int get hashCode => Object.hash(runtimeType,path,masterPassword);

@override
String toString() {
  return 'OpenDatabaseDto(path: $path, masterPassword: $masterPassword)';
}


}

/// @nodoc
abstract mixin class $OpenDatabaseDtoCopyWith<$Res>  {
  factory $OpenDatabaseDtoCopyWith(OpenDatabaseDto value, $Res Function(OpenDatabaseDto) _then) = _$OpenDatabaseDtoCopyWithImpl;
@useResult
$Res call({
 String path, String masterPassword
});




}
/// @nodoc
class _$OpenDatabaseDtoCopyWithImpl<$Res>
    implements $OpenDatabaseDtoCopyWith<$Res> {
  _$OpenDatabaseDtoCopyWithImpl(this._self, this._then);

  final OpenDatabaseDto _self;
  final $Res Function(OpenDatabaseDto) _then;

/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? masterPassword = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenDatabaseDto].
extension OpenDatabaseDtoPatterns on OpenDatabaseDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenDatabaseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenDatabaseDto value)  $default,){
final _that = this;
switch (_that) {
case _OpenDatabaseDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenDatabaseDto value)?  $default,){
final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String masterPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that.path,_that.masterPassword);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String masterPassword)  $default,) {final _that = this;
switch (_that) {
case _OpenDatabaseDto():
return $default(_that.path,_that.masterPassword);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String masterPassword)?  $default,) {final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that.path,_that.masterPassword);case _:
  return null;

}
}

}

/// @nodoc


class _OpenDatabaseDto implements OpenDatabaseDto {
  const _OpenDatabaseDto({required this.path, required this.masterPassword});
  

@override final  String path;
@override final  String masterPassword;

/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenDatabaseDtoCopyWith<_OpenDatabaseDto> get copyWith => __$OpenDatabaseDtoCopyWithImpl<_OpenDatabaseDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenDatabaseDto&&(identical(other.path, path) || other.path == path)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword));
}


@override
int get hashCode => Object.hash(runtimeType,path,masterPassword);

@override
String toString() {
  return 'OpenDatabaseDto(path: $path, masterPassword: $masterPassword)';
}


}

/// @nodoc
abstract mixin class _$OpenDatabaseDtoCopyWith<$Res> implements $OpenDatabaseDtoCopyWith<$Res> {
  factory _$OpenDatabaseDtoCopyWith(_OpenDatabaseDto value, $Res Function(_OpenDatabaseDto) _then) = __$OpenDatabaseDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, String masterPassword
});




}
/// @nodoc
class __$OpenDatabaseDtoCopyWithImpl<$Res>
    implements _$OpenDatabaseDtoCopyWith<$Res> {
  __$OpenDatabaseDtoCopyWithImpl(this._self, this._then);

  final _OpenDatabaseDto _self;
  final $Res Function(_OpenDatabaseDto) _then;

/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? masterPassword = null,}) {
  return _then(_OpenDatabaseDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
