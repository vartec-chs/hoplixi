// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'webrtc_error.freezed.dart';
// part 'webrtc_error.g.dart';

// /// Ошибки WebRTC соединения
// @freezed
// abstract class WebRTCError with _$WebRTCError {
//   const factory WebRTCError({
//     /// Код ошибки
//     required String code,

//     /// Сообщение об ошибке
//     required String message,

//     /// Детали ошибки
//     String? details,

//     /// Время возникновения ошибки
//     DateTime? timestamp,

//     /// Можно ли повторить операцию
//     @Default(false) bool canRetry,
//   }) = _WebRTCError;

//   factory WebRTCError.fromJson(Map<String, dynamic> json) =>
//       _$WebRTCErrorFromJson(json);
// }

// /// Расширения для WebRTCError
// extension WebRTCErrorExtension on WebRTCError {
//   /// Создать ошибку из исключения
//   static WebRTCError fromException(
//     Exception e, {
//     String? code,
//     bool canRetry = false,
//   }) {
//     return WebRTCError(
//       code: code ?? 'UNKNOWN_ERROR',
//       message: e.toString(),
//       timestamp: DateTime.now(),
//       canRetry: canRetry,
//     );
//   }

//   /// Стандартные ошибки
//   static WebRTCError signalingFailed({String? details}) => WebRTCError(
//     code: 'SIGNALING_FAILED',
//     message: 'Не удалось установить сигнальный канал',
//     details: details,
//     timestamp: DateTime.now(),
//     canRetry: true,
//   );

//   static WebRTCError peerConnectionFailed({String? details}) => WebRTCError(
//     code: 'PEER_CONNECTION_FAILED',
//     message: 'Не удалось создать PeerConnection',
//     details: details,
//     timestamp: DateTime.now(),
//     canRetry: true,
//   );

//   static WebRTCError dataChannelFailed({String? details}) => WebRTCError(
//     code: 'DATA_CHANNEL_FAILED',
//     message: 'Не удалось создать DataChannel',
//     details: details,
//     timestamp: DateTime.now(),
//     canRetry: true,
//   );

//   static WebRTCError connectionTimeout({String? details}) => WebRTCError(
//     code: 'CONNECTION_TIMEOUT',
//     message: 'Превышено время ожидания подключения',
//     details: details,
//     timestamp: DateTime.now(),
//     canRetry: true,
//   );

//   static WebRTCError networkError({String? details}) => WebRTCError(
//     code: 'NETWORK_ERROR',
//     message: 'Ошибка сети',
//     details: details,
//     timestamp: DateTime.now(),
//     canRetry: true,
//   );
// }
