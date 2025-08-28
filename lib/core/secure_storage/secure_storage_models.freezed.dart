// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secure_storage_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StorageFileConfig {

 String get fileName; String get displayName; bool get encryptionEnabled;
/// Create a copy of StorageFileConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageFileConfigCopyWith<StorageFileConfig> get copyWith => _$StorageFileConfigCopyWithImpl<StorageFileConfig>(this as StorageFileConfig, _$identity);

  /// Serializes this StorageFileConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFileConfig&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.encryptionEnabled, encryptionEnabled) || other.encryptionEnabled == encryptionEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,displayName,encryptionEnabled);

@override
String toString() {
  return 'StorageFileConfig(fileName: $fileName, displayName: $displayName, encryptionEnabled: $encryptionEnabled)';
}


}

/// @nodoc
abstract mixin class $StorageFileConfigCopyWith<$Res>  {
  factory $StorageFileConfigCopyWith(StorageFileConfig value, $Res Function(StorageFileConfig) _then) = _$StorageFileConfigCopyWithImpl;
@useResult
$Res call({
 String fileName, String displayName, bool encryptionEnabled
});




}
/// @nodoc
class _$StorageFileConfigCopyWithImpl<$Res>
    implements $StorageFileConfigCopyWith<$Res> {
  _$StorageFileConfigCopyWithImpl(this._self, this._then);

  final StorageFileConfig _self;
  final $Res Function(StorageFileConfig) _then;

/// Create a copy of StorageFileConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? displayName = null,Object? encryptionEnabled = null,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,encryptionEnabled: null == encryptionEnabled ? _self.encryptionEnabled : encryptionEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageFileConfig].
extension StorageFileConfigPatterns on StorageFileConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageFileConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageFileConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageFileConfig value)  $default,){
final _that = this;
switch (_that) {
case _StorageFileConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageFileConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StorageFileConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String displayName,  bool encryptionEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageFileConfig() when $default != null:
return $default(_that.fileName,_that.displayName,_that.encryptionEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String displayName,  bool encryptionEnabled)  $default,) {final _that = this;
switch (_that) {
case _StorageFileConfig():
return $default(_that.fileName,_that.displayName,_that.encryptionEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String displayName,  bool encryptionEnabled)?  $default,) {final _that = this;
switch (_that) {
case _StorageFileConfig() when $default != null:
return $default(_that.fileName,_that.displayName,_that.encryptionEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageFileConfig implements StorageFileConfig {
  const _StorageFileConfig({required this.fileName, required this.displayName, this.encryptionEnabled = true});
  factory _StorageFileConfig.fromJson(Map<String, dynamic> json) => _$StorageFileConfigFromJson(json);

@override final  String fileName;
@override final  String displayName;
@override@JsonKey() final  bool encryptionEnabled;

/// Create a copy of StorageFileConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageFileConfigCopyWith<_StorageFileConfig> get copyWith => __$StorageFileConfigCopyWithImpl<_StorageFileConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageFileConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageFileConfig&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.encryptionEnabled, encryptionEnabled) || other.encryptionEnabled == encryptionEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,displayName,encryptionEnabled);

@override
String toString() {
  return 'StorageFileConfig(fileName: $fileName, displayName: $displayName, encryptionEnabled: $encryptionEnabled)';
}


}

/// @nodoc
abstract mixin class _$StorageFileConfigCopyWith<$Res> implements $StorageFileConfigCopyWith<$Res> {
  factory _$StorageFileConfigCopyWith(_StorageFileConfig value, $Res Function(_StorageFileConfig) _then) = __$StorageFileConfigCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String displayName, bool encryptionEnabled
});




}
/// @nodoc
class __$StorageFileConfigCopyWithImpl<$Res>
    implements _$StorageFileConfigCopyWith<$Res> {
  __$StorageFileConfigCopyWithImpl(this._self, this._then);

  final _StorageFileConfig _self;
  final $Res Function(_StorageFileConfig) _then;

/// Create a copy of StorageFileConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? displayName = null,Object? encryptionEnabled = null,}) {
  return _then(_StorageFileConfig(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,encryptionEnabled: null == encryptionEnabled ? _self.encryptionEnabled : encryptionEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DatabaseEntry {

 String get id; String get name; String get path; DateTime get lastAccessed; String? get description;
/// Create a copy of DatabaseEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseEntryCopyWith<DatabaseEntry> get copyWith => _$DatabaseEntryCopyWithImpl<DatabaseEntry>(this as DatabaseEntry, _$identity);

  /// Serializes this DatabaseEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,lastAccessed,description);

@override
String toString() {
  return 'DatabaseEntry(id: $id, name: $name, path: $path, lastAccessed: $lastAccessed, description: $description)';
}


}

/// @nodoc
abstract mixin class $DatabaseEntryCopyWith<$Res>  {
  factory $DatabaseEntryCopyWith(DatabaseEntry value, $Res Function(DatabaseEntry) _then) = _$DatabaseEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String path, DateTime lastAccessed, String? description
});




}
/// @nodoc
class _$DatabaseEntryCopyWithImpl<$Res>
    implements $DatabaseEntryCopyWith<$Res> {
  _$DatabaseEntryCopyWithImpl(this._self, this._then);

  final DatabaseEntry _self;
  final $Res Function(DatabaseEntry) _then;

/// Create a copy of DatabaseEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? path = null,Object? lastAccessed = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,lastAccessed: null == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseEntry].
extension DatabaseEntryPatterns on DatabaseEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseEntry value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String path,  DateTime lastAccessed,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseEntry() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.lastAccessed,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String path,  DateTime lastAccessed,  String? description)  $default,) {final _that = this;
switch (_that) {
case _DatabaseEntry():
return $default(_that.id,_that.name,_that.path,_that.lastAccessed,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String path,  DateTime lastAccessed,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseEntry() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.lastAccessed,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DatabaseEntry implements DatabaseEntry {
  const _DatabaseEntry({required this.id, required this.name, required this.path, required this.lastAccessed, this.description});
  factory _DatabaseEntry.fromJson(Map<String, dynamic> json) => _$DatabaseEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String path;
@override final  DateTime lastAccessed;
@override final  String? description;

/// Create a copy of DatabaseEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseEntryCopyWith<_DatabaseEntry> get copyWith => __$DatabaseEntryCopyWithImpl<_DatabaseEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DatabaseEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.lastAccessed, lastAccessed) || other.lastAccessed == lastAccessed)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,lastAccessed,description);

@override
String toString() {
  return 'DatabaseEntry(id: $id, name: $name, path: $path, lastAccessed: $lastAccessed, description: $description)';
}


}

/// @nodoc
abstract mixin class _$DatabaseEntryCopyWith<$Res> implements $DatabaseEntryCopyWith<$Res> {
  factory _$DatabaseEntryCopyWith(_DatabaseEntry value, $Res Function(_DatabaseEntry) _then) = __$DatabaseEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String path, DateTime lastAccessed, String? description
});




}
/// @nodoc
class __$DatabaseEntryCopyWithImpl<$Res>
    implements _$DatabaseEntryCopyWith<$Res> {
  __$DatabaseEntryCopyWithImpl(this._self, this._then);

  final _DatabaseEntry _self;
  final $Res Function(_DatabaseEntry) _then;

/// Create a copy of DatabaseEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? path = null,Object? lastAccessed = null,Object? description = freezed,}) {
  return _then(_DatabaseEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,lastAccessed: null == lastAccessed ? _self.lastAccessed : lastAccessed // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AuthSession {

 String get sessionId; String get userId; DateTime get createdAt; DateTime get expiresAt; String? get refreshToken; Map<String, dynamic>? get metadata;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);

  /// Serializes this AuthSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,userId,createdAt,expiresAt,refreshToken,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'AuthSession(sessionId: $sessionId, userId: $userId, createdAt: $createdAt, expiresAt: $expiresAt, refreshToken: $refreshToken, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, String userId, DateTime createdAt, DateTime expiresAt, String? refreshToken, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? userId = null,Object? createdAt = null,Object? expiresAt = null,Object? refreshToken = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String userId,  DateTime createdAt,  DateTime expiresAt,  String? refreshToken,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.sessionId,_that.userId,_that.createdAt,_that.expiresAt,_that.refreshToken,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String userId,  DateTime createdAt,  DateTime expiresAt,  String? refreshToken,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.sessionId,_that.userId,_that.createdAt,_that.expiresAt,_that.refreshToken,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String userId,  DateTime createdAt,  DateTime expiresAt,  String? refreshToken,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.sessionId,_that.userId,_that.createdAt,_that.expiresAt,_that.refreshToken,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthSession implements AuthSession {
  const _AuthSession({required this.sessionId, required this.userId, required this.createdAt, required this.expiresAt, this.refreshToken, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

@override final  String sessionId;
@override final  String userId;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  String? refreshToken;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,userId,createdAt,expiresAt,refreshToken,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'AuthSession(sessionId: $sessionId, userId: $userId, createdAt: $createdAt, expiresAt: $expiresAt, refreshToken: $refreshToken, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String userId, DateTime createdAt, DateTime expiresAt, String? refreshToken, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? userId = null,Object? createdAt = null,Object? expiresAt = null,Object? refreshToken = freezed,Object? metadata = freezed,}) {
  return _then(_AuthSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$FileMetadata {

 String get version; DateTime get createdAt; DateTime get updatedAt; String get checksum; String get encryptionAlgorithm; int get pbkdf2Iterations;
/// Create a copy of FileMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileMetadataCopyWith<FileMetadata> get copyWith => _$FileMetadataCopyWithImpl<FileMetadata>(this as FileMetadata, _$identity);

  /// Serializes this FileMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileMetadata&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.encryptionAlgorithm, encryptionAlgorithm) || other.encryptionAlgorithm == encryptionAlgorithm)&&(identical(other.pbkdf2Iterations, pbkdf2Iterations) || other.pbkdf2Iterations == pbkdf2Iterations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,createdAt,updatedAt,checksum,encryptionAlgorithm,pbkdf2Iterations);

@override
String toString() {
  return 'FileMetadata(version: $version, createdAt: $createdAt, updatedAt: $updatedAt, checksum: $checksum, encryptionAlgorithm: $encryptionAlgorithm, pbkdf2Iterations: $pbkdf2Iterations)';
}


}

/// @nodoc
abstract mixin class $FileMetadataCopyWith<$Res>  {
  factory $FileMetadataCopyWith(FileMetadata value, $Res Function(FileMetadata) _then) = _$FileMetadataCopyWithImpl;
@useResult
$Res call({
 String version, DateTime createdAt, DateTime updatedAt, String checksum, String encryptionAlgorithm, int pbkdf2Iterations
});




}
/// @nodoc
class _$FileMetadataCopyWithImpl<$Res>
    implements $FileMetadataCopyWith<$Res> {
  _$FileMetadataCopyWithImpl(this._self, this._then);

  final FileMetadata _self;
  final $Res Function(FileMetadata) _then;

/// Create a copy of FileMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? checksum = null,Object? encryptionAlgorithm = null,Object? pbkdf2Iterations = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,encryptionAlgorithm: null == encryptionAlgorithm ? _self.encryptionAlgorithm : encryptionAlgorithm // ignore: cast_nullable_to_non_nullable
as String,pbkdf2Iterations: null == pbkdf2Iterations ? _self.pbkdf2Iterations : pbkdf2Iterations // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FileMetadata].
extension FileMetadataPatterns on FileMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileMetadata value)  $default,){
final _that = this;
switch (_that) {
case _FileMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _FileMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  DateTime createdAt,  DateTime updatedAt,  String checksum,  String encryptionAlgorithm,  int pbkdf2Iterations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileMetadata() when $default != null:
return $default(_that.version,_that.createdAt,_that.updatedAt,_that.checksum,_that.encryptionAlgorithm,_that.pbkdf2Iterations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  DateTime createdAt,  DateTime updatedAt,  String checksum,  String encryptionAlgorithm,  int pbkdf2Iterations)  $default,) {final _that = this;
switch (_that) {
case _FileMetadata():
return $default(_that.version,_that.createdAt,_that.updatedAt,_that.checksum,_that.encryptionAlgorithm,_that.pbkdf2Iterations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  DateTime createdAt,  DateTime updatedAt,  String checksum,  String encryptionAlgorithm,  int pbkdf2Iterations)?  $default,) {final _that = this;
switch (_that) {
case _FileMetadata() when $default != null:
return $default(_that.version,_that.createdAt,_that.updatedAt,_that.checksum,_that.encryptionAlgorithm,_that.pbkdf2Iterations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileMetadata implements FileMetadata {
  const _FileMetadata({required this.version, required this.createdAt, required this.updatedAt, required this.checksum, this.encryptionAlgorithm = 'AES-256-GCM', this.pbkdf2Iterations = 100000});
  factory _FileMetadata.fromJson(Map<String, dynamic> json) => _$FileMetadataFromJson(json);

@override final  String version;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String checksum;
@override@JsonKey() final  String encryptionAlgorithm;
@override@JsonKey() final  int pbkdf2Iterations;

/// Create a copy of FileMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileMetadataCopyWith<_FileMetadata> get copyWith => __$FileMetadataCopyWithImpl<_FileMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileMetadata&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.encryptionAlgorithm, encryptionAlgorithm) || other.encryptionAlgorithm == encryptionAlgorithm)&&(identical(other.pbkdf2Iterations, pbkdf2Iterations) || other.pbkdf2Iterations == pbkdf2Iterations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,createdAt,updatedAt,checksum,encryptionAlgorithm,pbkdf2Iterations);

@override
String toString() {
  return 'FileMetadata(version: $version, createdAt: $createdAt, updatedAt: $updatedAt, checksum: $checksum, encryptionAlgorithm: $encryptionAlgorithm, pbkdf2Iterations: $pbkdf2Iterations)';
}


}

/// @nodoc
abstract mixin class _$FileMetadataCopyWith<$Res> implements $FileMetadataCopyWith<$Res> {
  factory _$FileMetadataCopyWith(_FileMetadata value, $Res Function(_FileMetadata) _then) = __$FileMetadataCopyWithImpl;
@override @useResult
$Res call({
 String version, DateTime createdAt, DateTime updatedAt, String checksum, String encryptionAlgorithm, int pbkdf2Iterations
});




}
/// @nodoc
class __$FileMetadataCopyWithImpl<$Res>
    implements _$FileMetadataCopyWith<$Res> {
  __$FileMetadataCopyWithImpl(this._self, this._then);

  final _FileMetadata _self;
  final $Res Function(_FileMetadata) _then;

/// Create a copy of FileMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? checksum = null,Object? encryptionAlgorithm = null,Object? pbkdf2Iterations = null,}) {
  return _then(_FileMetadata(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,encryptionAlgorithm: null == encryptionAlgorithm ? _self.encryptionAlgorithm : encryptionAlgorithm // ignore: cast_nullable_to_non_nullable
as String,pbkdf2Iterations: null == pbkdf2Iterations ? _self.pbkdf2Iterations : pbkdf2Iterations // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
