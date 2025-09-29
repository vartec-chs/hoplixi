import '../services/http_signaling_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final httpSignalingProvider = Provider<HttpSignalingService>((ref) {
  final service = HttpSignalingService();
  ref.onDispose(() {
    service.stop();
  });
  return service;
});
