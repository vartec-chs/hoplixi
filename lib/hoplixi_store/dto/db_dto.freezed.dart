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

 String get name; String? get description; String get masterPassword; String? get customPath; bool get saveMasterPassword; bool get isFavorite;
/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateDatabaseDtoCopyWith<CreateDatabaseDto> get copyWith => _$CreateDatabaseDtoCopyWithImpl<CreateDatabaseDto>(this as CreateDatabaseDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateDatabaseDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.customPath, customPath) || other.customPath == customPath)&&(identical(other.saveMasterPassword, saveMasterPassword) || other.saveMasterPassword == saveMasterPassword)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,masterPassword,customPath,saveMasterPassword,isFavorite);

@override
String toString() {
  return 'CreateDatabaseDto(name: $name, description: $description, masterPassword: $masterPassword, customPath: $customPath, saveMasterPassword: $saveMasterPassword, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $CreateDatabaseDtoCopyWith<$Res>  {
  factory $CreateDatabaseDtoCopyWith(CreateDatabaseDto value, $Res Function(CreateDatabaseDto) _then) = _$CreateDatabaseDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String masterPassword, String? customPath, bool saveMasterPassword, bool isFavorite
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? masterPassword = null,Object? customPath = freezed,Object? saveMasterPassword = null,Object? isFavorite = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,customPath: freezed == customPath ? _self.customPath : customPath // ignore: cast_nullable_to_non_nullable
as String?,saveMasterPassword: null == saveMasterPassword ? _self.saveMasterPassword : saveMasterPassword // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description,  String masterPassword,  String? customPath,  bool saveMasterPassword,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath,_that.saveMasterPassword,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description,  String masterPassword,  String? customPath,  bool saveMasterPassword,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _CreateDatabaseDto():
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath,_that.saveMasterPassword,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description,  String masterPassword,  String? customPath,  bool saveMasterPassword,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _CreateDatabaseDto() when $default != null:
return $default(_that.name,_that.description,_that.masterPassword,_that.customPath,_that.saveMasterPassword,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc


class _CreateDatabaseDto implements CreateDatabaseDto {
  const _CreateDatabaseDto({required this.name, this.description = null, required this.masterPassword, this.customPath, this.saveMasterPassword = false, this.isFavorite = false});
  

@override final  String name;
@override@JsonKey() final  String? description;
@override final  String masterPassword;
@override final  String? customPath;
@override@JsonKey() final  bool saveMasterPassword;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of CreateDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateDatabaseDtoCopyWith<_CreateDatabaseDto> get copyWith => __$CreateDatabaseDtoCopyWithImpl<_CreateDatabaseDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateDatabaseDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.customPath, customPath) || other.customPath == customPath)&&(identical(other.saveMasterPassword, saveMasterPassword) || other.saveMasterPassword == saveMasterPassword)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,masterPassword,customPath,saveMasterPassword,isFavorite);

@override
String toString() {
  return 'CreateDatabaseDto(name: $name, description: $description, masterPassword: $masterPassword, customPath: $customPath, saveMasterPassword: $saveMasterPassword, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$CreateDatabaseDtoCopyWith<$Res> implements $CreateDatabaseDtoCopyWith<$Res> {
  factory _$CreateDatabaseDtoCopyWith(_CreateDatabaseDto value, $Res Function(_CreateDatabaseDto) _then) = __$CreateDatabaseDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String masterPassword, String? customPath, bool saveMasterPassword, bool isFavorite
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? masterPassword = null,Object? customPath = freezed,Object? saveMasterPassword = null,Object? isFavorite = null,}) {
  return _then(_CreateDatabaseDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,customPath: freezed == customPath ? _self.customPath : customPath // ignore: cast_nullable_to_non_nullable
as String?,saveMasterPassword: null == saveMasterPassword ? _self.saveMasterPassword : saveMasterPassword // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OpenDatabaseDto {

 String get path; String get masterPassword; bool get saveMasterPassword;
/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenDatabaseDtoCopyWith<OpenDatabaseDto> get copyWith => _$OpenDatabaseDtoCopyWithImpl<OpenDatabaseDto>(this as OpenDatabaseDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenDatabaseDto&&(identical(other.path, path) || other.path == path)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.saveMasterPassword, saveMasterPassword) || other.saveMasterPassword == saveMasterPassword));
}


@override
int get hashCode => Object.hash(runtimeType,path,masterPassword,saveMasterPassword);

@override
String toString() {
  return 'OpenDatabaseDto(path: $path, masterPassword: $masterPassword, saveMasterPassword: $saveMasterPassword)';
}


}

