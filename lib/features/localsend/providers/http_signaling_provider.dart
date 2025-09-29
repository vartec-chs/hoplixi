import '../services/http_signaling_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final httpSignalingProvider = Provider.autoDispose<HttpSignalingService>((ref) {
  final service = HttpSignalingService();
  ref.onDispose(() {
    if (!ref.mounted) return;
    service.stop();
  });
  return service;
});
