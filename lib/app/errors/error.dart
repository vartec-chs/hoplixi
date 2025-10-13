import 'package:freezed_annotation/freezed_annotation.dart';

part 'error.freezed.dart';

@freezed
abstract class OtherError with _$OtherError implements Exception {
  const factory OtherError({
    @Default('unknown') String code,
    required String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = _OtherError;

  const OtherError._();

  String get displayMessage => message;

  String get errorCode => code;

  Map<String, dynamic>? get errorData => data;

  StackTrace? get errorStackTrace => stackTrace;

  DateTime? get errorTimestamp => timestamp;

  @override
  String toString() {
    return 'Error(code: $code, message: $message, data: $data, stackTrace: $stackTrace, timestamp: $timestamp)';
  }
}
