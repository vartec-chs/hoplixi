import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/webrtc_state.dart';
import 'package:hoplixi/features/localsend/providers/http_signaling_provider.dart';
import 'package:hoplixi/features/localsend/services/http_signaling_service.dart';

import '../services/webrtc_service.dart';

final webrtcProvider = AsyncNotifierProvider.family
    .autoDispose<WebrtcProvider, WebrtcState, (ConnectionMode, String)>(
      WebrtcProvider.new,
    );

class WebrtcProvider extends AsyncNotifier<WebrtcState> {
  WebrtcProvider(this.params);
  final (ConnectionMode, String) params;

  late final HttpSignalingService signalingService;

  @override
  Future<WebrtcState> build() async {
    signalingService = ref.read(httpSignalingProvider);
    return WebrtcState.initial();
  }
}
