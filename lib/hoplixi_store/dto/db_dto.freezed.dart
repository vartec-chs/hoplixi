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

// dart format on