/// @nodoc
abstract mixin class $OpenDatabaseDtoCopyWith<$Res>  {
  factory $OpenDatabaseDtoCopyWith(OpenDatabaseDto value, $Res Function(OpenDatabaseDto) _then) = _$OpenDatabaseDtoCopyWithImpl;
@useResult
$Res call({
 String path, String masterPassword, bool saveMasterPassword
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
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? masterPassword = null,Object? saveMasterPassword = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,saveMasterPassword: null == saveMasterPassword ? _self.saveMasterPassword : saveMasterPassword // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String masterPassword,  bool saveMasterPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that.path,_that.masterPassword,_that.saveMasterPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String masterPassword,  bool saveMasterPassword)  $default,) {final _that = this;
switch (_that) {
case _OpenDatabaseDto():
return $default(_that.path,_that.masterPassword,_that.saveMasterPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String masterPassword,  bool saveMasterPassword)?  $default,) {final _that = this;
switch (_that) {
case _OpenDatabaseDto() when $default != null:
return $default(_that.path,_that.masterPassword,_that.saveMasterPassword);case _:
  return null;

}
}

}

/// @nodoc


class _OpenDatabaseDto implements OpenDatabaseDto {
  const _OpenDatabaseDto({required this.path, required this.masterPassword, this.saveMasterPassword = false});
  

@override final  String path;
@override final  String masterPassword;
@override@JsonKey() final  bool saveMasterPassword;

/// Create a copy of OpenDatabaseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenDatabaseDtoCopyWith<_OpenDatabaseDto> get copyWith => __$OpenDatabaseDtoCopyWithImpl<_OpenDatabaseDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenDatabaseDto&&(identical(other.path, path) || other.path == path)&&(identical(other.masterPassword, masterPassword) || other.masterPassword == masterPassword)&&(identical(other.saveMasterPassword, saveMasterPassword) || other.saveMasterPassword == saveMasterPassword));
}


@override
int get hashCode => Object.hash(runtimeType,path,masterPassword,saveMasterPassword);

@override
String toString() {
  return 'OpenDatabaseDto(path: $path, masterPassword: $masterPassword, saveMasterPassword: $saveMasterPassword)';
}


}

/// @nodoc
abstract mixin class _$OpenDatabaseDtoCopyWith<$Res> implements $OpenDatabaseDtoCopyWith<$Res> {
  factory _$OpenDatabaseDtoCopyWith(_OpenDatabaseDto value, $Res Function(_OpenDatabaseDto) _then) = __$OpenDatabaseDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, String masterPassword, bool saveMasterPassword
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
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? masterPassword = null,Object? saveMasterPassword = null,}) {
  return _then(_OpenDatabaseDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,masterPassword: null == masterPassword ? _self.masterPassword : masterPassword // ignore: cast_nullable_to_non_nullable
as String,saveMasterPassword: null == saveMasterPassword ? _self.saveMasterPassword : saveMasterPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AutoLoginDto {

 String get path; bool get updateLastAccessed;
/// Create a copy of AutoLoginDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoLoginDtoCopyWith<AutoLoginDto> get copyWith => _$AutoLoginDtoCopyWithImpl<AutoLoginDto>(this as AutoLoginDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoLoginDto&&(identical(other.path, path) || other.path == path)&&(identical(other.updateLastAccessed, updateLastAccessed) || other.updateLastAccessed == updateLastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,path,updateLastAccessed);

@override
String toString() {
  return 'AutoLoginDto(path: $path, updateLastAccessed: $updateLastAccessed)';
}


}

/// @nodoc
abstract mixin class $AutoLoginDtoCopyWith<$Res>  {
  factory $AutoLoginDtoCopyWith(AutoLoginDto value, $Res Function(AutoLoginDto) _then) = _$AutoLoginDtoCopyWithImpl;
@useResult
$Res call({
 String path, bool updateLastAccessed
});




}
/// @nodoc
class _$AutoLoginDtoCopyWithImpl<$Res>
    implements $AutoLoginDtoCopyWith<$Res> {
  _$AutoLoginDtoCopyWithImpl(this._self, this._then);

  final AutoLoginDto _self;
  final $Res Function(AutoLoginDto) _then;

/// Create a copy of AutoLoginDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? updateLastAccessed = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,updateLastAccessed: null == updateLastAccessed ? _self.updateLastAccessed : updateLastAccessed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoLoginDto].
extension AutoLoginDtoPatterns on AutoLoginDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoLoginDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoLoginDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoLoginDto value)  $default,){
final _that = this;
switch (_that) {
case _AutoLoginDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoLoginDto value)?  $default,){
final _that = this;
switch (_that) {
case _AutoLoginDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  bool updateLastAccessed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoLoginDto() when $default != null:
return $default(_that.path,_that.updateLastAccessed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  bool updateLastAccessed)  $default,) {final _that = this;
switch (_that) {
case _AutoLoginDto():
return $default(_that.path,_that.updateLastAccessed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  bool updateLastAccessed)?  $default,) {final _that = this;
switch (_that) {
case _AutoLoginDto() when $default != null:
return $default(_that.path,_that.updateLastAccessed);case _:
  return null;

}
}

}

/// @nodoc


class _AutoLoginDto implements AutoLoginDto {
  const _AutoLoginDto({required this.path, this.updateLastAccessed = true});
  

@override final  String path;
@override@JsonKey() final  bool updateLastAccessed;

/// Create a copy of AutoLoginDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoLoginDtoCopyWith<_AutoLoginDto> get copyWith => __$AutoLoginDtoCopyWithImpl<_AutoLoginDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoLoginDto&&(identical(other.path, path) || other.path == path)&&(identical(other.updateLastAccessed, updateLastAccessed) || other.updateLastAccessed == updateLastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,path,updateLastAccessed);

@override
String toString() {
  return 'AutoLoginDto(path: $path, updateLastAccessed: $updateLastAccessed)';
}


}

/// @nodoc
abstract mixin class _$AutoLoginDtoCopyWith<$Res> implements $AutoLoginDtoCopyWith<$Res> {
  factory _$AutoLoginDtoCopyWith(_AutoLoginDto value, $Res Function(_AutoLoginDto) _then) = __$AutoLoginDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, bool updateLastAccessed
});




}
/// @nodoc
class __$AutoLoginDtoCopyWithImpl<$Res>
    implements _$AutoLoginDtoCopyWith<$Res> {
  __$AutoLoginDtoCopyWithImpl(this._self, this._then);

  final _AutoLoginDto _self;
  final $Res Function(_AutoLoginDto) _then;

/// Create a copy of AutoLoginDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? updateLastAccessed = null,}) {
  return _then(_AutoLoginDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,updateLastAccessed: null == updateLastAccessed ? _self.updateLastAccessed : updateLastAccessed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$QuickOpenDto {

 String get path; String? get providedPassword; bool get tryAutoLogin; bool get updateLastAccessed;
/// Create a copy of QuickOpenDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickOpenDtoCopyWith<QuickOpenDto> get copyWith => _$QuickOpenDtoCopyWithImpl<QuickOpenDto>(this as QuickOpenDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickOpenDto&&(identical(other.path, path) || other.path == path)&&(identical(other.providedPassword, providedPassword) || other.providedPassword == providedPassword)&&(identical(other.tryAutoLogin, tryAutoLogin) || other.tryAutoLogin == tryAutoLogin)&&(identical(other.updateLastAccessed, updateLastAccessed) || other.updateLastAccessed == updateLastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,path,providedPassword,tryAutoLogin,updateLastAccessed);

@override
String toString() {
  return 'QuickOpenDto(path: $path, providedPassword: $providedPassword, tryAutoLogin: $tryAutoLogin, updateLastAccessed: $updateLastAccessed)';
}


}

/// @nodoc
abstract mixin class $QuickOpenDtoCopyWith<$Res>  {
  factory $QuickOpenDtoCopyWith(QuickOpenDto value, $Res Function(QuickOpenDto) _then) = _$QuickOpenDtoCopyWithImpl;
@useResult
$Res call({
 String path, String? providedPassword, bool tryAutoLogin, bool updateLastAccessed
});




}
/// @nodoc
class _$QuickOpenDtoCopyWithImpl<$Res>
    implements $QuickOpenDtoCopyWith<$Res> {
  _$QuickOpenDtoCopyWithImpl(this._self, this._then);

  final QuickOpenDto _self;
  final $Res Function(QuickOpenDto) _then;

/// Create a copy of QuickOpenDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? providedPassword = freezed,Object? tryAutoLogin = null,Object? updateLastAccessed = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,providedPassword: freezed == providedPassword ? _self.providedPassword : providedPassword // ignore: cast_nullable_to_non_nullable
as String?,tryAutoLogin: null == tryAutoLogin ? _self.tryAutoLogin : tryAutoLogin // ignore: cast_nullable_to_non_nullable
as bool,updateLastAccessed: null == updateLastAccessed ? _self.updateLastAccessed : updateLastAccessed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickOpenDto].
extension QuickOpenDtoPatterns on QuickOpenDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickOpenDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickOpenDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickOpenDto value)  $default,){
final _that = this;
switch (_that) {
case _QuickOpenDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickOpenDto value)?  $default,){
final _that = this;
switch (_that) {
case _QuickOpenDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String? providedPassword,  bool tryAutoLogin,  bool updateLastAccessed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickOpenDto() when $default != null:
return $default(_that.path,_that.providedPassword,_that.tryAutoLogin,_that.updateLastAccessed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String? providedPassword,  bool tryAutoLogin,  bool updateLastAccessed)  $default,) {final _that = this;
switch (_that) {
case _QuickOpenDto():
return $default(_that.path,_that.providedPassword,_that.tryAutoLogin,_that.updateLastAccessed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String? providedPassword,  bool tryAutoLogin,  bool updateLastAccessed)?  $default,) {final _that = this;
switch (_that) {
case _QuickOpenDto() when $default != null:
return $default(_that.path,_that.providedPassword,_that.tryAutoLogin,_that.updateLastAccessed);case _:
  return null;

}
}

}

/// @nodoc


class _QuickOpenDto implements QuickOpenDto {
  const _QuickOpenDto({required this.path, this.providedPassword, this.tryAutoLogin = true, this.updateLastAccessed = true});
  

@override final  String path;
@override final  String? providedPassword;
@override@JsonKey() final  bool tryAutoLogin;
@override@JsonKey() final  bool updateLastAccessed;

/// Create a copy of QuickOpenDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickOpenDtoCopyWith<_QuickOpenDto> get copyWith => __$QuickOpenDtoCopyWithImpl<_QuickOpenDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickOpenDto&&(identical(other.path, path) || other.path == path)&&(identical(other.providedPassword, providedPassword) || other.providedPassword == providedPassword)&&(identical(other.tryAutoLogin, tryAutoLogin) || other.tryAutoLogin == tryAutoLogin)&&(identical(other.updateLastAccessed, updateLastAccessed) || other.updateLastAccessed == updateLastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,path,providedPassword,tryAutoLogin,updateLastAccessed);

@override
String toString() {
  return 'QuickOpenDto(path: $path, providedPassword: $providedPassword, tryAutoLogin: $tryAutoLogin, updateLastAccessed: $updateLastAccessed)';
}


}

/// @nodoc
abstract mixin class _$QuickOpenDtoCopyWith<$Res> implements $QuickOpenDtoCopyWith<$Res> {
  factory _$QuickOpenDtoCopyWith(_QuickOpenDto value, $Res Function(_QuickOpenDto) _then) = __$QuickOpenDtoCopyWithImpl;
@override @useResult
$Res call({
 String path, String? providedPassword, bool tryAutoLogin, bool updateLastAccessed
});




}
/// @nodoc
class __$QuickOpenDtoCopyWithImpl<$Res>
    implements _$QuickOpenDtoCopyWith<$Res> {
  __$QuickOpenDtoCopyWithImpl(this._self, this._then);

  final _QuickOpenDto _self;
  final $Res Function(_QuickOpenDto) _then;

/// Create a copy of QuickOpenDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? providedPassword = freezed,Object? tryAutoLogin = null,Object? updateLastAccessed = null,}) {
  return _then(_QuickOpenDto(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,providedPassword: freezed == providedPassword ? _self.providedPassword : providedPassword // ignore: cast_nullable_to_non_nullable
as String?,tryAutoLogin: null == tryAutoLogin ? _self.tryAutoLogin : tryAutoLogin // ignore: cast_nullable_to_non_nullable
as bool,updateLastAccessed: null == updateLastAccessed ? _self.updateLastAccessed : updateLastAccessed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CreatePasswordDto {

 String get name; String? get description; String get password; String? get url; String? get notes; String? get login; String? get email; String? get categoryId; bool get isFavorite;
/// Create a copy of CreatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePasswordDtoCopyWith<CreatePasswordDto> get copyWith => _$CreatePasswordDtoCopyWithImpl<CreatePasswordDto>(this as CreatePasswordDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePasswordDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.password, password) || other.password == password)&&(identical(other.url, url) || other.url == url)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.login, login) || other.login == login)&&(identical(other.email, email) || other.email == email)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,password,url,notes,login,email,categoryId,isFavorite);

@override
String toString() {
  return 'CreatePasswordDto(name: $name, description: $description, password: $password, url: $url, notes: $notes, login: $login, email: $email, categoryId: $categoryId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $CreatePasswordDtoCopyWith<$Res>  {
  factory $CreatePasswordDtoCopyWith(CreatePasswordDto value, $Res Function(CreatePasswordDto) _then) = _$CreatePasswordDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String password, String? url, String? notes, String? login, String? email, String? categoryId, bool isFavorite
});




}
/// @nodoc
class _$CreatePasswordDtoCopyWithImpl<$Res>
    implements $CreatePasswordDtoCopyWith<$Res> {
  _$CreatePasswordDtoCopyWithImpl(this._self, this._then);

  final CreatePasswordDto _self;
  final $Res Function(CreatePasswordDto) _then;

/// Create a copy of CreatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? password = null,Object? url = freezed,Object? notes = freezed,Object? login = freezed,Object? email = freezed,Object? categoryId = freezed,Object? isFavorite = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,login: freezed == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatePasswordDto].
extension CreatePasswordDtoPatterns on CreatePasswordDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatePasswordDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatePasswordDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatePasswordDto value)  $default,){
final _that = this;
switch (_that) {
case _CreatePasswordDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatePasswordDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreatePasswordDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description,  String password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatePasswordDto() when $default != null:
return $default(_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description,  String password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _CreatePasswordDto():
return $default(_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description,  String password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _CreatePasswordDto() when $default != null:
return $default(_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc


class _CreatePasswordDto implements CreatePasswordDto {
  const _CreatePasswordDto({required this.name, this.description, required this.password, this.url, this.notes, this.login, this.email, this.categoryId, this.isFavorite = false});
  

@override final  String name;
@override final  String? description;
@override final  String password;
@override final  String? url;
@override final  String? notes;
@override final  String? login;
@override final  String? email;
@override final  String? categoryId;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of CreatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePasswordDtoCopyWith<_CreatePasswordDto> get copyWith => __$CreatePasswordDtoCopyWithImpl<_CreatePasswordDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePasswordDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.password, password) || other.password == password)&&(identical(other.url, url) || other.url == url)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.login, login) || other.login == login)&&(identical(other.email, email) || other.email == email)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,password,url,notes,login,email,categoryId,isFavorite);

@override
String toString() {
  return 'CreatePasswordDto(name: $name, description: $description, password: $password, url: $url, notes: $notes, login: $login, email: $email, categoryId: $categoryId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$CreatePasswordDtoCopyWith<$Res> implements $CreatePasswordDtoCopyWith<$Res> {
  factory _$CreatePasswordDtoCopyWith(_CreatePasswordDto value, $Res Function(_CreatePasswordDto) _then) = __$CreatePasswordDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String password, String? url, String? notes, String? login, String? email, String? categoryId, bool isFavorite
});




}
/// @nodoc
class __$CreatePasswordDtoCopyWithImpl<$Res>
    implements _$CreatePasswordDtoCopyWith<$Res> {
  __$CreatePasswordDtoCopyWithImpl(this._self, this._then);

  final _CreatePasswordDto _self;
  final $Res Function(_CreatePasswordDto) _then;

/// Create a copy of CreatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? password = null,Object? url = freezed,Object? notes = freezed,Object? login = freezed,Object? email = freezed,Object? categoryId = freezed,Object? isFavorite = null,}) {
  return _then(_CreatePasswordDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,login: freezed == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$UpdatePasswordDto {

 String get id; String? get name; String? get description; String? get password; String? get url; String? get notes; String? get login; String? get email; String? get categoryId; bool? get isFavorite; DateTime? get lastAccessed;
/// Create a copy of UpdatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePasswordDtoCopyWith<UpdatePasswordDto> get copyWith => _$UpdatePasswordDtoCopyWithImpl<UpdatePasswordDto>(this as UpdatePasswordDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePasswordDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.password, password) || other.password == password)&&(identical(other.url, url) || other.url == url)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.login, login) || other.login == login)&&(identical(other.email, email) || other.email == email)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,password,url,notes,login,email,categoryId,isFavorite,lastAccessed);

@override
String toString() {
  return 'UpdatePasswordDto(id: $id, name: $name, description: $description, password: $password, url: $url, notes: $notes, login: $login, email: $email, categoryId: $categoryId, isFavorite: $isFavorite, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class $UpdatePasswordDtoCopyWith<$Res>  {
  factory $UpdatePasswordDtoCopyWith(UpdatePasswordDto value, $Res Function(UpdatePasswordDto) _then) = _$UpdatePasswordDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? description, String? password, String? url, String? notes, String? login, String? email, String? categoryId, bool? isFavorite, DateTime? lastAccessed
});




}
/// @nodoc
class _$UpdatePasswordDtoCopyWithImpl<$Res>
    implements $UpdatePasswordDtoCopyWith<$Res> {
  _$UpdatePasswordDtoCopyWithImpl(this._self, this._then);

  final UpdatePasswordDto _self;
  final $Res Function(UpdatePasswordDto) _then;

/// Create a copy of UpdatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? password = freezed,Object? url = freezed,Object? notes = freezed,Object? login = freezed,Object? email = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? lastAccessed = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,login: freezed == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePasswordDto].
extension UpdatePasswordDtoPatterns on UpdatePasswordDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePasswordDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePasswordDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePasswordDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePasswordDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePasswordDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePasswordDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePasswordDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)  $default,) {final _that = this;
switch (_that) {
case _UpdatePasswordDto():
return $default(_that.id,_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? description,  String? password,  String? url,  String? notes,  String? login,  String? email,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePasswordDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.password,_that.url,_that.notes,_that.login,_that.email,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
  return null;

}
}

}

/// @nodoc


class _UpdatePasswordDto implements UpdatePasswordDto {
  const _UpdatePasswordDto({required this.id, this.name, this.description, this.password, this.url, this.notes, this.login, this.email, this.categoryId, this.isFavorite, this.lastAccessed});
  

@override final  String id;
@override final  String? name;
@override final  String? description;
@override final  String? password;
@override final  String? url;
@override final  String? notes;
@override final  String? login;
@override final  String? email;
@override final  String? categoryId;
@override final  bool? isFavorite;
@override final  DateTime? lastAccessed;

/// Create a copy of UpdatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePasswordDtoCopyWith<_UpdatePasswordDto> get copyWith => __$UpdatePasswordDtoCopyWithImpl<_UpdatePasswordDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePasswordDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.password, password) || other.password == password)&&(identical(other.url, url) || other.url == url)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.login, login) || other.login == login)&&(identical(other.email, email) || other.email == email)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,password,url,notes,login,email,categoryId,isFavorite,lastAccessed);

@override
String toString() {
  return 'UpdatePasswordDto(id: $id, name: $name, description: $description, password: $password, url: $url, notes: $notes, login: $login, email: $email, categoryId: $categoryId, isFavorite: $isFavorite, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class _$UpdatePasswordDtoCopyWith<$Res> implements $UpdatePasswordDtoCopyWith<$Res> {
  factory _$UpdatePasswordDtoCopyWith(_UpdatePasswordDto value, $Res Function(_UpdatePasswordDto) _then) = __$UpdatePasswordDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? description, String? password, String? url, String? notes, String? login, String? email, String? categoryId, bool? isFavorite, DateTime? lastAccessed
});




}
/// @nodoc
class __$UpdatePasswordDtoCopyWithImpl<$Res>
    implements _$UpdatePasswordDtoCopyWith<$Res> {
  __$UpdatePasswordDtoCopyWithImpl(this._self, this._then);

  final _UpdatePasswordDto _self;
  final $Res Function(_UpdatePasswordDto) _then;

/// Create a copy of UpdatePasswordDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? password = freezed,Object? url = freezed,Object? notes = freezed,Object? login = freezed,Object? email = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? lastAccessed = freezed,}) {
  return _then(_UpdatePasswordDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,login: freezed == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$CreateNoteDto {

 String get title; String? get description; String get content; String? get categoryId; bool get isFavorite; bool get isPinned;
/// Create a copy of CreateNoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateNoteDtoCopyWith<CreateNoteDto> get copyWith => _$CreateNoteDtoCopyWithImpl<CreateNoteDto>(this as CreateNoteDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateNoteDto&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,content,categoryId,isFavorite,isPinned);

@override
String toString() {
  return 'CreateNoteDto(title: $title, description: $description, content: $content, categoryId: $categoryId, isFavorite: $isFavorite, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class $CreateNoteDtoCopyWith<$Res>  {
  factory $CreateNoteDtoCopyWith(CreateNoteDto value, $Res Function(CreateNoteDto) _then) = _$CreateNoteDtoCopyWithImpl;
@useResult
$Res call({
 String title, String? description, String content, String? categoryId, bool isFavorite, bool isPinned
});




}
/// @nodoc
class _$CreateNoteDtoCopyWithImpl<$Res>
    implements $CreateNoteDtoCopyWith<$Res> {
  _$CreateNoteDtoCopyWithImpl(this._self, this._then);

  final CreateNoteDto _self;
  final $Res Function(CreateNoteDto) _then;

/// Create a copy of CreateNoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = freezed,Object? content = null,Object? categoryId = freezed,Object? isFavorite = null,Object? isPinned = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateNoteDto].
extension CreateNoteDtoPatterns on CreateNoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateNoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateNoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateNoteDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateNoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateNoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateNoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? description,  String content,  String? categoryId,  bool isFavorite,  bool isPinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateNoteDto() when $default != null:
return $default(_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? description,  String content,  String? categoryId,  bool isFavorite,  bool isPinned)  $default,) {final _that = this;
switch (_that) {
case _CreateNoteDto():
return $default(_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? description,  String content,  String? categoryId,  bool isFavorite,  bool isPinned)?  $default,) {final _that = this;
switch (_that) {
case _CreateNoteDto() when $default != null:
return $default(_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned);case _:
  return null;

}
}

}

/// @nodoc


class _CreateNoteDto implements CreateNoteDto {
  const _CreateNoteDto({required this.title, this.description, required this.content, this.categoryId, this.isFavorite = false, this.isPinned = false});
  

@override final  String title;
@override final  String? description;
@override final  String content;
@override final  String? categoryId;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool isPinned;

/// Create a copy of CreateNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateNoteDtoCopyWith<_CreateNoteDto> get copyWith => __$CreateNoteDtoCopyWithImpl<_CreateNoteDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateNoteDto&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,content,categoryId,isFavorite,isPinned);

@override
String toString() {
  return 'CreateNoteDto(title: $title, description: $description, content: $content, categoryId: $categoryId, isFavorite: $isFavorite, isPinned: $isPinned)';
}


}

/// @nodoc
abstract mixin class _$CreateNoteDtoCopyWith<$Res> implements $CreateNoteDtoCopyWith<$Res> {
  factory _$CreateNoteDtoCopyWith(_CreateNoteDto value, $Res Function(_CreateNoteDto) _then) = __$CreateNoteDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String? description, String content, String? categoryId, bool isFavorite, bool isPinned
});




}
/// @nodoc
class __$CreateNoteDtoCopyWithImpl<$Res>
    implements _$CreateNoteDtoCopyWith<$Res> {
  __$CreateNoteDtoCopyWithImpl(this._self, this._then);

  final _CreateNoteDto _self;
  final $Res Function(_CreateNoteDto) _then;

/// Create a copy of CreateNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = freezed,Object? content = null,Object? categoryId = freezed,Object? isFavorite = null,Object? isPinned = null,}) {
  return _then(_CreateNoteDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$UpdateNoteDto {

 String get id; String? get title; String? get description; String? get content; String? get categoryId; bool? get isFavorite; bool? get isPinned; DateTime? get lastAccessed;
/// Create a copy of UpdateNoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateNoteDtoCopyWith<UpdateNoteDto> get copyWith => _$UpdateNoteDtoCopyWithImpl<UpdateNoteDto>(this as UpdateNoteDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateNoteDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,content,categoryId,isFavorite,isPinned,lastAccessed);

@override
String toString() {
  return 'UpdateNoteDto(id: $id, title: $title, description: $description, content: $content, categoryId: $categoryId, isFavorite: $isFavorite, isPinned: $isPinned, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class $UpdateNoteDtoCopyWith<$Res>  {
  factory $UpdateNoteDtoCopyWith(UpdateNoteDto value, $Res Function(UpdateNoteDto) _then) = _$UpdateNoteDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? description, String? content, String? categoryId, bool? isFavorite, bool? isPinned, DateTime? lastAccessed
});




}
/// @nodoc
class _$UpdateNoteDtoCopyWithImpl<$Res>
    implements $UpdateNoteDtoCopyWith<$Res> {
  _$UpdateNoteDtoCopyWithImpl(this._self, this._then);

  final UpdateNoteDto _self;
  final $Res Function(UpdateNoteDto) _then;

/// Create a copy of UpdateNoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? isPinned = freezed,Object? lastAccessed = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateNoteDto].
extension UpdateNoteDtoPatterns on UpdateNoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateNoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateNoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateNoteDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateNoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateNoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateNoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? content,  String? categoryId,  bool? isFavorite,  bool? isPinned,  DateTime? lastAccessed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateNoteDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? content,  String? categoryId,  bool? isFavorite,  bool? isPinned,  DateTime? lastAccessed)  $default,) {final _that = this;
switch (_that) {
case _UpdateNoteDto():
return $default(_that.id,_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? description,  String? content,  String? categoryId,  bool? isFavorite,  bool? isPinned,  DateTime? lastAccessed)?  $default,) {final _that = this;
switch (_that) {
case _UpdateNoteDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.content,_that.categoryId,_that.isFavorite,_that.isPinned,_that.lastAccessed);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateNoteDto implements UpdateNoteDto {
  const _UpdateNoteDto({required this.id, this.title, this.description, this.content, this.categoryId, this.isFavorite, this.isPinned, this.lastAccessed});
  

@override final  String id;
@override final  String? title;
@override final  String? description;
@override final  String? content;
@override final  String? categoryId;
@override final  bool? isFavorite;
@override final  bool? isPinned;
@override final  DateTime? lastAccessed;

/// Create a copy of UpdateNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateNoteDtoCopyWith<_UpdateNoteDto> get copyWith => __$UpdateNoteDtoCopyWithImpl<_UpdateNoteDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateNoteDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,content,categoryId,isFavorite,isPinned,lastAccessed);

@override
String toString() {
  return 'UpdateNoteDto(id: $id, title: $title, description: $description, content: $content, categoryId: $categoryId, isFavorite: $isFavorite, isPinned: $isPinned, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class _$UpdateNoteDtoCopyWith<$Res> implements $UpdateNoteDtoCopyWith<$Res> {
  factory _$UpdateNoteDtoCopyWith(_UpdateNoteDto value, $Res Function(_UpdateNoteDto) _then) = __$UpdateNoteDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? description, String? content, String? categoryId, bool? isFavorite, bool? isPinned, DateTime? lastAccessed
});




}
/// @nodoc
class __$UpdateNoteDtoCopyWithImpl<$Res>
    implements _$UpdateNoteDtoCopyWith<$Res> {
  __$UpdateNoteDtoCopyWithImpl(this._self, this._then);

  final _UpdateNoteDto _self;
  final $Res Function(_UpdateNoteDto) _then;

/// Create a copy of UpdateNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? content = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? isPinned = freezed,Object? lastAccessed = freezed,}) {
  return _then(_UpdateNoteDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,isPinned: freezed == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$CreateTotpDto {

 String? get passwordId; String get name; String? get description; OtpType get type; String? get issuer; String? get accountName; String get secret;// Will be encrypted internally
 String get algorithm; int get digits; int get period; int? get counter;// Only for HOTP
 String? get categoryId; bool get isFavorite;
/// Create a copy of CreateTotpDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTotpDtoCopyWith<CreateTotpDto> get copyWith => _$CreateTotpDtoCopyWithImpl<CreateTotpDto>(this as CreateTotpDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTotpDto&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,passwordId,name,description,type,issuer,accountName,secret,algorithm,digits,period,counter,categoryId,isFavorite);

@override
String toString() {
  return 'CreateTotpDto(passwordId: $passwordId, name: $name, description: $description, type: $type, issuer: $issuer, accountName: $accountName, secret: $secret, algorithm: $algorithm, digits: $digits, period: $period, counter: $counter, categoryId: $categoryId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $CreateTotpDtoCopyWith<$Res>  {
  factory $CreateTotpDtoCopyWith(CreateTotpDto value, $Res Function(CreateTotpDto) _then) = _$CreateTotpDtoCopyWithImpl;
@useResult
$Res call({
 String? passwordId, String name, String? description, OtpType type, String? issuer, String? accountName, String secret, String algorithm, int digits, int period, int? counter, String? categoryId, bool isFavorite
});




}
/// @nodoc
class _$CreateTotpDtoCopyWithImpl<$Res>
    implements $CreateTotpDtoCopyWith<$Res> {
  _$CreateTotpDtoCopyWithImpl(this._self, this._then);

  final CreateTotpDto _self;
  final $Res Function(CreateTotpDto) _then;

/// Create a copy of CreateTotpDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passwordId = freezed,Object? name = null,Object? description = freezed,Object? type = null,Object? issuer = freezed,Object? accountName = freezed,Object? secret = null,Object? algorithm = null,Object? digits = null,Object? period = null,Object? counter = freezed,Object? categoryId = freezed,Object? isFavorite = null,}) {
  return _then(_self.copyWith(
passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OtpType,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,digits: null == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,counter: freezed == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTotpDto].
extension CreateTotpDtoPatterns on CreateTotpDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTotpDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTotpDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTotpDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateTotpDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTotpDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTotpDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? passwordId,  String name,  String? description,  OtpType type,  String? issuer,  String? accountName,  String secret,  String algorithm,  int digits,  int period,  int? counter,  String? categoryId,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTotpDto() when $default != null:
return $default(_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? passwordId,  String name,  String? description,  OtpType type,  String? issuer,  String? accountName,  String secret,  String algorithm,  int digits,  int period,  int? counter,  String? categoryId,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _CreateTotpDto():
return $default(_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? passwordId,  String name,  String? description,  OtpType type,  String? issuer,  String? accountName,  String secret,  String algorithm,  int digits,  int period,  int? counter,  String? categoryId,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _CreateTotpDto() when $default != null:
return $default(_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc


class _CreateTotpDto implements CreateTotpDto {
  const _CreateTotpDto({this.passwordId, required this.name, this.description, this.type = OtpType.totp, this.issuer, this.accountName, required this.secret, this.algorithm = 'SHA1', this.digits = 6, this.period = 30, this.counter, this.categoryId, this.isFavorite = false});
  

@override final  String? passwordId;
@override final  String name;
@override final  String? description;
@override@JsonKey() final  OtpType type;
@override final  String? issuer;
@override final  String? accountName;
@override final  String secret;
// Will be encrypted internally
@override@JsonKey() final  String algorithm;
@override@JsonKey() final  int digits;
@override@JsonKey() final  int period;
@override final  int? counter;
// Only for HOTP
@override final  String? categoryId;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of CreateTotpDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTotpDtoCopyWith<_CreateTotpDto> get copyWith => __$CreateTotpDtoCopyWithImpl<_CreateTotpDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTotpDto&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,passwordId,name,description,type,issuer,accountName,secret,algorithm,digits,period,counter,categoryId,isFavorite);

@override
String toString() {
  return 'CreateTotpDto(passwordId: $passwordId, name: $name, description: $description, type: $type, issuer: $issuer, accountName: $accountName, secret: $secret, algorithm: $algorithm, digits: $digits, period: $period, counter: $counter, categoryId: $categoryId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$CreateTotpDtoCopyWith<$Res> implements $CreateTotpDtoCopyWith<$Res> {
  factory _$CreateTotpDtoCopyWith(_CreateTotpDto value, $Res Function(_CreateTotpDto) _then) = __$CreateTotpDtoCopyWithImpl;
@override @useResult
$Res call({
 String? passwordId, String name, String? description, OtpType type, String? issuer, String? accountName, String secret, String algorithm, int digits, int period, int? counter, String? categoryId, bool isFavorite
});




}
/// @nodoc
class __$CreateTotpDtoCopyWithImpl<$Res>
    implements _$CreateTotpDtoCopyWith<$Res> {
  __$CreateTotpDtoCopyWithImpl(this._self, this._then);

  final _CreateTotpDto _self;
  final $Res Function(_CreateTotpDto) _then;

/// Create a copy of CreateTotpDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passwordId = freezed,Object? name = null,Object? description = freezed,Object? type = null,Object? issuer = freezed,Object? accountName = freezed,Object? secret = null,Object? algorithm = null,Object? digits = null,Object? period = null,Object? counter = freezed,Object? categoryId = freezed,Object? isFavorite = null,}) {
  return _then(_CreateTotpDto(
passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OtpType,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,digits: null == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,counter: freezed == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$UpdateTotpDto {

 String get id; String? get passwordId; String? get name; String? get description; OtpType? get type; String? get issuer; String? get accountName; String? get secret;// Will be encrypted internally
 String? get algorithm; int? get digits; int? get period; int? get counter; String? get categoryId; bool? get isFavorite; DateTime? get lastAccessed;
/// Create a copy of UpdateTotpDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateTotpDtoCopyWith<UpdateTotpDto> get copyWith => _$UpdateTotpDtoCopyWithImpl<UpdateTotpDto>(this as UpdateTotpDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateTotpDto&&(identical(other.id, id) || other.id == id)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,passwordId,name,description,type,issuer,accountName,secret,algorithm,digits,period,counter,categoryId,isFavorite,lastAccessed);

@override
String toString() {
  return 'UpdateTotpDto(id: $id, passwordId: $passwordId, name: $name, description: $description, type: $type, issuer: $issuer, accountName: $accountName, secret: $secret, algorithm: $algorithm, digits: $digits, period: $period, counter: $counter, categoryId: $categoryId, isFavorite: $isFavorite, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class $UpdateTotpDtoCopyWith<$Res>  {
  factory $UpdateTotpDtoCopyWith(UpdateTotpDto value, $Res Function(UpdateTotpDto) _then) = _$UpdateTotpDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? passwordId, String? name, String? description, OtpType? type, String? issuer, String? accountName, String? secret, String? algorithm, int? digits, int? period, int? counter, String? categoryId, bool? isFavorite, DateTime? lastAccessed
});




}
/// @nodoc
class _$UpdateTotpDtoCopyWithImpl<$Res>
    implements $UpdateTotpDtoCopyWith<$Res> {
  _$UpdateTotpDtoCopyWithImpl(this._self, this._then);

  final UpdateTotpDto _self;
  final $Res Function(UpdateTotpDto) _then;

/// Create a copy of UpdateTotpDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? passwordId = freezed,Object? name = freezed,Object? description = freezed,Object? type = freezed,Object? issuer = freezed,Object? accountName = freezed,Object? secret = freezed,Object? algorithm = freezed,Object? digits = freezed,Object? period = freezed,Object? counter = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? lastAccessed = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OtpType?,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,secret: freezed == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String?,algorithm: freezed == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String?,digits: freezed == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,counter: freezed == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateTotpDto].
extension UpdateTotpDtoPatterns on UpdateTotpDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateTotpDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateTotpDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateTotpDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateTotpDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateTotpDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateTotpDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? passwordId,  String? name,  String? description,  OtpType? type,  String? issuer,  String? accountName,  String? secret,  String? algorithm,  int? digits,  int? period,  int? counter,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateTotpDto() when $default != null:
return $default(_that.id,_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? passwordId,  String? name,  String? description,  OtpType? type,  String? issuer,  String? accountName,  String? secret,  String? algorithm,  int? digits,  int? period,  int? counter,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)  $default,) {final _that = this;
switch (_that) {
case _UpdateTotpDto():
return $default(_that.id,_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? passwordId,  String? name,  String? description,  OtpType? type,  String? issuer,  String? accountName,  String? secret,  String? algorithm,  int? digits,  int? period,  int? counter,  String? categoryId,  bool? isFavorite,  DateTime? lastAccessed)?  $default,) {final _that = this;
switch (_that) {
case _UpdateTotpDto() when $default != null:
return $default(_that.id,_that.passwordId,_that.name,_that.description,_that.type,_that.issuer,_that.accountName,_that.secret,_that.algorithm,_that.digits,_that.period,_that.counter,_that.categoryId,_that.isFavorite,_that.lastAccessed);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateTotpDto implements UpdateTotpDto {
  const _UpdateTotpDto({required this.id, this.passwordId, this.name, this.description, this.type, this.issuer, this.accountName, this.secret, this.algorithm, this.digits, this.period, this.counter, this.categoryId, this.isFavorite, this.lastAccessed});
  

@override final  String id;
@override final  String? passwordId;
@override final  String? name;
@override final  String? description;
@override final  OtpType? type;
@override final  String? issuer;
@override final  String? accountName;
@override final  String? secret;
// Will be encrypted internally
@override final  String? algorithm;
@override final  int? digits;
@override final  int? period;
@override final  int? counter;
@override final  String? categoryId;
@override final  bool? isFavorite;
@override final  DateTime? lastAccessed;

/// Create a copy of UpdateTotpDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTotpDtoCopyWith<_UpdateTotpDto> get copyWith => __$UpdateTotpDtoCopyWithImpl<_UpdateTotpDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTotpDto&&(identical(other.id, id) || other.id == id)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed));
}


@override
int get hashCode => Object.hash(runtimeType,id,passwordId,name,description,type,issuer,accountName,secret,algorithm,digits,period,counter,categoryId,isFavorite,lastAccessed);

@override
String toString() {
  return 'UpdateTotpDto(id: $id, passwordId: $passwordId, name: $name, description: $description, type: $type, issuer: $issuer, accountName: $accountName, secret: $secret, algorithm: $algorithm, digits: $digits, period: $period, counter: $counter, categoryId: $categoryId, isFavorite: $isFavorite, lastAccessed: $lastAccessed)';
}


}

/// @nodoc
abstract mixin class _$UpdateTotpDtoCopyWith<$Res> implements $UpdateTotpDtoCopyWith<$Res> {
  factory _$UpdateTotpDtoCopyWith(_UpdateTotpDto value, $Res Function(_UpdateTotpDto) _then) = __$UpdateTotpDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? passwordId, String? name, String? description, OtpType? type, String? issuer, String? accountName, String? secret, String? algorithm, int? digits, int? period, int? counter, String? categoryId, bool? isFavorite, DateTime? lastAccessed
});




}
/// @nodoc
class __$UpdateTotpDtoCopyWithImpl<$Res>
    implements _$UpdateTotpDtoCopyWith<$Res> {
  __$UpdateTotpDtoCopyWithImpl(this._self, this._then);

  final _UpdateTotpDto _self;
  final $Res Function(_UpdateTotpDto) _then;

/// Create a copy of UpdateTotpDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? passwordId = freezed,Object? name = freezed,Object? description = freezed,Object? type = freezed,Object? issuer = freezed,Object? accountName = freezed,Object? secret = freezed,Object? algorithm = freezed,Object? digits = freezed,Object? period = freezed,Object? counter = freezed,Object? categoryId = freezed,Object? isFavorite = freezed,Object? lastAccessed = freezed,}) {
  return _then(_UpdateTotpDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OtpType?,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,secret: freezed == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String?,algorithm: freezed == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String?,digits: freezed == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,counter: freezed == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,lastAccessed: freezed == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$CreateCategoryDto {

 String get name; String? get description; String? get iconId; String get color; CategoryType get type;
/// Create a copy of CreateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCategoryDtoCopyWith<CreateCategoryDto> get copyWith => _$CreateCategoryDtoCopyWithImpl<CreateCategoryDto>(this as CreateCategoryDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateCategoryDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconId, iconId) || other.iconId == iconId)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,iconId,color,type);

@override
String toString() {
  return 'CreateCategoryDto(name: $name, description: $description, iconId: $iconId, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class $CreateCategoryDtoCopyWith<$Res>  {
  factory $CreateCategoryDtoCopyWith(CreateCategoryDto value, $Res Function(CreateCategoryDto) _then) = _$CreateCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String? iconId, String color, CategoryType type
});




}
/// @nodoc
class _$CreateCategoryDtoCopyWithImpl<$Res>
    implements $CreateCategoryDtoCopyWith<$Res> {
  _$CreateCategoryDtoCopyWithImpl(this._self, this._then);

  final CreateCategoryDto _self;
  final $Res Function(CreateCategoryDto) _then;

/// Create a copy of CreateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? iconId = freezed,Object? color = null,Object? type = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconId: freezed == iconId ? _self.iconId : iconId // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateCategoryDto].
extension CreateCategoryDtoPatterns on CreateCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description,  String? iconId,  String color,  CategoryType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateCategoryDto() when $default != null:
return $default(_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description,  String? iconId,  String color,  CategoryType type)  $default,) {final _that = this;
switch (_that) {
case _CreateCategoryDto():
return $default(_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description,  String? iconId,  String color,  CategoryType type)?  $default,) {final _that = this;
switch (_that) {
case _CreateCategoryDto() when $default != null:
return $default(_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _CreateCategoryDto implements CreateCategoryDto {
  const _CreateCategoryDto({required this.name, this.description, this.iconId, this.color = 'FFFFFF', required this.type});
  

@override final  String name;
@override final  String? description;
@override final  String? iconId;
@override@JsonKey() final  String color;
@override final  CategoryType type;

/// Create a copy of CreateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateCategoryDtoCopyWith<_CreateCategoryDto> get copyWith => __$CreateCategoryDtoCopyWithImpl<_CreateCategoryDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateCategoryDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconId, iconId) || other.iconId == iconId)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,iconId,color,type);

@override
String toString() {
  return 'CreateCategoryDto(name: $name, description: $description, iconId: $iconId, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class _$CreateCategoryDtoCopyWith<$Res> implements $CreateCategoryDtoCopyWith<$Res> {
  factory _$CreateCategoryDtoCopyWith(_CreateCategoryDto value, $Res Function(_CreateCategoryDto) _then) = __$CreateCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String? iconId, String color, CategoryType type
});




}
/// @nodoc
class __$CreateCategoryDtoCopyWithImpl<$Res>
    implements _$CreateCategoryDtoCopyWith<$Res> {
  __$CreateCategoryDtoCopyWithImpl(this._self, this._then);

  final _CreateCategoryDto _self;
  final $Res Function(_CreateCategoryDto) _then;

/// Create a copy of CreateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? iconId = freezed,Object? color = null,Object? type = null,}) {
  return _then(_CreateCategoryDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconId: freezed == iconId ? _self.iconId : iconId // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,
  ));
}


}

/// @nodoc
mixin _$UpdateCategoryDto {

 String get id; String? get name; String? get description; String? get iconId; String? get color; CategoryType? get type;
/// Create a copy of UpdateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCategoryDtoCopyWith<UpdateCategoryDto> get copyWith => _$UpdateCategoryDtoCopyWithImpl<UpdateCategoryDto>(this as UpdateCategoryDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconId, iconId) || other.iconId == iconId)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,iconId,color,type);

@override
String toString() {
  return 'UpdateCategoryDto(id: $id, name: $name, description: $description, iconId: $iconId, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class $UpdateCategoryDtoCopyWith<$Res>  {
  factory $UpdateCategoryDtoCopyWith(UpdateCategoryDto value, $Res Function(UpdateCategoryDto) _then) = _$UpdateCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? description, String? iconId, String? color, CategoryType? type
});




}
/// @nodoc
class _$UpdateCategoryDtoCopyWithImpl<$Res>
    implements $UpdateCategoryDtoCopyWith<$Res> {
  _$UpdateCategoryDtoCopyWithImpl(this._self, this._then);

  final UpdateCategoryDto _self;
  final $Res Function(UpdateCategoryDto) _then;

/// Create a copy of UpdateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? iconId = freezed,Object? color = freezed,Object? type = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconId: freezed == iconId ? _self.iconId : iconId // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateCategoryDto].
extension UpdateCategoryDtoPatterns on UpdateCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? iconId,  String? color,  CategoryType? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? iconId,  String? color,  CategoryType? type)  $default,) {final _that = this;
switch (_that) {
case _UpdateCategoryDto():
return $default(_that.id,_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? description,  String? iconId,  String? color,  CategoryType? type)?  $default,) {final _that = this;
switch (_that) {
case _UpdateCategoryDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.iconId,_that.color,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateCategoryDto implements UpdateCategoryDto {
  const _UpdateCategoryDto({required this.id, this.name, this.description, this.iconId, this.color, this.type});
  

@override final  String id;
@override final  String? name;
@override final  String? description;
@override final  String? iconId;
@override final  String? color;
@override final  CategoryType? type;

/// Create a copy of UpdateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCategoryDtoCopyWith<_UpdateCategoryDto> get copyWith => __$UpdateCategoryDtoCopyWithImpl<_UpdateCategoryDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCategoryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconId, iconId) || other.iconId == iconId)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,iconId,color,type);

@override
String toString() {
  return 'UpdateCategoryDto(id: $id, name: $name, description: $description, iconId: $iconId, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class _$UpdateCategoryDtoCopyWith<$Res> implements $UpdateCategoryDtoCopyWith<$Res> {
  factory _$UpdateCategoryDtoCopyWith(_UpdateCategoryDto value, $Res Function(_UpdateCategoryDto) _then) = __$UpdateCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? description, String? iconId, String? color, CategoryType? type
});




}
/// @nodoc
class __$UpdateCategoryDtoCopyWithImpl<$Res>
    implements _$UpdateCategoryDtoCopyWith<$Res> {
  __$UpdateCategoryDtoCopyWithImpl(this._self, this._then);

  final _UpdateCategoryDto _self;
  final $Res Function(_UpdateCategoryDto) _then;

/// Create a copy of UpdateCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? iconId = freezed,Object? color = freezed,Object? type = freezed,}) {
  return _then(_UpdateCategoryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconId: freezed == iconId ? _self.iconId : iconId // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType?,
  ));
}


}

/// @nodoc
mixin _$CreateTagDto {

 String get name; String? get color; TagType get type;
/// Create a copy of CreateTagDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTagDtoCopyWith<CreateTagDto> get copyWith => _$CreateTagDtoCopyWithImpl<CreateTagDto>(this as CreateTagDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTagDto&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,name,color,type);

@override
String toString() {
  return 'CreateTagDto(name: $name, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class $CreateTagDtoCopyWith<$Res>  {
  factory $CreateTagDtoCopyWith(CreateTagDto value, $Res Function(CreateTagDto) _then) = _$CreateTagDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? color, TagType type
});




}
/// @nodoc
class _$CreateTagDtoCopyWithImpl<$Res>
    implements $CreateTagDtoCopyWith<$Res> {
  _$CreateTagDtoCopyWithImpl(this._self, this._then);

  final CreateTagDto _self;
  final $Res Function(CreateTagDto) _then;

/// Create a copy of CreateTagDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? color = freezed,Object? type = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TagType,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTagDto].
extension CreateTagDtoPatterns on CreateTagDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTagDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTagDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTagDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateTagDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTagDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTagDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? color,  TagType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTagDto() when $default != null:
return $default(_that.name,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? color,  TagType type)  $default,) {final _that = this;
switch (_that) {
case _CreateTagDto():
return $default(_that.name,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? color,  TagType type)?  $default,) {final _that = this;
switch (_that) {
case _CreateTagDto() when $default != null:
return $default(_that.name,_that.color,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _CreateTagDto implements CreateTagDto {
  const _CreateTagDto({required this.name, this.color, required this.type});
  

@override final  String name;
@override final  String? color;
@override final  TagType type;

/// Create a copy of CreateTagDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTagDtoCopyWith<_CreateTagDto> get copyWith => __$CreateTagDtoCopyWithImpl<_CreateTagDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTagDto&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,name,color,type);

@override
String toString() {
  return 'CreateTagDto(name: $name, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class _$CreateTagDtoCopyWith<$Res> implements $CreateTagDtoCopyWith<$Res> {
  factory _$CreateTagDtoCopyWith(_CreateTagDto value, $Res Function(_CreateTagDto) _then) = __$CreateTagDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? color, TagType type
});




}
/// @nodoc
class __$CreateTagDtoCopyWithImpl<$Res>
    implements _$CreateTagDtoCopyWith<$Res> {
  __$CreateTagDtoCopyWithImpl(this._self, this._then);

  final _CreateTagDto _self;
  final $Res Function(_CreateTagDto) _then;

/// Create a copy of CreateTagDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? color = freezed,Object? type = null,}) {
  return _then(_CreateTagDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TagType,
  ));
}


}

/// @nodoc
mixin _$UpdateTagDto {

 String get id; String? get name; String? get color; TagType? get type;
/// Create a copy of UpdateTagDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateTagDtoCopyWith<UpdateTagDto> get copyWith => _$UpdateTagDtoCopyWithImpl<UpdateTagDto>(this as UpdateTagDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateTagDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,type);

@override
String toString() {
  return 'UpdateTagDto(id: $id, name: $name, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class $UpdateTagDtoCopyWith<$Res>  {
  factory $UpdateTagDtoCopyWith(UpdateTagDto value, $Res Function(UpdateTagDto) _then) = _$UpdateTagDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? color, TagType? type
});




}
/// @nodoc
class _$UpdateTagDtoCopyWithImpl<$Res>
    implements $UpdateTagDtoCopyWith<$Res> {
  _$UpdateTagDtoCopyWithImpl(this._self, this._then);

  final UpdateTagDto _self;
  final $Res Function(UpdateTagDto) _then;

/// Create a copy of UpdateTagDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? color = freezed,Object? type = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TagType?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateTagDto].
extension UpdateTagDtoPatterns on UpdateTagDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateTagDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateTagDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateTagDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateTagDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateTagDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateTagDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? color,  TagType? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateTagDto() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? color,  TagType? type)  $default,) {final _that = this;
switch (_that) {
case _UpdateTagDto():
return $default(_that.id,_that.name,_that.color,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? color,  TagType? type)?  $default,) {final _that = this;
switch (_that) {
case _UpdateTagDto() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateTagDto implements UpdateTagDto {
  const _UpdateTagDto({required this.id, this.name, this.color, this.type});
  

@override final  String id;
@override final  String? name;
@override final  String? color;
@override final  TagType? type;

/// Create a copy of UpdateTagDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTagDtoCopyWith<_UpdateTagDto> get copyWith => __$UpdateTagDtoCopyWithImpl<_UpdateTagDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTagDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,type);

@override
String toString() {
  return 'UpdateTagDto(id: $id, name: $name, color: $color, type: $type)';
}


}

/// @nodoc
abstract mixin class _$UpdateTagDtoCopyWith<$Res> implements $UpdateTagDtoCopyWith<$Res> {
  factory _$UpdateTagDtoCopyWith(_UpdateTagDto value, $Res Function(_UpdateTagDto) _then) = __$UpdateTagDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? color, TagType? type
});




}
/// @nodoc
class __$UpdateTagDtoCopyWithImpl<$Res>
    implements _$UpdateTagDtoCopyWith<$Res> {
  __$UpdateTagDtoCopyWithImpl(this._self, this._then);

  final _UpdateTagDto _self;
  final $Res Function(_UpdateTagDto) _then;

/// Create a copy of UpdateTagDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? color = freezed,Object? type = freezed,}) {
  return _then(_UpdateTagDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TagType?,
  ));
}


}

/// @nodoc
mixin _$CreateIconDto {

 String get name; IconType get type; Uint8List get data;
/// Create a copy of CreateIconDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateIconDtoCopyWith<CreateIconDto> get copyWith => _$CreateIconDtoCopyWithImpl<CreateIconDto>(this as CreateIconDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateIconDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,name,type,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'CreateIconDto(name: $name, type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class $CreateIconDtoCopyWith<$Res>  {
  factory $CreateIconDtoCopyWith(CreateIconDto value, $Res Function(CreateIconDto) _then) = _$CreateIconDtoCopyWithImpl;
@useResult
$Res call({
 String name, IconType type, Uint8List data
});




}
/// @nodoc
class _$CreateIconDtoCopyWithImpl<$Res>
    implements $CreateIconDtoCopyWith<$Res> {
  _$CreateIconDtoCopyWithImpl(this._self, this._then);

  final CreateIconDto _self;
  final $Res Function(CreateIconDto) _then;

/// Create a copy of CreateIconDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? data = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IconType,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateIconDto].
extension CreateIconDtoPatterns on CreateIconDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateIconDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateIconDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateIconDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateIconDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateIconDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateIconDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  IconType type,  Uint8List data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateIconDto() when $default != null:
return $default(_that.name,_that.type,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  IconType type,  Uint8List data)  $default,) {final _that = this;
switch (_that) {
case _CreateIconDto():
return $default(_that.name,_that.type,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  IconType type,  Uint8List data)?  $default,) {final _that = this;
switch (_that) {
case _CreateIconDto() when $default != null:
return $default(_that.name,_that.type,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _CreateIconDto implements CreateIconDto {
  const _CreateIconDto({required this.name, required this.type, required this.data});
  

@override final  String name;
@override final  IconType type;
@override final  Uint8List data;

/// Create a copy of CreateIconDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateIconDtoCopyWith<_CreateIconDto> get copyWith => __$CreateIconDtoCopyWithImpl<_CreateIconDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateIconDto&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,name,type,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'CreateIconDto(name: $name, type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CreateIconDtoCopyWith<$Res> implements $CreateIconDtoCopyWith<$Res> {
  factory _$CreateIconDtoCopyWith(_CreateIconDto value, $Res Function(_CreateIconDto) _then) = __$CreateIconDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, IconType type, Uint8List data
});




}
/// @nodoc
class __$CreateIconDtoCopyWithImpl<$Res>
    implements _$CreateIconDtoCopyWith<$Res> {
  __$CreateIconDtoCopyWithImpl(this._self, this._then);

  final _CreateIconDto _self;
  final $Res Function(_CreateIconDto) _then;

/// Create a copy of CreateIconDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? data = null,}) {
  return _then(_CreateIconDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IconType,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$UpdateIconDto {

 String get id; String? get name; IconType? get type; Uint8List? get data;
/// Create a copy of UpdateIconDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateIconDtoCopyWith<UpdateIconDto> get copyWith => _$UpdateIconDtoCopyWithImpl<UpdateIconDto>(this as UpdateIconDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateIconDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'UpdateIconDto(id: $id, name: $name, type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class $UpdateIconDtoCopyWith<$Res>  {
  factory $UpdateIconDtoCopyWith(UpdateIconDto value, $Res Function(UpdateIconDto) _then) = _$UpdateIconDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? name, IconType? type, Uint8List? data
});




}
/// @nodoc
class _$UpdateIconDtoCopyWithImpl<$Res>
    implements $UpdateIconDtoCopyWith<$Res> {
  _$UpdateIconDtoCopyWithImpl(this._self, this._then);

  final UpdateIconDto _self;
  final $Res Function(UpdateIconDto) _then;

/// Create a copy of UpdateIconDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? type = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IconType?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateIconDto].
extension UpdateIconDtoPatterns on UpdateIconDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateIconDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateIconDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateIconDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateIconDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateIconDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateIconDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  IconType? type,  Uint8List? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateIconDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  IconType? type,  Uint8List? data)  $default,) {final _that = this;
switch (_that) {
case _UpdateIconDto():
return $default(_that.id,_that.name,_that.type,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  IconType? type,  Uint8List? data)?  $default,) {final _that = this;
switch (_that) {
case _UpdateIconDto() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateIconDto implements UpdateIconDto {
  const _UpdateIconDto({required this.id, this.name, this.type, this.data});
  

@override final  String id;
@override final  String? name;
@override final  IconType? type;
@override final  Uint8List? data;

/// Create a copy of UpdateIconDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateIconDtoCopyWith<_UpdateIconDto> get copyWith => __$UpdateIconDtoCopyWithImpl<_UpdateIconDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateIconDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'UpdateIconDto(id: $id, name: $name, type: $type, data: $data)';
}


}

/// @nodoc
abstract mixin class _$UpdateIconDtoCopyWith<$Res> implements $UpdateIconDtoCopyWith<$Res> {
  factory _$UpdateIconDtoCopyWith(_UpdateIconDto value, $Res Function(_UpdateIconDto) _then) = __$UpdateIconDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, IconType? type, Uint8List? data
});




}
/// @nodoc
class __$UpdateIconDtoCopyWithImpl<$Res>
    implements _$UpdateIconDtoCopyWith<$Res> {
  __$UpdateIconDtoCopyWithImpl(this._self, this._then);

  final _UpdateIconDto _self;
  final $Res Function(_UpdateIconDto) _then;

/// Create a copy of UpdateIconDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? type = freezed,Object? data = freezed,}) {
  return _then(_UpdateIconDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IconType?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

/// @nodoc
mixin _$CreateAttachmentDto {

 String get name; String? get description; String get filePath; String get mimeType; int get fileSize; String? get checksum; String? get passwordId; String? get totpId; String? get noteId;
/// Create a copy of CreateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateAttachmentDtoCopyWith<CreateAttachmentDto> get copyWith => _$CreateAttachmentDtoCopyWithImpl<CreateAttachmentDto>(this as CreateAttachmentDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAttachmentDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.totpId, totpId) || other.totpId == totpId)&&(identical(other.noteId, noteId) || other.noteId == noteId));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,filePath,mimeType,fileSize,checksum,passwordId,totpId,noteId);

@override
String toString() {
  return 'CreateAttachmentDto(name: $name, description: $description, filePath: $filePath, mimeType: $mimeType, fileSize: $fileSize, checksum: $checksum, passwordId: $passwordId, totpId: $totpId, noteId: $noteId)';
}


}

/// @nodoc
abstract mixin class $CreateAttachmentDtoCopyWith<$Res>  {
  factory $CreateAttachmentDtoCopyWith(CreateAttachmentDto value, $Res Function(CreateAttachmentDto) _then) = _$CreateAttachmentDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? description, String filePath, String mimeType, int fileSize, String? checksum, String? passwordId, String? totpId, String? noteId
});




}
/// @nodoc
class _$CreateAttachmentDtoCopyWithImpl<$Res>
    implements $CreateAttachmentDtoCopyWith<$Res> {
  _$CreateAttachmentDtoCopyWithImpl(this._self, this._then);

  final CreateAttachmentDto _self;
  final $Res Function(CreateAttachmentDto) _then;

/// Create a copy of CreateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,Object? filePath = null,Object? mimeType = null,Object? fileSize = null,Object? checksum = freezed,Object? passwordId = freezed,Object? totpId = freezed,Object? noteId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,totpId: freezed == totpId ? _self.totpId : totpId // ignore: cast_nullable_to_non_nullable
as String?,noteId: freezed == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateAttachmentDto].
extension CreateAttachmentDtoPatterns on CreateAttachmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateAttachmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateAttachmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateAttachmentDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateAttachmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateAttachmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateAttachmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? description,  String filePath,  String mimeType,  int fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateAttachmentDto() when $default != null:
return $default(_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? description,  String filePath,  String mimeType,  int fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)  $default,) {final _that = this;
switch (_that) {
case _CreateAttachmentDto():
return $default(_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? description,  String filePath,  String mimeType,  int fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)?  $default,) {final _that = this;
switch (_that) {
case _CreateAttachmentDto() when $default != null:
return $default(_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
  return null;

}
}

}

/// @nodoc


class _CreateAttachmentDto implements CreateAttachmentDto {
  const _CreateAttachmentDto({required this.name, this.description, required this.filePath, required this.mimeType, required this.fileSize, this.checksum, this.passwordId, this.totpId, this.noteId});
  

@override final  String name;
@override final  String? description;
@override final  String filePath;
@override final  String mimeType;
@override final  int fileSize;
@override final  String? checksum;
@override final  String? passwordId;
@override final  String? totpId;
@override final  String? noteId;

/// Create a copy of CreateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateAttachmentDtoCopyWith<_CreateAttachmentDto> get copyWith => __$CreateAttachmentDtoCopyWithImpl<_CreateAttachmentDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateAttachmentDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.totpId, totpId) || other.totpId == totpId)&&(identical(other.noteId, noteId) || other.noteId == noteId));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,filePath,mimeType,fileSize,checksum,passwordId,totpId,noteId);

@override
String toString() {
  return 'CreateAttachmentDto(name: $name, description: $description, filePath: $filePath, mimeType: $mimeType, fileSize: $fileSize, checksum: $checksum, passwordId: $passwordId, totpId: $totpId, noteId: $noteId)';
}


}

/// @nodoc
abstract mixin class _$CreateAttachmentDtoCopyWith<$Res> implements $CreateAttachmentDtoCopyWith<$Res> {
  factory _$CreateAttachmentDtoCopyWith(_CreateAttachmentDto value, $Res Function(_CreateAttachmentDto) _then) = __$CreateAttachmentDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? description, String filePath, String mimeType, int fileSize, String? checksum, String? passwordId, String? totpId, String? noteId
});




}
/// @nodoc
class __$CreateAttachmentDtoCopyWithImpl<$Res>
    implements _$CreateAttachmentDtoCopyWith<$Res> {
  __$CreateAttachmentDtoCopyWithImpl(this._self, this._then);

  final _CreateAttachmentDto _self;
  final $Res Function(_CreateAttachmentDto) _then;

/// Create a copy of CreateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? filePath = null,Object? mimeType = null,Object? fileSize = null,Object? checksum = freezed,Object? passwordId = freezed,Object? totpId = freezed,Object? noteId = freezed,}) {
  return _then(_CreateAttachmentDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,totpId: freezed == totpId ? _self.totpId : totpId // ignore: cast_nullable_to_non_nullable
as String?,noteId: freezed == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UpdateAttachmentDto {

 String get id; String? get name; String? get description; String? get filePath; String? get mimeType; int? get fileSize; String? get checksum; String? get passwordId; String? get totpId; String? get noteId;
/// Create a copy of UpdateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateAttachmentDtoCopyWith<UpdateAttachmentDto> get copyWith => _$UpdateAttachmentDtoCopyWithImpl<UpdateAttachmentDto>(this as UpdateAttachmentDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateAttachmentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.totpId, totpId) || other.totpId == totpId)&&(identical(other.noteId, noteId) || other.noteId == noteId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,filePath,mimeType,fileSize,checksum,passwordId,totpId,noteId);

@override
String toString() {
  return 'UpdateAttachmentDto(id: $id, name: $name, description: $description, filePath: $filePath, mimeType: $mimeType, fileSize: $fileSize, checksum: $checksum, passwordId: $passwordId, totpId: $totpId, noteId: $noteId)';
}


}

/// @nodoc
abstract mixin class $UpdateAttachmentDtoCopyWith<$Res>  {
  factory $UpdateAttachmentDtoCopyWith(UpdateAttachmentDto value, $Res Function(UpdateAttachmentDto) _then) = _$UpdateAttachmentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? description, String? filePath, String? mimeType, int? fileSize, String? checksum, String? passwordId, String? totpId, String? noteId
});




}
/// @nodoc
class _$UpdateAttachmentDtoCopyWithImpl<$Res>
    implements $UpdateAttachmentDtoCopyWith<$Res> {
  _$UpdateAttachmentDtoCopyWithImpl(this._self, this._then);

  final UpdateAttachmentDto _self;
  final $Res Function(UpdateAttachmentDto) _then;

/// Create a copy of UpdateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? filePath = freezed,Object? mimeType = freezed,Object? fileSize = freezed,Object? checksum = freezed,Object? passwordId = freezed,Object? totpId = freezed,Object? noteId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,totpId: freezed == totpId ? _self.totpId : totpId // ignore: cast_nullable_to_non_nullable
as String?,noteId: freezed == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateAttachmentDto].
extension UpdateAttachmentDtoPatterns on UpdateAttachmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateAttachmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateAttachmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateAttachmentDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateAttachmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateAttachmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateAttachmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? filePath,  String? mimeType,  int? fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateAttachmentDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? description,  String? filePath,  String? mimeType,  int? fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)  $default,) {final _that = this;
switch (_that) {
case _UpdateAttachmentDto():
return $default(_that.id,_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? description,  String? filePath,  String? mimeType,  int? fileSize,  String? checksum,  String? passwordId,  String? totpId,  String? noteId)?  $default,) {final _that = this;
switch (_that) {
case _UpdateAttachmentDto() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.filePath,_that.mimeType,_that.fileSize,_that.checksum,_that.passwordId,_that.totpId,_that.noteId);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateAttachmentDto implements UpdateAttachmentDto {
  const _UpdateAttachmentDto({required this.id, this.name, this.description, this.filePath, this.mimeType, this.fileSize, this.checksum, this.passwordId, this.totpId, this.noteId});
  

@override final  String id;
@override final  String? name;
@override final  String? description;
@override final  String? filePath;
@override final  String? mimeType;
@override final  int? fileSize;
@override final  String? checksum;
@override final  String? passwordId;
@override final  String? totpId;
@override final  String? noteId;

/// Create a copy of UpdateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateAttachmentDtoCopyWith<_UpdateAttachmentDto> get copyWith => __$UpdateAttachmentDtoCopyWithImpl<_UpdateAttachmentDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateAttachmentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.passwordId, passwordId) || other.passwordId == passwordId)&&(identical(other.totpId, totpId) || other.totpId == totpId)&&(identical(other.noteId, noteId) || other.noteId == noteId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,filePath,mimeType,fileSize,checksum,passwordId,totpId,noteId);

@override
String toString() {
  return 'UpdateAttachmentDto(id: $id, name: $name, description: $description, filePath: $filePath, mimeType: $mimeType, fileSize: $fileSize, checksum: $checksum, passwordId: $passwordId, totpId: $totpId, noteId: $noteId)';
}


}

/// @nodoc
abstract mixin class _$UpdateAttachmentDtoCopyWith<$Res> implements $UpdateAttachmentDtoCopyWith<$Res> {
  factory _$UpdateAttachmentDtoCopyWith(_UpdateAttachmentDto value, $Res Function(_UpdateAttachmentDto) _then) = __$UpdateAttachmentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? description, String? filePath, String? mimeType, int? fileSize, String? checksum, String? passwordId, String? totpId, String? noteId
});




}
/// @nodoc
class __$UpdateAttachmentDtoCopyWithImpl<$Res>
    implements _$UpdateAttachmentDtoCopyWith<$Res> {
  __$UpdateAttachmentDtoCopyWithImpl(this._self, this._then);

  final _UpdateAttachmentDto _self;
  final $Res Function(_UpdateAttachmentDto) _then;

/// Create a copy of UpdateAttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? description = freezed,Object? filePath = freezed,Object? mimeType = freezed,Object? fileSize = freezed,Object? checksum = freezed,Object? passwordId = freezed,Object? totpId = freezed,Object? noteId = freezed,}) {
  return _then(_UpdateAttachmentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,passwordId: freezed == passwordId ? _self.passwordId : passwordId // ignore: cast_nullable_to_non_nullable
as String?,totpId: freezed == totpId ? _self.totpId : totpId // ignore: cast_nullable_to_non_nullable
as String?,noteId: freezed == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
