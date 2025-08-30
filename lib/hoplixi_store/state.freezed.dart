// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DatabaseState {

 String? get path; String? get name; DatabaseStatus get status; DatabaseError? get error;
/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseStateCopyWith<DatabaseState> get copyWith => _$DatabaseStateCopyWithImpl<DatabaseState>(this as DatabaseState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseState&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,status,error);

@override
String toString() {
  return 'DatabaseState(path: $path, name: $name, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class $DatabaseStateCopyWith<$Res>  {
  factory $DatabaseStateCopyWith(DatabaseState value, $Res Function(DatabaseState) _then) = _$DatabaseStateCopyWithImpl;
@useResult
$Res call({
 String? path, String? name, DatabaseStatus status, DatabaseError? error
});


$DatabaseErrorCopyWith<$Res>? get error;

}
/// @nodoc
class _$DatabaseStateCopyWithImpl<$Res>
    implements $DatabaseStateCopyWith<$Res> {
  _$DatabaseStateCopyWithImpl(this._self, this._then);

  final DatabaseState _self;
  final $Res Function(DatabaseState) _then;

/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = freezed,Object? name = freezed,Object? status = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DatabaseStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as DatabaseError?,
  ));
}
/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DatabaseErrorCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $DatabaseErrorCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [DatabaseState].
extension DatabaseStatePatterns on DatabaseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseState value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseState value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? path,  String? name,  DatabaseStatus status,  DatabaseError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseState() when $default != null:
return $default(_that.path,_that.name,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? path,  String? name,  DatabaseStatus status,  DatabaseError? error)  $default,) {final _that = this;
switch (_that) {
case _DatabaseState():
return $default(_that.path,_that.name,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? path,  String? name,  DatabaseStatus status,  DatabaseError? error)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseState() when $default != null:
return $default(_that.path,_that.name,_that.status,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _DatabaseState extends DatabaseState {
  const _DatabaseState({this.path, this.name, this.status = DatabaseStatus.closed, this.error}): super._();
  

@override final  String? path;
@override final  String? name;
@override@JsonKey() final  DatabaseStatus status;
@override final  DatabaseError? error;

/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseStateCopyWith<_DatabaseState> get copyWith => __$DatabaseStateCopyWithImpl<_DatabaseState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseState&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,status,error);

@override
String toString() {
  return 'DatabaseState(path: $path, name: $name, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DatabaseStateCopyWith<$Res> implements $DatabaseStateCopyWith<$Res> {
  factory _$DatabaseStateCopyWith(_DatabaseState value, $Res Function(_DatabaseState) _then) = __$DatabaseStateCopyWithImpl;
@override @useResult
$Res call({
 String? path, String? name, DatabaseStatus status, DatabaseError? error
});


@override $DatabaseErrorCopyWith<$Res>? get error;

}
/// @nodoc
class __$DatabaseStateCopyWithImpl<$Res>
    implements _$DatabaseStateCopyWith<$Res> {
  __$DatabaseStateCopyWithImpl(this._self, this._then);

  final _DatabaseState _self;
  final $Res Function(_DatabaseState) _then;

/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = freezed,Object? name = freezed,Object? status = null,Object? error = freezed,}) {
  return _then(_DatabaseState(
path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DatabaseStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as DatabaseError?,
  ));
}

/// Create a copy of DatabaseState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DatabaseErrorCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $DatabaseErrorCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on
