import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/app_preferences/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/features/auth/providers/authorization_notifier_provider.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_import_state.dart';
import 'package:hoplixi/features/cloud_sync/providers/cloud_import_provider.dart';

/// Notifier для управления состоянием router refresh
class RouterRefreshNotifier extends Notifier<int> with ChangeNotifier {
  @override
  int build() {
    // Слушаем изменения состояния авторизации
    ref.listen(authorizationProvider, (previous, next) {
      // При изменении состояния авторизации обновляем router
      if (previous != next) {
        logInfo(
          'Состояние авторизации изменилось, обновляем router',
          tag: 'RouterRefreshNotifier',
        );
        notifyListeners();
      }
    });

    // Слушаем изменения состояния импорта
    ref.listen(cloudImportStateProvider, (previous, next) {
      if (previous != next) {
        next.whenData((state) {
          state.when(
            idle: () {
              // Ничего не делаем в idle состоянии
            },
            checking: (_) {
              // Ничего не делаем при проверке версии
            },
            importing: (_, __, ___) {
              logInfo(
                'Начался импорт базы данных, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
            fileProgress: (_, __) {
              // Не требует обновления router
            },
            success: (_, __) {
              logInfo(
                'Импорт завершён успешно, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
            failure: (_) {
              logInfo(
                'Импорт завершён с ошибкой, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
            warning: (_) {
              logInfo(
                'Импорт: предупреждение, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
            info: (_) {
              logInfo(
                'Импорт: информационное состояние, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
            canceled: () {
              logInfo(
                'Импорт отменён, обновляем router',
                tag: 'RouterRefreshNotifier',
              );
              notifyListeners();
            },
          );
        });
      }
    });

    // Слушаем изменения состояния блокировки БД
    ref.listen<bool>(databaseLockedProvider, (previous, next) {
      if (next == true && previous == false) {
        logInfo(
          'БД заблокирована, уведомляем router о необходимости refresh',
          tag: 'RouterRefreshNotifier',
        );
        // Уведомляем router об изменении состояния
        notifyListeners();
      }
    });

    // Слушаем изменения состояния очистки данных
    ref.listen<bool>(dataClearedProvider, (previous, next) async {
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
