import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/global/providers/app_lifecycle_provider.dart';

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

        // Флаг dataCleared теперь сбрасывается только при ручном нажатии пользователя на оверлей
        // Убираем автоматический сброс, чтобы оповещение висело до нажатия пользователя
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

class FirstRunNotifier extends Notifier<bool> {
  @override
  bool build() {
    bool isFirstRun = Prefs.get<bool>(Keys.isFirstRun) ?? true;
    state = isFirstRun;
    return state;
  }

  Future<void> markFirstRunComplete() async {
    state = false;
    await Prefs.set<bool>(Keys.isFirstRun, false);
    logInfo(
      'Первый запуск завершен, обновлено состояние isFirstRun',
      tag: 'FirstRunNotifier',
      data: {'isFirstRun': state},
    );
  }
}

final firstRunProvider = NotifierProvider.autoDispose<FirstRunNotifier, bool>(
  FirstRunNotifier.new,
);
