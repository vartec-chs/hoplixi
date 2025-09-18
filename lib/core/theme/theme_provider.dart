import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = AsyncNotifierProvider<ThemeProvider, ThemeMode>(
  ThemeProvider.new,
);

class ThemeProvider extends AsyncNotifier<ThemeMode> {
  @override
  FutureOr<ThemeMode> build() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeMode = prefs.getString('theme_mode');
      if (themeMode == 'light') {
        state = const AsyncData(ThemeMode.light);
        return ThemeMode.light;
      } else if (themeMode == 'dark') {
        state = const AsyncData(ThemeMode.dark);
        return ThemeMode.dark;
      } else {
        state = const AsyncData(ThemeMode.system);
        return ThemeMode.system;
      }
    } catch (e) {
      state = AsyncData(ThemeMode.system);
      return ThemeMode.system;
    }
  }

  /// Сохраняет текущую тему в SharedPreferences
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (themeMode == ThemeMode.light) {
        await prefs.setString('theme_mode', 'light');
      } else if (themeMode == ThemeMode.dark) {
        await prefs.setString('theme_mode', 'dark');
      } else {
        await prefs.setString('theme_mode', 'system');
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to save theme: $e',
        tag: 'Theme',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setLightTheme() async {
    state = AsyncData(ThemeMode.light);
    logInfo('Theme changed to light', tag: 'Theme');
    await _saveTheme(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    state = AsyncData(ThemeMode.dark);
    logInfo('Theme changed to dark', tag: 'Theme');
    await _saveTheme(ThemeMode.dark);
  }

  Future<void> setSystemTheme() async {
    state = AsyncData(ThemeMode.system);
    logInfo('Theme changed to system', tag: 'Theme');
    await _saveTheme(ThemeMode.system);
  }

  Future<void> toggleTheme() async {
    final currentTheme = state.value ?? ThemeMode.system;
    switch (currentTheme) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        // При системной теме переключаемся на противоположную
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
          await setLightTheme();
        } else {
          await setDarkTheme();
        }
        break;
    }
  }
}
