import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_close_app_provider.freezed.dart';

@freezed
abstract class AutoCloseSettings with _$AutoCloseSettings {
  const factory AutoCloseSettings({
    required bool autoClose,
    required int timeout,
  }) = _AutoCloseSettings;

  factory AutoCloseSettings.fromPrefs() {
    return AutoCloseSettings(
      autoClose: Prefs.get<bool>(Keys.autoCloseApp) ?? false,
      timeout: Prefs.get<int>(Keys.autoCloseAppTimeout) ?? 120,
    );
  }
}

class AutoCloseAppNotifier extends AsyncNotifier<AutoCloseSettings> {
  @override
  Future<AutoCloseSettings> build() async {
    return AutoCloseSettings.fromPrefs();
  }

  Future<void> setAutoClose(bool value) async {
    final currentState = state.value!;
    final newState = currentState.copyWith(autoClose: value);
    await Prefs.set<bool>(Keys.autoCloseApp, value);
    state = AsyncData(newState);
  }

  Future<void> setTimeout(int value) async {
    final currentState = state.value!;
    final newState = currentState.copyWith(timeout: value);
    await Prefs.set<int>(Keys.autoCloseAppTimeout, value);
    state = AsyncData(newState);
  }
}

final autoCloseAppProvider =
    AsyncNotifierProvider<AutoCloseAppNotifier, AutoCloseSettings>(
      () => AutoCloseAppNotifier(),
    );
