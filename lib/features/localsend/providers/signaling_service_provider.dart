import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/services/http_signaling_service.dart';

final signalingServiceProvider = Provider.family<HttpSignalingService, String>((
  ref,
  uniqueId,
) {
  // uniqueId не используется внутри сервиса, но позволяет family-инстанцировать
  final svc = HttpSignalingService();
  ref.onDispose(() {
    // на случай, если кто-то создаёт сервис напрямую
    svc.stop();
  });
  return svc;
});
