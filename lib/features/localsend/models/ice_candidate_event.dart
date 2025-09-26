import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'ice_candidate_event.freezed.dart';
part 'ice_candidate_event.g.dart';

@freezed
abstract class IceCandidateEvent with _$IceCandidateEvent {
  const factory IceCandidateEvent({
    required String deviceId,
    required String candidate,
    required String sdpMid,
    required int sdpMLineIndex,
  }) = _IceCandidateEvent;

  factory IceCandidateEvent.fromJson(Map<String, Object?> json) =>
      _$IceCandidateEventFromJson(json);

  factory IceCandidateEvent.fromRTCIceCandidate({
    required String deviceId,
    required RTCIceCandidate candidate,
  }) => IceCandidateEvent(
    deviceId: deviceId,
    candidate: candidate.candidate!,
    sdpMid: candidate.sdpMid!,
    sdpMLineIndex: candidate.sdpMLineIndex!,
  );
}
