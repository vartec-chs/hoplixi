import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend_rc/services/http_signaling_service.dart';

final signalingServiceProvider = Provider.family<HttpSignalingService, String>((
  ref,
  uniqueId,
) {
  const logTag = 'SignalingServiceProvider';

  logDebug('Создание HttpSignalingService для $uniqueId', tag: logTag);

  final svc = HttpSignalingService();

  ref.onDispose(() async {
    logInfo('Cleanup HttpSignalingService для $uniqueId', tag: logTag);

    try {
      await svc.stop();
      logDebug(
        'HttpSignalingService успешно остановлен для $uniqueId',
        tag: logTag,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка при остановке HttpSignalingService для $uniqueId',
        error: e,
        stackTrace: stackTrace,
        tag: logTag,
      );
    }
  });

  return svc;
});
