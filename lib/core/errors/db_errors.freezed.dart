// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'db_errors.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DatabaseError {

 String get code; String? get message; Map<String, dynamic>? get data;
/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseErrorCopyWith<DatabaseError> get copyWith => _$DatabaseErrorCopyWithImpl<DatabaseError>(this as DatabaseError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DatabaseError(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $DatabaseErrorCopyWith<$Res>  {
  factory $DatabaseErrorCopyWith(DatabaseError value, $Res Function(DatabaseError) _then) = _$DatabaseErrorCopyWithImpl;
@useResult
$Res call({
 String code, String message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$DatabaseErrorCopyWithImpl<$Res>
    implements $DatabaseErrorCopyWith<$Res> {
  _$DatabaseErrorCopyWithImpl(this._self, this._then);

  final DatabaseError _self;
  final $Res Function(DatabaseError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message! : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseError].
extension DatabaseErrorPatterns on DatabaseError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvalidPasswordError value)?  invalidPassword,TResult Function( DatabaseNotFoundError value)?  databaseNotFound,TResult Function( DatabaseAlreadyExistsError value)?  databaseAlreadyExists,TResult Function( ConnectionFailedError value)?  connectionFailed,TResult Function( OperationFailedError value)?  operationFailed,TResult Function( PathNotAccessibleError value)?  pathNotAccessible,TResult Function( UnknownDatabaseError value)?  unknown,TResult Function( KeyError value)?  keyError,TResult Function( SecureStorageError value)?  secureStorageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvalidPasswordError() when invalidPassword != null:
return invalidPassword(_that);case DatabaseNotFoundError() when databaseNotFound != null:
return databaseNotFound(_that);case DatabaseAlreadyExistsError() when databaseAlreadyExists != null:
return databaseAlreadyExists(_that);case ConnectionFailedError() when connectionFailed != null:
return connectionFailed(_that);case OperationFailedError() when operationFailed != null:
return operationFailed(_that);case PathNotAccessibleError() when pathNotAccessible != null:
return pathNotAccessible(_that);case UnknownDatabaseError() when unknown != null:
return unknown(_that);case KeyError() when keyError != null:
return keyError(_that);case SecureStorageError() when secureStorageError != null:
return secureStorageError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvalidPasswordError value)  invalidPassword,required TResult Function( DatabaseNotFoundError value)  databaseNotFound,required TResult Function( DatabaseAlreadyExistsError value)  databaseAlreadyExists,required TResult Function( ConnectionFailedError value)  connectionFailed,required TResult Function( OperationFailedError value)  operationFailed,required TResult Function( PathNotAccessibleError value)  pathNotAccessible,required TResult Function( UnknownDatabaseError value)  unknown,required TResult Function( KeyError value)  keyError,required TResult Function( SecureStorageError value)  secureStorageError,}){
final _that = this;
switch (_that) {
case InvalidPasswordError():
return invalidPassword(_that);case DatabaseNotFoundError():
return databaseNotFound(_that);case DatabaseAlreadyExistsError():
return databaseAlreadyExists(_that);case ConnectionFailedError():
return connectionFailed(_that);case OperationFailedError():
return operationFailed(_that);case PathNotAccessibleError():
return pathNotAccessible(_that);case UnknownDatabaseError():
return unknown(_that);case KeyError():
return keyError(_that);case SecureStorageError():
return secureStorageError(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvalidPasswordError value)?  invalidPassword,TResult? Function( DatabaseNotFoundError value)?  databaseNotFound,TResult? Function( DatabaseAlreadyExistsError value)?  databaseAlreadyExists,TResult? Function( ConnectionFailedError value)?  connectionFailed,TResult? Function( OperationFailedError value)?  operationFailed,TResult? Function( PathNotAccessibleError value)?  pathNotAccessible,TResult? Function( UnknownDatabaseError value)?  unknown,TResult? Function( KeyError value)?  keyError,TResult? Function( SecureStorageError value)?  secureStorageError,}){
final _that = this;
switch (_that) {
case InvalidPasswordError() when invalidPassword != null:
return invalidPassword(_that);case DatabaseNotFoundError() when databaseNotFound != null:
return databaseNotFound(_that);case DatabaseAlreadyExistsError() when databaseAlreadyExists != null:
return databaseAlreadyExists(_that);case ConnectionFailedError() when connectionFailed != null:
return connectionFailed(_that);case OperationFailedError() when operationFailed != null:
return operationFailed(_that);case PathNotAccessibleError() when pathNotAccessible != null:
return pathNotAccessible(_that);case UnknownDatabaseError() when unknown != null:
return unknown(_that);case KeyError() when keyError != null:
return keyError(_that);case SecureStorageError() when secureStorageError != null:
return secureStorageError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String code,  String message,  Map<String, dynamic>? data)?  invalidPassword,TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  databaseNotFound,TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  databaseAlreadyExists,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  connectionFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  operationFailed,TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  pathNotAccessible,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  unknown,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyError,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  secureStorageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvalidPasswordError() when invalidPassword != null:
return invalidPassword(_that.code,_that.message,_that.data);case DatabaseNotFoundError() when databaseNotFound != null:
return databaseNotFound(_that.path,_that.code,_that.message,_that.data);case DatabaseAlreadyExistsError() when databaseAlreadyExists != null:
return databaseAlreadyExists(_that.path,_that.code,_that.message,_that.data);case ConnectionFailedError() when connectionFailed != null:
return connectionFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError() when operationFailed != null:
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case PathNotAccessibleError() when pathNotAccessible != null:
return pathNotAccessible(_that.path,_that.code,_that.message,_that.data);case UnknownDatabaseError() when unknown != null:
return unknown(_that.details,_that.code,_that.message,_that.data);case KeyError() when keyError != null:
return keyError(_that.details,_that.code,_that.message,_that.data);case SecureStorageError() when secureStorageError != null:
return secureStorageError(_that.details,_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String code,  String message,  Map<String, dynamic>? data)  invalidPassword,required TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)  databaseNotFound,required TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)  databaseAlreadyExists,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  connectionFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  operationFailed,required TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)  pathNotAccessible,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  unknown,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  keyError,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  secureStorageError,}) {final _that = this;
switch (_that) {
case InvalidPasswordError():
return invalidPassword(_that.code,_that.message,_that.data);case DatabaseNotFoundError():
return databaseNotFound(_that.path,_that.code,_that.message,_that.data);case DatabaseAlreadyExistsError():
return databaseAlreadyExists(_that.path,_that.code,_that.message,_that.data);case ConnectionFailedError():
return connectionFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError():
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case PathNotAccessibleError():
return pathNotAccessible(_that.path,_that.code,_that.message,_that.data);case UnknownDatabaseError():
return unknown(_that.details,_that.code,_that.message,_that.data);case KeyError():
return keyError(_that.details,_that.code,_that.message,_that.data);case SecureStorageError():
return secureStorageError(_that.details,_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String code,  String message,  Map<String, dynamic>? data)?  invalidPassword,TResult? Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  databaseNotFound,TResult? Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  databaseAlreadyExists,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  connectionFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  operationFailed,TResult? Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  pathNotAccessible,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  unknown,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyError,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  secureStorageError,}) {final _that = this;
switch (_that) {
case InvalidPasswordError() when invalidPassword != null:
return invalidPassword(_that.code,_that.message,_that.data);case DatabaseNotFoundError() when databaseNotFound != null:
return databaseNotFound(_that.path,_that.code,_that.message,_that.data);case DatabaseAlreadyExistsError() when databaseAlreadyExists != null:
return databaseAlreadyExists(_that.path,_that.code,_that.message,_that.data);case ConnectionFailedError() when connectionFailed != null:
return connectionFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError() when operationFailed != null:
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case PathNotAccessibleError() when pathNotAccessible != null:
return pathNotAccessible(_that.path,_that.code,_that.message,_that.data);case UnknownDatabaseError() when unknown != null:
return unknown(_that.details,_that.code,_that.message,_that.data);case KeyError() when keyError != null:
return keyError(_that.details,_that.code,_that.message,_that.data);case SecureStorageError() when secureStorageError != null:
return secureStorageError(_that.details,_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class InvalidPasswordError extends DatabaseError {
  const InvalidPasswordError({this.code = 'DB_INVALID_PASSWORD', this.message = 'Неверный пароль для базы данных', final  Map<String, dynamic>? data}): _data = data,super._();
  

@override@JsonKey() final  String code;
@override@JsonKey() final  String message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidPasswordErrorCopyWith<InvalidPasswordError> get copyWith => _$InvalidPasswordErrorCopyWithImpl<InvalidPasswordError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidPasswordError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.invalidPassword(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $InvalidPasswordErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $InvalidPasswordErrorCopyWith(InvalidPasswordError value, $Res Function(InvalidPasswordError) _then) = _$InvalidPasswordErrorCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$InvalidPasswordErrorCopyWithImpl<$Res>
    implements $InvalidPasswordErrorCopyWith<$Res> {
  _$InvalidPasswordErrorCopyWithImpl(this._self, this._then);

  final InvalidPasswordError _self;
  final $Res Function(InvalidPasswordError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = freezed,}) {
  return _then(InvalidPasswordError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class DatabaseNotFoundError extends DatabaseError {
  const DatabaseNotFoundError({required this.path, this.code = 'DB_NOT_FOUND', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String path;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseNotFoundErrorCopyWith<DatabaseNotFoundError> get copyWith => _$DatabaseNotFoundErrorCopyWithImpl<DatabaseNotFoundError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseNotFoundError&&(identical(other.path, path) || other.path == path)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,path,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.databaseNotFound(path: $path, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $DatabaseNotFoundErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $DatabaseNotFoundErrorCopyWith(DatabaseNotFoundError value, $Res Function(DatabaseNotFoundError) _then) = _$DatabaseNotFoundErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$DatabaseNotFoundErrorCopyWithImpl<$Res>
    implements $DatabaseNotFoundErrorCopyWith<$Res> {
  _$DatabaseNotFoundErrorCopyWithImpl(this._self, this._then);

  final DatabaseNotFoundError _self;
  final $Res Function(DatabaseNotFoundError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(DatabaseNotFoundError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class DatabaseAlreadyExistsError extends DatabaseError {
  const DatabaseAlreadyExistsError({required this.path, this.code = 'DB_ALREADY_EXISTS', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String path;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseAlreadyExistsErrorCopyWith<DatabaseAlreadyExistsError> get copyWith => _$DatabaseAlreadyExistsErrorCopyWithImpl<DatabaseAlreadyExistsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseAlreadyExistsError&&(identical(other.path, path) || other.path == path)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,path,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.databaseAlreadyExists(path: $path, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $DatabaseAlreadyExistsErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $DatabaseAlreadyExistsErrorCopyWith(DatabaseAlreadyExistsError value, $Res Function(DatabaseAlreadyExistsError) _then) = _$DatabaseAlreadyExistsErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$DatabaseAlreadyExistsErrorCopyWithImpl<$Res>
    implements $DatabaseAlreadyExistsErrorCopyWith<$Res> {
  _$DatabaseAlreadyExistsErrorCopyWithImpl(this._self, this._then);

  final DatabaseAlreadyExistsError _self;
  final $Res Function(DatabaseAlreadyExistsError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(DatabaseAlreadyExistsError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class ConnectionFailedError extends DatabaseError {
  const ConnectionFailedError({required this.details, this.code = 'DB_CONNECTION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String details;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionFailedErrorCopyWith<ConnectionFailedError> get copyWith => _$ConnectionFailedErrorCopyWithImpl<ConnectionFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionFailedError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.connectionFailed(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $ConnectionFailedErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $ConnectionFailedErrorCopyWith(ConnectionFailedError value, $Res Function(ConnectionFailedError) _then) = _$ConnectionFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$ConnectionFailedErrorCopyWithImpl<$Res>
    implements $ConnectionFailedErrorCopyWith<$Res> {
  _$ConnectionFailedErrorCopyWithImpl(this._self, this._then);

  final ConnectionFailedError _self;
  final $Res Function(ConnectionFailedError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(ConnectionFailedError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class OperationFailedError extends DatabaseError {
  const OperationFailedError({required this.operation, required this.details, this.code = 'DB_OPERATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String operation;
 final  String details;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationFailedErrorCopyWith<OperationFailedError> get copyWith => _$OperationFailedErrorCopyWithImpl<OperationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.operationFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $OperationFailedErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $OperationFailedErrorCopyWith(OperationFailedError value, $Res Function(OperationFailedError) _then) = _$OperationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$OperationFailedErrorCopyWithImpl<$Res>
    implements $OperationFailedErrorCopyWith<$Res> {
  _$OperationFailedErrorCopyWithImpl(this._self, this._then);

  final OperationFailedError _self;
  final $Res Function(OperationFailedError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(OperationFailedError(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class PathNotAccessibleError extends DatabaseError {
  const PathNotAccessibleError({required this.path, this.code = 'DB_PATH_NOT_ACCESSIBLE', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String path;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathNotAccessibleErrorCopyWith<PathNotAccessibleError> get copyWith => _$PathNotAccessibleErrorCopyWithImpl<PathNotAccessibleError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathNotAccessibleError&&(identical(other.path, path) || other.path == path)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,path,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.pathNotAccessible(path: $path, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $PathNotAccessibleErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $PathNotAccessibleErrorCopyWith(PathNotAccessibleError value, $Res Function(PathNotAccessibleError) _then) = _$PathNotAccessibleErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$PathNotAccessibleErrorCopyWithImpl<$Res>
    implements $PathNotAccessibleErrorCopyWith<$Res> {
  _$PathNotAccessibleErrorCopyWithImpl(this._self, this._then);

  final PathNotAccessibleError _self;
  final $Res Function(PathNotAccessibleError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(PathNotAccessibleError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class UnknownDatabaseError extends DatabaseError {
  const UnknownDatabaseError({required this.details, this.code = 'DB_UNKNOWN_ERROR', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String details;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownDatabaseErrorCopyWith<UnknownDatabaseError> get copyWith => _$UnknownDatabaseErrorCopyWithImpl<UnknownDatabaseError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownDatabaseError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.unknown(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $UnknownDatabaseErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $UnknownDatabaseErrorCopyWith(UnknownDatabaseError value, $Res Function(UnknownDatabaseError) _then) = _$UnknownDatabaseErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$UnknownDatabaseErrorCopyWithImpl<$Res>
    implements $UnknownDatabaseErrorCopyWith<$Res> {
  _$UnknownDatabaseErrorCopyWithImpl(this._self, this._then);

  final UnknownDatabaseError _self;
  final $Res Function(UnknownDatabaseError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(UnknownDatabaseError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class KeyError extends DatabaseError {
  const KeyError({required this.details, this.code = 'DB_KEY_ERROR', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String details;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyErrorCopyWith<KeyError> get copyWith => _$KeyErrorCopyWithImpl<KeyError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.keyError(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $KeyErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $KeyErrorCopyWith(KeyError value, $Res Function(KeyError) _then) = _$KeyErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$KeyErrorCopyWithImpl<$Res>
    implements $KeyErrorCopyWith<$Res> {
  _$KeyErrorCopyWithImpl(this._self, this._then);

  final KeyError _self;
  final $Res Function(KeyError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(KeyError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class SecureStorageError extends DatabaseError {
  const SecureStorageError({required this.details, this.code = 'DB_SECURE_STORAGE_ERROR', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String details;
@override@JsonKey() final  String code;
@override final  String? message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecureStorageErrorCopyWith<SecureStorageError> get copyWith => _$SecureStorageErrorCopyWithImpl<SecureStorageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecureStorageError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DatabaseError.secureStorageError(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $SecureStorageErrorCopyWith<$Res> implements $DatabaseErrorCopyWith<$Res> {
  factory $SecureStorageErrorCopyWith(SecureStorageError value, $Res Function(SecureStorageError) _then) = _$SecureStorageErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$SecureStorageErrorCopyWithImpl<$Res>
    implements $SecureStorageErrorCopyWith<$Res> {
  _$SecureStorageErrorCopyWithImpl(this._self, this._then);

  final SecureStorageError _self;
  final $Res Function(SecureStorageError) _then;

/// Create a copy of DatabaseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(SecureStorageError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
