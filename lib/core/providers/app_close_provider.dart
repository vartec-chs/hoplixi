import 'dart:io';

import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

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

  Future<void> handleAppClose() async {
    if (state.value == AppCloseState.closing ||
        state.value == AppCloseState.closed) {
      return; // Already closing or closed
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

    if (UniversalPlatform.isDesktop) await windowManager.close();

    logInfo('Приложение закрыто', tag: 'AppCloseProvider');

    AppLogger.instance.dispose();

    state = const AsyncValue.data(AppCloseState.closed);
  }
}
