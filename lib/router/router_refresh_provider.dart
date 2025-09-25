import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/providers/app_lifecycle_provider.dart';

/// Notifier для управления состоянием router refresh
class RouterRefreshNotifier extends Notifier<int> with ChangeNotifier {
  @override
  int build() {
    // Слушаем изменения состояния очистки данных
    ref.listen<bool>(dataClearedProvider, (previous, next) {
      if (next == true && previous == false) {
        logInfo(
          'Данные очищены, уведомляем router о необходимости refresh',
          tag: 'RouterRefreshNotifier',
        );
        // Уведомляем router об изменении состояния
        notifyListeners();

        // Сбрасываем флаг после уведомления
        Future.microtask(() {
          ref.read(appLifecycleProvider.notifier).resetDataClearedFlag();
        });
      }
    });

    return 0;
  }

  /// Метод для принудительного обновления router
  void refresh() {
    logInfo('Принудительное обновление router', tag: 'RouterRefreshNotifier');
    state = state + 1;
    notifyListeners();
  }
}

/// Провайдер для router refresh
final routerRefreshProvider = NotifierProvider<RouterRefreshNotifier, int>(
  RouterRefreshNotifier.new,
);
