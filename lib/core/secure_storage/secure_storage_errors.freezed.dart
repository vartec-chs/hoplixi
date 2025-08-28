// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secure_storage_errors.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SecureStorageError {

 String get code; String? get message; Map<String, dynamic>? get data;
/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecureStorageErrorCopyWith<SecureStorageError> get copyWith => _$SecureStorageErrorCopyWithImpl<SecureStorageError>(this as SecureStorageError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecureStorageError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'SecureStorageError(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $SecureStorageErrorCopyWith<$Res>  {
  factory $SecureStorageErrorCopyWith(SecureStorageError value, $Res Function(SecureStorageError) _then) = _$SecureStorageErrorCopyWithImpl;
@useResult
$Res call({
 String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$SecureStorageErrorCopyWithImpl<$Res>
    implements $SecureStorageErrorCopyWith<$Res> {
  _$SecureStorageErrorCopyWithImpl(this._self, this._then);

  final SecureStorageError _self;
  final $Res Function(SecureStorageError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecureStorageError].
extension SecureStorageErrorPatterns on SecureStorageError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EncryptionFailedError value)?  encryptionFailed,TResult Function( DecryptionFailedError value)?  decryptionFailed,TResult Function( KeyGenerationFailedError value)?  keyGenerationFailed,TResult Function( KeyNotFoundError value)?  keyNotFound,TResult Function( KeyValidationFailedError value)?  keyValidationFailed,TResult Function( FileAccessFailedError value)?  fileAccessFailed,TResult Function( FileNotFoundError value)?  fileNotFound,TResult Function( FileCorruptedError value)?  fileCorrupted,TResult Function( InitializationFailedError value)?  initializationFailed,TResult Function( OperationFailedError value)?  operationFailed,TResult Function( SerializationFailedError value)?  serializationFailed,TResult Function( ValidationFailedError value)?  validationFailed,TResult Function( CacheError value)?  cacheError,TResult Function( SecurityBreachError value)?  securityBreach,TResult Function( UnknownSecureStorageError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EncryptionFailedError() when encryptionFailed != null:
return encryptionFailed(_that);case DecryptionFailedError() when decryptionFailed != null:
return decryptionFailed(_that);case KeyGenerationFailedError() when keyGenerationFailed != null:
return keyGenerationFailed(_that);case KeyNotFoundError() when keyNotFound != null:
return keyNotFound(_that);case KeyValidationFailedError() when keyValidationFailed != null:
return keyValidationFailed(_that);case FileAccessFailedError() when fileAccessFailed != null:
return fileAccessFailed(_that);case FileNotFoundError() when fileNotFound != null:
return fileNotFound(_that);case FileCorruptedError() when fileCorrupted != null:
return fileCorrupted(_that);case InitializationFailedError() when initializationFailed != null:
return initializationFailed(_that);case OperationFailedError() when operationFailed != null:
return operationFailed(_that);case SerializationFailedError() when serializationFailed != null:
return serializationFailed(_that);case ValidationFailedError() when validationFailed != null:
return validationFailed(_that);case CacheError() when cacheError != null:
return cacheError(_that);case SecurityBreachError() when securityBreach != null:
return securityBreach(_that);case UnknownSecureStorageError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EncryptionFailedError value)  encryptionFailed,required TResult Function( DecryptionFailedError value)  decryptionFailed,required TResult Function( KeyGenerationFailedError value)  keyGenerationFailed,required TResult Function( KeyNotFoundError value)  keyNotFound,required TResult Function( KeyValidationFailedError value)  keyValidationFailed,required TResult Function( FileAccessFailedError value)  fileAccessFailed,required TResult Function( FileNotFoundError value)  fileNotFound,required TResult Function( FileCorruptedError value)  fileCorrupted,required TResult Function( InitializationFailedError value)  initializationFailed,required TResult Function( OperationFailedError value)  operationFailed,required TResult Function( SerializationFailedError value)  serializationFailed,required TResult Function( ValidationFailedError value)  validationFailed,required TResult Function( CacheError value)  cacheError,required TResult Function( SecurityBreachError value)  securityBreach,required TResult Function( UnknownSecureStorageError value)  unknown,}){
final _that = this;
switch (_that) {
case EncryptionFailedError():
return encryptionFailed(_that);case DecryptionFailedError():
return decryptionFailed(_that);case KeyGenerationFailedError():
return keyGenerationFailed(_that);case KeyNotFoundError():
return keyNotFound(_that);case KeyValidationFailedError():
return keyValidationFailed(_that);case FileAccessFailedError():
return fileAccessFailed(_that);case FileNotFoundError():
return fileNotFound(_that);case FileCorruptedError():
return fileCorrupted(_that);case InitializationFailedError():
return initializationFailed(_that);case OperationFailedError():
return operationFailed(_that);case SerializationFailedError():
return serializationFailed(_that);case ValidationFailedError():
return validationFailed(_that);case CacheError():
return cacheError(_that);case SecurityBreachError():
return securityBreach(_that);case UnknownSecureStorageError():
return unknown(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EncryptionFailedError value)?  encryptionFailed,TResult? Function( DecryptionFailedError value)?  decryptionFailed,TResult? Function( KeyGenerationFailedError value)?  keyGenerationFailed,TResult? Function( KeyNotFoundError value)?  keyNotFound,TResult? Function( KeyValidationFailedError value)?  keyValidationFailed,TResult? Function( FileAccessFailedError value)?  fileAccessFailed,TResult? Function( FileNotFoundError value)?  fileNotFound,TResult? Function( FileCorruptedError value)?  fileCorrupted,TResult? Function( InitializationFailedError value)?  initializationFailed,TResult? Function( OperationFailedError value)?  operationFailed,TResult? Function( SerializationFailedError value)?  serializationFailed,TResult? Function( ValidationFailedError value)?  validationFailed,TResult? Function( CacheError value)?  cacheError,TResult? Function( SecurityBreachError value)?  securityBreach,TResult? Function( UnknownSecureStorageError value)?  unknown,}){
final _that = this;
switch (_that) {
case EncryptionFailedError() when encryptionFailed != null:
return encryptionFailed(_that);case DecryptionFailedError() when decryptionFailed != null:
return decryptionFailed(_that);case KeyGenerationFailedError() when keyGenerationFailed != null:
return keyGenerationFailed(_that);case KeyNotFoundError() when keyNotFound != null:
return keyNotFound(_that);case KeyValidationFailedError() when keyValidationFailed != null:
return keyValidationFailed(_that);case FileAccessFailedError() when fileAccessFailed != null:
return fileAccessFailed(_that);case FileNotFoundError() when fileNotFound != null:
return fileNotFound(_that);case FileCorruptedError() when fileCorrupted != null:
return fileCorrupted(_that);case InitializationFailedError() when initializationFailed != null:
return initializationFailed(_that);case OperationFailedError() when operationFailed != null:
return operationFailed(_that);case SerializationFailedError() when serializationFailed != null:
return serializationFailed(_that);case ValidationFailedError() when validationFailed != null:
return validationFailed(_that);case CacheError() when cacheError != null:
return cacheError(_that);case SecurityBreachError() when securityBreach != null:
return securityBreach(_that);case UnknownSecureStorageError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  encryptionFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  decryptionFailed,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyGenerationFailed,TResult Function( String storageKey,  String code,  String? message,  Map<String, dynamic>? data)?  keyNotFound,TResult Function( String storageKey,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyValidationFailed,TResult Function( String operation,  String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  fileAccessFailed,TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  fileNotFound,TResult Function( String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  fileCorrupted,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  initializationFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  operationFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  serializationFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  validationFailed,TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  cacheError,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  securityBreach,TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EncryptionFailedError() when encryptionFailed != null:
return encryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case DecryptionFailedError() when decryptionFailed != null:
return decryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case KeyGenerationFailedError() when keyGenerationFailed != null:
return keyGenerationFailed(_that.details,_that.code,_that.message,_that.data);case KeyNotFoundError() when keyNotFound != null:
return keyNotFound(_that.storageKey,_that.code,_that.message,_that.data);case KeyValidationFailedError() when keyValidationFailed != null:
return keyValidationFailed(_that.storageKey,_that.details,_that.code,_that.message,_that.data);case FileAccessFailedError() when fileAccessFailed != null:
return fileAccessFailed(_that.operation,_that.path,_that.details,_that.code,_that.message,_that.data);case FileNotFoundError() when fileNotFound != null:
return fileNotFound(_that.path,_that.code,_that.message,_that.data);case FileCorruptedError() when fileCorrupted != null:
return fileCorrupted(_that.path,_that.details,_that.code,_that.message,_that.data);case InitializationFailedError() when initializationFailed != null:
return initializationFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError() when operationFailed != null:
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case SerializationFailedError() when serializationFailed != null:
return serializationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case ValidationFailedError() when validationFailed != null:
return validationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case CacheError() when cacheError != null:
return cacheError(_that.operation,_that.details,_that.code,_that.message,_that.data);case SecurityBreachError() when securityBreach != null:
return securityBreach(_that.details,_that.code,_that.message,_that.data);case UnknownSecureStorageError() when unknown != null:
return unknown(_that.details,_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  encryptionFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  decryptionFailed,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  keyGenerationFailed,required TResult Function( String storageKey,  String code,  String? message,  Map<String, dynamic>? data)  keyNotFound,required TResult Function( String storageKey,  String details,  String code,  String? message,  Map<String, dynamic>? data)  keyValidationFailed,required TResult Function( String operation,  String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)  fileAccessFailed,required TResult Function( String path,  String code,  String? message,  Map<String, dynamic>? data)  fileNotFound,required TResult Function( String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)  fileCorrupted,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  initializationFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  operationFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  serializationFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  validationFailed,required TResult Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)  cacheError,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  securityBreach,required TResult Function( String details,  String code,  String? message,  Map<String, dynamic>? data)  unknown,}) {final _that = this;
switch (_that) {
case EncryptionFailedError():
return encryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case DecryptionFailedError():
return decryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case KeyGenerationFailedError():
return keyGenerationFailed(_that.details,_that.code,_that.message,_that.data);case KeyNotFoundError():
return keyNotFound(_that.storageKey,_that.code,_that.message,_that.data);case KeyValidationFailedError():
return keyValidationFailed(_that.storageKey,_that.details,_that.code,_that.message,_that.data);case FileAccessFailedError():
return fileAccessFailed(_that.operation,_that.path,_that.details,_that.code,_that.message,_that.data);case FileNotFoundError():
return fileNotFound(_that.path,_that.code,_that.message,_that.data);case FileCorruptedError():
return fileCorrupted(_that.path,_that.details,_that.code,_that.message,_that.data);case InitializationFailedError():
return initializationFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError():
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case SerializationFailedError():
return serializationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case ValidationFailedError():
return validationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case CacheError():
return cacheError(_that.operation,_that.details,_that.code,_that.message,_that.data);case SecurityBreachError():
return securityBreach(_that.details,_that.code,_that.message,_that.data);case UnknownSecureStorageError():
return unknown(_that.details,_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  encryptionFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  decryptionFailed,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyGenerationFailed,TResult? Function( String storageKey,  String code,  String? message,  Map<String, dynamic>? data)?  keyNotFound,TResult? Function( String storageKey,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  keyValidationFailed,TResult? Function( String operation,  String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  fileAccessFailed,TResult? Function( String path,  String code,  String? message,  Map<String, dynamic>? data)?  fileNotFound,TResult? Function( String path,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  fileCorrupted,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  initializationFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  operationFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  serializationFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  validationFailed,TResult? Function( String operation,  String details,  String code,  String? message,  Map<String, dynamic>? data)?  cacheError,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  securityBreach,TResult? Function( String details,  String code,  String? message,  Map<String, dynamic>? data)?  unknown,}) {final _that = this;
switch (_that) {
case EncryptionFailedError() when encryptionFailed != null:
return encryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case DecryptionFailedError() when decryptionFailed != null:
return decryptionFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case KeyGenerationFailedError() when keyGenerationFailed != null:
return keyGenerationFailed(_that.details,_that.code,_that.message,_that.data);case KeyNotFoundError() when keyNotFound != null:
return keyNotFound(_that.storageKey,_that.code,_that.message,_that.data);case KeyValidationFailedError() when keyValidationFailed != null:
return keyValidationFailed(_that.storageKey,_that.details,_that.code,_that.message,_that.data);case FileAccessFailedError() when fileAccessFailed != null:
return fileAccessFailed(_that.operation,_that.path,_that.details,_that.code,_that.message,_that.data);case FileNotFoundError() when fileNotFound != null:
return fileNotFound(_that.path,_that.code,_that.message,_that.data);case FileCorruptedError() when fileCorrupted != null:
return fileCorrupted(_that.path,_that.details,_that.code,_that.message,_that.data);case InitializationFailedError() when initializationFailed != null:
return initializationFailed(_that.details,_that.code,_that.message,_that.data);case OperationFailedError() when operationFailed != null:
return operationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case SerializationFailedError() when serializationFailed != null:
return serializationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case ValidationFailedError() when validationFailed != null:
return validationFailed(_that.operation,_that.details,_that.code,_that.message,_that.data);case CacheError() when cacheError != null:
return cacheError(_that.operation,_that.details,_that.code,_that.message,_that.data);case SecurityBreachError() when securityBreach != null:
return securityBreach(_that.details,_that.code,_that.message,_that.data);case UnknownSecureStorageError() when unknown != null:
return unknown(_that.details,_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class EncryptionFailedError extends SecureStorageError {
  const EncryptionFailedError({required this.operation, required this.details, this.code = 'SS_ENCRYPTION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncryptionFailedErrorCopyWith<EncryptionFailedError> get copyWith => _$EncryptionFailedErrorCopyWithImpl<EncryptionFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncryptionFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.encryptionFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $EncryptionFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $EncryptionFailedErrorCopyWith(EncryptionFailedError value, $Res Function(EncryptionFailedError) _then) = _$EncryptionFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$EncryptionFailedErrorCopyWithImpl<$Res>
    implements $EncryptionFailedErrorCopyWith<$Res> {
  _$EncryptionFailedErrorCopyWithImpl(this._self, this._then);

  final EncryptionFailedError _self;
  final $Res Function(EncryptionFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(EncryptionFailedError(
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


class DecryptionFailedError extends SecureStorageError {
  const DecryptionFailedError({required this.operation, required this.details, this.code = 'SS_DECRYPTION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecryptionFailedErrorCopyWith<DecryptionFailedError> get copyWith => _$DecryptionFailedErrorCopyWithImpl<DecryptionFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecryptionFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.decryptionFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $DecryptionFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $DecryptionFailedErrorCopyWith(DecryptionFailedError value, $Res Function(DecryptionFailedError) _then) = _$DecryptionFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$DecryptionFailedErrorCopyWithImpl<$Res>
    implements $DecryptionFailedErrorCopyWith<$Res> {
  _$DecryptionFailedErrorCopyWithImpl(this._self, this._then);

  final DecryptionFailedError _self;
  final $Res Function(DecryptionFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(DecryptionFailedError(
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


class KeyGenerationFailedError extends SecureStorageError {
  const KeyGenerationFailedError({required this.details, this.code = 'SS_KEY_GENERATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyGenerationFailedErrorCopyWith<KeyGenerationFailedError> get copyWith => _$KeyGenerationFailedErrorCopyWithImpl<KeyGenerationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyGenerationFailedError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.keyGenerationFailed(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $KeyGenerationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $KeyGenerationFailedErrorCopyWith(KeyGenerationFailedError value, $Res Function(KeyGenerationFailedError) _then) = _$KeyGenerationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$KeyGenerationFailedErrorCopyWithImpl<$Res>
    implements $KeyGenerationFailedErrorCopyWith<$Res> {
  _$KeyGenerationFailedErrorCopyWithImpl(this._self, this._then);

  final KeyGenerationFailedError _self;
  final $Res Function(KeyGenerationFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(KeyGenerationFailedError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class KeyNotFoundError extends SecureStorageError {
  const KeyNotFoundError({required this.storageKey, this.code = 'SS_KEY_NOT_FOUND', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String storageKey;
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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyNotFoundErrorCopyWith<KeyNotFoundError> get copyWith => _$KeyNotFoundErrorCopyWithImpl<KeyNotFoundError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyNotFoundError&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,storageKey,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.keyNotFound(storageKey: $storageKey, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $KeyNotFoundErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $KeyNotFoundErrorCopyWith(KeyNotFoundError value, $Res Function(KeyNotFoundError) _then) = _$KeyNotFoundErrorCopyWithImpl;
@override @useResult
$Res call({
 String storageKey, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$KeyNotFoundErrorCopyWithImpl<$Res>
    implements $KeyNotFoundErrorCopyWith<$Res> {
  _$KeyNotFoundErrorCopyWithImpl(this._self, this._then);

  final KeyNotFoundError _self;
  final $Res Function(KeyNotFoundError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? storageKey = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(KeyNotFoundError(
storageKey: null == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class KeyValidationFailedError extends SecureStorageError {
  const KeyValidationFailedError({required this.storageKey, required this.details, this.code = 'SS_KEY_VALIDATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String storageKey;
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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyValidationFailedErrorCopyWith<KeyValidationFailedError> get copyWith => _$KeyValidationFailedErrorCopyWithImpl<KeyValidationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyValidationFailedError&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,storageKey,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.keyValidationFailed(storageKey: $storageKey, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $KeyValidationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $KeyValidationFailedErrorCopyWith(KeyValidationFailedError value, $Res Function(KeyValidationFailedError) _then) = _$KeyValidationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String storageKey, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$KeyValidationFailedErrorCopyWithImpl<$Res>
    implements $KeyValidationFailedErrorCopyWith<$Res> {
  _$KeyValidationFailedErrorCopyWithImpl(this._self, this._then);

  final KeyValidationFailedError _self;
  final $Res Function(KeyValidationFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? storageKey = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(KeyValidationFailedError(
storageKey: null == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class FileAccessFailedError extends SecureStorageError {
  const FileAccessFailedError({required this.operation, required this.path, required this.details, this.code = 'SS_FILE_ACCESS_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String operation;
 final  String path;
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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileAccessFailedErrorCopyWith<FileAccessFailedError> get copyWith => _$FileAccessFailedErrorCopyWithImpl<FileAccessFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileAccessFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.path, path) || other.path == path)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,path,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.fileAccessFailed(operation: $operation, path: $path, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $FileAccessFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $FileAccessFailedErrorCopyWith(FileAccessFailedError value, $Res Function(FileAccessFailedError) _then) = _$FileAccessFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String path, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$FileAccessFailedErrorCopyWithImpl<$Res>
    implements $FileAccessFailedErrorCopyWith<$Res> {
  _$FileAccessFailedErrorCopyWithImpl(this._self, this._then);

  final FileAccessFailedError _self;
  final $Res Function(FileAccessFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? path = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(FileAccessFailedError(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class FileNotFoundError extends SecureStorageError {
  const FileNotFoundError({required this.path, this.code = 'SS_FILE_NOT_FOUND', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileNotFoundErrorCopyWith<FileNotFoundError> get copyWith => _$FileNotFoundErrorCopyWithImpl<FileNotFoundError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileNotFoundError&&(identical(other.path, path) || other.path == path)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,path,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.fileNotFound(path: $path, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $FileNotFoundErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $FileNotFoundErrorCopyWith(FileNotFoundError value, $Res Function(FileNotFoundError) _then) = _$FileNotFoundErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$FileNotFoundErrorCopyWithImpl<$Res>
    implements $FileNotFoundErrorCopyWith<$Res> {
  _$FileNotFoundErrorCopyWithImpl(this._self, this._then);

  final FileNotFoundError _self;
  final $Res Function(FileNotFoundError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(FileNotFoundError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class FileCorruptedError extends SecureStorageError {
  const FileCorruptedError({required this.path, required this.details, this.code = 'SS_FILE_CORRUPTED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

 final  String path;
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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileCorruptedErrorCopyWith<FileCorruptedError> get copyWith => _$FileCorruptedErrorCopyWithImpl<FileCorruptedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileCorruptedError&&(identical(other.path, path) || other.path == path)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,path,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.fileCorrupted(path: $path, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $FileCorruptedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $FileCorruptedErrorCopyWith(FileCorruptedError value, $Res Function(FileCorruptedError) _then) = _$FileCorruptedErrorCopyWithImpl;
@override @useResult
$Res call({
 String path, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$FileCorruptedErrorCopyWithImpl<$Res>
    implements $FileCorruptedErrorCopyWith<$Res> {
  _$FileCorruptedErrorCopyWithImpl(this._self, this._then);

  final FileCorruptedError _self;
  final $Res Function(FileCorruptedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(FileCorruptedError(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class InitializationFailedError extends SecureStorageError {
  const InitializationFailedError({required this.details, this.code = 'SS_INITIALIZATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InitializationFailedErrorCopyWith<InitializationFailedError> get copyWith => _$InitializationFailedErrorCopyWithImpl<InitializationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InitializationFailedError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.initializationFailed(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $InitializationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $InitializationFailedErrorCopyWith(InitializationFailedError value, $Res Function(InitializationFailedError) _then) = _$InitializationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$InitializationFailedErrorCopyWithImpl<$Res>
    implements $InitializationFailedErrorCopyWith<$Res> {
  _$InitializationFailedErrorCopyWithImpl(this._self, this._then);

  final InitializationFailedError _self;
  final $Res Function(InitializationFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(InitializationFailedError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class OperationFailedError extends SecureStorageError {
  const OperationFailedError({required this.operation, required this.details, this.code = 'SS_OPERATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
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
  return 'SecureStorageError.operationFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $OperationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
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

/// Create a copy of SecureStorageError
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


class SerializationFailedError extends SecureStorageError {
  const SerializationFailedError({required this.operation, required this.details, this.code = 'SS_SERIALIZATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SerializationFailedErrorCopyWith<SerializationFailedError> get copyWith => _$SerializationFailedErrorCopyWithImpl<SerializationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SerializationFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.serializationFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $SerializationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $SerializationFailedErrorCopyWith(SerializationFailedError value, $Res Function(SerializationFailedError) _then) = _$SerializationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$SerializationFailedErrorCopyWithImpl<$Res>
    implements $SerializationFailedErrorCopyWith<$Res> {
  _$SerializationFailedErrorCopyWithImpl(this._self, this._then);

  final SerializationFailedError _self;
  final $Res Function(SerializationFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(SerializationFailedError(
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


class ValidationFailedError extends SecureStorageError {
  const ValidationFailedError({required this.operation, required this.details, this.code = 'SS_VALIDATION_FAILED', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailedErrorCopyWith<ValidationFailedError> get copyWith => _$ValidationFailedErrorCopyWithImpl<ValidationFailedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailedError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.validationFailed(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $ValidationFailedErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $ValidationFailedErrorCopyWith(ValidationFailedError value, $Res Function(ValidationFailedError) _then) = _$ValidationFailedErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$ValidationFailedErrorCopyWithImpl<$Res>
    implements $ValidationFailedErrorCopyWith<$Res> {
  _$ValidationFailedErrorCopyWithImpl(this._self, this._then);

  final ValidationFailedError _self;
  final $Res Function(ValidationFailedError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(ValidationFailedError(
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


class CacheError extends SecureStorageError {
  const CacheError({required this.operation, required this.details, this.code = 'SS_CACHE_ERROR', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheErrorCopyWith<CacheError> get copyWith => _$CacheErrorCopyWithImpl<CacheError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheError&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,operation,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.cacheError(operation: $operation, details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CacheErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $CacheErrorCopyWith(CacheError value, $Res Function(CacheError) _then) = _$CacheErrorCopyWithImpl;
@override @useResult
$Res call({
 String operation, String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$CacheErrorCopyWithImpl<$Res>
    implements $CacheErrorCopyWith<$Res> {
  _$CacheErrorCopyWithImpl(this._self, this._then);

  final CacheError _self;
  final $Res Function(CacheError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(CacheError(
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


class SecurityBreachError extends SecureStorageError {
  const SecurityBreachError({required this.details, this.code = 'SS_SECURITY_BREACH', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecurityBreachErrorCopyWith<SecurityBreachError> get copyWith => _$SecurityBreachErrorCopyWithImpl<SecurityBreachError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityBreachError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.securityBreach(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $SecurityBreachErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $SecurityBreachErrorCopyWith(SecurityBreachError value, $Res Function(SecurityBreachError) _then) = _$SecurityBreachErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$SecurityBreachErrorCopyWithImpl<$Res>
    implements $SecurityBreachErrorCopyWith<$Res> {
  _$SecurityBreachErrorCopyWithImpl(this._self, this._then);

  final SecurityBreachError _self;
  final $Res Function(SecurityBreachError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(SecurityBreachError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc


class UnknownSecureStorageError extends SecureStorageError {
  const UnknownSecureStorageError({required this.details, this.code = 'SS_UNKNOWN_ERROR', this.message, final  Map<String, dynamic>? data}): _data = data,super._();
  

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


/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownSecureStorageErrorCopyWith<UnknownSecureStorageError> get copyWith => _$UnknownSecureStorageErrorCopyWithImpl<UnknownSecureStorageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownSecureStorageError&&(identical(other.details, details) || other.details == details)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,details,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'SecureStorageError.unknown(details: $details, code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $UnknownSecureStorageErrorCopyWith<$Res> implements $SecureStorageErrorCopyWith<$Res> {
  factory $UnknownSecureStorageErrorCopyWith(UnknownSecureStorageError value, $Res Function(UnknownSecureStorageError) _then) = _$UnknownSecureStorageErrorCopyWithImpl;
@override @useResult
$Res call({
 String details, String code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$UnknownSecureStorageErrorCopyWithImpl<$Res>
    implements $UnknownSecureStorageErrorCopyWith<$Res> {
  _$UnknownSecureStorageErrorCopyWithImpl(this._self, this._then);

  final UnknownSecureStorageError _self;
  final $Res Function(UnknownSecureStorageError) _then;

/// Create a copy of SecureStorageError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? details = null,Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(UnknownSecureStorageError(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
