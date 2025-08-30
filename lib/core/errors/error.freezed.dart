// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtherError {

 String get code; String get message; Map<String, dynamic>? get data;@JsonKey(includeToJson: true) StackTrace? get stackTrace;@JsonKey(includeToJson: true) DateTime? get timestamp;
/// Create a copy of OtherError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtherErrorCopyWith<OtherError> get copyWith => _$OtherErrorCopyWithImpl<OtherError>(this as OtherError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtherError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data),stackTrace,timestamp);



}

/// @nodoc
abstract mixin class $OtherErrorCopyWith<$Res>  {
  factory $OtherErrorCopyWith(OtherError value, $Res Function(OtherError) _then) = _$OtherErrorCopyWithImpl;
@useResult
$Res call({
 String code, String message, Map<String, dynamic>? data,@JsonKey(includeToJson: true) StackTrace? stackTrace,@JsonKey(includeToJson: true) DateTime? timestamp
});




}
/// @nodoc
class _$OtherErrorCopyWithImpl<$Res>
    implements $OtherErrorCopyWith<$Res> {
  _$OtherErrorCopyWithImpl(this._self, this._then);

  final OtherError _self;
  final $Res Function(OtherError) _then;

/// Create a copy of OtherError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = freezed,Object? stackTrace = freezed,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtherError].
extension OtherErrorPatterns on OtherError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtherError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtherError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtherError value)  $default,){
final _that = this;
switch (_that) {
case _OtherError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtherError value)?  $default,){
final _that = this;
switch (_that) {
case _OtherError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  Map<String, dynamic>? data, @JsonKey(includeToJson: true)  StackTrace? stackTrace, @JsonKey(includeToJson: true)  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtherError() when $default != null:
return $default(_that.code,_that.message,_that.data,_that.stackTrace,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  Map<String, dynamic>? data, @JsonKey(includeToJson: true)  StackTrace? stackTrace, @JsonKey(includeToJson: true)  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _OtherError():
return $default(_that.code,_that.message,_that.data,_that.stackTrace,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  Map<String, dynamic>? data, @JsonKey(includeToJson: true)  StackTrace? stackTrace, @JsonKey(includeToJson: true)  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _OtherError() when $default != null:
return $default(_that.code,_that.message,_that.data,_that.stackTrace,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc


class _OtherError extends OtherError {
  const _OtherError({this.code = 'unknown', required this.message, final  Map<String, dynamic>? data, @JsonKey(includeToJson: true) this.stackTrace, @JsonKey(includeToJson: true) this.timestamp}): _data = data,super._();
  

@override@JsonKey() final  String code;
@override final  String message;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(includeToJson: true) final  StackTrace? stackTrace;
@override@JsonKey(includeToJson: true) final  DateTime? timestamp;

/// Create a copy of OtherError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtherErrorCopyWith<_OtherError> get copyWith => __$OtherErrorCopyWithImpl<_OtherError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtherError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data),stackTrace,timestamp);



}

/// @nodoc
abstract mixin class _$OtherErrorCopyWith<$Res> implements $OtherErrorCopyWith<$Res> {
  factory _$OtherErrorCopyWith(_OtherError value, $Res Function(_OtherError) _then) = __$OtherErrorCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, Map<String, dynamic>? data,@JsonKey(includeToJson: true) StackTrace? stackTrace,@JsonKey(includeToJson: true) DateTime? timestamp
});




}
/// @nodoc
class __$OtherErrorCopyWithImpl<$Res>
    implements _$OtherErrorCopyWith<$Res> {
  __$OtherErrorCopyWithImpl(this._self, this._then);

  final _OtherError _self;
  final $Res Function(_OtherError) _then;

/// Create a copy of OtherError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = freezed,Object? stackTrace = freezed,Object? timestamp = freezed,}) {
  return _then(_OtherError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
