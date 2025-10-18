import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';
import 'package:riverpod/riverpod.dart';

enum AppCloseState { idle, closing, closed }

final appCloseProvider = AsyncNotifierProvider<AppCloseNotifier, AppCloseState>(
  AppCloseNotifier.new,
);

class AppCloseNotifier extends AsyncNotifier<AppCloseState> {
  @override
  Future<AppCloseState> build() async {
    state = const AsyncValue.data(AppCloseState.idle);
    return AppCloseState.idle;
  }

  Future<bool> handleAppClose() async {
    if (state.value == AppCloseState.closing ||
        state.value == AppCloseState.closed) {
      return false; // Already closing or closed
    }
    state = const AsyncValue.data(AppCloseState.closing);

    final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
    final isDatabaseOpen = ref.read(isDatabaseOpenProvider);
    try {
      await ref.read(clearAllProvider.notifier).clearAll();
    } catch (e, st) {
      logError(
        'Ошибка при закрытии базы данных: $e',
        tag: 'AppCloseProvider',
        error: e,
        stackTrace: st,
      );
    }

    isDatabaseOpen ? await dbNotifier.closeDatabase() : null;

    logInfo('Приложение закрыто', tag: 'AppCloseProvider');

    AppLogger.instance.dispose();

    state = const AsyncValue.data(AppCloseState.closed);
    return true;
  }
}
